// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  // 💡 🎯 FIXED: දැන් මේක මුළු memberData එකම බාරගන්නවා
  final Map<String, dynamic> memberData;

  const RatingWidget({super.key, required this.memberData});

  @override
  Widget build(BuildContext context) {
    // 💡 🎯 FIXED: ඩේටාබේස් එකෙන් එන 'rating' field එක ගන්නවා
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
            Text(
                displayRating,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDarkMode ? Colors.white : const Color(0xFF0F172A))
            ),
            const SizedBox(width: 2),
            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
          ],
        ),
        const SizedBox(height: 2),
        const Text("Rating", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}