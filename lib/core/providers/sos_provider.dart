import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class SosProvider extends ChangeNotifier {
  bool _isSosActive = false;
  bool get isSosActive => _isSosActive;

  String? _currentSosId;
  String? get currentSosId => _currentSosId;

  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _recordingTimer;
  StreamSubscription<Position>? _locationSubscription;
  
  bool _isRecording = false;

  /// Starts the SOS Process
  Future<void> startSos(ProfileProvider profile) async {
    if (_isSosActive) return;

    final memberData = profile.memberData;
    if (memberData == null) return;

    _isSosActive = true;
    notifyListeners();

    try {
      // 1. Get exact current location
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      );

      // 2. Create SOS Document ID
      final String memberId = memberData['membershipNo'] ?? 'Unknown';
      _currentSosId = "${memberId}_${DateTime.now().millisecondsSinceEpoch}";

      // 3. Save to Firestore
      final sosDoc = FirebaseFirestore.instance.collection('sos_alerts').doc(_currentSosId);
      await sosDoc.set({
        'sosId': _currentSosId,
        'memberId': memberId,
        'memberName': memberData['firstName'] ?? 'Unknown',
        'memberPhone': memberData['mobile'] ?? 'Unknown',
        'startLocation': GeoPoint(position.latitude, position.longitude),
        'currentLocation': GeoPoint(position.latitude, position.longitude),
        'status': 'active',
        'voiceRecordingUrls': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Start Continuous Recording (30 sec chunks)
      _startContinuousRecording();

      // 5. Start high-frequency location streaming
      _startLocationStreaming(sosDoc);

    } catch (e) {
      debugPrint("Failed to start SOS: $e");
      _isSosActive = false;
      notifyListeners();
    }
  }

  /// Stops the SOS process (requires PIN check before calling this)
  Future<void> cancelSos() async {
    if (!_isSosActive || _currentSosId == null) return;

    _isSosActive = false;
    notifyListeners();

    try {
      // 1. Stop recording and timer
      _recordingTimer?.cancel();
      _recordingTimer = null;
      if (_isRecording) {
        String? finalPath = await _audioRecorder.stop();
        _isRecording = false;
        if (finalPath != null) {
          _uploadAudioChunk(finalPath);
        }
      }

      // 2. Stop location streaming
      _locationSubscription?.cancel();
      _locationSubscription = null;

      // 3. Mark Firestore doc as resolved
      await FirebaseFirestore.instance.collection('sos_alerts').doc(_currentSosId).update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      _currentSosId = null;

    } catch (e) {
      debugPrint("Error cancelling SOS: $e");
    }
  }

  /// Validates PIN from member profile
  Future<bool> validatePin(String pin, String memberId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('member').doc(memberId).get();
      if (doc.exists) {
        final data = doc.data();
        // Fallback: If no sosPin is set, use mobile number or '1234' as default for testing
        String expectedPin = data?['sosPin']?.toString() ?? '1234'; 
        return pin == expectedPin;
      }
    } catch (e) {
      debugPrint("PIN validation error: $e");
    }
    return false;
  }

  // --- PRIVATE METHODS ---

  void _startContinuousRecording() async {
    if (await _audioRecorder.hasPermission()) {
      _recordNextChunk();
      
      // Every 30 seconds, stop the current recording and start a new one
      _recordingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
        if (!_isSosActive) {
          timer.cancel();
          return;
        }

        if (_isRecording) {
          String? path = await _audioRecorder.stop();
          _isRecording = false;
          if (path != null) {
            _uploadAudioChunk(path);
          }
        }
        
        // Start next chunk immediately
        if (_isSosActive) {
          _recordNextChunk();
        }
      });
    } else {
      debugPrint("Microphone permission denied.");
    }
  }

  Future<void> _recordNextChunk() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = 'sos_chunk_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final String filePath = '${directory.path}/$fileName';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );
      _isRecording = true;
    } catch (e) {
      debugPrint("Error starting audio chunk: $e");
    }
  }

  Future<void> _uploadAudioChunk(String filePath) async {
    if (_currentSosId == null) return;
    
    final File file = File(filePath);
    if (!await file.exists()) return;

    try {
      final String fileName = filePath.split('/').last;
      final ref = FirebaseStorage.instance.ref().child('sos_audio/$_currentSosId/$fileName');
      
      final uploadTask = await ref.putFile(file);
      final String downloadUrl = await uploadTask.ref.getDownloadURL();

      // Update Firestore array
      await FirebaseFirestore.instance.collection('sos_alerts').doc(_currentSosId).update({
        'voiceRecordingUrls': FieldValue.arrayUnion([downloadUrl])
      });
      
      // Clean up local file
      await file.delete();
    } catch (e) {
      debugPrint("Error uploading audio chunk: $e");
    }
  }

  void _startLocationStreaming(DocumentReference sosDoc) {
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      )
    ).listen((Position position) {
      if (_isSosActive) {
        sosDoc.update({
          'currentLocation': GeoPoint(position.latitude, position.longitude),
        });
      }
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _locationSubscription?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }
}
