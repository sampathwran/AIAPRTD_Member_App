// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';

class VehicleOverviewSection extends StatelessWidget {
  final Map data;

  const VehicleOverviewSection({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final String imageUrl =
        data['frontImage']?.toString() ?? '';

    final String make =
        data['make']?.toString() ?? 'N/A';

    final String model =
        data['model']?.toString() ?? 'N/A';

    final String plateNumber =
        data['vehicleNumber']?.toString() ?? 'N/A';

    final String category =
        data['selectedCategory']?.toString() ?? 'N/A';

    // 💡 🎯 Firebase එකෙන් එන Make සහ Model එකතු කරලා වාහනයේ සම්පූර්ණ නම හදනවා
    final String vehicleName = (make == 'N/A' && model == 'N/A')
        ? 'N/A'
        : '${make == 'N/A' ? '' : make} ${model == 'N/A' ? '' : model}'.trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imagePlaceholder(),
            )
                : _imagePlaceholder(),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Vehicle Overview",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // ==========================================================
                // 🚗 🎯 FIXED ROW: Brand & Model දෙක එකතු කරපු තනි Full Width කාඩ් එක
                // ==========================================================
                _infoCard(
                  Icons.directions_car,
                  "Vehicle Brand & Model",
                  vehicleName,
                ),

                const SizedBox(height: 12),

                // Plate Number සහ Category පේලිය (බෙදිලා පෙනෙන්න)
                Row(
                  children: [
                    Expanded(
                      child: _infoCard(
                        Icons.pin,
                        "Plate Number",
                        plateNumber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _infoCard(
                        Icons.category,
                        "Category",
                        category,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 220,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.directions_car,
          size: 70,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _infoCard(
      IconData icon,
      String title,
      String value,
      ) {
    return Container(
      width: double.infinity, // මුළු පළලම ගන්න මචං
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.blue,
            size: 22,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? "N/A" : value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}