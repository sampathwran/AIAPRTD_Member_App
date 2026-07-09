import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';

class CommunityAssistanceProvider extends ChangeNotifier {
  String _selectedIssue = 'Flat Tire';
  String get selectedIssue => _selectedIssue;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  List<Map<String, dynamic>> _nearbyRequests = [];
  List<Map<String, dynamic>> get nearbyRequests => _nearbyRequests;

  StreamSubscription<QuerySnapshot>? _requestsSubscription;
  StreamSubscription<DocumentSnapshot>? _myRequestSubscription;

  String? _myActiveRequestId;
  String? get myActiveRequestId => _myActiveRequestId;

  bool _isMyRequestAccepted = false;
  bool get isMyRequestAccepted => _isMyRequestAccepted;

  final AudioRecorder _audioRecorder = AudioRecorder();

  void selectIssue(String issue) {
    _selectedIssue = issue;
    notifyListeners();
  }

  Future<void> startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final String fileName = 'assistance_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final String filePath = '${directory.path}/$fileName';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );
        _isRecording = true;
        notifyListeners();
      } catch (e) {
        debugPrint("Error starting assistance recording: $e");
      }
    }
  }

  Future<bool> stopRecordingAndSubmit(ProfileProvider profile) async {
    if (!_isRecording) return false;

    try {
      String? path = await _audioRecorder.stop();
      _isRecording = false;
      _isSubmitting = true;
      notifyListeners();

      if (path != null) {
        final memberData = profile.memberData;
        if (memberData == null) return false;

        // 1. Get Location
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
        );

        // 2. Upload Audio
        final File file = File(path);
        final String fileName = path.split('/').last;
        final ref = FirebaseStorage.instance.ref().child('community_assistance_audio/$fileName');
        
        final uploadTask = await ref.putFile(file);
        final String downloadUrl = await uploadTask.ref.getDownloadURL();
        await file.delete();

        // 3. Create Firestore Document
        final String memberId = memberData['membershipNo'] ?? 'Unknown';
        final String requestId = "REQ_${DateTime.now().millisecondsSinceEpoch}";

        await FirebaseFirestore.instance.collection('community_assistance_requests').doc(requestId).set({
          'requestId': requestId,
          'requesterId': memberId,
          'requesterName': memberData['firstName'] ?? 'Unknown',
          'requesterPhone': memberData['mobile'] ?? 'Unknown',
          'issueType': _selectedIssue,
          'voiceNoteUrl': downloadUrl,
          'requesterLocation': GeoPoint(position.latitude, position.longitude),
          'status': 'pending',
          'helperId': null,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _myActiveRequestId = requestId;
        _isMyRequestAccepted = false;
        _listenToMyRequest(requestId);

        _isSubmitting = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error submitting assistance request: $e");
    }
    
    _isSubmitting = false;
    notifyListeners();
    return false;
  }

  void _listenToMyRequest(String requestId) {
    _myRequestSubscription?.cancel();
    _myRequestSubscription = FirebaseFirestore.instance
        .collection('community_assistance_requests')
        .doc(requestId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        var data = snapshot.data();
        if (data != null && data['status'] == 'accepted') {
          _isMyRequestAccepted = true;
          notifyListeners();
        } else if (data != null && data['status'] == 'completed') {
          clearMyRequest();
        }
      }
    });
  }

  void clearMyRequest() {
    _myRequestSubscription?.cancel();
    _myRequestSubscription = null;
    _myActiveRequestId = null;
    _isMyRequestAccepted = false;
    notifyListeners();
  }

  Future<bool> acceptRequest(String requestId, ProfileProvider profile) async {
    try {
      final memberData = profile.memberData;
      if (memberData == null) return false;

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      );

      final String memberId = memberData['membershipNo'] ?? 'Unknown';

      await FirebaseFirestore.instance.collection('community_assistance_requests').doc(requestId).update({
        'status': 'accepted',
        'helperId': memberId,
        'helperName': memberData['firstName'] ?? 'Unknown',
        'helperLocation': GeoPoint(position.latitude, position.longitude),
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint("Error accepting request: $e");
      return false;
    }
  }

  void startListeningForRequests(ProfileProvider profile) {
    if (_requestsSubscription != null) return; // Already listening

    _requestsSubscription = FirebaseFirestore.instance
        .collection('community_assistance_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) async {
      
      final memberData = profile.memberData;
      if (memberData == null) return;
      final String currentMemberId = memberData['membershipNo'] ?? '';
      final double currentLat = memberData['latitude'] ?? 0.0;
      final double currentLng = memberData['longitude'] ?? 0.0;

      List<Map<String, dynamic>> validRequests = [];

      for (var doc in snapshot.docs) {
        var data = doc.data();
        if (data['requesterId'] == currentMemberId) continue; // Skip own requests
        
        GeoPoint? reqLoc = data['requesterLocation'] as GeoPoint?;
        if (reqLoc != null) {
          // Calculate distance in meters
          double distance = Geolocator.distanceBetween(
            currentLat, currentLng, 
            reqLoc.latitude, reqLoc.longitude
          );

          // If within 5km (5000 meters)
          if (distance <= 5000) {
            data['distanceMeters'] = distance;
            validRequests.add(data);
          }
        }
      }

      // Sort by distance
      validRequests.sort((a, b) => (a['distanceMeters'] as double).compareTo(b['distanceMeters'] as double));

      _nearbyRequests = validRequests;
      notifyListeners();
    });
  }

  void stopListeningForRequests() {
    _requestsSubscription?.cancel();
    _requestsSubscription = null;
    _nearbyRequests.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    _myRequestSubscription?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }
}
