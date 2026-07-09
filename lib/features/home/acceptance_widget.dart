import 'package:flutter/material.dart';

class AcceptanceWidget extends StatelessWidget {
  // Required data
  final Map<String, dynamic> memberData;

  const AcceptanceWidget({super.key, required this.memberData});

  @override
  Widget build(BuildContext context) {
    // The user requested to keep Acceptance Rate at 0.0% for now
    // until passenger app logic is finalized.
    String displayValue = "0.0%";

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 15),
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
        Text("Acceptance", style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}