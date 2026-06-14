// ==========================================
// 1. IMPORTS SECTION
// ==========================================
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

// ==========================================
// 2. MEMBER PROVIDER CLASS SECTION
// ==========================================
class MemberProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _memberData;
  bool _isLoading = false;

  StreamSubscription<QuerySnapshot>? _memberStreamSubscription;

  // ==========================================
  // 3. GETTERS SECTION
  // ==========================================
  Map<String, dynamic>? get memberData => _memberData;
  bool get isLoading => _isLoading;

  String get memberStatus => _memberData?['status'] ?? 'inactive';
  String get memberFullName => _memberData?['fullName'] ?? 'Member';

  String get profileImageUrl {
    String url = _memberData?['profileImageUrl'] ?? '';
    debugPrint("DEBUG: පින්තූරයේ URL එක: $url");
    return url;
  }

  // ==========================================
  // 4. DATA FETCH & AUTO SYNC LOGIC
  // ==========================================

  Future<bool> fetchAndStoreMemberData() async {
    _isLoading = true;
    notifyListeners();

    await _cancelActiveStream();

    try {
      User? currentUser = _auth.currentUser;

      if (currentUser != null && currentUser.email != null) {
        final Completer<bool> completer = Completer<bool>();

        _memberStreamSubscription = _firestore
            .collection('member')
            .where('user_email', isEqualTo: currentUser.email)
            .limit(1)
            .snapshots()
            .listen(
              (querySnapshot) async { // async එකතු කරන ලදී
            if (querySnapshot.docs.isNotEmpty) {
              var memberDoc = querySnapshot.docs.first;
              _memberData = Map<String, dynamic>.from(memberDoc.data());

              // requests collection එකෙන් අදාළ පින්තූරය පරීක්ෂා කිරීම
              try {
                String memNo = _memberData!['membershipNo'] ?? 'N/A';
                var requestDoc = await _firestore.collection('requests').doc(memNo).get();

                if (requestDoc.exists && requestDoc.data() != null) {
                  // requests එකේ පින්තූරය තිබේ නම් එය තාවකාලිකව පෙන්වීම සඳහා memberData එකට දාගන්න
                  _memberData!['profileImageUrl'] = requestDoc.data()!['newImageUrl'];
                }
              } catch (e) {
                debugPrint("Error fetching request image: $e");
              }

              _isLoading = false;
              notifyListeners();

              if (!completer.isCompleted) completer.complete(true);
            } else {
              _isLoading = false;
              notifyListeners();
              if (!completer.isCompleted) completer.complete(false);
            }
          },
          onError: (error) {
            _isLoading = false;
            notifyListeners();
            if (!completer.isCompleted) completer.complete(false);
          },
        );

        return await completer.future;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint("Error fetching member: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // 5. PROFILE IMAGE REQUEST LOGIC
  // ==========================================
  Future<bool> submitProfileImageRequest(String memNo, File imageFile) async {
    _isLoading = true;
    notifyListeners();

    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('pending_profiles')
          .child(memNo)
          .child(fileName);

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // requests collection එකට Document ID එක membershipNo ලෙස දීම
      await _firestore.collection('requests').doc(memNo).set({
        'membershipNo': memNo,
        'newImageUrl': downloadUrl,
        'status': 'pending',
        'requestType': 'profile_update',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint("Error in submitProfileImageRequest: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // 6. CLEANUP & LOGOUT LOGIC
  // ==========================================

  Future<void> clearMemberData() async {
    await _cancelActiveStream();
    _memberData = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _cancelActiveStream() async {
    if (_memberStreamSubscription != null) {
      await _memberStreamSubscription!.cancel();
      _memberStreamSubscription = null;
    }
  }

  @override
  void dispose() {
    _cancelActiveStream();
    super.dispose();
  }
}