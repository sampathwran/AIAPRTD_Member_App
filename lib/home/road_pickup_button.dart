import 'package:flutter/material.dart';

class RoadPickupButton extends StatelessWidget {
  final VoidCallback onTap;
  const RoadPickupButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE3F2FD),
          child: Icon(Icons.directions_car, color: Color(0xFF1E3A8A)),
        ),
        title: const Text("Road Pickup", style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}