import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; // 💡 ලොකේෂන් සඳහා
import 'dart:async'; // 💡 Timer එක සඳහා
import '../providers/profile_provider.dart';

import 'scheduled_bookings_tab.dart';
import 'live_bookings_tab.dart';

class BookingDashboardPage extends StatefulWidget {
  const BookingDashboardPage({super.key});

  @override
  State<BookingDashboardPage> createState() => _BookingDashboardPageState();
}

class _BookingDashboardPageState extends State<BookingDashboardPage> {
  double _searchRadiusKm = 20.0; // 💡 මූලිකව 20km 
  Position? _currentPosition;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    
    // Auto-refresh the screen every 1 minute so time-based logic (moving to Live) triggers
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = pos);
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  void _filterBookings(
      List<QueryDocumentSnapshot> allDocs,
      List<QueryDocumentSnapshot> live,
      List<QueryDocumentSnapshot> scheduled,
      String myCategory,
      ) {
    DateTime now = DateTime.now();

    for (var doc in allDocs) {
      var data = doc.data() as Map<String, dynamic>;
      
      String category = (data['vehicleCategory'] ?? data['selectedCategory'] ?? '').toString().toLowerCase();
      
      // 1. Category check
      if (category.isEmpty) category = 'unknown';
      if (category != myCategory.toLowerCase()) {
        continue;
      }

      // 2. Radius filter
      Map<String, dynamic>? getMap(String key) {
        if (data[key] is Map) {
          return Map<String, dynamic>.from(data[key] as Map);
        }
        return null;
      }
      
      var pickupMap = getMap('pickupLocation');
      double? pLat = (pickupMap?['lat'] ?? data['pickupLat'])?.toDouble();
      double? pLng = (pickupMap?['lng'] ?? data['pickupLng'])?.toDouble();
      
      if (_currentPosition != null && pLat != null && pLng != null) {
        double distanceInMeters = Geolocator.distanceBetween(
            _currentPosition!.latitude, _currentPosition!.longitude,
            pLat, pLng
        );
        double distanceKm = distanceInMeters / 1000;
        if (distanceKm > _searchRadiusKm) {
          continue; // Out of radius
        }
      }

      // 3. Time filter & Auto-expire
      DateTime? startTime;
      if (data['pickupTime'] != null) {
        startTime = DateTime.tryParse(data['pickupTime']?.toString() ?? '');
      } else if (data['startTime'] != null && data['startTime'] is Timestamp) {
        startTime = (data['startTime'] as Timestamp).toDate();
      }

      if (startTime != null) {
        Duration diff = startTime.difference(now);

        if (diff.inMinutes < 0) {
          FirebaseFirestore.instance.collection('all_bookings').doc(doc.id).update({
            'status': 'expired',
            'reason': 'No driver accepted in time'
          });
          continue;
        }

        if (diff.inMinutes <= 30) {
          live.add(doc); 
        } else {
          scheduled.add(doc); 
        }
      } else {
        scheduled.add(doc); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    // 💡 🎯 Member ගේ Category එක විතරක් ගන්නවා.    // Extract my vehicle category from memberData
    final String myCategory = (profileProvider.memberData?['vehicle_category'] ?? 
                              profileProvider.memberData?['selectedCategory'] ?? 
                              '').toString();

    debugPrint("=== DASHBOARD BUILD ===");
    debugPrint("Is Profile Loading? ${profileProvider.isLoading}");
    debugPrint("Logged in as MembershipNo: ${profileProvider.memberData?['membershipNo']}");
    debugPrint("Fetched Document ID: ${profileProvider.memberData?['docId']}");
    debugPrint("Member Data Keys: ${profileProvider.memberData?.keys.toList()}");
    debugPrint("Derived myCategory: '$myCategory'");
    debugPrint("=======================");

    return DefaultTabController(
      length: 2,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('all_bookings') // 
            .where('status', whereIn: ['pending', 'Pending', 'PENDING'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          List<QueryDocumentSnapshot> liveBookings = [];
          List<QueryDocumentSnapshot> scheduledBookings = [];

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            _filterBookings(snapshot.data!.docs, liveBookings, scheduledBookings, myCategory);
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              title: const Text("Hires Dashboard", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              bottom: TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: "Live Bookings (${liveBookings.length})"),
                  Tab(text: "Scheduled (${scheduledBookings.length})"),
                ],
              ),
            ),
            body: Column(
              children: [
                // ==========================================
                // 📍 RADIUS SLIDER SECTION
                // ==========================================
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Max Distance (Radius)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          Text("${_searchRadiusKm.toInt()} km", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
                        ],
                      ),
                      Slider(
                        value: _searchRadiusKm,
                        min: 1.0,
                        max: 20.0,
                        divisions: 19,
                        activeColor: Colors.blue,
                        inactiveColor: Colors.blue.shade100,
                        onChanged: (val) {
                          setState(() {
                            _searchRadiusKm = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                Expanded(
                  child: TabBarView(
                    children: [
                      LiveBookingsTab(bookings: liveBookings, currentPosition: _currentPosition),
                      ScheduledBookingsTab(bookings: scheduledBookings, currentPosition: _currentPosition),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}