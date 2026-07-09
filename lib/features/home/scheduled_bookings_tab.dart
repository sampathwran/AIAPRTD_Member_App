import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/features/home/swipe_to_accept_button.dart';
import 'package:aiaprtd_member/features/home/active_booking_page.dart';
import 'package:aiaprtd_member/features/home/online_status_controller.dart';

class ScheduledBookingsTab extends StatefulWidget {
  final List<QueryDocumentSnapshot> bookings;
  final Position? currentPosition;

  const ScheduledBookingsTab({super.key, required this.bookings, this.currentPosition});

  @override
  State<ScheduledBookingsTab> createState() => _ScheduledBookingsTabState();
}

class _ScheduledBookingsTabState extends State<ScheduledBookingsTab> {
  final Map<String, Map<String, dynamic>> _displayBookings = {};
  final Set<String> _removingIds = {};

  @override
  void initState() {
    super.initState();
    _updateDisplayBookings(widget.bookings);
  }

  @override
  void didUpdateWidget(ScheduledBookingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleIncomingBookings(widget.bookings);
  }

  void _updateDisplayBookings(List<QueryDocumentSnapshot> newBookings) {
    for (var doc in newBookings) {
      _displayBookings[doc.id] = doc.data() as Map<String, dynamic>;
    }
    final newIds = newBookings.map((e) => e.id).toSet();
    _displayBookings.removeWhere((id, data) => !newIds.contains(id) && !_removingIds.contains(id));
  }

  void _handleIncomingBookings(List<QueryDocumentSnapshot> newBookings) {
    final newIds = newBookings.map((e) => e.id).toSet();
    final oldIds = _displayBookings.keys.toSet();

    final removedIds = oldIds.difference(newIds).difference(_removingIds);

    for (var doc in newBookings) {
      _displayBookings[doc.id] = doc.data() as Map<String, dynamic>;
    }

    for (String id in removedIds) {
      _removingIds.add(id);
      _checkWhyRemoved(id);
    }
  }

