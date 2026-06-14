import 'package:flutter/material.dart';

class ParkingIconWidget extends StatelessWidget {
  final VoidCallback onTap;
  const ParkingIconWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.local_parking_rounded,
          size: 24,
          color: Colors.blueAccent,
        ),
      ),
    );
  }
}