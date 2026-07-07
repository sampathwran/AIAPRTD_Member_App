// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 💡 FIXED: අලුත් නම (PaymentHistoryTab) සහ StatefulWidget විදියට මාරු කළා
class PaymentHistoryTab extends StatefulWidget {
  final Map<String, dynamic> memberData;
  const PaymentHistoryTab({super.key, required this.memberData});

  @override
  State<PaymentHistoryTab> createState() => _PaymentHistoryTabState();
}

class _PaymentHistoryTabState extends State<PaymentHistoryTab> {
  // =========================================================================
  // 💡 LOGIC & CALCULATION METHODS
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

    // If an explicit year field exists, use it
    if (record['year'] != null && record['year'].toString().isNotEmpty) {
      int? explicitYear = int.tryParse(record['year'].toString());
      if (explicitYear != null) {
        return DateTime(explicitYear, paidMonth);
      }
    }

    // Fallback: Infer year from the payment date

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

    // If payment was made early in the year (Jan-Mar) for late last year (Oct-Dec)
    if (paymentDate.month <= 3 && paidMonth >= 10) {
      year -= 1;
    }
    // If payment was made late in the year (Oct-Dec) for early next year (Jan-Mar)
    else if (paymentDate.month >= 10 && paidMonth <= 3) {
      year += 1;
    }

    return DateTime(year, paidMonth);
  }

  DateTime? _getLastPaidPeriod(List<dynamic> history) {
    if (history.isEmpty) return null;

    DateTime? latestPeriod;

    for (var rec in history) {
      if (rec is Map<String, dynamic>) {
        DateTime period = _getPaidPeriod(rec);
        if (latestPeriod == null || period.isAfter(latestPeriod)) {
          latestPeriod = period;
        }
      } else if (rec is Map) {
        Map<String, dynamic> castedRec = Map<String, dynamic>.from(rec);
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
    // 💡 FIXED: widget.memberData විදියට Data ගන්න ඕනේ
    final List<dynamic> paymentHistory = widget.memberData['payment_history'] ?? [];
    final List<dynamic> pendingPayments = widget.memberData['pending_payments'] ?? [];

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========================================================
          // 🌟 PAYMENT BEHAVIOR CARD
          // ========================================================
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
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
                    const Text("Payment Behavior", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey, fontSize: 13, letterSpacing: 1.0)),
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
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ========================================================
          // 📊 DASHBOARD SECTION
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
          // ⏳ PENDING PAYMENTS SECTION
          // ========================================================
          if (pendingPayments.isNotEmpty) ...[
            _buildSectionTitle("Pending Approvals"),
            const SizedBox(height: 12),
            ...pendingPayments.map((pending) {
              Map<String, dynamic> pendingMap = pending is Map<String, dynamic> 
                  ? pending 
                  : Map<String, dynamic>.from(pending as Map);
              DateTime pendingPeriod = _getPaidPeriod(pendingMap);
              String pendingMonth = pendingMap['month']?.toString() ?? 'Unknown';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200, width: 1.5),
                ),
                child: ListTile(
                  leading: const Icon(Icons.hourglass_top, color: Colors.orange),
                  title: Text("$pendingMonth ${pendingPeriod.year} Verification", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text("Awaiting admin approval...", style: TextStyle(color: Colors.orange, fontSize: 13)),
                  trailing: const Text("Pending", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],

          // ========================================================
          // 📋 PAYMENT HISTORY TABLE
          // ========================================================
          _buildSectionTitle("Payment History"),
          const SizedBox(height: 12),

          if (paymentHistory.isEmpty)
            _buildEmptyState()
          else
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
                    dataRowMaxHeight: 65,
                    columnSpacing: 28,
                    columns: const [
                      DataColumn(label: Text("Period", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey))),
                      DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey))),
                      DataColumn(label: Text("Amount", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey))),
                      DataColumn(label: Text("Method", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey))),
                    ],
                    rows: paymentHistory.reversed.map((record) {
                      Map<String, dynamic> recordMap = record is Map<String, dynamic> 
                          ? record 
                          : Map<String, dynamic>.from(record as Map);
                      
                      // 💡 ALUTH: මාසයයි අවුරුද්දයි දෙකම හරියටම ගන්නවා (Fallback logic එකත් එක්කම)
                      DateTime paidPeriod = _getPaidPeriod(recordMap);
                      String periodText = "${recordMap['month']?.toString() ?? '-'} ${paidPeriod.year}";

                      return DataRow(
                        cells: [
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                  periodText,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)
                              ),
                            ),
                          ),
                          DataCell(Text(recordMap['date']?.toString() ?? '-', style: const TextStyle(color: Colors.black87))),
                          DataCell(Text("Rs. ${recordMap['amount']?.toString() ?? '0'}", style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(recordMap['type']?.toString() ?? '-', style: const TextStyle(color: Colors.grey))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // =========================================================================
  // 💡 HELPER WIDGETS
  // =========================================================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.blueGrey, letterSpacing: 1.2),
    );
  }

  Widget _buildGradientCard({required String title, required String value, required IconData icon, required List<Color> colors}) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No Payment History", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 8),
          const Text("Your payment records will appear here once approved.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}