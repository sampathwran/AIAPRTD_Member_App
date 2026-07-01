import 'package:flutter/material.dart';

class AcceptanceWidget extends StatelessWidget {
  // 💡 මේ පේළිය අනිවාර්යයි
  final Map<String, dynamic> memberData;

  const AcceptanceWidget({super.key, required this.memberData});

  @override
  Widget build(BuildContext context) {
    final dynamic acceptance = memberData['acceptance'];
    String displayValue = (acceptance != null) ? acceptance.toString() : "0.0";
    if (!displayValue.contains('%')) {
      displayValue = "$displayValue%";
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 15),
            const SizedBox(width: 4),
            Text(displayValue, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          ],
        ),
        const SizedBox(height: 2),
        const Text("Acceptance", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}