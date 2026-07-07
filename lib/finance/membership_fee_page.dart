// ignore_for_file: spell_check_on_languages

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
import 'bank_details_tab.dart';
import 'payment_history_tab.dart';
import 'upload_slip_tab.dart';

class MembershipFeePage extends StatelessWidget {
  const MembershipFeePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileProvider profileProvider =
    Provider.of<ProfileProvider>(context, listen: false);


    final String membershipNo = profileProvider.memberNo.trim();

    return DefaultTabController(
    length: 3,
    child: Scaffold(
    backgroundColor: const Color(0xFFF5F7FB),
    appBar: AppBar(
    title: const Text(
    'Membership Fee',
    style: TextStyle(
    fontWeight: FontWeight.w800,
    letterSpacing: 0.4,
    ),
    ),
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
    ),
    body: membershipNo.isEmpty
    ? const Center(
    child: Text(
    'Membership number not found.',
    style: TextStyle(
    color: Colors.red,
    fontWeight: FontWeight.w600,
    ),
    ),
    )
        : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection('web_sync_membership_fee')
        .doc(membershipNo)
        .snapshots(),
    builder: (context, snapshot) {
    if (snapshot.connectionState ==
    ConnectionState.waiting &&
    !snapshot.hasData) {
    return const Center(
    child: CircularProgressIndicator(
    color: Colors.blue,
    ),
    );
    }

    if (snapshot.hasError) {
    return Center(
    child: Padding(
    padding: const EdgeInsets.all(24),
    child: Text(
    'Unable to load payment details.\n${snapshot.error}',
    textAlign: TextAlign.center,
    style: const TextStyle(
    color: Colors.red,
    fontWeight: FontWeight.w600,
    ),
    ),
    ),
    );
    }

    final Map<String, dynamic> paymentData =
    snapshot.data?.data() ?? <String, dynamic>{};

    return Column(
    children: [
    _buildTabBar(),
    Expanded(
    child: TabBarView(
    physics: const BouncingScrollPhysics(),
    children: [
    PaymentHistoryTab(
    memberData: paymentData,
    ),
    BankDetailsTab(
    membershipNo: membershipNo,
    ),
    const UploadSlipTab(),
    ],
    ),
    ),
    ],
    );
    },
    ),
    ),
    );


  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: const Color(0xFF1565C0),
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        tabs: const [
          Tab(
            icon: Icon(
              Icons.history_rounded,
              size: 19,
            ),
            text: 'History',
          ),
          Tab(
            icon: Icon(
              Icons.account_balance_rounded,
              size: 19,
            ),
            text: 'Bank',
          ),
          Tab(
            icon: Icon(
              Icons.upload_file_rounded,
              size: 19,
            ),
            text: 'Upload',
          ),
        ],
      ),
    );
  }
}
