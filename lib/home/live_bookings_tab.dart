import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/profile_provider.dart';
import 'active_booking_page.dart';

class LiveBookingsTab extends StatelessWidget {
  final List<QueryDocumentSnapshot> bookings;
  final Position? currentPosition;

  const LiveBookingsTab({super.key, required this.bookings, this.currentPosition});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flash_on_rounded, size: 60, color: Colors.orange.shade100),
            const SizedBox(height: 16),
            const Text("No Live Bookings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            const Text("Bookings starting within 30 mins appear here.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Sort active bookings by time (ascending)
    List<QueryDocumentSnapshot> sortedBookings = List.from(bookings);
    sortedBookings.sort((a, b) {
      var dataA = a.data() as Map<String, dynamic>;
      var dataB = b.data() as Map<String, dynamic>;

      DateTime? timeA;
      if (dataA['pickupTime'] != null) {
        timeA = DateTime.tryParse(dataA['pickupTime'].toString());
      } else if (dataA['startTime'] != null && dataA['startTime'] is Timestamp) {
        timeA = (dataA['startTime'] as Timestamp).toDate();
      }

      DateTime? timeB;
      if (dataB['pickupTime'] != null) {
        timeB = DateTime.tryParse(dataB['pickupTime'].toString());
      } else if (dataB['startTime'] != null && dataB['startTime'] is Timestamp) {
        timeB = (dataB['startTime'] as Timestamp).toDate();
      }

      if (timeA == null && timeB == null) {
        return 0;
      }
      if (timeA == null) {
        return 1; // Put nulls at the end
      }
      if (timeB == null) {
        return -1;
      }

      return timeA.compareTo(timeB);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: sortedBookings.length,
      itemBuilder: (context, index) {
        var data = sortedBookings[index].data() as Map<String, dynamic>;
        String docId = sortedBookings[index].id;

        return _buildLiveCard(context, data, docId);
      },
    );
  }

  Widget _buildLiveCard(BuildContext context, Map<String, dynamic> data, String docId) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final String myMembershipNo = profileProvider.memberNo;
    final String myName = profileProvider.memberFullName;
    final String myPhone = profileProvider.memberData?['mobile']?.toString() ?? '';
    final String myVehicle = profileProvider.memberData?['vehicle_category']?.toString() ?? '';
    final String myImage = profileProvider.profileImageUrl;

    Map<String, dynamic>? getMap(String key) {
      if (data[key] is Map) {
        return Map<String, dynamic>.from(data[key] as Map);
      }
      return null;
    }
    
    var pickupMap = getMap('pickupLocation');
    var dropMap = getMap('dropLocation');

    String pickup = data['startAddress'] ?? pickupMap?['address'] ?? 'Unknown Pickup';
    String drop = data['endAddress'] ?? dropMap?['address'] ?? 'Unknown Drop';
    List<dynamic> additionalDrops = data['additionalDrops'] ?? [];
    String price = (data['estimateFare'] ?? data['totalFare'] ?? 0).toString();
    
    // Date and time extracting from pickupTime
    String date = 'Today';
    String time = 'N/A';
    bool isOverdue = false;
    
    if (data['pickupTime'] != null) {
      try {
        DateTime dt = DateTime.parse(data['pickupTime'].toString());
        date = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
        time = "${dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour)}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}";
        if (DateTime.now().isAfter(dt.add(const Duration(minutes: 5)))) {
          isOverdue = true;
        }
      } catch (e) {
        debugPrint("Date parse error: $e");
      }
    } else if (data['startTime'] != null && data['startTime'] is Timestamp) {
      DateTime dt = (data['startTime'] as Timestamp).toDate();
      if (DateTime.now().isAfter(dt.add(const Duration(minutes: 5)))) {
        isOverdue = true;
      }
    }

    String distanceText = "";
    if (currentPosition != null) {
      double? parseDouble(dynamic value) {
        if (value == null) {
          return null;
        }
        if (value is double) {
          return value;
        }
        if (value is int) {
          return value.toDouble();
        }
        if (value is String) {
          return double.tryParse(value);
        }
        return null;
      }
      
      double? pLat = parseDouble(pickupMap?['lat'] ?? data['pickupLat']);
      double? pLng = parseDouble(pickupMap?['lng'] ?? data['pickupLng']);
      
      if (pLat != null && pLng != null) {
        double distMeters = Geolocator.distanceBetween(
          currentPosition!.latitude, 
          currentPosition!.longitude, 
          pLat, 
          pLng
        );
        double distKm = distMeters / 1000;
        distanceText = "${distKm.toStringAsFixed(1)} km away from you";
      }
    }

    String paymentMethod = data['paymentMethod'] ?? 'Cash';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade300, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.orange.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🛡️ Top Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: isOverdue ? Colors.red : Colors.orange, borderRadius: BorderRadius.circular(20)),
                  child: Text(isOverdue ? "LATE" : "LIVE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.schedule, color: isOverdue ? Colors.red : Colors.grey.shade700, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              "$date • $time", 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isOverdue ? Colors.red : Colors.grey.shade800),
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
                  height: 15, width: 2, color: Colors.grey.shade300,
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

                // 💳 Payment
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
                  onAccept: () async {
                    try {
                      final docRef = FirebaseFirestore.instance.collection('all_bookings').doc(docId);

                      // 💡 100% ආරක්ෂිත Firebase Transaction
                      await FirebaseFirestore.instance.runTransaction((transaction) async {
                        DocumentSnapshot snapshot = await transaction.get(docRef);

                        if (!snapshot.exists) throw Exception("Booking not found");

                        var currentData = snapshot.data() as Map<String, dynamic>;
                        String currentStatus = currentData['status']?.toString().toLowerCase() ?? '';

                        if (currentStatus == 'pending') {
                          // 🟢 Update all_bookings collection
                          transaction.update(docRef, {
                            'status': 'accepted',
                            'acceptedBy': myMembershipNo,
                            'driverName': myName,
                            'driverPhone': myPhone,
                            'driverVehicle': myVehicle,
                            'driverImage': myImage,
                          });

                          // 🟢 Sync with passenger's my_bookings collection
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
                        } else {
                          // 🔴 කවුරුහරි කලින් අරගෙන!
                          String takenBy = currentData['acceptedBy'] ?? 'Another Member';
                          throw Exception("TAKEN:$takenBy");
                        }
                      });

                      // සාර්ථකව ගත්තම notification එක පෙන්නලා අලුත් Page එකට යනවා
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("✅ You accepted the ride successfully!"),
                          backgroundColor: Colors.green,
                        ));

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ActiveBookingPage(bookingData: data, bookingId: docId)),
                        );
                      }
                      return true;

                    } catch (e) {
                      if (e.toString().contains("TAKEN:")) {
                        String takenBy = e.toString().split("TAKEN:")[1];
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("🚨 Ride was already taken by: $takenBy"),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 4),
                          ));
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text("❌ Failed to accept booking."),
                            backgroundColor: Colors.red,
                          ));
                        }
                      }
                      return false;
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMapPreview(BuildContext context, Map<String, dynamic> data) {
    double? parseDouble(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is double) {
        return value;
      }
      if (value is int) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value);
      }
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

