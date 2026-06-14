import 'package:flutter/material.dart';

class MembershipFeePage extends StatelessWidget {
  const MembershipFeePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Membership Fee", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 50),
                  const SizedBox(height: 10),
                  const Text("Active Member", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 5),
                  const Text("Next renewal: 12 July 2026", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Fee Summary
            _buildSection("Payment Summary", [
              _buildTile(Icons.calendar_month, "Monthly Fee", "LKR 500.00"),
              _buildTile(Icons.access_time, "Last Paid Date", "12 June 2026"),
              _buildTile(Icons.receipt_long, "Payment Method", "Card (Visa ****1234)"),
            ]),

            const SizedBox(height: 20),

            // History Section
            _buildSection("Payment History", [
              _buildTile(Icons.history, "June 2026", "Paid - LKR 500.00"),
              _buildTile(Icons.history, "May 2026", "Paid - LKR 500.00"),
              _buildTile(Icons.history, "April 2026", "Paid - LKR 500.00"),
            ]),
          ],
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8),
          child: Text(title.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey, letterSpacing: 1.2)),
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
        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.blue, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    );
  }
}