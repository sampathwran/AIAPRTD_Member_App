// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart'; // 💡 අලුත් ProfileProvider එකට හැරෙව්වා
import 'personal_details_tab.dart';
import 'member_bank_details_tab.dart';
import 'member_registration_tab.dart';

class PersonalInfoPage extends StatelessWidget {
  const PersonalInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text("Personal Information",
              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
          bottom: TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey,
            indicatorColor: Colors.blue,
            indicatorWeight: 3,
            tabs: [
              Tab(text: "Personal Details"),
              Tab(text: "Bank Details"),
            ],
          ),
        ),
        body: Consumer<ProfileProvider>( // 💡 ProfileProvider ලෙස වෙනස් කළා
          builder: (context, profileProvider, child) {
            final data = profileProvider.memberData;

            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }

            // 💡 NEW FIX: මුලින්ම ආපු කෙනෙක්ගේ Web status එක active වුණත්,
            // KYC සහ Face verification Approve වෙලා නැත්නම් එයාව ෆෝම් එකට (MemberRegistrationTab) යවනවා.
            final String kycStatus = data['kycApprovalStatus']?.toString().toLowerCase() ??
                data['kycStatus']?.toString().toLowerCase() ?? 'none';
            final String faceStatus = data['faceKycStatus']?.toString().toLowerCase() ?? 'none';

            // Fully approved ONLY if they have done KYC and Face, and admin approved them.
            final bool isApproved = (kycStatus == 'approved' && faceStatus == 'approved');

            final String membershipNo = data['membershipNo'] ??
                data['membership_number'] ??
                "MB-001";

            return TabBarView(
              children: [
                isApproved
                    ? const PersonalDetailsTab() // 🔴 Approve වුණාම මේක පෙන්නනවා (Edit බෑ)
                    : const MemberRegistrationTab(), // 🔴 මුලින්ම ෆෝම් එක පෙන්නනවා. Submit කලාම මේකෙම "Pending" කියලා වැටෙනවා.

                // Bank Details Tab (membershipNo pass කරනවා)
                BankDetailsTab(membershipNo: membershipNo),
              ],
            );
          },
        ),
      ),
    );
  }
}