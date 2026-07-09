import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/meter_provider.dart';
import 'package:aiaprtd_member/core/providers/settings_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/core/providers/sos_provider.dart';
import 'package:aiaprtd_member/features/home/chat_page.dart';
import 'package:aiaprtd_member/features/home/home_page.dart';
import 'package:aiaprtd_member/features/home/trip_summary_page.dart';
import 'package:aiaprtd_member/features/home/widgets/meter/meter_fare_display.dart';
import 'package:aiaprtd_member/features/home/widgets/meter/meter_metrics_row.dart';
import 'package:aiaprtd_member/features/home/widgets/meter/meter_status_card.dart';

class ActiveBookingPage extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final String bookingId;

  const ActiveBookingPage({super.key, required this.bookingData, required this.bookingId});

  @override
  State<ActiveBookingPage> createState() => _ActiveBookingPageState();
}

class _ActiveBookingPageState extends State<ActiveBookingPage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _pickupLatLng;
  LatLng? _dropLatLng;
  LatLng? _currentDriverLatLng;
  
  final Set<Polyline> _polylines = {};
  String _currentRoutePhase = '';
  bool _isFetchingRoute = false;
  
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<DocumentSnapshot>? _bookingStream;
  String _tripState = 'accepted'; // 'accepted', 'arrived', 'started', 'completed'
  Timer? _countdownTimer;
  String _countdownText = "";
  bool _isSheetExpanded = true;
  bool _passengerCancelledAlertShown = false;
  late Future<DocumentSnapshot> _passengerFuture;

  @override
  void initState() {
    super.initState();
    _tripState = widget.bookingData['tripState'] ?? 'accepted';
    
    String passengerId = widget.bookingData['memberId']?.toString() ?? '';
    if (passengerId.isNotEmpty) {
      _passengerFuture = FirebaseFirestore.instance.collection('member').doc(passengerId).get();
    } else {
      // Create a dummy future that returns an empty document if no passengerId (should not happen)
      _passengerFuture = Future.value({} as DocumentSnapshot);
    }

    _setupMapMarkers();
    _startLocationTracking();
    _listenToBookingChanges();
  }

  void _listenToBookingChanges() {
    _bookingStream = FirebaseFirestore.instance
        .collection('all_bookings')
        .doc(widget.bookingId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        String status = data['status']?.toString().toLowerCase() ?? '';
        String cancelledBy = data['cancelledBy']?.toString() ?? '';
        
        // If passenger cancelled the booking, notify driver and exit
        if (status == 'cancelled' && cancelledBy == 'Passenger' && !_passengerCancelledAlertShown) {
          _passengerCancelledAlertShown = true;
          _showPassengerCancelledDialog();
        }
      }
    });
  }
  
  void _showPassengerCancelledDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Trip Cancelled", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: const Text("The passenger has cancelled this trip."),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to Home/Map
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _positionStream?.cancel();
    _bookingStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    try {
      Position initialPos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentDriverLatLng = LatLng(initialPos.latitude, initialPos.longitude);
        });
        _recenterMap();
      }
    } catch (e) {
      debugPrint("Error getting initial location: $e");
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      if (!mounted) return;
      setState(() {
        _currentDriverLatLng = LatLng(position.latitude, position.longitude);
      });
      _recenterMap();

      if (_tripState != 'completed' && _tripState != 'cancelled') {
        // Broadcast location to Firebase so passenger can see
        FirebaseFirestore.instance.collection('all_bookings').doc(widget.bookingId).set({
          'driverLat': position.latitude,
          'driverLng': position.longitude,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        // Geofencing Logic
        if (_pickupLatLng != null && _tripState == 'accepted') {
          double dist = Geolocator.distanceBetween(
            position.latitude, position.longitude,
            _pickupLatLng!.latitude, _pickupLatLng!.longitude,
          );
          
          if (dist <= 100 && !(widget.bookingData['approachingNotified'] == true)) {
            // Mark as notified in DB
            FirebaseFirestore.instance.collection('all_bookings').doc(widget.bookingId).set({
              'approachingNotified': true
            }, SetOptions(merge: true));
            widget.bookingData['approachingNotified'] = true;
          }
            
          if (dist <= 1000 && !_isSheetExpanded) {
            setState(() => _isSheetExpanded = true);
          }

          if (dist <= 500 && _tripState == 'accepted') {
             var data = widget.bookingData;
             if (data['arrivingNotificationSent'] != true) {
               FirebaseFirestore.instance.collection('all_bookings').doc(widget.bookingId).update({
                 'arrivingNotificationSent': true,
                 'tripState': 'accepted', 
                 'statusMsg': 'Driver is arriving soon',
                 'timestamp': FieldValue.serverTimestamp(),
                 'isRead': false,
               });
             }
          }

          if (dist <= 20 && _tripState == 'accepted') {
            _updateTripState('arrived');
          }
        }
      }
    });
  }

  Future<void> _updateTripState(String newState) async {
    setState(() {
      _tripState = newState;
      _setupMapMarkers();
    });
    _recenterMap();

    Map<String, dynamic> updates = {'tripState': newState};

    if (newState == 'arrived') {
      _startCountdownIfNeeded();
    }

    if (newState == 'completed') {
      double liveFare = 0.0;
      if (mounted) {
        final meter = Provider.of<MeterProvider>(context, listen: false);
        liveFare = meter.totalFare;
        if (liveFare > 0) {
          updates['totalFare'] = liveFare;
          updates['distanceKm'] = meter.totalDistanceKm;
          updates['waitingTimeSec'] = meter.waitingTimeSeconds;
        }
        String membershipNo = Provider.of<ProfileProvider>(context, listen: false).memberData?['membershipNo'] ?? 'Unknown';
        String category = widget.bookingData['vehicle_category'] ?? widget.bookingData['vehicleCategory'] ?? 'Mini';
        await meter.stopMeter(membershipNo, category, tripType: 'App Booking');
      }
      updates['status'] = 'completed';
    }

    try {
      await FirebaseFirestore.instance.collection('all_bookings').doc(widget.bookingId).set(updates, SetOptions(merge: true));
      
      String passengerId = widget.bookingData['memberId']?.toString() ?? '';
      if (passengerId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('members').doc(passengerId).collection('my_bookings').doc(widget.bookingId).set(updates, SetOptions(merge: true));
        
        // Update booking_hires if completed
        if (newState == 'completed') {
          DateTime? createdAt;
          if (widget.bookingData['timestamp'] is Timestamp) {
            createdAt = (widget.bookingData['timestamp'] as Timestamp).toDate();
          } else if (widget.bookingData['createdAt'] is Timestamp) {
            createdAt = (widget.bookingData['createdAt'] as Timestamp).toDate();
          }
          if (createdAt != null) {
            String dateStr = "${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}";
            
            // Get driver's membership number
            String? driverMembershipNo = Provider.of<ProfileProvider>(context, listen: false).memberData?['membershipNo'];
            
            if (driverMembershipNo != null && driverMembershipNo.isNotEmpty) {
              // Combine full booking data with updates
              Map<String, dynamic> fullCompletedData = Map.from(widget.bookingData);
              updates.forEach((key, value) {
                fullCompletedData[key] = value;
              });
              
              await FirebaseFirestore.instance
                  .collection('booking_hires')
                  .doc(dateStr)
                  .collection(driverMembershipNo)
                  .doc(widget.bookingId)
                  .set(fullCompletedData, SetOptions(merge: true))
                  .catchError((e) => debugPrint("Error saving to booking_hires: $e"));
            }
          }
        }
      }

      if (newState == 'completed') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trip Completed Successfully!"), backgroundColor: Colors.green));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TripSummaryPage(
              bookingId: widget.bookingId,
              bookingData: widget.bookingData,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("State update error: $e");
    }
  }

  void _showEndRideConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("End Trip"),
        content: const Text("Are you sure you want to end this trip?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateTripState('completed');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("END RIDE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _startCountdownIfNeeded() {
    String? pickupTimeStr = widget.bookingData['pickupTime']?.toString();
    DateTime scheduledTime;

    if (pickupTimeStr == null || pickupTimeStr.isEmpty) {
      // Immediate booking: Start 10-minute free waiting countdown immediately
      scheduledTime = DateTime.now();
    } else {
      try {
        scheduledTime = DateTime.parse(pickupTimeStr);
      } catch (e) {
        debugPrint("Error parsing pickupTime: $e");
        scheduledTime = DateTime.now(); // Fallback
      }
    }

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _tripState != 'arrived') {
        timer.cancel();
        return;
      }

      DateTime now = DateTime.now();
      Duration diffFromScheduled = now.difference(scheduledTime);

      if (diffFromScheduled.isNegative) {
        // Arrived early. Wait until scheduled time.
        setState(() {
          _countdownText = "Waiting (Count starts at ${TimeOfDay.fromDateTime(scheduledTime).format(context)})";
        });
      } else {
        // Scheduled time reached. 10 mins (600s) free waiting.
        int secondsPassed = diffFromScheduled.inSeconds;
        int remainingSeconds = 600 - secondsPassed;

        if (remainingSeconds <= 0) {
          // Free waiting is over. Auto-start trip.
          timer.cancel();
          setState(() {
            _countdownText = "Starting...";
          });
          _startTrip();
        } else {
          // Counting down free waiting minutes
          setState(() {
            String minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
            String seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
            _countdownText = "Free Waiting: $minutes:$seconds";
          });
        }
      }
    });
  }

  Future<void> _startTrip() async {
    _countdownTimer?.cancel();
    await _updateTripState('started');
    
    String vehicleCategory = widget.bookingData['vehicle_category'] ?? widget.bookingData['vehicleCategory'] ?? 'Mini';
    if (mounted) {
      Provider.of<MeterProvider>(context, listen: false).startMeter(vehicleCategory);
      
      // Play Seatbelt Audio if enabled
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      if (settings.enableSeatbeltAudio) {
        final AudioPlayer player = AudioPlayer();
        player.setVolume(settings.appVolume);
        // We use a placeholder sound here until the actual seatbelt MP3 is added
        player.play(AssetSource('sounds/intro.mp3')).catchError((_) {});
      }
    }
  }

  void _setupMapMarkers() {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    var pickupMap = widget.bookingData['pickupLocation'];
    var dropMap = widget.bookingData['dropLocation'];

    double? pLat = parseDouble(pickupMap?['lat'] ?? widget.bookingData['pickupLat']);
    double? pLng = parseDouble(pickupMap?['lng'] ?? widget.bookingData['pickupLng']);
    double? dLat = parseDouble(dropMap?['lat'] ?? widget.bookingData['dropLat']);
    double? dLng = parseDouble(dropMap?['lng'] ?? widget.bookingData['dropLng']);

    if (pLat != null && pLng != null) {
      _pickupLatLng = LatLng(pLat, pLng);
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        ),
      );
    }

    if (dLat != null && dLng != null) {
      _dropLatLng = LatLng(dLat, dLng);
      if (_tripState == 'started' || _tripState == 'completed') {
        _markers.add(
          Marker(
            markerId: const MarkerId('drop'),
            position: _dropLatLng!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'Drop Location'),
          ),
        );
      }
    }
  }

  List<LatLng> _decodePoly(String poly) {
    var list = poly.codeUnits;
    var lList = <LatLng>[];
    int index = 0;
    int len = poly.length;
    int c = 0;
    do {
      var shift = 0;
      int result = 0;
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);
      if (result & 1 == 1) result = ~result;
      var result1 = (result >> 1) * 0.00001;
      var lat = result1;
      shift = 0;
      result = 0;
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);
      if (result & 1 == 1) result = ~result;
      var result2 = (result >> 1) * 0.00001;
      var lng = result2;
      lList.add(LatLng(
          (lat != 0.0) ? (lList.isEmpty ? lat : lList.last.latitude + lat) : (lList.isEmpty ? 0.0 : lList.last.latitude),
          (lng != 0.0) ? (lList.isEmpty ? lng : lList.last.longitude + lng) : (lList.isEmpty ? 0.0 : lList.last.longitude)));
    } while (index < len);
    return lList;
  }

  Future<void> _fetchRoute(LatLng origin, LatLng destination, String phase) async {
    if (_isFetchingRoute) return;
    _isFetchingRoute = true;
    
    const String apiKey = "AIzaSyD2ZaITIFYTcb1fThVzChQYJ-cHm0aZ2iE";
    final String url = 'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          String polylineEncoded = data['routes'][0]['overview_polyline']['points'];
          List<LatLng> polylineCoordinates = _decodePoly(polylineEncoded);

          if (mounted) {
            setState(() {
              _polylines.clear();
              _polylines.add(Polyline(
                polylineId: const PolylineId('driver_route'),
                color: Colors.blue,
                width: 5,
                points: polylineCoordinates,
              ));
              _currentRoutePhase = phase;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching driver route: $e");
    } finally {
      _isFetchingRoute = false;
    }
  }

  void _recenterMap() {
    if (_mapController == null || _currentDriverLatLng == null) return;
    
    LatLng? activeDestination;
    String phaseName = '';

    if (_tripState == 'accepted' || _tripState == 'arrived') {
      activeDestination = _pickupLatLng;
      phaseName = 'pickup';
    } else if (_tripState == 'started' || _tripState == 'completed') {
      activeDestination = _dropLatLng;
      phaseName = 'drop';
    }

    if (activeDestination != null) {
      final dest = activeDestination;
      final driverLoc = _currentDriverLatLng;
      if (driverLoc == null) return;

      if (_currentRoutePhase != phaseName) {
        _fetchRoute(driverLoc, dest, phaseName);
      }
      
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        double minLat = math.min(driverLoc.latitude, dest.latitude);
        double maxLat = math.max(driverLoc.latitude, dest.latitude);
        double minLng = math.min(driverLoc.longitude, dest.longitude);
        double maxLng = math.max(driverLoc.longitude, dest.longitude);
        
        if (minLat == maxLat) {
          minLat -= 0.005;
          maxLat += 0.005;
        }
        if (minLng == maxLng) {
          minLng -= 0.005;
          maxLng += 0.005;
        }
        
        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );
        _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
      });
    } else {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentDriverLatLng!, 16));
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _recenterMap();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final String cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not launch phone dialer")));
    }
  }

  Future<void> _navigateToPickup() async {
    if (_pickupLatLng == null) return;
    final Uri url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${_pickupLatLng!.latitude},${_pickupLatLng!.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open Google Maps")));
    }
  }

  void _showEmergencyCancelDialog() {
    TextEditingController reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Emergency Cancel", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Are you sure you want to cancel this ongoing trip? This should only be used in emergencies (e.g. vehicle breakdown)."),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(labelText: "Reason", border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                if (!isSubmitting)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Go Back", style: TextStyle(color: Colors.grey)),
                  ),
                isSubmitting
                    ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: () async {
                          if (reasonController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide a reason")));
                            return;
                          }
                          setState(() => isSubmitting = true);
                          
                          Map<String, dynamic> updates = {
                            'status': 'Cancelled',
                            'cancelReason': reasonController.text.trim(),
                            'cancelledBy': 'Driver',
                            'cancelledAt': FieldValue.serverTimestamp(),
                          };

                          try {
                            await FirebaseFirestore.instance.collection('all_bookings').doc(widget.bookingId).set(updates, SetOptions(merge: true));
                            
                            String passengerId = widget.bookingData['memberId']?.toString() ?? '';
                            if (passengerId.isNotEmpty) {
                              await FirebaseFirestore.instance.collection('members').doc(passengerId).collection('my_bookings').doc(widget.bookingId).set(updates, SetOptions(merge: true));
                            }
                            
                            // Increment totalCancelledCount for driver
                            String? driverMembershipNo = Provider.of<ProfileProvider>(context, listen: false).memberData?['membershipNo'];
                            if (driverMembershipNo != null && driverMembershipNo.isNotEmpty) {
                              await FirebaseFirestore.instance.collection('member').doc(driverMembershipNo).set({
                                'totalCancelledCount': FieldValue.increment(1)
                              }, SetOptions(merge: true));
                            }
                            
                            if (context.mounted) {
                              Navigator.pop(context); // Close dialog
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
                            }
                          } catch (e) {
                            setState(() => isSubmitting = false);
                            debugPrint("Cancel error: $e");
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text("Confirm Cancel", style: TextStyle(color: Colors.white)),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String pickup = widget.bookingData['startAddress'] ?? (widget.bookingData['pickupLocation'] != null ? widget.bookingData['pickupLocation']['address'] : null) ?? 'Unknown Pickup';
    String drop = widget.bookingData['endAddress'] ?? (widget.bookingData['dropLocation'] != null ? widget.bookingData['dropLocation']['address'] : null) ?? 'Unknown Drop';
    String passengerId = widget.bookingData['memberId']?.toString() ?? '';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          automaticallyImplyLeading: false, // Remove back button
          title: const Text("Active Ride", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (_tripState != 'started')
              IconButton(
                icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                tooltip: "Emergency Cancel",
                onPressed: _showEmergencyCancelDialog,
              )
          ],
        ),
        body: _tripState == 'started'
            ? _buildStartedLayout()
            : Stack(
        children: [
          // ==========================================
          // 🗺️ 1. Google Map (Background)
          // ==========================================
          SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Stack(
              children: [
                _pickupLatLng == null
                    ? const Center(child: Text("Location not available"))
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(target: _pickupLatLng!, zoom: 14),
                        markers: _markers,
                        polylines: _polylines,
                        onMapCreated: _onMapCreated,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                      ),
                      
                // Floating Navigation Button on Top of Map
                if (_tripState == 'accepted' || _tripState == 'arrived')
                  Positioned(
                    top: 20,
                    right: 20,
                    child: FloatingActionButton(
                      heroTag: 'nav_pickup',
                      onPressed: _navigateToPickup,
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.navigation, color: Colors.white),
                    ),
                  ),
                  
                if (_tripState == 'started' && _dropLatLng != null)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: FloatingActionButton(
                      heroTag: 'nav_drop',
                      onPressed: () async {
                        final Uri url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${_dropLatLng!.latitude},${_dropLatLng!.longitude}');
                        if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                      },
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.navigation, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),

          // ==========================================
          // 📄 2. Bottom Sheet (Ride & Passenger Details)
          // ==========================================
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! > 10) {
                  if (_isSheetExpanded) setState(() => _isSheetExpanded = false);
                } else if (details.primaryDelta! < -10) {
                  if (!_isSheetExpanded) setState(() => _isSheetExpanded = true);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 20),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75, // Prevent overflow
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    
                    // 👤 Passenger Info & Contact
                    FutureBuilder<DocumentSnapshot>(
                    future: _passengerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      String passengerName = "Unknown Member";
                      String passengerMobile = "";
                      String passengerImage = "";
                      String passengerMembership = "";

                      if (snapshot.hasData && snapshot.data!.exists) {
                        var data = snapshot.data!.data() as Map<String, dynamic>;
                        passengerName = data['fullName'] ?? passengerName;
                        passengerMobile = data['mobile']?.toString() ?? "";
                        passengerImage = data['profileImageUrl'] ?? "";
                        passengerMembership = data['membershipNo'] ?? passengerId;
                      }

                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage: passengerImage.isNotEmpty ? NetworkImage(passengerImage) : null,
                            child: passengerImage.isEmpty ? const Icon(Icons.person, color: Colors.blue) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(passengerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(passengerMembership, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                          ),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('chats')
                                    .doc(widget.bookingId)
                                    .collection('messages')
                                    .where('isRead', isEqualTo: false)
                                    .snapshots(),
                                builder: (context, chatSnapshot) {
                                  final myMembershipNo = Provider.of<ProfileProvider>(context, listen: false).memberNo;
                                  int unreadCount = 0;
                                  String latestMsg = "";
                                  
                                  if (chatSnapshot.hasData && chatSnapshot.data!.docs.isNotEmpty) {
                                    var unreadDocs = chatSnapshot.data!.docs.where((doc) {
                                      var d = doc.data() as Map<String, dynamic>;
                                      return d['senderId'] != myMembershipNo;
                                    }).toList();
                                    
                                    unreadCount = unreadDocs.length;
                                    
                                    if (unreadCount > 0) {
                                      unreadDocs.sort((a, b) {
                                        var d1 = a.data() as Map<String, dynamic>;
                                        var d2 = b.data() as Map<String, dynamic>;
                                        var t1 = d1['timestamp'] as Timestamp?;
                                        var t2 = d2['timestamp'] as Timestamp?;
                                        if (t1 == null || t2 == null) return 0;
                                        return t2.compareTo(t1);
                                      });
                                      
                                      latestMsg = (unreadDocs.first.data() as Map<String, dynamic>)['text'] ?? '';
                                      if (latestMsg.length > 20) {
                                        latestMsg = "${latestMsg.substring(0, 20)}...";
                                      }
                                    }
                                  }
                                  
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ChatPage(
                                                tripId: widget.bookingId,
                                                otherUserName: passengerName,
                                                otherUserId: passengerId,
                                              ),
                                            ),
                                          ).then((_) {
                                            FirebaseFirestore.instance
                                                .collection('chats')
                                                .doc(widget.bookingId)
                                                .collection('messages')
                                                .where('isRead', isEqualTo: false)
                                                .get()
                                                .then((snapshot) {
                                              for (var doc in snapshot.docs) {
                                                var d = doc.data();
                                                if (d['senderId'] != myMembershipNo) {
                                                  doc.reference.update({'isRead': true});
                                                }
                                              }
                                            });
                                          });
                                        },
                                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                                      ),
                                      if (unreadCount > 0)
                                        Positioned(
                                          bottom: 45,
                                          right: -10,
                                          child: IgnorePointer(
                                            child: Material(
                                              color: Colors.transparent,
                                              elevation: 4,
                                              borderRadius: BorderRadius.circular(10),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade800,
                                                  borderRadius: const BorderRadius.only(
                                                    topLeft: Radius.circular(10),
                                                    topRight: Radius.circular(10),
                                                    bottomLeft: Radius.circular(10),
                                                    bottomRight: Radius.circular(2),
                                                  ),
                                                ),
                                                child: Text(
                                                  latestMsg,
                                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (unreadCount > 0)
                                        Positioned(
                                          right: -2,
                                          top: -2,
                                          child: IgnorePointer(
                                            child: Container(
                                              padding: const EdgeInsets.all(5),
                                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                              child: Text(
                                                unreadCount.toString(),
                                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                          const SizedBox(width: 8),
                          if (passengerMobile.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                              child: IconButton(
                                onPressed: () => _makePhoneCall(passengerMobile),
                                icon: const Icon(Icons.phone, color: Colors.green), // Call Button
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  
                  if (_isSheetExpanded) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(),
                    ),

                  // 📍 Pickup & Drop Locations
                  const Text("Locations:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, color: Colors.blue, size: 16),
                      const SizedBox(width: 12),
                      Expanded(child: Text(pickup, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 16),
                      const SizedBox(width: 12),
                      Expanded(child: Text(drop, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 💳 Price & Payment Method OR Live Meter
                  if (_tripState == 'started') ...[
                    Consumer<MeterProvider>(
                      builder: (context, meter, child) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: [
                              MeterStatusCard(meter: meter, category: widget.bookingData['vehicle_category'] ?? widget.bookingData['vehicleCategory'] ?? 'Mini'),
                              const SizedBox(height: 16),
                              GestureDetector(
                              onLongPress: _triggerSecretSos,
                              child: MeterFareDisplay(totalFare: meter.totalFare),
                            ),
                              const SizedBox(height: 16),
                              MeterMetricsRow(
                                distanceKm: meter.totalDistanceKm,
                                waitTimeSeconds: meter.waitingTimeSeconds,
                                speedKmh: meter.currentSpeedKmh,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: meter.toggleWaitPause,
                                  icon: Icon(meter.isWaitingPaused ? Icons.play_arrow : Icons.pause, color: meter.isWaitingPaused ? Colors.greenAccent : Colors.orange),
                                  label: Text(
                                    meter.isWaitingPaused ? "RESUME WAITING TIME" : "PAUSE WAITING TIME",
                                    style: TextStyle(color: meter.isWaitingPaused ? Colors.greenAccent : Colors.orange),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: meter.isWaitingPaused ? Colors.greenAccent : Colors.orange),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    ),
                  ],

                  ],

                  const SizedBox(height: 20),

                  // 🧭 Navigation & State Buttons
                  if (_tripState == 'accepted') ...[
                    ElevatedButton(
                      onPressed: () => _updateTripState('arrived'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: const Text("ARRIVED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ] else if (_tripState == 'arrived') ...[
                    if (_countdownText.isNotEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text(_countdownText.contains("Waiting") ? _countdownText : "Auto-starts in: $_countdownText", 
                            style: TextStyle(
                              color: _countdownText.contains("Waiting") ? Colors.orange : Colors.red, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 16
                            )
                          ),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _startTrip,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: const Text("START RIDE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ] else if (_tripState == 'started') ...[
                    ElevatedButton(
                      onPressed: () => _updateTripState('completed'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: const Text("END RIDE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  ),
));
}

  Widget _buildStartedLayout() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              _pickupLatLng == null
                  ? const Center(child: Text("Location not available"))
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(target: _pickupLatLng!, zoom: 14),
                      markers: _markers,
                      polylines: _polylines,
                      onMapCreated: _onMapCreated,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                    ),
              if (_dropLatLng != null)
                Positioned(
                  top: 20,
                  right: 20,
                  child: FloatingActionButton(
                    heroTag: 'nav_drop_started',
                    onPressed: () async {
                      final Uri url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${_dropLatLng!.latitude},${_dropLatLng!.longitude}');
                      if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                    },
                    backgroundColor: Colors.blue,
                    child: const Icon(Icons.navigation, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 15),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer<MeterProvider>(
                  builder: (context, meter, child) {
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          MeterStatusCard(meter: meter, category: widget.bookingData['vehicle_category'] ?? widget.bookingData['vehicleCategory'] ?? 'Mini'),
                          const SizedBox(height: 16),
                          GestureDetector(
                                  onLongPress: _triggerSecretSos,
                                  child: MeterFareDisplay(totalFare: meter.totalFare),
                                ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: MeterMetricsRow(
                                  distanceKm: meter.totalDistanceKm,
                                  waitTimeSeconds: meter.waitingTimeSeconds,
                                  speedKmh: meter.currentSpeedKmh,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade800,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  onPressed: meter.toggleWaitPause,
                                  icon: Icon(
                                    meter.isWaitingPaused ? Icons.play_arrow : Icons.pause, 
                                    color: meter.isWaitingPaused ? Colors.greenAccent : Colors.orange,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _showEndRideConfirmation,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: const Text("END RIDE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _triggerSecretSos() {
    HapticFeedback.vibrate();
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final sosProvider = Provider.of<SosProvider>(context, listen: false);
    sosProvider.startSos(profileProvider);
    Future.delayed(const Duration(milliseconds: 500), () {
      HapticFeedback.lightImpact();
    });
  }
}