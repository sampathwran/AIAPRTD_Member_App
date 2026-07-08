// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentHistoryTab extends StatefulWidget {
  final Map<String, dynamic> memberData;
  final bool isDark;
  
  const PaymentHistoryTab({super.key, required this.memberData, required this.isDark});

  @override
  State<PaymentHistoryTab> createState() => _PaymentHistoryTabState();
}

class _PaymentHistoryTabState extends State<PaymentHistoryTab> {
  // =========================================================================
  // LOGIC & CALCULATION METHODS
  // =========================================================================

  int _getMonthNumber(String monthName) {
    const months = {
      "January": 1, "February": 2, "March": 3, "April": 4,
      "May": 5, "June": 6, "July": 7, "August": 8,
      "September": 9, "October": 10, "November": 11, "December": 12
    };
    return months[monthName.trim()] ?? 0;
  }

  DateTime _getPaidPeriod(Map<String, dynamic> record) {
    int paidMonth = _getMonthNumber(record['month']?.toString() ?? "");
    if (paidMonth == 0) return DateTime(2000, 1);

    if (record['year'] != null && record['year'].toString().isNotEmpty) {
      int? explicitYear = int.tryParse(record['year'].toString());
      if (explicitYear != null) {
        return DateTime(explicitYear, paidMonth);
      }
    }

    String dateStr = record['date']?.toString() ?? "";
    DateTime paymentDate = DateTime.now();
    if (dateStr.isNotEmpty) {
      try {
        paymentDate = DateTime.parse(dateStr);
      } catch (e) {
        // ignore
      }
    }

    int year = paymentDate.year;
    if (paymentDate.month <= 3 && paidMonth >= 10) year -= 1;
    else if (paymentDate.month >= 10 && paidMonth <= 3) year += 1;

    return DateTime(year, paidMonth);
  }

  DateTime? _getLastPaidPeriod(List<dynamic> history) {
    if (history.isEmpty) return null;
    DateTime? latestPeriod;

    for (var rec in history) {
      if (rec is Map<String, dynamic> || rec is Map) {
        Map<String, dynamic> castedRec = Map<String, dynamic>.from(rec as Map);
        DateTime period = _getPaidPeriod(castedRec);
        if (latestPeriod == null || period.isAfter(latestPeriod)) {
          latestPeriod = period;
        }
      }
    }
    return latestPeriod;
  }

  int _calculateArrears(DateTime? lastPaidPeriod) {
    if (lastPaidPeriod == null) return 0;
    DateTime now = DateTime.now();
    int currentYear = now.year;
    int currentMonth = now.month;

    if (now.day <= 5) {
      currentMonth -= 1;
      if (currentMonth == 0) {
        currentMonth = 12;
        currentYear -= 1;
      }
    }

    int arrears = ((currentYear - lastPaidPeriod.year) * 12) + (currentMonth - lastPaidPeriod.month);
    return arrears > 0 ? arrears : 0;
  }

