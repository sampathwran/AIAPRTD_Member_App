import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/finance_provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/core/providers/payment_provider.dart';
import 'package:aiaprtd_member/features/finance/widgets/total_saving.dart';
import 'package:aiaprtd_member/features/finance/widgets/saving_history.dart';
import 'package:aiaprtd_member/features/finance/widgets/pay_fee.dart';
import 'package:aiaprtd_member/features/finance/widgets/withdraw.dart';

class SavingPage extends StatefulWidget {
  const SavingPage({super.key});

  @override
  State<SavingPage> createState() => _SavingPageState();
}

class _SavingPageState extends State<SavingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = Provider.of<ProfileProvider>(context, listen: false);
      final finance = Provider.of<FinanceProvider>(context, listen: false);
      final payment = Provider.of<PaymentProvider>(context, listen: false);
      
      if (profile.memberNo.isNotEmpty) {
        finance.listenToMyFinance(profile.memberNo);
        payment.fetchBankDetails(profile.memberNo);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("My Savings", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.teal.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, financeProv, child) {
          final balance = financeProv.mySavingsBalance;
          
          return Column(
            children: [
              TotalSavingCard(balance: balance),
              
              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.payments_rounded,
                        label: "Pay Fee",
                        color: Colors.blue.shade600,
                        onTap: () => handlePayMembershipFee(context, balance),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.account_balance_wallet_rounded,
                        label: "Withdraw",
                        color: Colors.orange.shade600,
                        onTap: () => handleWithdraw(context, balance),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Savings History",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ),
              const Expanded(
                child: SavingHistoryList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
