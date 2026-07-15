// ignore_for_file: spell_check_on_languages, spell_check_on_word

import 'dart:async';
import 'dart:io';
import 'package:app_to_foreground/app_to_foreground.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_bubble/dash_bubble.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

// 💡 NEW: Added `WidgetsBindingObserver` to check if the App is Minimized
class ProfileProvider extends ChangeNotifier with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Map<String, dynamic>? _memberData;
  bool _isLoading = false;
  bool _isLocalLoading = false;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _memberStreamSubscription;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _profileImageRequestSubscription;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _sessionSubscription;

  // 💡 NEW: Subscription for Rating Sync
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _ratingSyncSubscription;

  // 💡 NEW: Start App Lifecycle Observer in Constructor
  ProfileProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  // ==========================================================
  // 💡 NEW: Bubble Control when App is Minimized and Opened
  // ==========================================================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bool isOnline = _memberData?['isOnline'] == true;

    if (isOnline) {
      if (state == AppLifecycleState.paused) {
        // Show Bubble when App goes to Background (Minimize)
        _startFloatingBubble();
      } else if (state == AppLifecycleState.resumed) {
        // Hide Bubble when App comes to Foreground
        _stopFloatingBubble();
      }
    } else {
      _stopFloatingBubble();
    }
  }

  Map<String, dynamic>? get memberData => _memberData;
  bool get isLoading => _isLoading;
  bool get isLocalLoading => _isLocalLoading;

  String get memberStatus =>
      _memberData?['status']?.toString() ?? 'inactive';

  bool get isOnline => _memberData?['isOnline'] == true;

  String get collectionSource =>
      _memberData?['collectionSource']?.toString() ?? 'member';

  String get inactiveReason =>
      _memberData?['inactiveReason']?.toString() ??
      _memberData?['rejectionReason']?.toString() ??
      _memberData?['adminMessage']?.toString() ??
      "Your account is currently inactive. Please contact the Union Administrator for more details.";

  String get memberFullName =>
      _memberData?['fullName']?.toString() ?? 'Member';

  String get memberNo =>
      _memberData?['membershipNo']?.toString() ?? 'N/A';

  String get documentId =>
      _memberData?['docId']?.toString() ?? memberNo;

  String get profileImageUrl =>
      _memberData?['profileImageUrl']?.toString() ??
          _memberData?['imageUrl']?.toString() ??
          '';

  List<String> get grantedBenefits {
    if (_memberData?['grantedBenefits'] is List) {
      return List<String>.from(_memberData!['grantedBenefits']);
    }
    return [];
  }

  Future<bool> fetchAndStoreMemberData() async {
    _isLoading = true;
    notifyListeners();

    await clearProfileStreams();

    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final Completer<bool> completer = Completer<bool>();

      Query<Map<String, dynamic>> memberQuery = _firestore.collection('member');
      
      if (currentUser.email != null && currentUser.email!.isNotEmpty) {
        memberQuery = memberQuery.where('user_email', isEqualTo: currentUser.email);
      } else {
        memberQuery = memberQuery.where('auth_uid', isEqualTo: currentUser.uid);
      }

      _memberStreamSubscription = memberQuery
          .limit(1)
          .snapshots()
          .listen(
            (querySnapshot) async {
          QueryDocumentSnapshot<Map<String, dynamic>>? memberDocument;
          String collectionSource = 'member';

          if (querySnapshot.docs.isEmpty) {
            // Fallback to web_sync_member
            Query<Map<String, dynamic>> webSyncQuery = _firestore.collection('web_sync_member');
            if (currentUser.email != null && currentUser.email!.isNotEmpty) {
              webSyncQuery = webSyncQuery.where('user_email', isEqualTo: currentUser.email);
            } else {
              webSyncQuery = webSyncQuery.where('auth_uid', isEqualTo: currentUser.uid);
            }
            var webSyncSnapshot = await webSyncQuery.limit(1).get();
            
            if (webSyncSnapshot.docs.isEmpty) {
              _memberData = null;
              _isLoading = false;
              notifyListeners();

              if (!completer.isCompleted) {
                completer.complete(false);
              }
              return;
            }
            memberDocument = webSyncSnapshot.docs.first;
            collectionSource = 'web_sync_member';
          } else {
            memberDocument = querySnapshot.docs.first;
          }

          debugPrint("🟢 ProfileProvider: Successfully found in '$collectionSource' collection!");

          _memberData = Map<String, dynamic>.from(
            memberDocument.data(),
          );

          _memberData!['docId'] = memberDocument.id;
          _memberData!['collectionSource'] = collectionSource; // 💡 NEW: Expose source collection

          // 💡 🎯 FIXED: Use docId if membershipNo field is missing in member collection
          if (_memberData!['membershipNo'] == null || _memberData!['membershipNo'].toString().isEmpty) {
            _memberData!['membershipNo'] = memberDocument.id;
          }

          final String membershipNo =
              _memberData!['membershipNo']?.toString() ?? '';

          if (membershipNo.isNotEmpty) {
            await _loadPaymentData(membershipNo);
            await _loadVehicleCategory(membershipNo);
            _listenToProfileImageRequest(membershipNo);
          }

          _isLoading = false;
          notifyListeners();

          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
        onError: (error) {
          debugPrint('Error fetching member stream: $error');

          _isLoading = false;
          notifyListeners();

          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );

      return await completer.future;
    } catch (error) {
      debugPrint('Error fetching member data: $error');

      _isLoading = false;
      notifyListeners();

      return false;
    }
  }

  Future<void> _loadPaymentData(String membershipNo) async {
    try {
      if (_memberData == null) return;
      
      List<dynamic> combinedHistory = [];

      // 1. Fetch from app_membership_fee
      final appDoc = await _firestore.collection('app_membership_fee').doc(membershipNo).get();
      if (appDoc.exists && appDoc.data() != null) {
        final data = appDoc.data()!;
        if (data['payment_history'] != null && data['payment_history'] is List) {
          combinedHistory.addAll(data['payment_history']);
        }
      }

      // 2. Fetch from web_sync_membership_fee
      final webDoc = await _firestore.collection('web_sync_membership_fee').doc(membershipNo).get();
      if (webDoc.exists && webDoc.data() != null) {
        final data = webDoc.data()!;
        if (data['payment_history'] != null && data['payment_history'] is List) {
          combinedHistory.addAll(data['payment_history']);
        }
      }

      // 3. Fallback to old payments collection just in case
      final paymentDoc = await _firestore.collection('payments').doc(membershipNo).get();
      if (paymentDoc.exists && paymentDoc.data() != null) {
        final data = paymentDoc.data()!;
        if (data['payment_history'] != null && data['payment_history'] is List) {
          combinedHistory.addAll(data['payment_history']);
        }
      }

      _memberData!['payment_history'] = combinedHistory;
      
    } catch (error) {
      debugPrint('Error fetching payment data: $error');
    }
  }

  Future<void> _loadVehicleCategory(String membershipNo) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> vehicleDocument =
          await _firestore.collection('vehicles').doc(membershipNo).get();

      if (!vehicleDocument.exists || vehicleDocument.data() == null || _memberData == null) {
        return;
      }

      final Map<String, dynamic> vehicleData = vehicleDocument.data()!;
      _memberData!['vehicle_category'] = vehicleData['vehicle_category'] ?? vehicleData['selectedCategory'] ?? '';
      _memberData!['selectedCategory'] = vehicleData['selectedCategory'] ?? vehicleData['vehicle_category'] ?? '';
    } catch (e) {
      debugPrint("Error loading vehicle category: $e");
    }
  }

  void _listenToProfileImageRequest(
      String membershipNo,
      ) {
    _profileImageRequestSubscription?.cancel();

    _profileImageRequestSubscription = _firestore
        .collection('profile_image_requests')
        .doc(membershipNo)
        .snapshots()
        .listen(
          (document) {
        if (!document.exists ||
            document.data() == null ||
            _memberData == null) {
          return;
        }

        final Map<String, dynamic> requestData = document.data()!;

        _memberData!['imageRequestStatus'] =
        requestData['status'];

        _memberData!['imageRejectReason'] =
        requestData['rejectReason'];

        notifyListeners();
      },
      onError: (error) {
        debugPrint(
          'Profile image request listener error: $error',
        );
      },
    );
  }



  // 💡 🎯 UPDATED: Added Timeout and Error Handling
  Future<bool> toggleDriverStatus(
      bool isGoingOnline,
      ) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null || _memberData == null) {
      return false;
    }

    _isLocalLoading = true;
    notifyListeners();

    try {
      // 💡 Added Timeout to strictly complete within 10 seconds
      await _firestore
          .collection('member')
          .doc(documentId)
          .set(
        {
          'isOnline': isGoingOnline,
          'onlineStatus':
          isGoingOnline ? 'online' : 'offline',
          'lastSeen': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException("Firebase update timed out");
      });

      _memberData!['isOnline'] = isGoingOnline;
      _memberData!['onlineStatus'] =
      isGoingOnline ? 'online' : 'offline';

      if (isGoingOnline) {
        // 💡 NEW: Request Permission when going Online.
        // (Request early because we cannot request permission when App is Minimized)
        bool hasPermission = await DashBubble.instance.hasOverlayPermission();
        if (!hasPermission) {
          await DashBubble.instance.requestOverlayPermission();
        }
      } else {
        // Hide Bubble anyway when going Offline
        await _stopFloatingBubble();
      }

      _isLocalLoading = false;
      notifyListeners();
      return true;

    } on TimeoutException catch (e) {
      debugPrint('Firebase status sync TIMEOUT: $e');
      _isLocalLoading = false; // 💡 Strictly release button
      notifyListeners();
      return false;
    } catch (error) {
      debugPrint('Firebase status sync error: $error');
      _isLocalLoading = false; // 💡 Strictly release button
      notifyListeners();
      return false;
    }
  }

  Future<void> updateLiveLocation(
      double latitude,
      double longitude,
      double bearing,
      ) async {
    if (_auth.currentUser == null || _memberData == null) {
      return;
    }

    try {
      final Map<String, dynamic> locationData = {
        'latitude': latitude,
        'longitude': longitude,
        'bearing': bearing,
        'lastLocationUpdate':
        FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('member')
          .doc(documentId)
          .set(
        locationData,
        SetOptions(merge: true),
      ).timeout(const Duration(seconds: 10)); // 💡 Added timeout to Location update as well

      _memberData!['latitude'] = latitude;
      _memberData!['longitude'] = longitude;
      _memberData!['bearing'] = bearing;

      notifyListeners();
    } catch (error) {
      debugPrint('Location sync error: $error');
    }
  }

  Future<String> uploadFaceSelfie(
      File selfieFile,
      String membershipNo,
      ) async {
    try {
      final Reference storageReference = _storage
          .ref()
          .child('member_selfies/$membershipNo.jpg');

      final TaskSnapshot snapshot =
      await storageReference.putFile(selfieFile);

      return await snapshot.ref.getDownloadURL();
    } catch (error) {
      throw Exception(
        'Face selfie upload failed: $error',
      );
    }
  }

  Future<bool> submitOneTimeRegistrationDetails({
    required String membershipNo,
    required String fullName,
    required String email,
    required String mobile,
    required String nic,
    required String address,
    required String dob,
    required String religion,
    required File idFrontFile,
    required File idBackFile,
    required String faceImageUrl,
  }) async {
    try {
      await _firestore
          .collection('kyc_requests')
          .doc(membershipNo)
          .set({
        'membershipNo': membershipNo,
        'fullName': fullName,
        'email': email,
        'mobile': mobile,
        'nic': nic,
        'address': address,
        'dob': dob,
        'religion': religion,
        'faceImageUrl': faceImageUrl,
        'idFrontUrl': '',
        'idBackUrl': '',
        'status': 'pending',
        'submittedAt':
        FieldValue.serverTimestamp(),
      });

      return true;
    } catch (error) {
      debugPrint('KYC data submission error: $error');
      return false;
    }
  }

  void listenToDeviceSession(
      BuildContext context,
      String currentDeviceToken,
      ) {
    if (_memberData == null) {
      return;
    }

    final String membershipNo =
        _memberData!['membershipNo']?.toString().trim() ?? '';

    if (membershipNo.isEmpty) {
      return;
    }

    _sessionSubscription?.cancel();

    _sessionSubscription = _firestore
        .collection(collectionSource) // 👈 Use the actual collection the document is in!
        .doc(documentId)
        .snapshots()
        .listen(
          (snapshot) async {
        if (!snapshot.exists || snapshot.data() == null) {
          return;
        }

        final Map<String, dynamic> databaseData =
        snapshot.data()!;

        final String? savedDeviceToken =
        databaseData['currentDeviceToken']?.toString();

        if (savedDeviceToken == null ||
            savedDeviceToken == currentDeviceToken) {
          return;
        }

        await _sessionSubscription?.cancel();

        if (!context.mounted) {
          return;
        }

        clearUserData();
        await _auth.signOut();

        if (!context.mounted) {
          return;
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Session Expired',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: const Text(
                'You have been logged out because your account was logged into from another device.',
                style: TextStyle(fontSize: 14),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                          (route) => false,
                    );
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      onError: (error) {
        debugPrint('Session listener error: $error');
      },
    );
  }

  Future<void> _startFloatingBubble() async {
    try {
      bool hasPermission = await DashBubble.instance.hasOverlayPermission();

      if (!hasPermission) {
        // Cannot request permission when App is in Background. Therefore, return.
        return;
      }

      await DashBubble.instance.startBubble(
        bubbleOptions: BubbleOptions(
          bubbleIcon: 'my_bubble_icon', // 👈 Changed logo
          enableClose: false,
          distanceToClose: 100,
          enableAnimateToEdge: true,
          enableBottomShadow: true,
        ),
        notificationOptions: NotificationOptions(
          id: 101,
          title: 'AIAPRTD Driver Active',
          body: 'You are currently online. Tap to open app.',
          icon: 'my_bubble_icon', // 👈 Same for Notification icon
        ),
        onTap: () {
          debugPrint('Floating bubble clicked - Opening App...');
          // 💡 NEW: Brings App to Foreground when bubble is pressed.
          // Then bubble will automatically Hide through didChangeAppLifecycleState above!
          AppToForeground.appToForeground();
        },
      );
    } catch (error) {
      debugPrint('Bubble start error: $error');
    }
  }

  Future<void> _stopFloatingBubble() async {
    try {
      final bool isRunning = await DashBubble.instance.isRunning();

      if (isRunning) {
        await DashBubble.instance.stopBubble();
      }
    } catch (error) {
      debugPrint('Bubble stop error: $error');
    }
  }

  void clearUserData() {
    clearProfileStreams();
    _stopFloatingBubble();

    _memberData = null;
    _isLoading = false;
    _isLocalLoading = false;

    notifyListeners();
  }

  Future<void> clearProfileStreams() async {
    await _memberStreamSubscription?.cancel();
    _memberStreamSubscription = null;

    await _profileImageRequestSubscription?.cancel();
    _profileImageRequestSubscription = null;

    await _sessionSubscription?.cancel();
    _sessionSubscription = null;

    await _ratingSyncSubscription?.cancel();
    _ratingSyncSubscription = null;
  }

  @override
  void dispose() {
    // 💡 NEW: Remove Observer
    WidgetsBinding.instance.removeObserver(this);
    clearProfileStreams();
    super.dispose();
  }
}