import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Privacy Policy", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Last Updated: June 2026", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            _buildSection("1. Information We Collect",
                "We collect information you provide directly to us, such as your profile details, vehicle information, and location data to improve our service."),

            _buildSection("2. How We Use Information",
                "We use the collected information to provide, maintain, and improve our services, and to ensure the safety of our users."),

            _buildSection("3. Data Security",
                "We implement industry-standard security measures to protect your personal data from unauthorized access or disclosure."),

            _buildSection("4. Your Choices",
                "You can access and update your personal information through your profile settings at any time."),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            const Text("If you have any questions about this policy, please contact us at support@yourapp.com",
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // Section builder for clean layout
  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
        ],
      ),
    );
  }
}