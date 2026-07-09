import 'package:flutter/material.dart';

class ProfileHeaderInfoWidget extends StatelessWidget {
  final String fullName;
  final String membershipNo;

  const ProfileHeaderInfoWidget({
    super.key,
    required this.fullName,
    required this.membershipNo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Darker and more prominent style for the name
        Text(
          fullName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900, // Increased weight
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),

        // 2. Chip-like appearance for ID (with background)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50, // Light blue background
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Text(
            "#$membershipNo",
            style: TextStyle(
              color: Colors.blue.shade800,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}