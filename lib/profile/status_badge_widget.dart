import 'package:flutter/material.dart';

class StatusBadgeWidget extends StatelessWidget {
  final String status;
  final String? reason; // inactive වීමට හේතුව

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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.shade100 : Colors.red.shade100,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            isActive ? "ACTIVE" : "INACTIVE",
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.green : Colors.red
            ),
          ),
        ),

        // හේතුව (Inactive නම් විතරක් පේන්න)
        if (!isActive && reason != null && reason!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              "Reason: $reason",
              style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }
}