import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  // 💡 මේ පේළිය අනිවාර්යයි
  final Map<String, dynamic> memberData;

  const RatingWidget({super.key, required this.memberData});

  @override
  Widget build(BuildContext context) {
    final dynamic rating = memberData['rating'];
    final String displayRating = (rating != null) ? rating.toString() : "0.0";
    
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(displayRating, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : const Color(0xFF1E293B))),
          ],
        ),
        const SizedBox(height: 2),
        const Text("Rating", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}