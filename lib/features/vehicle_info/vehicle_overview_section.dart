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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String imageUrl =
        data['frontImage']?.toString() ?? '';

    final String make =
        data['make']?.toString() ?? 'N/A';

    final String model =
        data['model']?.toString() ?? 'N/A';

    final String plateNumber =
        data['vehicleNumber']?.toString() ?? 'N/A';

    final String category =
        (data['vehicle_category'] ?? data['selectedCategory'])?.toString() ?? 'N/A';

    // 💡 🎯 Create the full vehicle name by combining Make and Model from Firebase
    final String vehicleName = (make == 'N/A' && model == 'N/A')
        ? 'N/A'
        : '${make == 'N/A' ? '' : make} ${model == 'N/A' ? '' : model}'.trim();

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
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
              errorBuilder: (_, __, ___) => _imagePlaceholder(isDark),
            )
                : _imagePlaceholder(isDark),
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
                // 🚗 🎯 FIXED ROW: Single Full Width card combining Brand & Model
                // ==========================================================
                _infoCard(
                  context,
                  Icons.directions_car,
                  "Vehicle Brand & Model",
                  vehicleName,
                  isDark,
                ),

                const SizedBox(height: 12),

                // Plate Number and Category row (split view)
                Row(
                  children: [
                    Expanded(
                      child: _infoCard(
                        context,
                        Icons.pin,
                        "Plate Number",
                        plateNumber,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _infoCard(
                        context,
                        Icons.category,
                        "Category",
                        category,
                        isDark,
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

  Widget _imagePlaceholder(bool isDark) {
    return Container(
      height: 220,
      width: double.infinity,
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.directions_car,
          size: 70,
          color: isDark ? Colors.grey.shade600 : Colors.grey,
        ),
      ),
    );
  }

  Widget _infoCard(
      BuildContext context,
      IconData icon,
      String title,
      String value,
      bool isDark,
      ) {
    return Container(
      width: double.infinity, // Take full width
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.blueGrey.shade800 : Colors.grey.shade200,
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
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
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