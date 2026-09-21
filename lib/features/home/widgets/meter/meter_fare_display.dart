import 'package:flutter/material.dart';

class MeterFareDisplay extends StatelessWidget {
  final double totalFare;
  final bool isFlatRate;
  final double? driverFare;
  final double? passengerFare;
  final double? commission;

  const MeterFareDisplay({
    super.key,
    required this.totalFare,
    this.isFlatRate = false,
    this.driverFare,
    this.passengerFare,
    this.commission,
  });

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
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "LKR ${totalFare.toStringAsFixed(2)}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
