import 'package:flutter/material.dart';

class EarningSummaryCard extends StatelessWidget {
  final double totalEarnings;
  final double bookingsEarnings;
  final double roadPickupEarnings;
  final bool isDark;

  const EarningSummaryCard({
    super.key,
    required this.totalEarnings,
    required this.bookingsEarnings,
    required this.roadPickupEarnings,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final cardColor = Colors.white.withValues(alpha: 0.15);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Earnings",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "LKR ${totalEarnings.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSubEarnings(
                  icon: Icons.smartphone_rounded,
                  title: "Bookings",
                  amount: bookingsEarnings,
                  cardColor: cardColor,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildSubEarnings(
                  icon: Icons.hail_rounded,
                  title: "Pickups",
                  amount: roadPickupEarnings,
                  cardColor: cardColor,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSubEarnings({
    required IconData icon,
    required String title,
    required double amount,
    required Color cardColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "LKR ${amount.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}