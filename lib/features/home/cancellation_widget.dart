import 'package:flutter/material.dart';

class CancellationWidget extends StatelessWidget {
  // Required data
  final Map<String, dynamic> memberData;

  const CancellationWidget({super.key, required this.memberData});

  @override
  Widget build(BuildContext context) {
    final int totalAccepted = memberData['totalAcceptedCount'] ?? 0;
    final int totalCancelled = memberData['totalCancelledCount'] ?? 0;
    
    double percent = 0.0;
    if (totalAccepted > 0) {
      percent = (totalCancelled / totalAccepted) * 100;
    }
    String displayValue = "${percent.toStringAsFixed(1)}%";

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel_schedule_send_rounded, color: Colors.redAccent, size: 15),
            const SizedBox(width: 4),
            Text(
              displayValue, 
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text("Cancellation", style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}