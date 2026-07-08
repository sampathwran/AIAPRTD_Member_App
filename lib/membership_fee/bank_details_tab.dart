// ignore_for_file: spell_check_on_languages

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BankDetailsTab extends StatelessWidget {
  final String membershipNo;
  final bool isDark;

  const BankDetailsTab({
    super.key,
    required this.membershipNo,
    required this.isDark,
  });

  void _copyAllDetails(BuildContext context) {
    const String bankDetails =
        'Account Name: National Union of Seafarers Sri Lanka\n'
        'Account Number: 1117010822\n'
        'Bank: Commercial Bank\n'
        'Branch: Narahenpita';

    Clipboard.setData(const ClipboardData(text: bankDetails));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Bank details copied to clipboard!', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
    final dividerColor = isDark ? Colors.white12 : Colors.grey.shade100;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.account_balance, color: isDark ? Colors.blue.shade300 : Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "Transfer Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow("Account Name", "National Union of Seafarers Sri Lanka", labelColor, textColor, dividerColor),
                _buildDetailRow("Account Number", "1117010822", labelColor, textColor, dividerColor, isImportant: true),
                _buildDetailRow("Bank", "Commercial Bank", labelColor, textColor, dividerColor),
                _buildDetailRow("Branch", "Narahenpita", labelColor, textColor, Colors.transparent), // No divider for last
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.blue.shade700 : Colors.blue.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.copy_all_rounded),
              label: const Text(
                "Copy Details",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _copyAllDetails(context),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Use the exact details above to make your membership fee transfer.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color labelColor, Color textColor, Color dividerColor, {bool isImportant = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: isImportant ? 20 : 16,
            fontWeight: isImportant ? FontWeight.w900 : FontWeight.w600,
            color: textColor,
            letterSpacing: isImportant ? 1.5 : 0,
          ),
        ),
        if (dividerColor != Colors.transparent)
          Divider(height: 32, color: dividerColor, thickness: 1),
      ],
    );
  }
}
