import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:aiaprtd_member/features/home/chat_page.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/features/general/widgets/rating_dialog_widget.dart';

class PassengerOngoingTripPage extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const PassengerOngoingTripPage({super.key, required this.bookingId, required this.bookingData});

  @override
  State<PassengerOngoingTripPage> createState() => _PassengerOngoingTripPageState();
}

class _PassengerOngoingTripPageState extends State<PassengerOngoingTripPage> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _carIcon;
  bool _isRatingSubmitting = false;
  int _rating = 5;
  String _previousTripState = '';
  double? _lastDriverLat;
  double? _lastDriverLng;
  final Set<Polyline> _polylines = {};
  String _currentRoutePhase = '';
  bool _isFetchingRoute = false;

  @override
  void initState() {
    super.initState();
    String category = widget.bookingData['vehicleCategory']?.toString().toLowerCase() ?? 
                      widget.bookingData['selectedCategory']?.toString().toLowerCase() ?? 
                      'mini';
    _loadCarIcon(category);
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  Future<void> _loadCarIcon(String category) async {
    String assetPath = 'assets/images/map_mini.png'; // default fallback

    if (category.contains('budget')) {
      assetPath = 'assets/images/map_budget.png';
    } else if (category.contains('sedan')) {
      assetPath = 'assets/images/map_sedan.png';
    } else if (category.contains('6 seater') || category.contains('6_seater')) {
      assetPath = 'assets/images/map_6_seater.png';
    } else if (category.contains('9 seater') || category.contains('9_seater')) {
      assetPath = 'assets/images/map_9_seater.png';
    } else if (category.contains('14 seater') || category.contains('14_seater')) {
      assetPath = 'assets/images/map_14_seater.png';
    } else if (category.contains('mini')) {
      assetPath = 'assets/images/map_mini.png';
    }

    try {
      final Uint8List markerIcon = await getBytesFromAsset(assetPath, 80); // Reduced car icon size
      _carIcon = BitmapDescriptor.bytes(markerIcon);
    } catch (e) {
      try {
        _carIcon = await BitmapDescriptor.asset(
          const ImageConfiguration(),
          'assets/images/default_car.png',
        );
      } catch (e) {
        _carIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      }
    }
    
    if (mounted) setState(() {});
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
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

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null || x1 == null || y0 == null || y1 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1) y1 = latLng.longitude;
        if (latLng.longitude < y0) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
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
                polylineId: const PolylineId('active_route'),
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
      debugPrint("Error fetching route: $e");
    } finally {
      _isFetchingRoute = false;
    }
  }

  Set<Marker> _buildMarkers(Map<String, dynamic> data) {
    Set<Marker> markers = {};

    var pickupMap = data['pickupLocation'];
    var dropMap = data['dropLocation'];

    double? pLat = _parseDouble(pickupMap?['lat'] ?? data['pickupLat']);
    double? pLng = _parseDouble(pickupMap?['lng'] ?? data['pickupLng']);
    double? dLat = _parseDouble(dropMap?['lat'] ?? data['dropLat']);
    double? dLng = _parseDouble(dropMap?['lng'] ?? data['dropLng']);
    double? driverLat = _parseDouble(data['driverLat']);
    double? driverLng = _parseDouble(data['driverLng']);
    double? driverHeading = _parseDouble(data['driverHeading']);

    if (pLat != null && pLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(pLat, pLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Pickup Location'),
      ));
    }

    if (dLat != null && dLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('drop'),
        position: LatLng(dLat, dLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Drop Location'),
      ));
    }

    if (driverLat != null && driverLng != null) {
      LatLng driverLatLng = LatLng(driverLat, driverLng);
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: driverLatLng,
        icon: _carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Driver Location'),
        rotation: driverHeading ?? 0.0,
        flat: true,
        anchor: const Offset(0.5, 0.5),
      ));

      String tripState = data['tripState'] ?? 'accepted';
      LatLng? activeDestination;
      String phaseName = '';

      if (tripState == 'accepted' || tripState == 'arrived') {
        if (pLat != null && pLng != null) {
          activeDestination = LatLng(pLat, pLng);
          phaseName = 'pickup';
        }
      } else if (tripState == 'started') {
        if (dLat != null && dLng != null) {
          activeDestination = LatLng(dLat, dLng);
          phaseName = 'drop';
        }
      }

      if (activeDestination != null) {
        if (_currentRoutePhase != phaseName) {
          _fetchRoute(driverLatLng, activeDestination, phaseName);
        }
      }

      // Auto pan camera to driver if map exists and location changed
      if (_mapController != null && (driverLat != _lastDriverLat || driverLng != _lastDriverLng)) {
        _lastDriverLat = driverLat;
        _lastDriverLng = driverLng;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (activeDestination != null) {
            LatLngBounds bounds = _boundsFromLatLngList([driverLatLng, activeDestination]);
            _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80)); // 80px padding
          } else {
            _mapController?.animateCamera(CameraUpdate.newLatLng(driverLatLng));
          }
        });
      }
    }

    return markers;
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

  void _showRatingDialog() {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            bool isSubmitting = false;
            return RatingDialogWidget(
              title: "Rate Driver",
              isRatingDriver: true, // Passenger is rating the driver
              onSubmit: (rating, selectedChips, customReason) async {
                setStateDialog(() => isSubmitting = true);
                try {
                  await FirebaseFirestore.instance.collection('all_bookings').doc(widget.bookingId).set({
                    'driverRating': rating,
                    'driverRatingReasons': selectedChips,
                    'driverRatingCustomReason': customReason,
                    'ratingSubmittedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));

                  String passengerId = widget.bookingData['memberId']?.toString() ?? '';
                  if (passengerId.isNotEmpty) {
                    await FirebaseFirestore.instance.collection('members').doc(passengerId).collection('my_bookings').doc(widget.bookingId).set({
                      'driverRating': rating,
                      'driverRatingReasons': selectedChips,
                      'driverRatingCustomReason': customReason,
                    }, SetOptions(merge: true));
                  }

                  String driverId = widget.bookingData['driverId']?.toString() ?? '';
                  if (driverId.isNotEmpty) {
                    final driverRef = FirebaseFirestore.instance.collection('members').doc(driverId);
                    await FirebaseFirestore.instance.runTransaction((transaction) async {
                      final snapshot = await transaction.get(driverRef);
                      if (snapshot.exists) {
                        final data = snapshot.data()!;
                        double currentSum = (data['ratingSum'] ?? 0.0).toDouble();
                        int currentCount = (data['ratingCount'] ?? 0).toInt();
                        
                        currentSum += rating;
                        currentCount += 1;
                        double newRating = currentSum / currentCount;
                        
                        transaction.update(driverRef, {
                          'ratingSum': currentSum,
                          'ratingCount': currentCount,
                          'rating': double.parse(newRating.toStringAsFixed(1)),
                        });
                      }
                    });
                  }

                  scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Thanks for your feedback!"), backgroundColor: Colors.green));
                  navigator.pop(); // Close dialog
                  navigator.pop(); // Go back to Home
                } catch (e) {
                  debugPrint("Rating error: $e");
                  setStateDialog(() => isSubmitting = false);
                }
              },
            );
          },
        );
      },
    );
  }

  void _showNotification(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      backgroundColor: color,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showCancelDialog(BuildContext context) {
    bool isSubmitting = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Cancel Trip", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              content: const Text("Are you sure you want to cancel this trip?"),
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
                          setState(() => isSubmitting = true);
                          Map<String, dynamic> updates = {
                            'status': 'Cancelled',
                            'cancelReason': 'Cancelled by passenger',
                            'cancelledBy': 'Passenger',
                            'cancelledAt': FieldValue.serverTimestamp(),
                          };
                          try {
                            await FirebaseFirestore.instance.collection('all_bookings').doc(widget.bookingId).set(updates, SetOptions(merge: true));
                            final myMembershipNo = Provider.of<ProfileProvider>(context, listen: false).memberNo;
                            if (myMembershipNo.isNotEmpty) {
                              await FirebaseFirestore.instance.collection('members').doc(myMembershipNo).collection('my_bookings').doc(widget.bookingId).set(updates, SetOptions(merge: true));
                            }
                            if (context.mounted) {
                              Navigator.pop(context); // close dialog
                              Navigator.pop(context); // go back to previous screen
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('all_bookings').doc(widget.bookingId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Scaffold(body: Center(child: Text("Something went wrong")));
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text("Booking not found")));
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        String tripState = data['tripState'] ?? 'accepted';
        String status = data['status']?.toString().toLowerCase() ?? '';
        
        if (_previousTripState != tripState) {
          if (_previousTripState.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (tripState == 'arrived') {
                _showNotification("Your driver has arrived at the pickup location!", Colors.orange.shade700);
              } else if (tripState == 'started') {
                _showNotification("Your trip has started!", Colors.green.shade700);
              }
            });
          }
          // Update immediately but don't call setState to avoid infinite loops in builder
          _previousTripState = tripState;
        }

        String bannerText = "Driver is on the way";
        Color bannerColor = Colors.blue;
        if (tripState == 'arrived') {
          bannerText = "Driver has arrived at pickup!";
          bannerColor = Colors.orange;
        } else if (tripState == 'started') {
          bannerText = "Trip in progress. Heading to destination.";
          bannerColor = Colors.green;
        }

        String driverName = data['driverName'] ?? "Driver";
        String driverPhone = data['driverPhone'] ?? "";
        String driverVehicle = data['driverVehicle'] ?? "";
        String driverImage = data['driverImage'] ?? "";
        String driverId = data['acceptedBy'] ?? "";

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text("Live Trip Tracking", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black87),
            actions: [
              if (tripState == 'accepted' || tripState == 'arrived')
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  tooltip: "Cancel Booking",
                  onPressed: () => _showCancelDialog(context),
                ),
            ],
          ),
          body: (status == 'completed' || tripState == 'completed') ? _buildCompletedUI(data) : Stack(
            children: [
              Positioned.fill(
                child: GoogleMap(
                  padding: const EdgeInsets.only(bottom: 140), // Move Google logo up
                  initialCameraPosition: const CameraPosition(target: LatLng(7.8731, 80.7718), zoom: 7), // Sri Lanka center
                  markers: _buildMarkers(data),
                  polylines: _polylines,
                  onMapCreated: (controller) => _mapController = controller,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),

              // Status Banner
              Positioned(
                top: 20, left: 20, right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: bannerColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(bannerText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),

              // Bottom Sheet for Driver Details
              Positioned(
                bottom: 30, // move up a bit
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 5))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.blue.shade50,
                            backgroundImage: driverImage.isNotEmpty ? NetworkImage(driverImage) : null,
                            child: driverImage.isEmpty ? const Icon(Icons.person, color: Colors.blue, size: 30) : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(driverName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(driverVehicle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                              ],
                            ),
                          ),
                          if (driverPhone.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                              child: IconButton(
                                onPressed: () => _makePhoneCall(driverPhone),
                                icon: const Icon(Icons.phone, color: Colors.green),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
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
                                                  otherUserName: driverName,
                                                  otherUserId: driverId,
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletedUI(Map<String, dynamic> data) {
    String fare = (data['totalFare'] ?? data['estimateFare'] ?? 0.0).toString();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            const Text("Trip Completed!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Your trip has ended. Thank you for riding with us.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))],
              ),
              child: Column(
                children: [
                  const Text("Total Fare", style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Rs. $fare", style: const TextStyle(color: Colors.green, fontSize: 32, fontWeight: FontWeight.w900)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _showRatingDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("RATE DRIVER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}