import 'package:flutter/material.dart';
import 'package:aiaprtd_member/core/providers/meter_provider.dart';

class MeterStatusCard extends StatelessWidget {
  final MeterProvider meter;
  final String category;

  const MeterStatusCard({super.key, required this.meter, required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "VEHICLE: ${category.toUpperCase()}",
          style: const TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 2),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: meter.isRunning 
              ? (meter.isWaiting ? Colors.orange.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2))
              : Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            meter.isRunning 
              ? (meter.isWaiting ? "WAITING" : "CALCULATING")
              : "STOPPED",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: meter.isRunning 
                ? (meter.isWaiting ? Colors.orange : Colors.greenAccent)
                : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}