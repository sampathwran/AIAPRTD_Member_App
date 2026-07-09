// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';

class TenureWidget extends StatelessWidget {
  final Map<String, dynamic> memberData; // FIXED: Accepts a Map

  const TenureWidget({super.key, required this.memberData});

  @override
  Widget build(BuildContext context) {
    // 1. Get Join Date
    final String joinDateStr = memberData['joinDate']?.toString() ?? DateTime.now().toString().split(' ')[0];

    // 2. Calculate Tenure
    String tenure = _calculateTenure(joinDateStr);

    return Column(
      children: [
        Text(tenure, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), // Reduced font size slightly to prevent overflow
        const Text("Tenure", style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  // Calculation Logic
  String _calculateTenure(String joinDateStr) {
    try {
      DateTime joinDate = DateTime.parse(joinDateStr);
      DateTime now = DateTime.now();

      int years = now.year - joinDate.year;
      int months = now.month - joinDate.month;

      if (months < 0) {
        years--;
        months += 12;
      }

      String result = "";
      if (years > 0) result += "$years yr ";
      result += "$months mon";

      return result;
    } catch (e) {
      return "0 yr 0 mon";
    }
  }
}