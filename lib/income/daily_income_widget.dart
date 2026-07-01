import 'package:flutter/material.dart';

class DailyIncomeWidget extends StatelessWidget {
  const DailyIncomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // ඔයාගේ route එක 'income' නම් මේක හරි, නැත්නම් ඒකට ගැලපෙන විදියට වෙනස් කරන්න
        Navigator.pushNamed(context, '/income');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 18, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              "Rs. 0.00",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}