import 'package:flutter/material.dart';

class StatusBadgeWidget extends StatelessWidget {
  final String status;
  final String? reason;

  const StatusBadgeWidget({
    super.key,
    required this.status,
    this.reason,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive = status.toLowerCase() == 'active';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Badge එක
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            // වඩා තද වර්ණ සහ Shadow එකක් භාවිතයෙන් කැපී පෙනෙන පෙනුමක්
            color: isActive ? Colors.green.shade100 : Colors.red.shade100,
            borderRadius: BorderRadius.circular(20), // වඩා රවුම් හැඩයක්
            border: Border.all(
              color: isActive ? Colors.green.shade400 : Colors.red.shade400,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? Icons.verified_rounded : Icons.cancel_rounded,
                size: 14,
                color: isActive ? Colors.green.shade800 : Colors.red.shade800,
              ),
              const SizedBox(width: 6),
              Text(
                isActive ? "ACTIVE MEMBER" : "INACTIVE MEMBER",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isActive ? Colors.green.shade900 : Colors.red.shade900,
                ),
              ),
            ],
          ),
        ),

        // හේතුව (Inactive නම් විතරක් පේන්න - වඩා හොඳ Text Style එකක්)
        if (!isActive && reason != null && reason!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "Reason: $reason",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}