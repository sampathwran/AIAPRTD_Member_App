import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Privacy Policy", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shield_outlined, size: 45, color: primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We Care About Your Privacy',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Last Updated: June 2026',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildIntro(theme),
            
            const SizedBox(height: 24),
            _buildSectionCard(
              context: context,
              icon: Icons.data_usage_rounded,
              title: "1. Information We Collect",
              content: "To provide you with a highly reliable and seamless digital experience, we collect specific information when you use our app:\n\n• Profile & Contact Data: We collect your full name, Membership Number, official designation, email address, and mobile phone number to verify your identity and manage your AIAPRTD membership.\n\n• Authentication & Device Data: To ensure maximum security, we securely store encrypted passwords, unique device identifiers, and push notification tokens. This allows us to enforce single-device login and prevent unauthorized access.\n\n• Location Data (Foreground & Background): This is a core requirement for our app. We collect precise location data even when the app is running in the background. This allows our taxi meter to calculate accurate trip fares, helps you track your trips, find nearby parking spots, and enables our SOS and Community Assistance features to instantly broadcast your location to nearby members during an emergency.\n\n• Audio & Media Data: With your permission, we use your device's microphone for recording and sending voice messages within the Community Assistance module, and your camera/gallery to upload necessary profile pictures and vehicle documents.\n\n• Financial Data: We securely process and record your outstanding balances, payments, and member savings to ensure transparent financial management within the organization.",
            ),

            const SizedBox(height: 24),
            _buildSectionCard(
              context: context,
              icon: Icons.settings_suggest_rounded,
              title: "2. How We Use Your Information",
              content: "Your information is treated with the highest level of confidentiality and is strictly used for the administrative and operational purposes of the organization. The primary uses include:\n\n• Accurately calculating taxi meter fares by continuously tracking background location during active trips.\n• Instantly connecting you with nearby AIAPRTD members during distress or emergency situations via the SOS feature.\n• Verifying your membership status and preventing fraudulent usage by locking your account to a single authorized device.\n• Delivering essential official notices, system updates, and account alerts directly to your mobile phone via SMS or Push Notifications.",
            ),

            const SizedBox(height: 24),
            _buildSectionCard(
              context: context,
              icon: Icons.security_rounded,
              title: "3. Data Security & Storage",
              content: "We implement state-of-the-art security measures to protect your personal information. Your data is securely stored on enterprise-grade Google Firebase cloud servers, which restrict infrastructure access and use advanced encryption. We guarantee that we do not share, sell, or distribute your personal details to any third-party marketing or advertising companies.",
            ),

            const SizedBox(height: 24),
            _buildSectionCard(
              context: context,
              icon: Icons.contact_support_rounded,
              title: "4. Contact & Support",
              content: "We believe in complete transparency. If you have any questions, concerns, or require assistance regarding this Privacy Policy or your profile data, please do not hesitate to contact the administration team.\n\nEmail: info@aiaprtd.lk\nPhone: 0705001002, 0775018681",
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                "By using this application, you acknowledge that you have read, understood, and agreed to our Privacy Policy.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro(ThemeData theme) {
    return Text(
      "Welcome to the AIAPRTD Member App. We are deeply committed to protecting your personal data and respecting your privacy. This comprehensive privacy policy explains exactly how we collect, securely store, and utilize your information to provide our digital membership services.",
      textAlign: TextAlign.justify,
      style: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            textAlign: TextAlign.justify, // Text Justified as requested
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}