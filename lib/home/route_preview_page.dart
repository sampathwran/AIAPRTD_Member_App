import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart'; // ඔයාගේ path එක දෙන්න
import 'vehicle_selection_widget.dart';
import 'booking_summary_widget.dart';

class RoutePreviewPage extends StatefulWidget {
  const RoutePreviewPage({super.key});

  @override
  State<RoutePreviewPage> createState() => _RoutePreviewPageState();
}

class _RoutePreviewPageState extends State<RoutePreviewPage> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // 💡 1. Google Map Section (Top)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55, // 💡 Map එකට Screen එකෙන් 55% ක් දෙනවා
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: provider.currentPickupLatLng ?? const LatLng(6.9271, 79.8612),
                zoom: 14.5,
              ),
              markers: provider.markers,
              polylines: provider.polylines, // 💡 අර හැදෙන පාර (Route) එක
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                // Map loaded
              },
            ),
          ),

          // 💡 Back Button (Map එක උඩින් පේන්න)
          Positioned(
            top: 50,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 22,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 💡 2. Bottom Sheet Section (Vehicle Selection & Booking)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.50, // 💡 යටින් 50% ක් මේකට දෙනවා
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 💡 Handle Bar (Top Dash)
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),

                  // 💡 Vehicle Categories List (Horizontal)
                  const VehicleSelectionWidget(),

                  const Divider(),

                  // 💡 Booking Summary (Date/Time, Payment, Confirm Button)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: BookingSummaryWidget(),
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