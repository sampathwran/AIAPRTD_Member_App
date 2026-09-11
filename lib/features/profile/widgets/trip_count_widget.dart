// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class TripCountWidget extends StatelessWidget {
  final Map<String, dynamic> memberData; // FIXED: Accepts a Map

  const TripCountWidget({super.key, required this.memberData});

  @override
  Widget build(BuildContext context) {
    // Ensure 'tripCount' matches your database field name
    final String trips = memberData['tripCount']?.toString() ?? "0";

    return Column(
      children: [
        Text(trips,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text('profile.trips'.tr(), style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
