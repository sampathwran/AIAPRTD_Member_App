import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:aiaprtd_member/core/providers/finance_provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';

Future<void> handlePayMembershipFee(BuildContext context, double balance) async {
  final financeProv = Provider.of<FinanceProvider>(context, listen: false);
  final profile = Provider.of<ProfileProvider>(context, listen: false);
  final monthlyFee = financeProv.monthlyMembershipFee; 

  if (balance < monthlyFee) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Insufficient savings. You need LKR $monthlyFee to pay the fee.')));
    return;
  }

  // Confirmation dialog
  bool? confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Pay Membership Fee"),
      content: Text("Are you sure you want to deduct LKR $monthlyFee from your savings to pay this month's fee?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true), 
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          child: const Text("Pay", style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  if (confirm == true) {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final memNo = profile.memberNo;
      
      // 1. Deduct from savings
      batch.set(FirebaseFirestore.instance.collection('members').doc(memNo), {
        'savingsBalance': FieldValue.increment(-monthlyFee)
      }, SetOptions(merge: true));

      // 2. Add to payment history
      final monthName = DateFormat('MMMM').format(DateTime.now());
      final yearStr = DateTime.now().year.toString();
      
      batch.set(FirebaseFirestore.instance.collection('app_membership_fee').doc(memNo), {
        'payment_history': FieldValue.arrayUnion([{
          'month': monthName,
          'year': yearStr,
          'reason': 'Membership Fee',
          'amount': monthlyFee,
          'paid_via': 'savings',
          'date': DateTime.now().toIso8601String(),
        }])
      }, SetOptions(merge: true));

      // 3. Add transaction record
      final txnRef = FirebaseFirestore.instance.collection('finance_transactions').doc();
      batch.set(txnRef, {
        'transactionId': txnRef.id,
        'passengerId': memNo,
        'amount': monthlyFee,
        'type': 'fee_payment',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membership Fee paid successfully!')));
      }
    } catch (e) {
      debugPrint("Error paying fee: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to pay fee. Try again later.')));
      }
    }
  }
}
