import 'package:flutter/material.dart';

class SavingRulesCard extends StatelessWidget {
  const SavingRulesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.teal.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                "How Savings Work",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRuleItem("App Bookings:", "When you place an App Booking, a 10% commission is charged to the driver.", Icons.touch_app, Colors.teal),
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 4, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("• 7% is added to your Savings Balance as a reward", style: TextStyle(color: Colors.teal.shade700, fontSize: 12)),
                Text("• 3% is kept as App Usage Charge", style: TextStyle(color: Colors.teal.shade700, fontSize: 12)),
              ],
            ),
          ),
          _buildRuleItem("Street Hires (Road Pickups):", "Street hires do not contribute to your savings. They only incur a 3% App Usage Charge.", Icons.hail, Colors.orange),
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
