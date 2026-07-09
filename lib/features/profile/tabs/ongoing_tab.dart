import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aiaprtd_member/features/profile/widgets/booking_card.dart';
import 'package:aiaprtd_member/features/profile/widgets/empty_booking_state.dart';
import 'package:aiaprtd_member/features/profile/passenger_ongoing_trip_page.dart';

class OngoingTab extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  
  const OngoingTab({super.key, required this.docs});

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) {
      return const EmptyBookingState(
        title: "No Ongoing Bookings", 
        subtitle: "You have no active rides right now."
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final String docId = docs[index].id;
        
        return InkWell(
          onTap: () {
            String status = data['status']?.toString().toLowerCase() ?? '';
            if (status == 'ongoing' || status == 'accepted' || status == 'arrived' || status == 'started') {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => PassengerOngoingTripPage(bookingId: docId, bookingData: data))
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: BookingCard(data: data),
        );
      },
    );
  }
}