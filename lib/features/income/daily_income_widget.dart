import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/core/providers/earnings_provider.dart';
import 'package:aiaprtd_member/core/providers/theme_provider.dart';

class DailyIncomeWidget extends StatefulWidget {
  const DailyIncomeWidget({super.key});

  @override
  State<DailyIncomeWidget> createState() => _DailyIncomeWidgetState();
}

class _DailyIncomeWidgetState extends State<DailyIncomeWidget> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = Provider.of<ProfileProvider>(context, listen: false);
      final earnings = Provider.of<EarningsProvider>(context, listen: false);
      final membershipNo = profile.memberData?['membershipNo'] ?? '';

      if (membershipNo.isNotEmpty && !earnings.hasFetched) {
        earnings.fetchEarnings(membershipNo);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildEarningSlide(String title, double amount, IconData icon, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.1) : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: isDark ? color.withValues(alpha: 0.8) : color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Rs. ${amount.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: isDark ? color.withValues(alpha: 0.9) : color.withValues(alpha: 1.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<EarningsProvider>(
      builder: (context, earnings, child) {
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/earnings');
          },
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildEarningSlide("Today", earnings.todayEarnings, Icons.today_rounded, Colors.blue, isDark),
                  _buildEarningSlide("This Week", earnings.thisWeekEarnings, Icons.date_range_rounded, Colors.orange, isDark),
                  _buildEarningSlide("This Month", earnings.thisMonthEarnings, Icons.calendar_month_rounded, Colors.teal, isDark),
                ],
              ),
              // We can add page dots here if needed, but it might clutter the small height.
              // A simple scroll hint could be added, but bouncing scroll physics is usually enough.
            ],
          ),
        );
      },
    );
  }
}