// ==========================================
// 🚀 CUSTOM SWIPE TO ACCEPT BUTTON (සම්පූර්ණ කේතය)
// ==========================================
class SwipeToAcceptButton extends StatefulWidget {
  final Future<bool> Function() onAccept;
  const SwipeToAcceptButton({super.key, required this.onAccept});

  @override
  State<SwipeToAcceptButton> createState() => _SwipeToAcceptButtonState();
}

class _SwipeToAcceptButtonState extends State<SwipeToAcceptButton> {
  double _dragPosition = 0.0;
  bool _isLoading = false;
  bool _isAccepted = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          // ඇඟිල්ලෙන් අදින්න පුළුවන් උපරිම දුර (Button එකේ පළල - අදින රවුමේ පළල)
          double maxDrag = constraints.maxWidth - 60;

          return Container(
            height: 60,
            decoration: BoxDecoration(
              color: _isAccepted ? Colors.green : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _isAccepted ? Colors.green : Colors.blue, width: 2),
            ),
            child: Stack(
              children: [
                // 1. Text eka (Swipe to Accept >>>)
                Center(
                  child: Text(
                    _isAccepted
                        ? "ACCEPTED!"
                        : (_isLoading ? "Processing..." : "Swipe to Accept >>>"),
                    style: TextStyle(
                      color: _isAccepted ? Colors.white : Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                // 2. අදින රවුම (Draggable Thumb)
                if (!_isAccepted && !_isLoading)
                  Positioned(
                    left: _dragPosition,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _dragPosition += details.primaryDelta!;
                          // සීමාවෙන් පිට යන්න දෙන්නේ නෑ
                          if (_dragPosition < 0) {
                            _dragPosition = 0;
                          }
                          if (_dragPosition > maxDrag) {
                            _dragPosition = maxDrag;
                          }
                        });
                      },
                      onHorizontalDragEnd: (details) async {
                        // 80% කට වඩා ඇදලා නම් Accept කරනවා
                        if (_dragPosition > maxDrag * 0.8) {
                          setState(() {
                            _dragPosition = maxDrag;
                            _isLoading = true; // Processing වෙනවා කියලා පෙන්නනවා
                          });

                          // Firebase Function එක Call කරනවා
                          bool success = await widget.onAccept();

                          if (success) {
                            setState(() {
                              _isAccepted = true;
                              _isLoading = false;
                            });
                          } else {
                            // Error එකක් ආවොත් ආපහු මුලට යනවා
                            setState(() {
                              _dragPosition = 0.0;
                              _isLoading = false;
                            });
                          }
                        } else {
                          // 80% කට වඩා ඇදලා නැත්නම් ආපහු මුලට පනිනවා
                          setState(() {
                            _dragPosition = 0.0;
                          });
                        }
                      },
                      child: Container(
                        width: 60,
                        height: 56, // Border එක නිසා පොඩ්ඩක් අඩුයි
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(Icons.double_arrow, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
    );
  }
}