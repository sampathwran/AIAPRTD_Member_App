import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aiaprtd_member/core/providers/community_assistance_provider.dart';

class AssistanceTrackingPage extends StatefulWidget {
  final String requestId;
  final bool isHelper;

  const AssistanceTrackingPage({
    super.key,
    required this.requestId,
    required this.isHelper,
  });

  @override
  State<AssistanceTrackingPage> createState() => _AssistanceTrackingPageState();
}

class _AssistanceTrackingPageState extends State<AssistanceTrackingPage> {
  GoogleMapController? _mapController;
  StreamSubscription<DocumentSnapshot>? _requestSub;
  StreamSubscription<Position>? _positionSub;

  Map<String, dynamic>? _requestData;
  Map<String, dynamic>? _otherMemberData;

  Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  void _startTracking() {
    // 1. Listen to the Request Document
    _requestSub = FirebaseFirestore.instance
        .collection('community_assistance_requests')
        .doc(widget.requestId)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          setState(() {
            _requestData = data;
          });

          _updateMarkers();
          
          if (_otherMemberData == null) {
            await _fetchOtherMemberDetails();
          }

          if (data['status'] == 'completed') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Assistance completed!"))
              );
              Navigator.pop(context);
            }
          }
        }
      }
    });

    // 2. Stream My Own Location and push to Firestore
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5)
    ).listen((Position position) {
      String locationField = widget.isHelper ? 'helperLocation' : 'requesterLocation';
      FirebaseFirestore.instance
          .collection('community_assistance_requests')
          .doc(widget.requestId)
          .update({
        locationField: GeoPoint(position.latitude, position.longitude)
      });
    });
  }

  Future<void> _fetchOtherMemberDetails() async {
    if (_requestData == null) return;
    String otherMemberId = widget.isHelper ? _requestData!['requesterId'] : _requestData!['helperId'];
    
    try {
      // First try to fetch by document ID
      final doc = await FirebaseFirestore.instance.collection('member').doc(otherMemberId).get();
      
      if (doc.exists && doc.data() != null) {
        setState(() {
          _otherMemberData = doc.data();
          _isLoading = false;
        });
      } else {
        // Fallback to querying by membershipNo field
        final qs = await FirebaseFirestore.instance
            .collection('member')
            .where('membershipNo', isEqualTo: otherMemberId)
            .limit(1)
            .get();
        
        if (qs.docs.isNotEmpty) {
          setState(() {
            _otherMemberData = qs.docs.first.data();
            _isLoading = false;
          });
        } else {
          // If still not found, just use the name we have in request data
          setState(() {
            _otherMemberData = {
              'fullName': widget.isHelper ? _requestData!['requesterName'] : _requestData!['helperName'],
              'mobile': widget.isHelper ? _requestData!['requesterPhone'] : null,
              'membershipNo': otherMemberId
            };
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching other member data: $e");
      setState(() => _isLoading = false);
    }
  }

  void _updateMarkers() {
    if (_requestData == null) return;
    
    Set<Marker> newMarkers = {};
    
    GeoPoint? reqLoc = _requestData!['requesterLocation'] as GeoPoint?;
    GeoPoint? helpLoc = _requestData!['helperLocation'] as GeoPoint?;

    if (reqLoc != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('requester'),
        position: LatLng(reqLoc.latitude, reqLoc.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Requester'),
      ));
    }

    if (helpLoc != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('helper'),
        position: LatLng(helpLoc.latitude, helpLoc.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Helper'),
      ));
    }

    setState(() {
      _markers = newMarkers;
    });

    // Move camera to fit both if both exist
    if (reqLoc != null && helpLoc != null && _mapController != null) {
      LatLngBounds bounds;
      if (reqLoc.latitude > helpLoc.latitude) {
        bounds = LatLngBounds(
            southwest: LatLng(helpLoc.latitude, helpLoc.longitude),
            northeast: LatLng(reqLoc.latitude, reqLoc.longitude));
      } else {
        bounds = LatLngBounds(
            southwest: LatLng(reqLoc.latitude, reqLoc.longitude),
            northeast: LatLng(helpLoc.latitude, helpLoc.longitude));
      }
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    } else if (reqLoc != null && _mapController != null && newMarkers.length == 1) {
       _mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(reqLoc.latitude, reqLoc.longitude)));
    }
  }

  @override
  void dispose() {
    _requestSub?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  void _callOtherPerson() {
    if (_otherMemberData != null && _otherMemberData!['mobile'] != null) {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: _otherMemberData!['mobile'],
      );
      launchUrl(launchUri);
    }
  }

  void _markResolved() {
    FirebaseFirestore.instance
        .collection('community_assistance_requests')
        .doc(widget.requestId)
        .update({'status': 'completed'});
        
    Provider.of<CommunityAssistanceProvider>(context, listen: false).clearMyRequest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assistance Live Tracking"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(7.8731, 80.7718),
                      zoom: 12,
                    ),
                    markers: _markers,
                    onMapCreated: (controller) => _mapController = controller,
                    myLocationEnabled: true,
                  ),
                ),
                if (_otherMemberData != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isHelper ? "Requester Details" : "Helper Details",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: _otherMemberData!['profileImageUrl'] != null 
                                  ? NetworkImage(_otherMemberData!['profileImageUrl'])
                                  : null,
                              child: _otherMemberData!['profileImageUrl'] == null ? const Icon(Icons.person) : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_otherMemberData!['fullName'] ?? 'Unknown', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text("Mem No: ${_otherMemberData!['membershipNo'] ?? (widget.isHelper ? _requestData!['requesterId'] : _requestData!['helperId']) ?? 'N/A'}", style: const TextStyle(color: Colors.grey)),
                                  
                                  // Extract Plate Number
                                  Builder(builder: (context) {
                                    String? plate;
                                    try {
                                      final docs = _otherMemberData!['currentVehicle']?['documents'] as List?;
                                      if (docs != null && docs.length > 2) {
                                        plate = docs[2]?['reviewData']?['Plate Number'];
                                      }
                                    } catch (_) {}
                                    
                                    if (plate != null && plate.isNotEmpty) {
                                      return Text("Vehicle: $plate", style: const TextStyle(color: Colors.grey));
                                    }
                                    return const SizedBox.shrink();
                                  }),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _callOtherPerson,
                              icon: const Icon(Icons.call, color: Colors.green, size: 32),
                            )
                          ],
                        ),
                        
                        // Extract Vehicle Photo
                        Builder(builder: (context) {
                          String? photoUrl;
                          try {
                            photoUrl = _otherMemberData!['currentVehicle']?['vehiclePhotos']?['Front']?['url'];
                          } catch (_) {}
                          
                          if (photoUrl != null && photoUrl.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(photoUrl, height: 120, width: double.infinity, fit: BoxFit.cover),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),

                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _markResolved,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16)
                            ),
                            child: const Text("MARK AS RESOLVED", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  )
              ],
            ),
    );
  }
}
