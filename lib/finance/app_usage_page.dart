import 'package:flutter/material.dart';

class AppUsagePage extends StatelessWidget {
  const AppUsagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("App Usage Charge", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Current Month Charge Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.indigo.shade500,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.indigo.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: const Column(
                children: [
                  Text("Current Usage Charge", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  SizedBox(height: 10),
                  Text("LKR 1,250.00",
                      style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text("Due Date: 20 June 2026", style: TextStyle(color: Colors.white60)),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Billing Details
            _buildSection("Billing Summary", [
              _buildTile(Icons.data_usage, "Data Usage Fee", "LKR 500.00"),
              _buildTile(Icons.support_agent, "Service Fee", "LKR 500.00"),
              _buildTile(Icons.percent, "Tax (VAT)", "LKR 250.00"),
            ]),

            const SizedBox(height: 20),

            // Recent Invoices
            _buildSection("Recent Invoices", [
              _buildTile(Icons.receipt_long, "May 2026 Invoice", "Paid - LKR 1,250.00"),
              _buildTile(Icons.receipt_long, "April 2026 Invoice", "Paid - LKR 1,250.00"),
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