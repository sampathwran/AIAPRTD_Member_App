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
      // 
        data['id'] = doc.id;
        return data;
      }).toList();
      notifyListeners();
    });
  }

  // 3. Process Location Updates (Called from HomePage)
  Future<void> processLocationUpdate(double lat, double lng, String memberNo) async {
    if (memberNo.isEmpty) return;

    _checkAirportGeofence(lat, lng, memberNo);
    _checkCityParkingAutoLeave(lat, lng, memberNo);
  }

  // 4. Airport Geofence Check
  Future<void> _checkAirportGeofence(double lat, double lng, String memberNo) async {
    bool foundInZone = false;

    for (var zone in _geofences) {
      if (zone['name'] == 'Airport' || zone['name'] == 'Airport Queue') {
        double distance = Geolocator.distanceBetween(
          lat, lng,
          zone['latitude'], zone['longitude'],
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
      // 
      _isInAirportQueue = false;
      _airportQueuePosition = 0;
      notifyListeners();
    } catch (e) {
      // 
      
      int pos = 1;
      bool found = false;
      for (var doc in snapshot.docs) {
        if (doc.id == memberNo) {
          found = true;
          break;
        }
        pos++;
      }

      if (found) {
        _airportQueuePosition = pos;
        notifyListeners();
      }
    } catch (e) {
      // 
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;
        
        int occupied = snapshot.data()?['occupied'] ?? 0;
        int capacity = snapshot.data()?['capacity'] ?? 0;
        List<dynamic> parkedMembers = snapshot.data()?['parkedMembers'] ?? [];

        if (occupied < capacity && !parkedMembers.contains(memberNo)) {
          parkedMembers.add(memberNo);
          transaction.update(docRef, {
            'occupied': occupied + 1,
            'parkedMembers': parkedMembers,
          });
          _currentParkedSlotId = slotId;
        }
      });
      notifyListeners();
    } catch (e) {
      // 
    if (targetSlotId == null) return;

    try {
      final docRef = _firestore.collection('parking_slots').doc(targetSlotId);
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;
        
        int occupied = snapshot.data()?['occupied'] ?? 0;
        List<dynamic> parkedMembers = snapshot.data()?['parkedMembers'] ?? [];

        if (parkedMembers.contains(memberNo)) {
          parkedMembers.remove(memberNo);
          transaction.update(docRef, {
            'occupied': (occupied > 0) ? occupied - 1 : 0,
            'parkedMembers': parkedMembers,
          });
        }
      });

      if (_currentParkedSlotId == targetSlotId) {
        _currentParkedSlotId = null;
        
        // Notify user via Snack bar if context is provided
        if (context != null && context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("You have automatically left the parking slot."),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 4),
              ),
            );
        }
      }
      notifyListeners();
    } catch (e) {
      // 

    // Find the current slot data
    final slot = _parkingSlots.firstWhere(
      (s) => s['id'] == _currentParkedSlotId,
      orElse: () => {},
    );

    if (slot.isNotEmpty) {
      double distance = Geolocator.distanceBetween(
        lat, lng,
        slot['latitude'], slot['longitude'],
      );

      // If driver is more than 300 meters away from the parking slot, auto-remove them
      if (distance > 300) {
        await leaveParking(memberNo);
        NotificationService().showLocalNotification(
          id: 999123,
          title: "Parking Update",
          body: "You have been automatically removed from ${slot['name']} parking slot because you left the area.",
        );
      }
    }
  }
}
