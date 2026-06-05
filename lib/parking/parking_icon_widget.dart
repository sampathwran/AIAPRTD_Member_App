import 'package:flutter/material.dart';

class ParkingIconWidget extends StatelessWidget {
  final VoidCallback onTap;
  const ParkingIconWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Icon(Icons.local_parking, size: 30, color: Colors.blueAccent),
    );
  }
}