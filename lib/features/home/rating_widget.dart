import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  // Required data
  final Map<String, dynamic> memberData;

  const RatingWidget({super.key, required this.memberData});

  @override
  Widget build(BuildContext context) {
    final dynamic rating = memberData['rating'];
    String displayRating = "0.0";
    if (rating != null) {
      try {
        displayRating = double.parse(rating.toString()).toStringAsFixed(1);
      } catch (e) {
        displayRating = "0.0";
      }
    }
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(
              displayRating, 
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text("Rating", style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}