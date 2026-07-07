import 'package:flutter/material.dart';

class MeterMetricsRow extends StatelessWidget {
  final double distanceKm;
  final int waitTimeSeconds;
  final double speedKmh;

  const MeterMetricsRow({
    super.key, 
    required this.distanceKm, 
    required this.waitTimeSeconds, 
    required this.speedKmh
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricCard("DISTANCE", "${distanceKm.toStringAsFixed(2)} km", Icons.route)),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricCard("WAITING", "${(waitTimeSeconds / 60).floor()}:${(waitTimeSeconds % 60).toString().padLeft(2, '0')}", Icons.timer)),
          ],
        ),
        const SizedBox(height: 16),
        _buildMetricCard("CURRENT SPEED", "${speedKmh.toStringAsFixed(1)} km/h", Icons.speed),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey, size: 24),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
