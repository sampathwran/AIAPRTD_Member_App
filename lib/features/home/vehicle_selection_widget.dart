import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/vehicle_provider.dart';
import 'package:aiaprtd_member/core/providers/booking_provider.dart';

class VehicleSelectionWidget extends StatefulWidget {
  const VehicleSelectionWidget({super.key});

  @override
  State<VehicleSelectionWidget> createState() => _VehicleSelectionWidgetState();
}

class _VehicleSelectionWidgetState extends State<VehicleSelectionWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VehicleProvider>(context, listen: false).fetchVehiclesFromFirebase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = Provider.of<VehicleProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);

    if (vehicleProvider.isCategoriesLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (vehicleProvider.vehicles.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text("No vehicles available.")),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 160,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: vehicleProvider.vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = vehicleProvider.vehicles[index];
          final bool isSelected = vehicleProvider.selectedVehicleIndex == index;

          final double estimateFare = vehicleProvider.calculateEstimateFare(
              bookingProvider.totalDistanceKm,
              index
          );

          String rawName = vehicle['name'].toString();
          String displayName = rawName.split('(').first.trim().replaceAll(' Van', '');
          
          int seatingCapacity = 3;
          String lowerName = displayName.toLowerCase();
          if (lowerName.contains('budget')) seatingCapacity = 3;
          else if (lowerName.contains('mini van')) seatingCapacity = 6;
          else if (lowerName.contains('mini')) seatingCapacity = 4;
          else if (lowerName.contains('sedan')) seatingCapacity = 4;
          else if (lowerName.contains('6 seater')) seatingCapacity = 6;
          else if (lowerName.contains('9 seater')) seatingCapacity = 9;
          else if (lowerName.contains('14 seater')) seatingCapacity = 14;
          else seatingCapacity = vehicle['seating_capacity'] ?? 3;

          return GestureDetector(
            onTap: () => vehicleProvider.selectVehicle(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              width: 130,
              decoration: BoxDecoration(
                color: isSelected ? (isDark ? theme.colorScheme.primary.withValues(alpha: 0.2) : Colors.grey.shade100) : theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Load images from Assets folder by ID
                    Image.asset(
                      'assets/images/${vehicle['id']}.png',
                      height: 40,
                      width: 80, 
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                          _getVehicleIcon(vehicle['name']),
                          size: 44,
                          color: Colors.black87
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 2),
                        Text(
                          "$seatingCapacity",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "LKR ${estimateFare.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getVehicleIcon(String name) {
    String lowerName = name.toLowerCase();
    if (lowerName.contains('tuk') || lowerName.contains('budget')) return Icons.electric_rickshaw;
    if (lowerName.contains('car') || lowerName.contains('sedan')) return Icons.directions_car;
    if (lowerName.contains('van') || lowerName.contains('seater')) return Icons.airport_shuttle;
    if (lowerName.contains('mini')) return Icons.local_taxi;
    return Icons.directions_car;
  }
}