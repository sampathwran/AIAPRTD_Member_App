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
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.shade200, Colors.amber.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Current Rank",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.amber.shade900)),
                  Text(rank,
                      style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.amber.shade900),
            ],
          ),
        ),
      ),
    );
  }
}