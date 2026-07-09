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
    return Row(
      children: [
        Expanded(child: _buildMetricCard("DIST", "${distanceKm.toStringAsFixed(1)} km", Icons.route)),
        const SizedBox(width: 8),
        Expanded(child: _buildMetricCard("WAIT", "${(waitTimeSeconds / 60).floor()}:${(waitTimeSeconds % 60).toString().padLeft(2, '0')}", Icons.timer)),
        const SizedBox(width: 8),
        Expanded(child: _buildMetricCard("SPEED", "${speedKmh.toStringAsFixed(1)} km/h", Icons.speed)),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey, size: 16),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}