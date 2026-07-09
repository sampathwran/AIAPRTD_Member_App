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
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text("Taxi Meter", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<MeterProvider>(
        builder: (context, meter, child) {
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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MeterStatusCard(meter: meter, category: category),
                  const Spacer(),
                  MeterFareDisplay(totalFare: meter.totalFare),
                  const Spacer(),
                  MeterMetricsRow(
                    distanceKm: meter.totalDistanceKm, 
                    waitTimeSeconds: meter.waitingTimeSeconds, 
                    speedKmh: meter.currentSpeedKmh
                  ),
                  const Spacer(),
                  MeterControls(meter: meter, category: category, membershipNo: membershipNo),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}