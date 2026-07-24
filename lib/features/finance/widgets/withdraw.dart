import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:aiaprtd_member/core/providers/payment_provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';

Future<void> handleWithdraw(BuildContext context, double balance) async {
  if (balance <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No savings available to withdraw.')));
    return;
  }

  final payment = Provider.of<PaymentProvider>(context, listen: false);
  if (payment.bankData == null || payment.bankData!['bankName'] == null || payment.bankData!['bankName'].toString().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Please complete your Bank Details in the Profile section first.'),
      backgroundColor: Colors.red,
    ));
    return;
  }

  final profile = Provider.of<ProfileProvider>(context, listen: false);
  
  bool? confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Withdraw Savings"),
      content: Text("Are you sure you want to request a withdrawal of LKR ${NumberFormat('#,##0.00').format(balance)} to your bank account?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true), 
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text("Request", style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  if (confirm == true) {
    try {
      final memNo = profile.memberNo;
      final batch = FirebaseFirestore.instance.batch();

      // 1. Create Withdrawal Request
      final reqRef = FirebaseFirestore.instance.collection('withdrawal_requests').doc();
      batch.set(reqRef, {
        'requestId': reqRef.id,
        'memberId': memNo,
        'amount': balance,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'bankDetails': payment.bankData,
      });

      // 2. Deduct from member's savingsBalance immediately
      batch.set(FirebaseFirestore.instance.collection('member').doc(memNo), {
        'savingsBalance': FieldValue.increment(-balance)
      }, SetOptions(merge: true));

      // 3. Add transaction record
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final txnRef = FirebaseFirestore.instance
          .collection('finance_transactions')
          .doc(memNo)
          .collection('history')
          .doc(dateStr)
          .collection('transactions')
          .doc();

      batch.set(txnRef, {
        'transactionId': txnRef.id,
        'passengerId': memNo, // To show in SavingHistoryList
        'amount': balance,
        'type': 'withdrawal_request',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal request sent to Admin.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to request withdrawal: $e')));
      }
    }
  }
}
