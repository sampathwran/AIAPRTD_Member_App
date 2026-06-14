import 'package:flutter/material.dart';

class TripCountWidget extends StatelessWidget {
  final String trips;
  const TripCountWidget({super.key, required this.trips});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(trips, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const Text("Trips", style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}