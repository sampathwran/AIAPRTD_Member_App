import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import 'tabs/upcoming_tab.dart';
import 'tabs/ongoing_tab.dart';
import 'tabs/completed_tab.dart';
import 'tabs/cancelled_tab.dart';

class MyBookingPage extends StatefulWidget {
  final int initialIndex;
  
  const MyBookingPage({super.key, this.initialIndex = 0});

  @override
  State<MyBookingPage> createState() => _MyBookingPageState();
}

class _MyBookingPageState extends State<MyBookingPage> {
  // Fire and forget cancellation for expired bookings
  void _autoCancelBooking(String tripId, String memberId, Map<String, dynamic> data) async {
    try {
      Map<String, dynamic> updates = {
        'status': 'Cancelled',
        'cancelReason': 'Auto cancelled: Pickup time passed',
        'cancelledBy': 'System',
        'cancelledAt': FieldValue.serverTimestamp(),
      };

      // Update all_bookings
      await FirebaseFirestore.instance.collection('all_bookings').doc(tripId).set(updates, SetOptions(merge: true));
      
      // Update my_bookings
      await FirebaseFirestore.instance
          .collection('members')
          .doc(memberId)
          .collection('my_bookings')
          .doc(tripId)
          .set(updates, SetOptions(merge: true));
          
      // Update dayly_trips
      DateTime? createdAt;
      if (data['timestamp'] is Timestamp) {
        createdAt = (data['timestamp'] as Timestamp).toDate();
      } else if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      }
      
      if (createdAt != null) {
        String dateStr = "${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}";
        await FirebaseFirestore.instance
            .collection('dayly_trips')
            .doc(dateStr)
            .collection(memberId)
            .doc(tripId)
            .set(updates, SetOptions(merge: true))
            .catchError((e) => debugPrint("dayly_trips not found, skipping."));
      }
    } catch (e) {
      debugPrint("Auto cancel error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberId = Provider.of<ProfileProvider>(context).memberNo;

    if (memberId == 'N/A' || memberId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Please login to view bookings")),
      );
    }

    return DefaultTabController(
      initialIndex: widget.initialIndex,
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text("My Bookings", style: TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Upcoming"),
              Tab(text: "Ongoing"),
              Tab(text: "Completed"),
              Tab(text: "Cancelled"),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('all_bookings')
              .where('memberId', isEqualTo: memberId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error loading bookings: ${snapshot.error}"));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const TabBarView(
                children: [
                  UpcomingTab(docs: []),
                  OngoingTab(docs: []),
                  CompletedTab(docs: []),
                  CancelledTab(docs: []),
                ],
              );
            }

            // Manually sort by createdAt descending to avoid needing a composite index
            List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
            docs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              
              Timestamp? aTime = (aData['createdAt'] is Timestamp) ? aData['createdAt'] : (aData['timestamp'] is Timestamp ? aData['timestamp'] : null);
              Timestamp? bTime = (bData['createdAt'] is Timestamp) ? bData['createdAt'] : (bData['timestamp'] is Timestamp ? bData['timestamp'] : null);
              
              if (aTime != null && bTime != null) {
                return bTime.compareTo(aTime);
              }
              if (aTime == null && bTime != null) return 1;
              if (bTime == null && aTime != null) return -1;
              return 0;
            });

            // Filter bookings by status
            List<QueryDocumentSnapshot> upcoming = [];
            List<QueryDocumentSnapshot> ongoing = [];
            List<QueryDocumentSnapshot> completed = [];
            List<QueryDocumentSnapshot> cancelled = [];

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              String status = data['status']?.toString().toLowerCase() ?? '';
              
              if (status == 'pending' || status == 'upcoming' || status == 'scheduled') {
                bool isExpired = false;
                if (status == 'pending' && data['pickupTime'] != null) {
                  try {
                    DateTime pickup = DateTime.parse(data['pickupTime'].toString());
                    if (DateTime.now().isAfter(pickup)) {
                      isExpired = true;
                    }
                  } catch (e) {
                    debugPrint("Time parse error: $e");
                  }
                }

                if (isExpired) {
                  _autoCancelBooking(doc.id, memberId, data);
                  cancelled.add(doc);
                } else {
                  upcoming.add(doc);
                }
              } else if (status == 'ongoing' || status == 'accepted' || status == 'started' || status == 'arrived') {
                ongoing.add(doc);
              } else if (status == 'completed' || status == 'collected') {
                completed.add(doc);
              } else if (status == 'cancelled' || status == 'rejected') {
                cancelled.add(doc);
              } else {
                upcoming.add(doc); 
              }
            }

            return TabBarView(
              children: [
                UpcomingTab(docs: upcoming),
                OngoingTab(docs: ongoing),
                CompletedTab(docs: completed),
                CancelledTab(docs: cancelled),
              ],
            );
          },
        ),
      ),
    );
  }
}