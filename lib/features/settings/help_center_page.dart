import 'package:flutter/material.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Help Center", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("How can we help you?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // FAQ Section
            _buildSection("Frequently Asked Questions", [
              _buildExpansionTile("How to update my profile?", "You can go to settings and tap on your profile picture to edit."),
              _buildExpansionTile("How to withdraw money?", "Navigate to Earning page and tap on Withdraw button."),
              _buildExpansionTile("What is the rank system?", "Check your Rank page to see your current status and progress."),
            ]),

            const SizedBox(height: 30),

            // Contact Support
            _buildSection("Contact Support", [
              ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),
                title: const Text("Email Support"),
                subtitle: const Text("support@yourapp.com"),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: const Text("Call Hotline"),
                subtitle: const Text("+94 11 234 5678"),
                onTap: () {},
              ),
            ]),
          ],
        ),
      ),
    );
  }

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

  Widget _buildExpansionTile(String title, String answer) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(answer, style: const TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}