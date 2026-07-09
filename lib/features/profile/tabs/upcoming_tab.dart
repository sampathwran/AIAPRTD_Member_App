import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aiaprtd_member/features/profile/widgets/booking_card.dart';
import 'package:aiaprtd_member/features/profile/widgets/empty_booking_state.dart';

class UpcomingTab extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  
  const UpcomingTab({super.key, required this.docs});

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) {
      return const EmptyBookingState(
        title: "No Upcoming Bookings", 
        subtitle: "You don't have any scheduled rides yet."
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        
        return InkWell(
          onTap: () {
            // Do nothing or navigate to details
          },
          borderRadius: BorderRadius.circular(16),
          child: BookingCard(data: data),
        );
      },
    );
  }
}