import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E3A8A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📝 Header Section
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1), // 💡 New Flutter Standard
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      size: 45,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'User Agreement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Last updated: May 2026',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 📑 Section 1
            _buildSectionTitle('1. Acceptance of Terms'),
            _buildParagraph(
              'By activating and using the AIAPRTD Member App, you agree to comply with and be bound by the following terms and conditions. If you do not agree with any part of these terms, you should not access or use this application.',
            ),

            // 📑 Section 2
            _buildSectionTitle('2. Account Activation & Security'),
            _buildParagraph(
              'Members are responsible for maintaining the confidentiality of their digital accounts. Please note the following rules:',
            ),
            _buildBulletPoint('Only registered AIAPRTD members are permitted to activate an account.'),
            _buildBulletPoint('You are fully responsible for all activities that occur under your password.'),
            _buildBulletPoint('Any unauthorized use of your membership profile must be reported immediately.'),

            // 📑 Section 3: Prohibited Activities Card
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.redAccent, width: 0.8),
              ),
              color: Colors.red.withValues(alpha: 0.02), // 💡 New Flutter Standard
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.gavel_outlined, color: Colors.redAccent, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prohibited Conduct',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Users are strictly prohibited from attempting to bypass app security, reverse-engineering the system, modifying data unauthorizedly, or sharing personal digital membership barcodes/credentials with non-members.',
                            style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4), // 💡 Changed from Colors.black72 to black54
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // 📑 Section 4
            _buildSectionTitle('3. Limitation of Liability'),
            _buildParagraph(
              'The organization reserves the right to modify, suspend, or terminate the digital app features at any time without prior notice. We strive to maintain continuous uptime but are not liable for temporary data access disruptions due to cloud maintenance.',
            ),

            // 📑 Section 5
            _buildSectionTitle('4. Profile Termination'),
            _buildParagraph(
              'Violation of these official app usage terms or any organizational bylaws may result in immediate suspension or total deletion of your digital app access, alongside standard disciplinary actions.',
            ),

            // 📑 Section 6
            _buildSectionTitle('5. Updates to Terms'),
            _buildParagraph(
              'We may update our Terms & Conditions from time to time. Continued use of the application after such modifications implies your automatic consent to the revised terms.',
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E3A8A),
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0, right: 10.0),
            child: Icon(Icons.circle, size: 6, color: Color(0xFF1E3A8A)),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}