import 'package:flutter/material.dart';
import 'package:aiaprtd_member/core/providers/meter_provider.dart';
import 'package:aiaprtd_member/features/home/trip_summary_page.dart';

class MeterControls extends StatelessWidget {
  final MeterProvider meter;
  final String category;
  final String membershipNo;

  const MeterControls({super.key, required this.meter, required this.category, required this.membershipNo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!meter.isRunning && meter.totalFare == 0)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => meter.startMeter(category),
              child: const Text("START TRIP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          )
        else if (meter.isRunning)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                await meter.stopMeter(membershipNo, category);
              },
              child: const Text("STOP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          
        if (!meter.isRunning && meter.totalFare > 0 && meter.isTripCompleted) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const TripSummaryPage()),
                );
              },
              child: const Text("VIEW SUMMARY", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey.shade900,
                  title: const Text("Reset Meter?", style: TextStyle(color: Colors.white)),
                  content: const Text("Are you sure you want to reset the meter? All current trip data will be lost.", style: TextStyle(color: Colors.grey)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel", style: TextStyle(color: Colors.blue)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        meter.resetMeter();
                      },
                      child: const Text("Yes, Reset", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            child: const Text("Reset Meter", style: TextStyle(color: Colors.grey, fontSize: 16)),
          )
        ]
      ],
    );
  }
}