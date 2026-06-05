import 'package:flutter/material.dart';

// Import Pages (ඔයාගේ ෆෝල්ඩර් ටිකට අනුව මේ path ටික check කරගන්න)
import '../personal/personal_info_page.dart';
import '../personal/vehicle_info_page.dart';
import '../finance/earning_page.dart';
import '../finance/membership_fee_page.dart';
import '../finance/app_usage_page.dart';
import '../finance/saving_page.dart';
import '../general/ride_history_page.dart';
import '../general/member_benefits_page.dart';
import '../general/support_tickets_page.dart';
import '../general/votes_page.dart';
import '../general/ads_page.dart';
import '../general/notification_page.dart';
import '../settings/dark_mode_page.dart';
import '../settings/app_volume_page.dart';
import '../settings/language_page.dart';
import '../settings/help_center_page.dart';
import '../settings/privacy_policy_page.dart';
import '../settings/terms_conditions_page.dart';

class ProfileMenuWidget extends StatelessWidget {
  const ProfileMenuWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSection("Personal Information", [
            _buildTile(Icons.person, "Personal Information", () => _nav(context, const PersonalInfoPage())),
            _buildTile(Icons.directions_car, "Vehicle Information", () => _nav(context, const VehicleInfoPage())),
          ]),
          _buildSection("My Finance", [
            _buildTile(Icons.attach_money, "Earning", () => _nav(context, const EarningPage())),
            _buildTile(Icons.card_membership, "AIAPRTD Membership Fee", () => _nav(context, const MembershipFeePage())),
            _buildTile(Icons.receipt_long, "App Usage Charge", () => _nav(context, const AppUsagePage())),
            _buildTile(Icons.savings, "Saving", () => _nav(context, const SavingPage())),
          ]),
          _buildSection("General", [
            _buildTile(Icons.history, "Ride History", () => _nav(context, const RideHistoryPage())),
            _buildTile(Icons.star, "Member Benefits", () => _nav(context, const MemberBenefitsPage())),
            _buildTile(Icons.support_agent, "Support Tickets", () => _nav(context, const SupportTicketsPage())),
            _buildTile(Icons.how_to_vote, "Votes", () => _nav(context, const VotesPage())),
            _buildTile(Icons.ads_click, "Ads", () => _nav(context, const AdsPage())),
            _buildTile(Icons.notifications, "Notification", () => _nav(context, const NotificationPage())),
          ]),
          _buildSection("App Setting", [
            _buildTile(Icons.dark_mode, "Dark Mode", () => _nav(context, const DarkModePage())),
            _buildTile(Icons.volume_up, "App Volume", () => _nav(context, const AppVolumePage())),
            _buildTile(Icons.language, "Language", () => _nav(context, const LanguagePage())),
            _buildTile(Icons.help_outline, "Help Center", () => _nav(context, const HelpCenterPage())),
            _buildTile(Icons.privacy_tip, "Privacy Policy", () => _nav(context, const PrivacyPolicyPage())),
            _buildTile(Icons.description, "Terms & Conditions", () => _nav(context, const TermsConditionsPage())),
          ]),
        ],
      ),
    );
  }

  // Navigation එකට පොඩි helper එකක්
  void _nav(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 15, bottom: 5, left: 5),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}