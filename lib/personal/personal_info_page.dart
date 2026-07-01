// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart'; // 💡 අලුත් ProfileProvider එකට හැරෙව්වා
import 'personal_details_tab.dart';
import '../finance/member_bank_details_tab.dart';
import 'member_registration_tab.dart';

class PersonalInfoPage extends StatelessWidget {
  const PersonalInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text("Personal Information",
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
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

            final String status = data['status'] ?? 'inactive';
            final bool isApproved = (status.toLowerCase() == 'active');

            final String membershipNo = data['membershipNo'] ??
                data['membership_number'] ??
                "MB-001";

            return TabBarView(
              children: [
                isApproved
                    ? const PersonalDetailsTab()
                    : const MemberRegistrationTab(),

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