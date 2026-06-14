import 'package:flutter/material.dart';

class RankPage extends StatelessWidget {
  const RankPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Rank Details", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Current Rank Badge Visual
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.amber.shade400, Colors.orange.shade300]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                children: [
                  Icon(Icons.workspace_premium, size: 80, color: Colors.white),
                  SizedBox(height: 10),
                  Text("GOLD MEMBER", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Rank Benefits Section
            _buildSection("Rank Benefits", [
              _buildTile(Icons.local_shipping, "Priority Support", "24/7 Access"),
              _buildTile(Icons.discount, "Exclusive Discounts", "15% off on fees"),
              _buildTile(Icons.card_giftcard, "Monthly Bonuses", "Enabled"),
            ]),

            const SizedBox(height: 20),

            // Progression Section
            _buildSection("Progression Criteria", [
              _buildTile(Icons.directions_car, "Completed Rides", "450 / 500"),
              _buildTile(Icons.stars, "Rating", "4.8 / 5.0"),
            ]),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8),
          child: Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey, letterSpacing: 1.2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.amber.shade800, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
    );
  }
}