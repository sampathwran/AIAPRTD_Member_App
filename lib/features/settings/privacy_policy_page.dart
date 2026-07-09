import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Privacy Policy", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Last Updated: June 2026", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            _buildSection(context, "1. Information We Collect",
                "We collect information you provide directly to us, such as your profile details, vehicle information, and location data to improve our service."),

            _buildSection(context, "2. How We Use Information",
                "We use the collected information to provide, maintain, and improve our services, and to ensure the safety of our users."),

            _buildSection(context, "3. Data Security",
                "We implement industry-standard security measures to protect your personal data from unauthorized access or disclosure."),

            _buildSection(context, "4. Your Choices",
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
  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface, height: 1.5)),
        ],
      ),
    );
  }
}