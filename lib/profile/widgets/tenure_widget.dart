import 'package:flutter/material.dart';

class TenureWidget extends StatelessWidget {
  final String years;
  const TenureWidget({super.key, required this.years});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(years, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const Text("Tenure", style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}