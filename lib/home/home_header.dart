// ignore_for_file: spell_check_on_languages, spell_check_on_word
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../profile/profile_image_widget.dart';
import '../parking/parking_icon_widget.dart';
import '../income/daily_income_widget.dart';

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
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
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
              padding: const EdgeInsets.only(left: 6, right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
                      color: Colors.grey.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        _isIncomeVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isIncomeVisible = !_isIncomeVisible;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  Expanded(
                    child: Center(
                      child: _isIncomeVisible
                          ? const DailyIncomeWidget()
                          : const Text(
                        "Rs. ••••••",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF10B981) // 💡 ලස්සනම කොළ පාටක්
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
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.15), // 💡 Parking අයිකන් එකට ගැලපෙන ලා නිල් පාට Shadow එකක්
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
                        style: TextStyle(fontWeight: FontWeight.bold)
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: const Color(0xFF3B82F6), // 💡 SnackBar එකත් ලස්සන කළා
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}