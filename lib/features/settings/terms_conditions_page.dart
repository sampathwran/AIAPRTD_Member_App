import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Terms & Conditions", style: TextStyle(fontWeight: FontWeight.bold)),
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
                    child: Icon(Icons.description_outlined, size: 45, color: primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'User Agreement',
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
              icon: Icons.gavel_rounded,
              title: "1. Acceptance of Terms",
              content: "By activating and using the AIAPRTD Member App, you agree to comply with and be bound by these comprehensive terms and conditions, as well as the organizational bylaws of AIAPRTD. If you do not agree with any part of these terms, you should immediately cease using this application.",
            ),

            const SizedBox(height: 24),
            _buildSectionCard(
              context: context,
              icon: Icons.account_circle_rounded,
              title: "2. Account & Security",
              content: "As a registered member, you are solely responsible for maintaining the confidentiality of your digital account.\n\n• You are fully responsible for all activities and financial transactions that occur under your account.\n• Unauthorized sharing of credentials, membership barcodes, or attempting multi-device abuse is strictly prohibited.\n• You must use your officially registered email and phone number for all communications.",
            ),

            const SizedBox(height: 24),
            _buildSectionCard(
              context: context,
              icon: Icons.location_on_rounded,
              title: "3. App Permissions & Usage",
              content: "To function correctly, the app requires specific device permissions. By using the app, you grant permission to access:\n\n• Location (Background & Foreground): Essential for taxi meter fare calculations, trip tracking, and SOS features.\n• Microphone & Camera: Necessary for community assistance voice notes, SOS audio, and document uploads.\n• Storage: To manage local data securely.\n\nDenying these critical permissions will severely limit the functionality of the app, including the inability to calculate taxi fares.",
            ),

            const SizedBox(height: 24),
            _buildSectionCard(
              context: context,
              icon: Icons.cancel_presentation_rounded,
              title: "4. Misconduct & Suspension",
              content: "We enforce strict disciplinary actions for misuse of the platform. The following actions are strictly prohibited and will result in immediate account suspension and organizational disciplinary action:\n\n• Evading commissions by failing to collect cash properly for trips.\n• Bypassing app security, reverse-engineering, or tampering with financial/trip data.\n• Misusing the SOS or Community Assistance features for non-emergencies.",
            ),

            const SizedBox(height: 24),
            _buildSectionCard(
              context: context,
              icon: Icons.contact_support_rounded,
              title: "5. Updates & Contact",
              content: "AIAPRTD reserves the right to modify these terms periodically. Continued use implies consent to any revisions. For inquiries, you may contact us via:\n\nEmail: info@aiaprtd.lk\nPhone: 0705001002, 0775018681",
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                "By using this application, you acknowledge that you have read, understood, and agreed to our Terms & Conditions.",
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
      "Welcome to the AIAPRTD Member App. This User Agreement sets forth the legally binding terms and conditions governing your access to and use of our digital platform.",
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
    
    // Check if it is a red flag card
    final isWarning = title.contains("Misconduct");
    final iconColor = isWarning ? Colors.redAccent : Colors.blueAccent;
    final titleColor = isWarning ? Colors.redAccent : theme.colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : (isWarning ? Colors.red.withValues(alpha: 0.02) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isWarning ? Colors.redAccent.withValues(alpha: 0.3) : theme.dividerColor.withValues(alpha: 0.1),
          width: isWarning ? 1.2 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
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