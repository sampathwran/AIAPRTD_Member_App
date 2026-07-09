import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Terms & Conditions", style: TextStyle(fontWeight: FontWeight.bold)),
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

            _buildSection(context, Icons.gavel, "1. Acceptance of Terms",
                "By accessing or using our services, you agree to be bound by these terms. If you disagree with any part of the terms, you may not access the service."),

            _buildSection(context, Icons.account_circle, "2. User Accounts",
                "You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account."),

            _buildSection(context, Icons.payments, "3. Payments & Refunds",
                "All transactions are final unless specified otherwise. We reserve the right to change our fees at any time."),

            _buildSection(context, Icons.block, "4. Prohibited Conduct",
                "Users are prohibited from using the service for any unlawful purpose, or in any way that could damage, disable, or impair our services."),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            const Text("By using this application, you acknowledge that you have read and understood these terms.",
                style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, IconData icon, String title, String content) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(content, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}