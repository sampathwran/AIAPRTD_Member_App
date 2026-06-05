import 'package:flutter/material.dart';

class AchievementBadgeWidget extends StatelessWidget {
  final String rank;
  final VoidCallback onTap;

  const AchievementBadgeWidget({
    super.key,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap, // මෙතන තමයි click event එක යන්නේ
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.shade100),
          ),
          child: Row(
            children: [
              const Icon(Icons.workspace_premium, color: Colors.amber, size: 30),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Current Rank",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(rank,
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.amber),
            ],
          ),
        ),
      ),
    );
  }
}