  String _getNextPaymentDate(DateTime? lastPaidPeriod) {
    if (lastPaidPeriod == null) return "N/A";
    int nextDueMonth = lastPaidPeriod.month + 1;
    int nextDueYear = lastPaidPeriod.year;

    if (nextDueMonth > 12) {
      nextDueMonth = 1;
      nextDueYear += 1;
    }
    DateTime nextDate = DateTime(nextDueYear, nextDueMonth, 5);
    return DateFormat('MMM 05, yyyy').format(nextDate);
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> paymentHistory = widget.memberData['payment_history'] ?? [];
    final List<dynamic> pendingPayments = widget.memberData['pending_payments'] ?? [];
    final isDark = widget.isDark;

    DateTime? lastPaidPeriod = _getLastPaidPeriod(paymentHistory);
    int arrearsMonths = _calculateArrears(lastPaidPeriod);
    String nextPaymentDate = _getNextPaymentDate(lastPaidPeriod);

    String healthStatus;
    String healthEmoji;
    Color healthColor;
    double healthPercent;

    if (paymentHistory.isEmpty) {
      healthStatus = "No Data";
      healthEmoji = "🤔";
      healthColor = Colors.grey;
      healthPercent = 0.0;
    } else if (arrearsMonths == 0) {
      healthStatus = "Excellent Payer";
      healthEmoji = "🤩";
      healthColor = Colors.green;
      healthPercent = 1.0;
    } else if (arrearsMonths == 1) {
      healthStatus = "Slightly Late";
      healthEmoji = "😐";
      healthColor = Colors.orange;
      healthPercent = 0.6;
    } else {
      healthStatus = "Needs Attention";
      healthEmoji = "😟";
      healthColor = Colors.red;
      healthPercent = 0.2;
    }

    final sectionTitleColor = isDark ? Colors.blueGrey.shade300 : Colors.blueGrey;
    final cardBgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final cardBorderColor = isDark ? Colors.white12 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========================================================
          // PAYMENT BEHAVIOR CARD
          // ========================================================
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cardBorderColor),
              boxShadow: [
                BoxShadow(color: healthColor.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Payment Behavior", style: TextStyle(fontWeight: FontWeight.w900, color: sectionTitleColor, fontSize: 13, letterSpacing: 1.0)),
                    Text(healthEmoji, style: const TextStyle(fontSize: 24)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                    healthStatus,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: healthColor)
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: healthPercent,
                    minHeight: 8,
                    backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ========================================================
          // DASHBOARD SECTION
          // ========================================================
          Row(
            children: [
              Expanded(
                child: _buildGradientCard(
                  title: arrearsMonths > 0 ? "Overdue Date" : "Next Payment",
                  value: nextPaymentDate,
                  icon: Icons.calendar_month,
                  colors: arrearsMonths > 0
                      ? [Colors.orange.shade400, Colors.orange.shade700]
                      : [Colors.blue.shade400, Colors.blue.shade700],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGradientCard(
                  title: "Arrears (හිඟ)",
                  value: arrearsMonths > 0 ? "$arrearsMonths Months" : "No Arrears",
                  icon: arrearsMonths > 0 ? Icons.warning_amber_rounded : Icons.check_circle,
                  colors: arrearsMonths > 0
                      ? [Colors.red.shade400, Colors.red.shade700]
                      : [Colors.green.shade400, Colors.green.shade700],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ========================================================
          // PENDING PAYMENTS SECTION
          // ========================================================
          if (pendingPayments.isNotEmpty) ...[
            _buildSectionTitle("Pending Approvals", sectionTitleColor),
            const SizedBox(height: 12),
            ...pendingPayments.map((pending) {
              Map<String, dynamic> pendingMap = Map<String, dynamic>.from(pending as Map);
              
              String pendingMonthText = "";
              String yearText = "";

              if (pendingMap.containsKey('months')) {
                List<dynamic> mList = pendingMap['months'] is List ? pendingMap['months'] : [];
                pendingMonthText = mList.join(', ');
                if (pendingMap.containsKey('paymentDate') && pendingMap['paymentDate'] != null) {
                  try {
                     DateTime pd = DateTime.parse(pendingMap['paymentDate'].toString());
                     yearText = pd.year.toString();
                  } catch (e) {
                     yearText = DateTime.now().year.toString();
                  }
                } else {
                  yearText = DateTime.now().year.toString();
                }
              } else {
                DateTime pendingPeriod = _getPaidPeriod(pendingMap);
                pendingMonthText = pendingMap['month']?.toString() ?? 'Unknown';
                yearText = pendingPeriod.year.toString();
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.orange.withValues(alpha: 0.1) : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200, width: 1.5),
                ),
                child: ListTile(
                  leading: const Icon(Icons.hourglass_top, color: Colors.orange),
                  title: Text("$pendingMonthText $yearText Verification", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                  subtitle: const Text("Awaiting admin approval...", style: TextStyle(color: Colors.orange, fontSize: 13)),
                  trailing: const Text("Pending", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],

          // ========================================================
          // PAYMENT HISTORY LIST
          // ========================================================
          _buildSectionTitle("Payment History", sectionTitleColor),
          const SizedBox(height: 12),

          if (paymentHistory.isEmpty)
            _buildEmptyState(isDark)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: paymentHistory.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                // Reverse the list
                var record = paymentHistory[paymentHistory.length - 1 - index];
                Map<String, dynamic> recordMap = Map<String, dynamic>.from(record as Map);
                DateTime paidPeriod = _getPaidPeriod(recordMap);
                String periodText = "${recordMap['month']?.toString() ?? '-'} ${paidPeriod.year}";

                return Container(
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorderColor),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.receipt_long, color: isDark ? Colors.blue.shade300 : Colors.blue),
                    ),
                    title: Text(
                      periodText,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: isDark ? Colors.grey.shade400 : Colors.grey),
                          const SizedBox(width: 4),
                          Text((recordMap['paymentDate']?.toString() ?? recordMap['date']?.toString() ?? '-').split('T').first.split(' ').first, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Rs. ${recordMap['amount']?.toString() ?? '0'}",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.green.shade400 : Colors.green.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recordMap['type']?.toString() ?? '-',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // =========================================================================
  // HELPER WIDGETS
  // =========================================================================

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: color, letterSpacing: 1.2),
    );
  }

  Widget _buildGradientCard({required String title, required String value, required IconData icon, required List<Color> colors}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: colors.last.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long, size: 60, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No Payment History", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 8),
          Text("Your payment records will appear here once approved.", textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
