import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/finance_provider.dart';
import 'package:aiaprtd_member/core/providers/earnings_provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/core/theme/app_theme.dart';
import 'package:aiaprtd_member/features/finance/widgets/outstanding_balance.dart';
import 'package:aiaprtd_member/features/finance/widgets/transaction_history.dart';
import 'package:aiaprtd_member/features/finance/widgets/upload_slip.dart';
import 'package:aiaprtd_member/features/finance/widgets/p2p_debts_list.dart';

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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text("App Usage Charge", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppTheme.primaryBlue,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Outstanding"),
              Tab(text: "To Pay"),
              Tab(text: "Receiver"),
            ],
          ),
        ),
        body: Consumer<FinanceProvider>(
          builder: (context, financeProv, child) {
            final earningsProv = Provider.of<EarningsProvider>(context, listen: false);
            double balance = financeProv.myAppUsageChargeBalance;
            if (earningsProv.hasFetched && earningsProv.totalTrips == 0) {
              balance = 0.0;
            }
            
            return TabBarView(
              children: [
                // Tab 1: Outstanding (Union Charge & History)
                Column(
                  children: [
                    OutstandingBalanceCard(balance: balance, limit: financeProv.appUsageLimit),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => Padding(
                              padding: const EdgeInsets.only(top: 60.0),
                              child: SingleChildScrollView(child: UploadSlipForm(balance: balance)),
                            ),
                          ),
                          icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
                          label: const Text("Upload Bank Slip", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ),
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
                ),
                
                // Tab 2: To Pay (P2P Payables - I accepted the hire, I owe 7% to the member who shared)
                const Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        "You Accepted these Hires. Pay 7% commission to the member who shared.",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                    Expanded(child: P2PDebtsList(isPayable: true)),
                  ],
                ),
                
                // Tab 3: Receiver (P2P Receivables - I shared the hire, they owe me 7%)
                const Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        "You Shared these Hires. These members owe you 7% commission.",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                    Expanded(child: P2PDebtsList(isPayable: false)),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
