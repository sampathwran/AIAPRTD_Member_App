import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TripModel {
  final String id;
  final String type; // "booking" or "road_pickup"
  final DateTime date;
  final double fare;
  final double distanceKm;
  final String startAddress;
  final String endAddress;

  // Status and CancelBy
  final String status;
  final String? cancelBy;

  TripModel({
    required this.id,
    required this.type,
    required this.date,
    required this.fare,
    required this.distanceKm,
    required this.startAddress,
    required this.endAddress,
    this.status = 'completed',
    this.cancelBy,
  });
}

class EarningsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<StreamSubscription> _bookingsSubscriptionList = [];
  final Map<String, List<TripModel>> _bookingTripsMap = {}; // Bookings Map
  final List<StreamSubscription> _roadPickupSubscriptions = []; // Road pickups Streams
  final Map<String, List<TripModel>> _roadTripsMap = {}; // Keep separated by date

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasFetched = false;
  bool get hasFetched => _hasFetched;

  String _timePeriod = 'Monthly'; // Daily, Weekly, Monthly
  String get timePeriod => _timePeriod;

  Future<void> setTimePeriod(String period) async {
    _timePeriod = period;
    _isLoading = true;
    notifyListeners();
    
    // Adding a small delay (to simulate data loading)
    await Future.delayed(const Duration(milliseconds: 400));
    
    _isLoading = false;
    notifyListeners();
  }

  List<TripModel> _bookingTrips = [];
  List<TripModel> _roadPickupTrips = [];

  List<TripModel> get trips {
    List<TripModel> allTrips = [..._bookingTrips, ..._roadPickupTrips];
    
    DateTime now = DateTime.now();
    DateTime startDate;
    
    if (_timePeriod == 'Daily') {
      startDate = DateTime(now.year, now.month, now.day);
    } else if (_timePeriod == 'Weekly') {
      startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
    } else {
      startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
    }

    allTrips = allTrips.where((t) => !t.date.isBefore(startDate)).toList();
    allTrips.sort((a, b) => b.date.compareTo(a.date));
    return allTrips;
  }

  // --- Helpers for Popup ---
  List<TripModel> get allUnfilteredTrips {
    List<TripModel> allTrips = [..._bookingTrips, ..._roadPickupTrips];
    return allTrips.where((t) => t.status != 'cancelled').toList();
  }

  double get todayEarnings {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    return allUnfilteredTrips
        .where((t) => !t.date.isBefore(today))
        .fold(0, (total, trip) => total + trip.fare);
  }

  double get thisWeekEarnings {
    DateTime now = DateTime.now();
    DateTime lastWeek = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
    return allUnfilteredTrips
        .where((t) => !t.date.isBefore(lastWeek))
        .fold(0, (total, trip) => total + trip.fare);
  }

  double get thisMonthEarnings {
    return allUnfilteredTrips.fold(0, (total, trip) => total + trip.fare);
  }
  // --------------------------

  double get totalEarnings => trips
      .where((t) => t.status != 'cancelled')
      .fold(0, (total, trip) => total + trip.fare);

  double get totalBookingsEarnings => trips
      .where((t) => t.type == 'booking' && t.status != 'cancelled')
      .fold(0, (total, trip) => total + trip.fare);

  double get totalRoadPickupEarnings => trips
      .where((t) => t.type == 'road_pickup' && t.status != 'cancelled')
      .fold(0, (total, trip) => total + trip.fare);

  int get totalTrips => trips.length;
  int get totalBookingsCount => trips.where((t) => t.type == 'booking').length;
  int get totalRoadPickupCount => trips.where((t) => t.type == 'road_pickup').length;

  Future<void> fetchEarnings(String membershipNo) async {
    if (membershipNo.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. App Bookings Real-time Streams
      for (var sub in _bookingsSubscriptionList) {
        sub.cancel();
      }
      _bookingsSubscriptionList.clear();
      _bookingTripsMap.clear();

      DateTime now = DateTime.now();
      for (int i = 0; i < 30; i++) {
        DateTime d = now.subtract(Duration(days: i));
        String dateStr = "${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}";

        var sub = _firestore
            .collection('booking_hires')
            .doc(dateStr)
            .collection(membershipNo)
            .snapshots()
            .listen((snap) {

          List<TripModel> dailyBookings = [];
          for (var doc in snap.docs) {
            Map<String, dynamic> data = doc.data();

            String dbStatus = data['status']?.toString().toLowerCase() ?? '';
            String tripState = data['tripState']?.toString().toLowerCase() ?? '';
            String paymentStatus = data['paymentStatus']?.toString().toLowerCase() ?? '';

            bool isCancelled = dbStatus.contains('cancel') || tripState.contains('cancel') || dbStatus.contains('reject') || tripState.contains('reject');

            String finalStatus = 'completed';
            String? finalCancelBy;

            if (isCancelled) {
              finalStatus = 'cancelled';
              String cancelInfo = "${data['cancelReason']} ${data['cancelledBy']} ${data['cancelBy']}".toLowerCase();
              if (cancelInfo.contains('passenger') || cancelInfo.contains('customer')) {
                finalCancelBy = 'passenger';
              } else if (cancelInfo.contains('driver')) {
                finalCancelBy = 'driver';
              } else {
                finalCancelBy = 'unknown';
              }
            } else {
              bool isCompleted = dbStatus == 'completed' || tripState == 'completed' || paymentStatus == 'collected';
              if (!isCompleted) continue;
            }

            DateTime tripDate;
            if (data['pickupTime'] != null) {
              tripDate = DateTime.tryParse(data['pickupTime'].toString()) ?? DateTime.now();
            } else if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
              tripDate = (data['timestamp'] as Timestamp).toDate();
            } else {
              tripDate = DateTime.now();
            }

            double fare = 0;
            if (data['totalFare'] != null) {
              fare = double.tryParse(data['totalFare'].toString()) ?? 0;
            } else if (data['bidAmount'] != null) {
              fare = double.tryParse(data['bidAmount'].toString()) ?? 0;
            }

            String pickupLoc = data['pickupLocation'] is Map ? (data['pickupLocation']['address']?.toString() ?? 'Unknown') : (data['pickupLocation']?.toString() ?? 'Unknown');
            String dropLoc = data['dropLocation'] is Map ? (data['dropLocation']['address']?.toString() ?? 'Unknown') : (data['dropLocation']?.toString() ?? 'Unknown');

            dailyBookings.add(TripModel(
              id: doc.id,
              type: 'booking',
              date: tripDate,
              fare: fare,
              distanceKm: double.tryParse(data['distance']?.toString() ?? '0') ?? 0,
              startAddress: pickupLoc,
              endAddress: dropLoc,
              status: finalStatus,
              cancelBy: finalCancelBy,
            ));
          }

          _bookingTripsMap[dateStr] = dailyBookings;
          _bookingTrips = _bookingTripsMap.values.expand((x) => x).toList();
          notifyListeners();

        }, onError: (e) {
          debugPrint("EarningsProvider: Booking Stream failed for $dateStr");
        });

        _bookingsSubscriptionList.add(sub);
      }

      // 2. Road Pickups Real-time Streams (Now removed from App as soon as it's deleted from Firebase)
      for (var sub in _roadPickupSubscriptions) {
        sub.cancel(); // Cancel previous streams
      }
      _roadPickupSubscriptions.clear();
      _roadTripsMap.clear();

      for (int i = 0; i < 30; i++) {
        DateTime d = now.subtract(Duration(days: i));
        String dateStr = "${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}";

        var sub = _firestore
            .collection('roadpickups_hires')
            .doc(dateStr)
            .collection(membershipNo)
            .snapshots() // Added snapshots() instead of one-time get()!
            .listen((snap) {

          List<TripModel> dailyTrips = [];
          for (var doc in snap.docs) {
            Map<String, dynamic> data = doc.data();

            if (data.containsKey('tripId') && data.containsKey('totalFare')) {
              DateTime tripDate = data['pickupTime'] != null ? (DateTime.tryParse(data['pickupTime'].toString()) ?? DateTime.now()) : DateTime.now();

              dailyTrips.add(TripModel(
                id: data['tripId'] ?? doc.id,
                type: 'road_pickup',
                date: tripDate,
                fare: double.tryParse(data['totalFare'].toString()) ?? 0,
                distanceKm: double.tryParse(data['distanceKm'].toString()) ?? 0,
                startAddress: data['startAddress'] ?? 'Street Pickup',
                endAddress: data['endAddress'] ?? 'Street Drop',
                status: 'completed',
              ));
            }
          }

          // Add updated day's data into the Map and refresh UI
          _roadTripsMap[dateStr] = dailyTrips;
          _roadPickupTrips = _roadTripsMap.values.expand((x) => x).toList();
          notifyListeners(); // Updates UI as soon as it's deleted from the database

        }, onError: (e) {
          debugPrint("EarningsProvider: Stream failed for $dateStr");
        });

        _roadPickupSubscriptions.add(sub);
      }

    } catch (e) {
      debugPrint("Error fetching earnings: $e");
    } 

    // Add a small delay (give time for Streams to load)
    await Future.delayed(const Duration(milliseconds: 800));

    _isLoading = false;
    _hasFetched = true;
    notifyListeners();
  }

  Future<bool> deleteTrip(TripModel trip, String membershipNo) async {
    try {
      final dateStr = "${trip.date.year}.${trip.date.month.toString().padLeft(2, '0')}.${trip.date.day.toString().padLeft(2, '0')}";
      
      if (trip.type == 'booking') {
        await _firestore
            .collection('booking_hires')
            .doc(dateStr)
            .collection(membershipNo)
            .doc(trip.id)
            .delete();
      } else if (trip.type == 'road_pickup') {
        await _firestore
            .collection('roadpickups_hires')
            .doc(dateStr)
            .collection(membershipNo)
            .doc(trip.id)
            .delete();
      }
      
      // Also update local list immediately
      if (trip.type == 'booking') {
        _bookingTrips.removeWhere((t) => t.id == trip.id);
      } else {
        _roadPickupTrips.removeWhere((t) => t.id == trip.id);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error deleting trip: $e");
      return false;
    }
  }

  @override
  void dispose() {
    for (var sub in _bookingsSubscriptionList) {
      sub.cancel();
    }
    for (var sub in _roadPickupSubscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}