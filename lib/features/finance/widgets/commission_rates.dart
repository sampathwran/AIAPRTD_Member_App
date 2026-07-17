import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/finance_provider.dart';

class CommissionRatesCard extends StatelessWidget {
  const CommissionRatesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                "App Usage Charge Rules",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRuleItem("App Bookings:", "10% commission is deducted.", Icons.touch_app, Colors.blue),
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 4, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("• 7% goes to the member who placed the booking (Savings)", style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                Text("• 3% is kept as App Usage Charge", style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
              ],
            ),
          ),
          _buildRuleItem("Street Hires (Road Pickups):", "Only 3% App Usage Charge is deducted.", Icons.hail, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.3),
                children: [
                  TextSpan(text: "$title ", style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
