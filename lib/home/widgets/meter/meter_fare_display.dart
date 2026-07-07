import 'package:flutter/material.dart';

class MeterFareDisplay extends StatelessWidget {
  final double totalFare;

  const MeterFareDisplay({super.key, required this.totalFare});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "TOTAL FARE",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16, letterSpacing: 2),
        ),
        const SizedBox(height: 8),
        Text(
          "LKR ${totalFare.toStringAsFixed(2)}",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
