import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';

class SavingHistoryList extends StatelessWidget {
  const SavingHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('transactions')
          .where('passengerId', isEqualTo: profile.memberNo)
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
                Icon(Icons.savings_outlined, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text("No savings yet.", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            final type = data['type'] as String? ?? 'app_booking_commission_split';
            final amount = (type == 'app_booking_commission_split' ? data['passengerSavings'] : data['amount'] ?? 0.0).toDouble();
            final date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            
            final tripId = data['tripId'] as String? ?? 'N/A';
            final totalFare = (data['totalFare'] ?? 0.0).toDouble();
            final isEarning = type == 'app_booking_commission_split';
            
            String title = "Withdrawal";
            if (type == 'app_booking_commission_split') {
              title = "Shared Booking Reward";
            } else if (type == 'auto_settlement') {
              title = "Auto-Settled App Charge";
            } else if (type == 'fee_payment') {
              title = "Membership Fee Payment";
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
                      color: isEarning ? Colors.teal.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEarning ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, 
                      color: isEarning ? Colors.teal : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                        if (isEarning && tripId != 'N/A') ...[
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
                    "${isEarning ? '+' : '-'} LKR ${NumberFormat('#,##0.00').format(amount)}",
                    style: TextStyle(fontWeight: FontWeight.bold, color: isEarning ? Colors.teal : Colors.orange, fontSize: 14),
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
