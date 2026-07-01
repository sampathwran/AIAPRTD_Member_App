import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduledBookingsTab extends StatelessWidget {
  final List<QueryDocumentSnapshot> bookings;

  const ScheduledBookingsTab({super.key, required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        var data = bookings[index].data() as Map<String, dynamic>;
        return _buildScheduledCard(context, data);
      },
    );
  }

  Widget _buildScheduledCard(BuildContext context, Map<String, dynamic> data) {
    String pickup = data['pickupAddress'] ?? 'Unknown Pickup';
    String drop = data['dropAddress'] ?? 'Unknown Drop';
    String price = data['estimatedPrice']?.toString() ?? '0.00';
    String date = data['date'] ?? 'N/A';
    String time = data['time'] ?? 'N/A';
    String paymentMethod = data['paymentMethod'] ?? 'Cash';

    // 💡 Dummy Data එක අයින් කරලා, Firebase එකේ තියෙන ගාන ගන්නවා (නැත්නම් 0)
    int viewCount = data['views'] ?? 0;

    return Container(
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
                Row(
                  children: [
                    const Icon(Icons.verified, color: Colors.blue, size: 18),
                    const SizedBox(width: 6),
                    const Text("Verified Member", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
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
                    Row(
                      children: [
                        Icon(Icons.calendar_month, color: Colors.grey.shade700, size: 18),
                        const SizedBox(width: 6),
                        Text("$date • $time", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                      ],
                    ),
                    Text("Rs. $price", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 16),

                // 📍 Locations
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.my_location, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(pickup, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
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

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),

                // 💳 Payment & Map Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(paymentMethod.toLowerCase() == 'card' ? Icons.credit_card : Icons.money, color: Colors.grey.shade600, size: 18),
                        const SizedBox(width: 6),
                        Text(paymentMethod.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.map, size: 16),
                      label: const Text("View on Map", style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}