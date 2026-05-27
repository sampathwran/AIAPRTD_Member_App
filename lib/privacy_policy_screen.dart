import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E3A8A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // ලස්සන Off-White බැක්ග්‍රවුන්ඩ් එකක්
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
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
            // ඉහළ තියෙන Header Icon සහ විස්තරය
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 45,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'We Care About Your Privacy',
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

            // 📄 Section 1: Introduction
            _buildSectionTitle('1. Introduction'),
            _buildParagraph(
              'Welcome to the AIAPRTD Member App. We are committed to protecting your personal data and respecting your privacy. This privacy policy explains how we collect, store, and use your information when you use our digital membership services.',
            ),

            // 📄 Section 2: Data Collection
            _buildSectionTitle('2. Information We Collect'),
            _buildParagraph(
              'To provide you with a seamless digital membership experience, we collect the following information:',
            ),
            _buildBulletPoint('Profile Data: Membership Number, full name, and official designation.'),
            _buildBulletPoint('Contact Data: Registered email address and mobile number.'),
            _buildBulletPoint('Authentication Data: Secure encrypted passwords managed by Firebase Auth.'),

            // 📄 Section 3: How We Use Data
            _buildSectionTitle('3. How We Use Your Information'),
            _buildParagraph(
              'Your information is used strictly for administrative and operational purposes within the organization, including:',
            ),
            _buildBulletPoint('Verifying your digital membership profile safely.'),
            _buildBulletPoint('Allowing secure access to member-only areas in the app.'),
            _buildBulletPoint('Sending critical official notices and account updates.'),

            // 📄 Section 4: Data Security Card (වැදගත් විස්තරයක් නිසා Card එකක් ඇතුලට දැම්මා)
            const SizedBox(height: 15),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.black12, width: 1),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_person_outlined, color: Colors.green, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Data Security',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your data is safely stored in Google Firebase cloud servers with restricted infrastructure access. We never share or sell your personal details to any third-party marketing companies.',
                            style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 📄 Section 5: Contact
            _buildSectionTitle('4. Contact Support'),
            _buildParagraph(
              'If you have any questions or faced issues regarding your profile data, please reach out to the organization administration team or email us at support@aiaprtd.org.',
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Section Title හදන Widget එක
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

  // සාමාන්‍ය ඡේද (Paragraphs) හදන Widget එක
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

  // Bullet Points හදන Widget එක
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