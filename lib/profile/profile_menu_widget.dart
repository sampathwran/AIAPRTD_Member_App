// ignore_for_file: spell_check_on_languages, spell_check_on_word
import 'package:flutter/material.dart';

// 💡 අලුතින් හදපු AuthService එක මෙතනට Import කරගන්න මචං
import '/auth_service.dart';

import '../personal/personal_info_page.dart';
import '../personal/vehicle_info_page.dart';
import '../finance/earning_page.dart';
import '../finance/membership_fee_page.dart';
import '../finance/app_usage_page.dart';
import '../finance/saving_page.dart';
// 💡 අලුතින් හදපු My Booking Page එක Import කළා
import 'my_booking_page.dart';
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
      child: Column(
        children: [
          _buildSection("Personal Information", [
            _buildTile(Icons.person_outline, "Personal Information", () => _nav(context, const PersonalInfoPage())),
            _buildTile(Icons.directions_car_outlined, "Vehicle Information", () => _nav(context, const VehicleInfoPage(membershipNo: "AIAPRTD-25-0001"))),
          ]),
          _buildSection("My Finance", [
            _buildTile(Icons.account_balance_wallet_outlined, "Earning", () => _nav(context, const EarningPage())),
            _buildTile(Icons.card_membership_outlined, "Membership Fee", () => _nav(context, const MembershipFeePage())),
            _buildTile(Icons.receipt_long_outlined, "App Usage Charge", () => _nav(context, const AppUsagePage())),
            _buildTile(Icons.savings_outlined, "Saving", () => _nav(context, const SavingPage())),
          ]),
          _buildSection("General", [
            // 💡 අලුතින් දාපු My Bookings Menu එක (Ride History එකට උඩින්)
            _buildTile(Icons.library_books_outlined, "My Bookings", () => _nav(context, const MyBookingPage())),
            _buildTile(Icons.history, "Ride History", () => _nav(context, const RideHistoryPage())),
            _buildTile(Icons.star_outline, "Member Benefits", () => _nav(context, const MemberBenefitsPage())),
            _buildTile(Icons.support_agent, "Support Tickets", () => _nav(context, const SupportTicketsPage())),
            _buildTile(Icons.how_to_vote, "Votes", () => _nav(context, const VotesPage())),
            _buildTile(Icons.ads_click, "Ads", () => _nav(context, const AdsPage())),
            _buildTile(Icons.notifications_none, "Notification", () => _nav(context, const NotificationPage())),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 25, bottom: 12, left: 10),
          child: Text("ACCOUNT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.blueGrey, letterSpacing: 1.5)),
        ),
        Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.shade100),
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

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 25, bottom: 12, left: 10),
          child: Text(title.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.blueGrey.shade400, letterSpacing: 1.5)),
        ),
        Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.blue.shade100.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile(IconData icon, String title, VoidCallback onTap) {
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
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 25, bottom: 12, left: 10),
          child: Text("APP SETTINGS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.blueGrey, letterSpacing: 1.5)),
        ),
        Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.blue.shade100.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.settings_outlined, color: Colors.black87),
            ),
            title: const Text("App Configuration", style: TextStyle(fontWeight: FontWeight.w600)),
            children: [
              _buildTile(Icons.dark_mode_outlined, "Dark Mode", () => _nav(context, const DarkModePage())),
              _buildTile(Icons.volume_up_outlined, "App Volume", () => _nav(context, const AppVolumePage())),
              _buildTile(Icons.language, "Language", () => _nav(context, const LanguagePage())),
              _buildTile(Icons.help_outline, "Help Center", () => _nav(context, const HelpCenterPage())),
              _buildTile(Icons.privacy_tip_outlined, "Privacy Policy", () => _nav(context, const PrivacyPolicyPage())),
              _buildTile(Icons.description_outlined, "Terms & Conditions", () => _nav(context, const TermsConditionsPage())),
            ],
          ),
        ),
      ],
    );
  }
}