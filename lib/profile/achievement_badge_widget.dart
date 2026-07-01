// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';

class AchievementBadgeWidget extends StatelessWidget {
  final String rank;
  final VoidCallback onTap;

  const AchievementBadgeWidget({
    super.key,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 💡 🎯 Rank එකට අනුව පාට සහ අයිකන් වෙනස් කරන Logic එක
    List<Color> gradientColors;
    IconData rankIcon;
    String rankTitle = "${rank.toUpperCase()} MEMBER";

    switch (rank.toLowerCase()) {
      case 'diamond':
        gradientColors = [const Color(0xFF00FFFF), const Color(0xFF1E90FF)];
        rankIcon = Icons.diamond_rounded;
        break;
      case 'platinum':
        gradientColors = [const Color(0xFFE5E4E2), const Color(0xFFB0C4DE)];
        rankIcon = Icons.diamond_outlined;
        break;
      case 'gold':
        gradientColors = [const Color(0xFFFFD700), const Color(0xFFFFA500)];
        rankIcon = Icons.workspace_premium;
        break;
      case 'silver':
        gradientColors = [const Color(0xFFC0C0C0), const Color(0xFFA9A9A9)];
        rankIcon = Icons.stars_rounded;
        break;
      case 'bronze':
        gradientColors = [const Color(0xFFCD7F32), const Color(0xFFB5732E)];
        rankIcon = Icons.workspace_premium_rounded;
        break;
      default:
        gradientColors = [const Color(0xFF64748B), const Color(0xFF475569)]; // Default Level
        rankIcon = Icons.military_tech_rounded;
        rankTitle = "NEW MEMBER";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16), // Click කරද්දී එන Ripple effect එක
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                // 💡 Rank Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(rankIcon, color: Colors.white, size: 28),
                ),

                const SizedBox(width: 16),

                // 💡 Rank Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rankTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Tap to view benefits & progress",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // 💡 Arrow Icon (ක්ලික් කරන්න පුළුවන් බව පෙන්වන්න)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}