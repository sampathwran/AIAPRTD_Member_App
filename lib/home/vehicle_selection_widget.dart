import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/booking_provider.dart';

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

    return SizedBox(
      height: 140,
      child: ListView.builder(
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

          return GestureDetector(
            onTap: () => vehicleProvider.selectVehicle(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8, left: 4),
              width: 120,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(color: Colors.blue.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 💡 අලුත් විදිහ: Assets ෆෝල්ඩර් එකෙන් පින්තූර ගන්නවා (ID එකට සමානව)
                  Image.asset(
                    'assets/images/${vehicle['id']}.png',
                    height: 40,
                    width: 70, // පින්තූරය ටිකක් ලොකුවට පේන්න 60 වෙනුවට 70 කළා
                    fit: BoxFit.contain,
                    // පින්තූරය හොයාගන්න බැරි වුණොත් විතරක් Icon එක පෙන්නනවා (Safety එකට)
                    errorBuilder: (context, error, stackTrace) => Icon(
                        _getVehicleIcon(vehicle['name']),
                        size: 40,
                        color: isSelected ? Colors.blue : Colors.black54
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? Colors.blue : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "LKR ${estimateFare.round()}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
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