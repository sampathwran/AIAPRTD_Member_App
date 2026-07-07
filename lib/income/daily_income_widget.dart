import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';

class DailyIncomeWidget extends StatefulWidget {
  const DailyIncomeWidget({super.key});

  @override
  State<DailyIncomeWidget> createState() => _DailyIncomeWidgetState();
}

class _DailyIncomeWidgetState extends State<DailyIncomeWidget> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Rebuild every minute to check if the date changes (for 00:01 am reset)
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context);
    final memberData = profile.memberData;

    if (memberData == null) {
      return _buildContainer("Rs. 0.00");
    }

    final dateStr = "${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().day.toString().padLeft(2, '0')}";
    final membershipNo = memberData['membershipNo'] ?? '';

    if (membershipNo.isEmpty) {
      return _buildContainer("Rs. 0.00");
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('dayly_trips')
          .doc(dateStr)
          .collection(membershipNo)
          .snapshots(),
      builder: (context, snapshot) {
        double total = 0.0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final fare = (data['totalFare'] ?? 0.0) as num;
            total += fare.toDouble();
          }
        }
        return _buildContainer("Rs. ${total.toStringAsFixed(2)}");
      },
    );
  }

  Widget _buildContainer(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}