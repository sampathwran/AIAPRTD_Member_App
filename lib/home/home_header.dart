import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../profile/profile_widget.dart';
import '../parking/parking_icon_widget.dart';
import '../incom/daily_income_widget.dart';

class HomeHeader extends StatelessWidget {
  final User? user;
  const HomeHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profile Section
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: ProfileWidget(user: user),
          ),

          // Daily Income Section (මධ්‍යයේ)
          const DailyIncomeWidget(),

          // Parking Section
          ParkingIconWidget(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Coming Soon!")),
            ),
          ),
        ],
      ),
    );
  }
}