import 'package:flutter/material.dart';

class SavingPage extends StatelessWidget {
  const SavingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("My Savings", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Savings Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  const Text("Total Savings", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 10),
                  const Text("LKR 125,000.00",
                      style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  // Progress Indicator
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: 0.7, // 70% complete
                      backgroundColor: Colors.blue.shade50,
                      color: Colors.blue,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("Goal: LKR 200,000.00", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Savings Details
            _buildSection("Saving Accounts", [
              _buildTile(Icons.account_balance_wallet, "Emergency Fund", "LKR 50,000.00"),
              _buildTile(Icons.directions_car, "Vehicle Maintenance", "LKR 30,000.00"),
              _buildTile(Icons.home, "Future Investment", "LKR 45,000.00"),
            ]),

            const SizedBox(height: 20),

            // Recent Activity
            _buildSection("Recent Transfers", [
              _buildTile(Icons.add_circle_outline, "Monthly Deposit", "+ LKR 5,000.00"),
              _buildTile(Icons.remove_circle_outline, "Withdrawal", "- LKR 2,000.00"),
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