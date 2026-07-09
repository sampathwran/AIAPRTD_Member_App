// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart'; // 💡 Changed to new ProfileProvider
import 'package:aiaprtd_member/features/personal_info/personal_details_tab.dart';
import 'package:aiaprtd_member/features/personal_info/member_bank_details_tab.dart';
import 'package:aiaprtd_member/features/personal_info/member_registration_tab.dart';

class PersonalInfoPage extends StatelessWidget {
  const PersonalInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("Personal Information"),
          bottom: TabBar(
            labelColor: colorScheme.primary,
            unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey,
            indicatorColor: colorScheme.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: "Personal Details"),
              Tab(text: "Bank Details"),
            ],
          ),
        ),
        body: Consumer<ProfileProvider>( // 💡 Changed to ProfileProvider
          builder: (context, profileProvider, child) {
            final data = profileProvider.memberData;

            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }

            // 💡 NEW FIX: Even if a new user's Web status is active,
            // if KYC and Face verification are not approved, send them to the form (MemberRegistrationTab).
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
                    ? const PersonalDetailsTab() // 🔴 Show this when approved (Cannot edit)
                    : const MemberRegistrationTab(), // 🔴 Show form initially. Once submitted, it will show as "Pending".

                // Bank Details Tab (passing membershipNo)
                BankDetailsTab(membershipNo: membershipNo),
              ],
            );
          },
        ),
      ),
    );
  }
}