import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';

class MeterProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Meter State
  bool _isRunning = false;
  bool _isWaiting = false;
  bool _isWaitingPaused = false;
  bool _isTripCompleted = false; // New state for showing summary
  
  double _totalDistanceKm = 0.0;
  int _waitingTimeSeconds = 0;
  double _currentSpeedKmh = 0.0;
  
  double _totalFare = 0.0;

  // Rate Info
  double _baseFare = 0.0;
  double _baseDistance = 0.0;
  double _perKm = 0.0;
  double _perMinute = 0.0;
  bool _ratesLoaded = false;

  // Tracking
  Position? _lastPosition;
  StreamSubscription<Position>? _positionStream;
  Timer? _waitingTimer;

  // Trip Summary Data
  final List<Position> _routePoints = [];
  String _startAddress = "Fetching...";
  String _endAddress = "Fetching...";
  String _tripId = "";
  DateTime? _startTime;
  DateTime? _endTime;
  
  // Getters
  bool get isRunning => _isRunning;
  bool get isWaiting => _isWaiting;
  bool get isWaitingPaused => _isWaitingPaused;
  bool get isTripCompleted => _isTripCompleted;
  double get totalDistanceKm => _totalDistanceKm;
  int get waitingTimeSeconds => _waitingTimeSeconds;
  double get currentSpeedKmh => _currentSpeedKmh;
  double get totalFare => _totalFare;
  bool get ratesLoaded => _ratesLoaded;
  List<Position> get routePoints => _routePoints;
  String get startAddress => _startAddress;
  String get endAddress => _endAddress;
  String get tripId => _tripId;
  DateTime? get startTime => _startTime;
  DateTime? get endTime => _endTime;

  Future<void> fetchRates(String categoryId) async {
    try {
      String norm = categoryId.toLowerCase().replaceAll(' ', '').replaceAll('_', '').replaceAll('van', '');
      String docId = categoryId.toLowerCase();
      if (norm.contains('budget')) docId = 'budget';
      else if (norm.contains('mini')) docId = 'mini';
      else if (norm.contains('sedan')) docId = 'sedan';
      else if (norm.contains('6seater')) docId = '6_seater';
      else if (norm.contains('9seater')) docId = '9_seater';
      else if (norm.contains('14seater')) docId = '14_seater';

      final doc = await _firestore.collection('rates').doc(docId).get();
      if (doc.exists) {
        final data = doc.data()!;
        _baseFare = (data['baseFare'] ?? 0.0).toDouble();
        _baseDistance = (data['baseDistance'] ?? 0.0).toDouble();
        _perKm = (data['perKm'] ?? 0.0).toDouble();
        _perMinute = (data['perMinute'] ?? 0.0).toDouble();
        _ratesLoaded = true;
        _calculateFare();
        notifyListeners();
      } else {
        debugPrint("Rates not found for category: $categoryId");
      }
    } catch (e) {
      debugPrint("Error fetching rates: $e");
    }
  }

  Future<bool> requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Future<void> startMeter(String vehicleCategory) async {
    if (_isRunning) return;
    
    bool hasPermission = await requestPermissions();
    if (!hasPermission) {
      debugPrint("Location permissions denied.");
      return; 
    }

    if (!_ratesLoaded) {
      await fetchRates(vehicleCategory);
    }

    _isRunning = true;
    _isWaiting = true;
    _isWaitingPaused = false;
    _isTripCompleted = false;
    _totalDistanceKm = 0.0;
    _waitingTimeSeconds = 0;
    _lastPosition = null;
    _routePoints.clear();
    _startAddress = "Fetching...";
    _endAddress = "Fetching...";
    _tripId = "";
    _startTime = DateTime.now();
    _endTime = null;
    
    _calculateFare();
    notifyListeners();

    LocationSettings locationSettings;
    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
        forceLocationManager: true,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Taxi Meter is running in the background",
          notificationTitle: "AIAPRTD Meter",
          enableWakeLock: true,
        ),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      );
    }

    try {
      Position currentPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _handlePositionUpdate(currentPos);
    } catch (e) {
      debugPrint("Error getting initial position: $e");
    }

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
      .listen((Position position) {
      _handlePositionUpdate(position);
    });

    _waitingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRunning && _isWaiting && !_isWaitingPaused) {
        _waitingTimeSeconds++;
        _calculateFare();
        notifyListeners();
      }
    });
  }

  void toggleWaitPause() {
    _isWaitingPaused = !_isWaitingPaused;
    notifyListeners();
  }

  void _handlePositionUpdate(Position position) {
    if (!_isRunning) return;

    _routePoints.add(position);
    _currentSpeedKmh = position.speed * 3.6;

    if (_currentSpeedKmh < 2.0) {
      _isWaiting = true;
    } else {
      _isWaiting = false;
    }

    if (_lastPosition != null && !_isWaiting) {
      double distanceMeters = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      
      if (distanceMeters > 2) {
        _totalDistanceKm += (distanceMeters / 1000.0);
        _calculateFare();
      }
    }
    
    _lastPosition = position;
    notifyListeners();
  }

  void _calculateFare() {
    if (!_ratesLoaded) return;

    double distanceFare = 0.0;
    if (_totalDistanceKm > _baseDistance) {
      distanceFare = (_totalDistanceKm - _baseDistance) * _perKm;
    }

    double waitingFare = (_waitingTimeSeconds / 60.0) * _perMinute;

    _totalFare = _baseFare + distanceFare + waitingFare;
  }

  String _incrementPrefix(String prefix) {
    if (prefix.isEmpty) return 'A';
    
    List<int> chars = prefix.codeUnits.toList();
    for (int i = chars.length - 1; i >= 0; i--) {
      if (chars[i] < 90) { // 'Z' is 90
        chars[i]++;
        return String.fromCharCodes(chars);
      } else {
        chars[i] = 65; // 'A'
      }
    }
    return 'A' + String.fromCharCodes(chars);
  }

  Future<String> _generateTripId() async {
    final docRef = _firestore.collection('system').doc('trip_counter');
    final now = DateTime.now();
    final currentYear = now.year % 100;

    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      int year = currentYear;
      String prefix = 'A';
      int count = 1;

      if (snapshot.exists) {
        final data = snapshot.data()!;
        year = data['year'] ?? currentYear;
        prefix = data['prefix'] ?? 'A';
        count = data['count'] ?? 1;

        if (year != currentYear) {
          year = currentYear;
          prefix = 'A';
          count = 1;
        } else {
          count++;
          if (count > 9999) {
            count = 1;
            prefix = _incrementPrefix(prefix);
          }
        }
      }

      transaction.set(docRef, {
        'year': year,
        'prefix': prefix,
        'count': count,
      });

      return "$prefix-$year-${count.toString().padLeft(4, '0')}";
    });
  }

  Future<void> stopMeter(String membershipNo, String vehicleCategory, {String tripType = 'Road Pickup'}) async {
    _isRunning = false;
    _isWaiting = false;
    _isTripCompleted = true;
    _endTime = DateTime.now();
    _positionStream?.cancel();
    _waitingTimer?.cancel();
    notifyListeners();

    // Fetch start and end addresses
    if (_routePoints.isNotEmpty) {
      _startAddress = await _getAddressFromCoordinate(_routePoints.first);
      _endAddress = await _getAddressFromCoordinate(_routePoints.last);
      notifyListeners();
    }

    try {
      _tripId = await _generateTripId();
      notifyListeners();

      final dateStr = "${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().day.toString().padLeft(2, '0')}";
      await _firestore
          .collection('roadpickups_hires')
          .doc(dateStr)
          .collection(membershipNo)
          .doc(_tripId)
          .set({
        'tripId': _tripId,
        'startAddress': _startAddress,
        'endAddress': _endAddress,
        'distanceKm': _totalDistanceKm,
        'waitingTimeSec': _waitingTimeSeconds,
        'totalFare': _totalFare,
        'vehicleCategory': vehicleCategory,
        'tripType': tripType,
        'startTime': _startTime?.toIso8601String(),
        'endTime': _endTime?.toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(),
        'paymentStatus': 'Pending',
      });
    } catch (e) {
      debugPrint("Error generating trip ID or saving trip: $e");
    }
  }

  Future<String> _getAddressFromCoordinate(Position pos) async {
    try {
      Geocoding geocoder = Geocoding();
      List<Placemark> placemarks = await geocoder.placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.street ?? ''}, ${place.locality ?? place.subLocality ?? ''}".trim().replaceAll(RegExp(r'^,\s*'), '');
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
    return "Unknown Location";
  }

  Future<void> collectCash(String membershipNo) async {
    if (_tripId.isEmpty) return;

    try {
      final dateStr = "${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().day.toString().padLeft(2, '0')}";
      await _firestore
          .collection('roadpickups_hires')
          .doc(dateStr)
          .collection(membershipNo)
          .doc(_tripId)
          .update({'paymentStatus': 'Collected'});
    } catch (e) {
      debugPrint("Error collecting cash: $e");
    }
  }

  void resetMeter() {
    _isRunning = false;
    _isWaiting = false;
    _isWaitingPaused = false;
    _isTripCompleted = false;
    _totalDistanceKm = 0.0;
    _waitingTimeSeconds = 0;
    _totalFare = 0.0;
    _currentSpeedKmh = 0.0;
    _lastPosition = null;
    _routePoints.clear();
    _tripId = "";
    _positionStream?.cancel();
    _waitingTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _waitingTimer?.cancel();
    super.dispose();
  }
}
