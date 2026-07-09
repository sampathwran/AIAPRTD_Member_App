import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/booking_provider.dart'; // Import provider
import 'package:aiaprtd_member/features/home/vehicle_selection_widget.dart';
import 'package:aiaprtd_member/features/home/booking_summary_widget.dart';

class RoutePreviewPage extends StatefulWidget {
  const RoutePreviewPage({super.key});

  @override
  State<RoutePreviewPage> createState() => _RoutePreviewPageState();
}

class _RoutePreviewPageState extends State<RoutePreviewPage> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Map Section (Top)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55, // Allocate 55% of screen to Map
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: provider.currentPickupLatLng ?? const LatLng(6.9271, 79.8612),
                zoom: 14.5,
              ),
              markers: provider.markers,
              polylines: provider.polylines, // Generated Route
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                // Map loaded
              },
            ),
          ),

          // Back Button (Overlaid on Map)
          Positioned(
            top: 50,
            left: 16,
            child: CircleAvatar(
              backgroundColor: theme.colorScheme.surface,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: theme.iconTheme.color ?? Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 2. Bottom Sheet Section (Vehicle Selection & Booking)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.50, // Allocate bottom 50%
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle Bar (Top Dash)
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),

                  // Vehicle Categories List (Horizontal)
                  const VehicleSelectionWidget(),

                  const Divider(),

                  // Booking Summary (Date/Time, Payment, Confirm Button)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      child: const BookingSummaryWidget(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}