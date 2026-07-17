import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/meter_provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/features/home/widgets/meter/meter_status_card.dart';
import 'package:aiaprtd_member/features/home/widgets/meter/meter_fare_display.dart';
import 'package:aiaprtd_member/features/home/widgets/meter/meter_metrics_row.dart';
import 'package:aiaprtd_member/features/home/widgets/meter/meter_controls.dart';

class RoadPickupPage extends StatefulWidget {
  const RoadPickupPage({super.key});

  @override
  State<RoadPickupPage> createState() => _RoadPickupPageState();
}

class _RoadPickupPageState extends State<RoadPickupPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MeterProvider>(
      builder: (context, meter, child) {
        return PopScope(
          canPop: !meter.isRunning,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("You cannot leave this page while the meter is running."),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              title: const Text("Taxi Meter", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              backgroundColor: Colors.black,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Builder(
              builder: (context) {
                final profile = Provider.of<ProfileProvider>(context, listen: false);
                
                String category = 'budget';
                String membershipNo = 'Unknown';
                if (profile.memberData != null) {
                  if (profile.memberData!['currentVehicle'] != null) {
                    category = profile.memberData!['currentVehicle']['vehicle_category'] 
                        ?? profile.memberData!['currentVehicle']['selectedCategory']
                        ?? profile.memberData!['vehicle_category'] 
                        ?? profile.memberData!['selectedCategory'] 
                        ?? 'budget';
                  }
                  membershipNo = profile.memberData!['membershipNo'] ?? 'Unknown';
                }

                return SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.1),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.hail_rounded,
                                    size: 48,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Road Pickup",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              MeterStatusCard(meter: meter, category: category),
                              const SizedBox(height: 16),
                              MeterFareDisplay(totalFare: meter.totalFare),
                              const SizedBox(height: 16),
                              MeterMetricsRow(
                                distanceKm: meter.totalDistanceKm, 
                                waitTimeSeconds: meter.waitingTimeSeconds, 
                                speedKmh: meter.currentSpeedKmh
                              ),
                              const SizedBox(height: 20),
                              MeterControls(meter: meter, category: category, membershipNo: membershipNo),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}