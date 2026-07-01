import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; // දුර මනින්න
import '../providers/profile_provider.dart';

import 'scheduled_bookings_tab.dart';
import 'live_bookings_tab.dart';

class BookingDashboardPage extends StatefulWidget {
  const BookingDashboardPage({super.key});

  @override
  State<BookingDashboardPage> createState() => _BookingDashboardPageState();
}

class _BookingDashboardPageState extends State<BookingDashboardPage> {
  double _searchRadiusKm = 10.0; // 💡 මූලිකව 10km
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = pos);
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  // 💡 කාලය සහ දුර අනුව ෆිල්ටර් කරන ලොජික් එක
  void _filterBookings(
      List<QueryDocumentSnapshot> allDocs,
      List<QueryDocumentSnapshot> live,
      List<QueryDocumentSnapshot> scheduled
      ) {
    DateTime now = DateTime.now();

    for (var doc in allDocs) {
      var data = doc.data() as Map<String, dynamic>;

      // 1. දුර (Radius) ෆිල්ටර් කිරීම
      if (_currentPosition != null && data['pickupLat'] != null && data['pickupLng'] != null) {
        double distanceInMeters = Geolocator.distanceBetween(
            _currentPosition!.latitude, _currentPosition!.longitude,
            data['pickupLat'], data['pickupLng']
        );
        if ((distanceInMeters / 1000) > _searchRadiusKm) {
          continue; // 🚫 Slider එකෙන් තෝරපු Radius එකෙන් පිට නම් ඒක අයින් කරනවා
        }
      }

      // 2. කාලය ෆිල්ටර් කිරීම (30 mins rule)
      DateTime? startTime;
      if (data['startTime'] != null && data['startTime'] is Timestamp) {
        startTime = (data['startTime'] as Timestamp).toDate();
      }

      if (startTime != null) {
        Duration diff = startTime.difference(now);

        if (diff.inMinutes <= 30 && diff.inMinutes >= 0) {
          live.add(doc); // 🔴 විනාඩි 30ට අඩු නම් Live එකට දානවා
        } else if (diff.inMinutes > 30) {
          scheduled.add(doc); // 🔵 විනාඩි 30ට වඩා වැඩි නම් Scheduled එකට දානවා
        }
      } else {
        scheduled.add(doc); // වෙලාවක් නැත්නම් සාමාන්ය Scheduled එකට දානවා
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    // 💡 🎯 Member ගේ Category එක ගන්නවා
    final String myCategory = profileProvider.memberData?['selectedCategory']?.toString() ?? 'Mini';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text("Hires Dashboard", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            indicatorWeight: 3,
            tabs: [
              Tab(text: "Live Bookings"),
              Tab(text: "Scheduled"),
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

            // ==========================================
            // 🔄 STREAM BUILDER & TABS
            // ==========================================
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('all_bookings') // ⚠️ ඔයා කිව්ව Collection එක
                    .where('status', isEqualTo: 'pending')
                    .where('selectedCategory', isEqualTo: myCategory) // 👈 හරියටම තමන්ගේ Category එක
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading bookings"));
                  }

                  List<QueryDocumentSnapshot> liveBookings = [];
                  List<QueryDocumentSnapshot> scheduledBookings = [];

                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    _filterBookings(snapshot.data!.docs, liveBookings, scheduledBookings);
                  }

                  return TabBarView(
                    children: [
                      LiveBookingsTab(bookings: liveBookings),
                      ScheduledBookingsTab(bookings: scheduledBookings),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}