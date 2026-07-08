// ignore_for_file: spell_check_on_languages, spell_check_on_word
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../profile/profile_image_widget.dart';
import '../parking/parking_icon_widget.dart';
import '../income/daily_income_widget.dart';
import '../providers/theme_provider.dart';

class HomeHeader extends StatefulWidget {
  final User? user;
  const HomeHeader({super.key, required this.user});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  bool _isIncomeVisible = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    
    // Premium Colors: Changed light mode from pure white to a sleek, slightly dark/glassy blue-grey
    final bgColor = isDark ? const Color(0xff1B2735) : const Color(0xFFF0F3F8); // Very light greyish-blue instead of pure white
    final shadowColor = isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08);
    final borderColor = isDark ? Colors.white12 : Colors.blueGrey.withValues(alpha: 0.1);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          // ==========================================================
          // 👤 1. PROFILE SECTION (Premium Pop-out Look)
          // ==========================================================
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
            child: Container(
              padding: const EdgeInsets.all(2.5), // 💡 ෆොටෝ එක වටේට ලස්සන සුදු රේඛාවක්
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const ProfileImageWidget(
                radius: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ==========================================================
          // 💰 2. DAILY INCOME SECTION (Premium Pill Shape)
          // ==========================================================
          Expanded(
            child: Container(
              height: 54,
              padding: const EdgeInsets.only(left: 6, right: 6), // 💡 Padding වෙනස් කළා swipe කරන්න ලේසි වෙන්න
              decoration: BoxDecoration(
                color: bgColor,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 💡 අයිකන් එකට වෙනම පොඩි රවුමක් (Premium feel)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? Colors.white12 : Colors.white),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        _isIncomeVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        color: isDark ? Colors.grey.shade400 : Colors.blueGrey.shade600,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isIncomeVisible = !_isIncomeVisible;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 4),

                  Expanded(
                    child: _isIncomeVisible
                        ? const DailyIncomeWidget()
                        : Center(
                            child: Text(
                              "Rs. ••••••",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF10B981) // 💡 ලස්සනම කොළ පාටක්
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ==========================================================
          // 🅿️ 3. PARKING SECTION (Premium Glossy Button)
          // ==========================================================
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: borderColor),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.blue.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.15), 
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: ParkingIconWidget(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                        "Parking Feature Coming Soon! 🅿️",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: const Color(0xFF3B82F6), // 💡 SnackBar එකත් ලස්සන කළා
                  ),
                ),
              ),
            ),
          ),
          // ==========================================================
          // 🔔 4. NOTIFICATION BELL SECTION (REMOVED: Moved to bubble)
          // ==========================================================
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}