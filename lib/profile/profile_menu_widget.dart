// ignore_for_file: spell_check_on_languages, spell_check_on_word
import 'package:flutter/material.dart';

// 💡 අලුතින් හදපු AuthService එක මෙතනට Import කරගන්න මචං
import '/auth_service.dart';

import '../personal_info/personal_info_page.dart';
import '../vehicle_info/vehicle_info_page.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../earnings/earnings_page.dart';
import '../membership_fee/membership_fee_page.dart';
import '../finance/app_usage_page.dart';
import '../finance/saving_page.dart';
// 💡 අලුතින් හදපු My Booking Page එක Import කළා
import 'my_booking_page.dart';
import '../general/member_benefits_page.dart';
import '../general/support_tickets_page.dart';
import '../general/votes_page.dart';
import '../ads/ads_page.dart';
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
      child: Column(
        children: [
          _buildSection(context, "Personal Information", [
            _buildTile(context, Icons.person_outline, "Personal Information", () => _nav(context, const PersonalInfoPage())),
            _buildTile(context, Icons.directions_car_outlined, "Vehicle Information", () {
              final String memberNo = Provider.of<ProfileProvider>(context, listen: false).memberNo;
              _nav(context, VehicleInfoPage(membershipNo: memberNo == 'N/A' ? Provider.of<ProfileProvider>(context, listen: false).documentId : memberNo));
            }),
          ]),
          _buildSection(context, "My Finance", [
            _buildTile(context, Icons.account_balance_wallet_outlined, "Earning", () => _nav(context, const EarningsPage())),
            _buildTile(context, Icons.card_membership_outlined, "Membership Fee", () => _nav(context, const MembershipFeePage())),
            _buildTile(context, Icons.receipt_long_outlined, "App Usage Charge", () => _nav(context, const AppUsagePage())),
            _buildTile(context, Icons.savings_outlined, "Saving", () => _nav(context, const SavingPage())),
          ]),
          _buildSection(context, "General", [
            // 💡 අලුතින් දාපු My Bookings Menu එක (Ride History එකට උඩින්)
            _buildTile(context, Icons.library_books_outlined, "My Bookings", () => _nav(context, const MyBookingPage())),
            _buildTile(context, Icons.star_outline, "Member Benefits", () => _nav(context, const MemberBenefitsPage())),
            _buildTile(context, Icons.support_agent, "Support Tickets", () => _nav(context, const SupportTicketsPage())),
            _buildTile(context, Icons.how_to_vote, "Votes", () => _nav(context, const VotesPage())),
            _buildTile(context, Icons.ads_click, "Ads", () => _nav(context, const AdsPage())),
            _buildTile(context, Icons.notifications_none, "Notification", () => _nav(context, const NotificationPage())),
          ]),
          _buildSettingsSection(context),

          // ACCOUNT Section
          _buildAccountSection(context),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to log out? All active sessions will be closed.'),
          actions: <Widget>[
            TextButton(
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                onPressed: () => Navigator.of(dialogContext).pop()
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                AuthService.logout(context);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 25, bottom: 12, left: 10),
          child: Text("ACCOUNT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: isDarkMode ? Colors.grey[400] : Colors.blueGrey, letterSpacing: 1.5)),
        ),
        Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDarkMode ? Colors.red.withValues(alpha: 0.3) : Colors.red.shade100),
          ),
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () => _showLogoutDialog(context),
          ),
        ),
      ],
    );
  }

  void _nav(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 25, bottom: 12, left: 10),
          child: Text(title.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: isDarkMode ? Colors.grey[400] : Colors.blueGrey.shade400, letterSpacing: 1.5)),
        ),
        Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey.shade100),
            boxShadow: [BoxShadow(color: isDarkMode ? Colors.black.withValues(alpha: 0.3) : Colors.blue.shade100.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue.shade300, Colors.blue.shade500]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : Colors.black87)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 25, bottom: 12, left: 10),
          child: Text("APP SETTINGS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: isDarkMode ? Colors.grey[400] : Colors.blueGrey, letterSpacing: 1.5)),
        ),
        Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey.shade100),
            boxShadow: [BoxShadow(color: isDarkMode ? Colors.black.withValues(alpha: 0.3) : Colors.blue.shade100.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: isDarkMode ? Colors.grey[700] : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.settings_outlined, color: isDarkMode ? Colors.white : Colors.black87),
            ),
            title: const Text("App Configuration", style: TextStyle(fontWeight: FontWeight.w600)),
            children: [
              _buildTile(context, Icons.dark_mode_outlined, "Dark Mode", () => _nav(context, const DarkModePage())),
              _buildTile(context, Icons.volume_up_outlined, "App Volume", () => _nav(context, const AppVolumePage())),
              _buildTile(context, Icons.language, "Language", () => _nav(context, const LanguagePage())),
              _buildTile(context, Icons.help_outline, "Help Center", () => _nav(context, const HelpCenterPage())),
              _buildTile(context, Icons.privacy_tip_outlined, "Privacy Policy", () => _nav(context, const PrivacyPolicyPage())),
              _buildTile(context, Icons.description_outlined, "Terms & Conditions", () => _nav(context, const TermsConditionsPage())),
            ],
          ),
        ),
      ],
    );
  }
}