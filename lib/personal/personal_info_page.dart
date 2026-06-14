import 'package:flutter/material.dart';
// මෙතන අනිවාර්යයෙන් ඔයාගේ අලුත් ෆයිල්ස් දෙක හරියට Import කරන්න
import 'personal_details_tab.dart';
import 'bank_details_tab.dart';

class PersonalInfoPage extends StatelessWidget {
  const PersonalInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text("Personal Information", style: TextStyle(fontWeight: FontWeight.bold)),
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
        body: const TabBarView(
          children: [
            PersonalDetailsTab(), // මෙතනට වෙනම ෆයිල් එකේ තියෙන class එක
            BankDetailsTab(),     // මෙතනට වෙනම ෆයිල් එකේ තියෙන class එක
          ],
        ),
      ),
    );
  }
}