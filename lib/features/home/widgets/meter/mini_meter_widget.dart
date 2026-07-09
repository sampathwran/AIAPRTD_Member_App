import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/meter_provider.dart';
import 'package:aiaprtd_member/features/home/road_pickup_page.dart';

class MiniMeterWidget extends StatelessWidget {
  const MiniMeterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MeterProvider>(
      builder: (context, meter, child) {
        if (!meter.isRunning && meter.totalFare == 0) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RoadPickupPage()),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
              ]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(meter.isRunning ? Icons.directions_car : Icons.receipt, color: Colors.blueAccent),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          meter.isRunning ? (meter.isWaiting ? "Waiting..." : "Meter Running") : "Trip Finished",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${meter.totalDistanceKm.toStringAsFixed(2)} km | ${(meter.waitingTimeSeconds / 60).floor()}m wait",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  "LKR ${meter.totalFare.toStringAsFixed(0)}",
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}