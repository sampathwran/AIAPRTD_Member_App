import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:aiaprtd_member/core/services/notification_service.dart';

class ParkingProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State Variables
  List<Map<String, dynamic>> _geofences = [];
  List<Map<String, dynamic>> _parkingSlots = [];

  // Current status
  bool _isInAirportQueue = false;
  int _airportQueuePosition = 0;
  String? _currentParkedSlotId;

  // Getters
  bool get isInAirportQueue => _isInAirportQueue;
  int get airportQueuePosition => _airportQueuePosition;
  String? get currentParkedSlotId => _currentParkedSlotId;
  List<Map<String, dynamic>> get parkingSlots => _parkingSlots;
  List<Map<String, dynamic>> get geofences => _geofences;

  ParkingProvider() {
    _fetchGeofences();
    _listenToParkingSlots();
  }

  // 1. Fetch Geofences
  Future<void> _fetchGeofences() async {
    try {
      final snapshot = await _firestore.collection('geofences').get();
      _geofences = snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching geofences: $e');
    }
  }

  // 3. Process Location Updates (Called from HomePage)
  Future<void> processLocationUpdate(
      double lat, double lng, String memberNo) async {
    if (memberNo.isEmpty) return;

    _checkAirportGeofence(lat, lng, memberNo);
    _checkCityParkingAutoLeave(lat, lng, memberNo);
  }

  // 4. Airport Geofence Check
  Future<void> _checkAirportGeofence(
      double lat, double lng, String memberNo) async {
    bool foundInZone = false;

    for (var zone in _geofences) {
      if (zone['name'] == 'Airport' || zone['name'] == 'Airport Queue') {
        double distance = Geolocator.distanceBetween(
          lat,
          lng,
          zone['latitude'],
          zone['longitude'],
        );

        if (distance <= (zone['radius'] ?? 1000)) {
          foundInZone = true;
          break;
        }
      }
    }

    if (foundInZone) {
      if (!_isInAirportQueue) {
        // Just entered
        await _enterAirportQueue(memberNo);
      } else {
        // Already in, just update position
        await _updateQueuePosition(memberNo);
      }
    } else {
      if (_isInAirportQueue) {
        // Just left
        await _leaveAirportQueue(memberNo);
      }
    }
  }

  Future<void> _enterAirportQueue(String memberNo) async {
    try {
      final docRef = _firestore.collection('airport_queue').doc(memberNo);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'memberNo': memberNo,
          'enteredAt': FieldValue.serverTimestamp(),
          'status': 'waiting'
        });
      }
      _isInAirportQueue = true;
      await _updateQueuePosition(memberNo);
    } catch (e) {
      print(e);
    }
  }

  Future<void> _updateQueuePosition(String memberNo) async {
    // Stub
  }

  Future<void> _leaveAirportQueue(String memberNo) async {
    // Stub
  }

  Future<void> _listenToParkingSlots() async {
    // Stub
  }

  Future<void> _checkCityParkingAutoLeave(
      double lat, double lng, String memberNo) async {
    // Stub
  }

  Future<void> leaveParking(String memberNo) async {
    // Stub
  }
}