  Future<void> _checkWhyRemoved(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('all_bookings').doc(docId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status']?.toString().toLowerCase();
        
        if (status == 'accepted' || status == 'arrived' || status == 'started') {
          if (mounted) {
            setState(() {
              _displayBookings[docId] = data; 
            });
          }
          await Future.delayed(const Duration(milliseconds: 1500));
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _removingIds.remove(docId);
        _displayBookings.remove(docId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> currentList = _displayBookings.entries.map((e) {
      var d = Map<String, dynamic>.from(e.value);
      d['_docId'] = e.key;
      return d;
    }).toList();

    if (currentList.isEmpty && widget.bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month, size: 60, color: Colors.blue.shade100),
            const SizedBox(height: 16),
            const Text("No Scheduled Bookings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            const Text("No upcoming bookings found in this radius.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Sort bookings by time (ascending)
    List<Map<String, dynamic>> sortedBookings = List.from(currentList);
    sortedBookings.sort((a, b) {
      var dataA = a;
      var dataB = b;

      DateTime? timeA;
      if (dataA['pickupTime'] != null) {
        timeA = DateTime.tryParse(dataA['pickupTime'].toString());
      } else if (dataA['startTime'] != null && dataA['startTime'] is Timestamp) timeA = (dataA['startTime'] as Timestamp).toDate();

      DateTime? timeB;
      if (dataB['pickupTime'] != null) {
        timeB = DateTime.tryParse(dataB['pickupTime'].toString());
      } else if (dataB['startTime'] != null && dataB['startTime'] is Timestamp) timeB = (dataB['startTime'] as Timestamp).toDate();

      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1; // Put nulls at the end
      if (timeB == null) return -1;

      return timeA.compareTo(timeB);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: sortedBookings.length,
      itemBuilder: (context, index) {
        var data = sortedBookings[index];
        String docId = data['_docId'];
        return _buildScheduledCard(context, data, docId);
      },
    );
  }

  Widget _buildScheduledCard(BuildContext context, Map<String, dynamic> data, String docId) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final String myMembershipNo = profileProvider.memberNo;
    final String myName = profileProvider.memberFullName;
    final String myPhone = profileProvider.memberData?['mobile']?.toString() ?? '';
    final String myVehicle = profileProvider.memberData?['vehicle_category']?.toString() ?? '';
    final String myImage = profileProvider.profileImageUrl;
    
    final systemStatus = OnlineStatusController.checkSystemActive(context);
    final bool isActive = systemStatus['isActive'] == true;
    final String inactiveReason = systemStatus['reason'] ?? profileProvider.inactiveReason;
    
    final bool isOnline = profileProvider.isOnline;

    String pickup = data['startAddress'] ?? (data['pickupLocation'] != null ? data['pickupLocation']['address'] : null) ?? 'Unknown Pickup';
    String drop = data['endAddress'] ?? (data['dropLocation'] != null ? data['dropLocation']['address'] : null) ?? 'Unknown Drop';
    List<dynamic> additionalDrops = data['additionalDrops'] ?? [];
    double fare = (data['totalFare'] ?? data['estimateFare'] ?? 0.0).toDouble();
    String price = fare.toStringAsFixed(2);
    String paymentMethod = data['paymentMethod'] ?? 'Cash';
    
    DateTime? pickupTime;
    if (data['pickupTime'] != null) {
      pickupTime = DateTime.tryParse(data['pickupTime']);
    } else if (data['startTime'] != null && data['startTime'] is Timestamp) {
      pickupTime = (data['startTime'] as Timestamp).toDate();
    }
    
    String distanceText = "";
    if (widget.currentPosition != null) {
      double? parseDouble(dynamic value) {
        if (value == null) return null;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.tryParse(value);
        return null;
      }
      
      var pickupLoc = data['pickupLocation'];
      double? pLat = parseDouble(pickupLoc?['lat'] ?? data['pickupLat']);
      double? pLng = parseDouble(pickupLoc?['lng'] ?? data['pickupLng']);
      
      if (pLat != null && pLng != null) {
        double distMeters = Geolocator.distanceBetween(
          widget.currentPosition!.latitude, 
          widget.currentPosition!.longitude, 
          pLat, 
          pLng
        );
        double distKm = distMeters / 1000;
        distanceText = "${distKm.toStringAsFixed(1)} km away from you";
      }
    }

    String date = pickupTime != null ? "${pickupTime.year}-${pickupTime.month.toString().padLeft(2, '0')}-${pickupTime.day.toString().padLeft(2, '0')}" : 'N/A';
    String time = pickupTime != null ? _formatTime(pickupTime) : 'N/A';

    int viewCount = data['views'] ?? 0;

        String currentStatus = data['status']?.toString().toLowerCase() ?? 'pending';
    bool isAcceptedByOther = currentStatus == 'accepted' || currentStatus == 'arrived' || currentStatus == 'started';
    String acceptedDriverName = data['driverName'] ?? 'Another Driver';

    return Stack(
      children: [
        Opacity(
          opacity: isAcceptedByOther ? 0.4 : 1.0,
          child: Container(
      margin: const EdgeInsets.only(bottom: 16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // 🛡️ 1. Verified Member & Views
          // ==========================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.verified, color: Colors.blue, size: 16),
                      SizedBox(width: 4),
                      Flexible(child: Text("Verified Member", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
                // 👁️ View Count
                Row(
                  children: [
                    Icon(Icons.visibility, color: Colors.grey.shade600, size: 16),
                    const SizedBox(width: 4),
                    Text("$viewCount views", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📅 Date & Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month, color: Colors.grey.shade700, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              "$date • $time", 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade800),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text("Rs. $price", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 16),

                // 📍 Locations
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.my_location, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pickup, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                          if (distanceText.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(distanceText, style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(left: 9, top: 4, bottom: 4),
                  height: 15,
                  width: 2,
                  color: Colors.grey.shade300,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(drop, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                if (additionalDrops.isNotEmpty)
                  ...additionalDrops.map((dropData) => Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(left: 9, top: 4, bottom: 4),
                        alignment: Alignment.centerLeft,
                        height: 15,
                        width: 2,
                        color: Colors.grey.shade300,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dropData['address'] ?? 'Unknown Drop',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),

                // 💳 Payment & Map Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(paymentMethod.toLowerCase() == 'card' ? Icons.credit_card : Icons.money, color: Colors.grey.shade600, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              paymentMethod.toUpperCase(), 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showMapPreview(context, data),
                      icon: const Icon(Icons.map, size: 14),
                      label: const Text("Map", style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ==========================================
                // 🟢 🎯 Swipe to Accept Button
                // ==========================================
                SwipeToAcceptButton(
                  isOnline: isOnline,
                  isActive: isActive,
                  onOfflineAttempt: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Please go ONLINE first to accept new bookings."),
                      backgroundColor: Colors.orange,
                    ));
                  },
                  onInactiveAttempt: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Action Required: $inactiveReason"),
                      backgroundColor: Colors.red,
                    ));
                  },
                  onAccept: () async {
                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    try {
                      final existingBookings = await FirebaseFirestore.instance
                          .collection('all_bookings')
                          .where('acceptedBy', isEqualTo: myMembershipNo)
                          .get();
                      
                      bool hasActive = existingBookings.docs.any((doc) {
                        String s = doc.data()['status']?.toString().toLowerCase() ?? '';
                        return s == 'accepted' || s == 'arrived' || s == 'started';
                      });
                      
                      if (hasActive) {
                        throw Exception("ALREADY_HAVE_BOOKING");
                      }

                      final docRef = FirebaseFirestore.instance.collection('all_bookings').doc(docId);

                      await FirebaseFirestore.instance.runTransaction((transaction) async {
                        DocumentSnapshot snapshot = await transaction.get(docRef);

                        if (!snapshot.exists) throw Exception("Booking not found");

                        var currentData = snapshot.data() as Map<String, dynamic>;
                        String currentStatus = currentData['status']?.toString().toLowerCase() ?? '';

                        if (currentStatus == 'pending') {
                          transaction.update(docRef, {
                            'status': 'accepted',
                            'acceptedBy': myMembershipNo,
                            'driverName': myName,
                            'driverPhone': myPhone,
                            'driverVehicle': myVehicle,
                            'driverImage': myImage,
                          });

                          String passengerId = currentData['memberId']?.toString() ?? '';
                          if (passengerId.isNotEmpty) {
                            final passengerDocRef = FirebaseFirestore.instance
                                .collection('members')
                                .doc(passengerId)
                                .collection('my_bookings')
                                .doc(docId);
                            
                            transaction.set(passengerDocRef, {
                              'status': 'accepted',
                              'acceptedBy': myMembershipNo,
                              'driverName': myName,
                              'driverPhone': myPhone,
                              'driverVehicle': myVehicle,
                              'driverImage': myImage,
                            }, SetOptions(merge: true));
                          }
                          
                          // Increment totalAcceptedCount for driver
                          final driverRef = FirebaseFirestore.instance.collection('member').doc(myMembershipNo);
                          transaction.update(driverRef, {
                            'totalAcceptedCount': FieldValue.increment(1)
                          });
                        } else {
                          String takenBy = currentData['acceptedBy'] ?? 'Another Member';
                          throw Exception("TAKEN:$takenBy");
                        }
                      });

                      scaffoldMessenger.showSnackBar(const SnackBar(
                        content: Text("✅ You accepted the scheduled ride successfully!"),
                        backgroundColor: Colors.green,
                      ));

                      navigator.push(
                        MaterialPageRoute(builder: (context) => ActiveBookingPage(bookingData: data, bookingId: docId)),
                      );
                      return true;

                    } catch (e) {
                      if (e.toString().contains("ALREADY_HAVE_BOOKING")) {
                        scaffoldMessenger.showSnackBar(const SnackBar(
                          content: Text("🚨 You already have an active booking! Complete it first."),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 4),
                        ));
                      } else if (e.toString().contains("TAKEN:")) {
                        String takenBy = e.toString().split("TAKEN:")[1];
                        scaffoldMessenger.showSnackBar(SnackBar(
                          content: Text("❌ Sorry! This hire was just taken by $takenBy."),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 4),
                        ));
                      } else {
                        debugPrint("Error accepting scheduled booking: $e");
                        scaffoldMessenger.showSnackBar(const SnackBar(
                          content: Text("❌ Failed to accept booking. Please try again."),
                          backgroundColor: Colors.red,
                        ));
                      }
                      return false;
                    }
                  },
                ),
              ],
            ),
          ),
        ], // End of children of Column inside Container
      ), // End of Column inside Container
    ), // End of Container
  ), // End of Opacity
  if (isAcceptedByOther)
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 48),
                    const SizedBox(height: 8),
                    const Text("Accepted by", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(acceptedDriverName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    String ampm = dt.hour >= 12 ? 'PM' : 'AM';
    int hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    String minute = dt.minute.toString().padLeft(2, '0');
    return "$hour:$minute $ampm";
  }

  void _showMapPreview(BuildContext context, Map<String, dynamic> data) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    Map<String, dynamic>? getMap(String key) {
      if (data[key] is Map) {
        return Map<String, dynamic>.from(data[key] as Map);
      }
      return null;
    }

    var pickupMap = getMap('pickupLocation');
    var dropMap = getMap('dropLocation');

    double? pickupLat = parseDouble(pickupMap?['lat'] ?? data['pickupLat']);
    double? pickupLng = parseDouble(pickupMap?['lng'] ?? data['pickupLng']);
    double? dropLat = parseDouble(dropMap?['lat'] ?? data['dropLat']);
    double? dropLng = parseDouble(dropMap?['lng'] ?? data['dropLng']);

    List<dynamic> additionalDrops = data['additionalDrops'] ?? [];

    if (pickupLat == null || pickupLng == null || dropLat == null || dropLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location coordinates not available")));
      return;
    }

    LatLng pickup = LatLng(pickupLat, pickupLng);
    LatLng drop = LatLng(dropLat, dropLng);

    Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: pickup,
        infoWindow: const InfoWindow(title: "Pickup"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('drop_main'),
        position: drop,
        infoWindow: const InfoWindow(title: "Final Drop"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    double minLat = pickup.latitude < drop.latitude ? pickup.latitude : drop.latitude;
    double maxLat = pickup.latitude > drop.latitude ? pickup.latitude : drop.latitude;
    double minLng = pickup.longitude < drop.longitude ? pickup.longitude : drop.longitude;
    double maxLng = pickup.longitude > drop.longitude ? pickup.longitude : drop.longitude;

    // Process additional drops
    int dropIndex = 1;
    for (var dropData in additionalDrops) {
      if (dropData is Map) {
        double? dLat = parseDouble(dropData['lat']);
        double? dLng = parseDouble(dropData['lng']);
        if (dLat != null && dLng != null) {
          LatLng addDrop = LatLng(dLat, dLng);
          markers.add(
            Marker(
              markerId: MarkerId('drop_$dropIndex'),
              position: addDrop,
              infoWindow: InfoWindow(title: "Drop $dropIndex"),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            )
          );
          dropIndex++;
          
          if (dLat < minLat) minLat = dLat;
          if (dLat > maxLat) maxLat = dLat;
          if (dLng < minLng) minLng = dLng;
          if (dLng > maxLng) maxLng = dLng;
        }
      }
    }

    // Add small padding if they are exactly the same to avoid assertion error
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                height: 5,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text("Route Preview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: pickup, zoom: 14),
                    markers: markers,
                    onMapCreated: (controller) {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        try {
                          controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
                        } catch (e) {
                          debugPrint("Map zoom error: $e");
                        }
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
