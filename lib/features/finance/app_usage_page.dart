import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/finance_provider.dart';
import 'package:aiaprtd_member/core/providers/earnings_provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/core/theme/app_theme.dart';
import 'package:aiaprtd_member/features/finance/widgets/outstanding_balance.dart';
import 'package:aiaprtd_member/features/finance/widgets/transaction_history.dart';
import 'package:aiaprtd_member/features/finance/widgets/upload_slip.dart';

class AppUsagePage extends StatefulWidget {
  const AppUsagePage({super.key});

  @override
  State<AppUsagePage> createState() => _AppUsagePageState();
}

class _AppUsagePageState extends State<AppUsagePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = Provider.of<ProfileProvider>(context, listen: false);
      final finance = Provider.of<FinanceProvider>(context, listen: false);
      if (profile.memberNo.isNotEmpty) {
        finance.listenToMyFinance(profile.memberNo);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("App Usage Charge", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, financeProv, child) {
          final earningsProv = Provider.of<EarningsProvider>(context, listen: false);
          double balance = financeProv.myAppUsageChargeBalance;
          if (earningsProv.hasFetched && earningsProv.totalTrips == 0) {
            balance = 0.0;
          }
          
          return Column(
            children: [
              OutstandingBalanceCard(balance: balance),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Transaction History",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ),
              const Expanded(
                child: TransactionHistoryList(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showUploadSlipDialog(context),
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
        label: const Text("Upload Slip", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

