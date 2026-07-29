import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aiaprtd_member/core/theme/app_theme.dart';
import 'package:aiaprtd_member/features/finance/widgets/commission_rates.dart';

class OutstandingBalanceCard extends StatelessWidget {
  final double balance;
  final double limit;
  final double pendingAmount;

  const OutstandingBalanceCard({super.key, required this.balance, required this.limit, this.pendingAmount = 0.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Outstanding Balance",
                style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                      ),
                      padding: const EdgeInsets.only(top: 15, bottom: 30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                          const SizedBox(height: 10),
                          const CommissionRatesCard(),
                        ],
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.info_outline, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                "- LKR ",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                NumberFormat('#,##0.00').format((balance - pendingAmount).clamp(0.0, double.infinity)),
                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (pendingAmount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: Colors.orangeAccent, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    "Pending Approval: LKR ${NumberFormat('#,##0.00').format(pendingAmount)}",
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final double effectiveBalance = (balance - pendingAmount).clamp(0.0, double.infinity);
    final double percentage = limit > 0 ? (effectiveBalance / limit).clamp(0.0, 1.0) : 0.0;
    
    Color progressColor = Colors.greenAccent;
    if (percentage > 0.8) {
      progressColor = Colors.redAccent;
    } else if (percentage > 0.5) {
      progressColor = Colors.orangeAccent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Credit Limit", style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text("LKR ${NumberFormat('#,##0').format(limit)}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 8,
          ),
        ),
        if (percentage >= 1.0)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              "⚠️ Limit exceeded. Please settle dues.",
              style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}
