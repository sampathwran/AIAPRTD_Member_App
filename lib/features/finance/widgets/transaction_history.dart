import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';

class TransactionHistoryList extends StatelessWidget {
  const TransactionHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('transactions')
          .where('driverId', isEqualTo: profile.memberNo)
          .where('type', whereIn: ['app_booking_commission_split', 'road_pickup_commission', 'auto_settlement', 'auto_settlement_refund'])
          .orderBy('timestamp', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text("No transactions yet.", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            final type = data['type'] as String? ?? '';
            final amount = type == 'auto_settlement' ? (data['amount'] ?? 0.0).toDouble() : (data['driverCommission'] ?? 0.0).toDouble();
            final date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            final tripId = data['tripId'] as String? ?? 'N/A';
            final totalFare = (data['totalFare'] ?? 0.0).toDouble();
            
            final isAppBooking = type == 'app_booking_commission_split';
            final isAutoSettled = type == 'auto_settlement';
            final isRefund = type == 'auto_settlement_refund';

            String title = "Street Hire Charge";
            Color itemColor = Colors.orange;
            if (isAppBooking) {
              title = "App Booking Charge";
              itemColor = Colors.red;
            } else if (isAutoSettled) {
              title = "Auto-Settled via Savings";
              itemColor = Colors.green;
            } else if (isRefund) {
              title = "Refund to Savings";
              itemColor = Colors.blue;
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: itemColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(isAutoSettled || isRefund ? Icons.check_circle_outline : Icons.arrow_upward_rounded, color: itemColor),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                        if (!isAutoSettled && !isRefund) ...[
                          const SizedBox(height: 4),
                          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text("Trip ID: $tripId", style: const TextStyle(color: Colors.black54, fontSize: 11))),
                          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text("Total Fare: LKR ${NumberFormat('#,##0.00').format(totalFare)}", style: const TextStyle(color: Colors.black54, fontSize: 11))),
                        ],
                        const SizedBox(height: 4),
                        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(DateFormat('MMM dd, yyyy • hh:mm a').format(date), style: const TextStyle(color: Colors.grey, fontSize: 10))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${isAutoSettled || isRefund ? '+' : '-'} LKR ${NumberFormat('#,##0.00').format(amount)}",
                    style: TextStyle(fontWeight: FontWeight.bold, color: itemColor, fontSize: 14),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
