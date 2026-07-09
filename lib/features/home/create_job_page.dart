import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/features/home/booking_form_widget.dart';
import 'package:aiaprtd_member/core/providers/booking_provider.dart';

class CreateJobPage extends StatefulWidget {
  const CreateJobPage({super.key});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  GoogleMapController? _mapController;
  LatLng? _lastMapPosition;

  Widget _buildConfirmLocationPanel(BookingProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(provider.isChoosingPickup ? "Set Pickup Location" : "Set Drop Location", 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              provider.hoveredAddress,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                LatLng? finalPosition = _lastMapPosition;
                if (finalPosition == null && _mapController != null) {
                  LatLngBounds bounds = await _mapController!.getVisibleRegion();
                  finalPosition = LatLng(
                    (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
                    (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
                  );
                }
                if (finalPosition != null) {
                  if (provider.isChoosingPickup) {
                    provider.setPickupLocation(finalPosition, provider.hoveredAddress);
                  } else {
                    provider.setDropLocation(provider.currentDropIndex, finalPosition, provider.hoveredAddress);
                  }
                  provider.addRecentLocation(provider.hoveredAddress, finalPosition, provider.hoveredAddress.split(',').first);
                  provider.disableChooseOnMap();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Confirm Location", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }


  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(6.9271, 79.8612), // Colombo
    zoom: 14.5,
  );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).resetBookingData();
      _goToCurrentLocation();
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    Provider.of<BookingProvider>(context, listen: false).setMapController(controller);
  }

  Future<void> _goToCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;

    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable Location (GPS) on your phone.")),
      );
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (!mounted) return;

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;

      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please grant Location Permission.")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission is permanently denied. Please enable it in Settings.")),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    if (!mounted) return;

    LatLng currentLatLng = LatLng(position.latitude, position.longitude);

    final provider = Provider.of<BookingProvider>(context, listen: false);

    provider.isProgrammaticMove = true;

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: currentLatLng, zoom: 16),
      ),
    );

    await provider.getAddressFromLatLng(currentLatLng, isPickup: true);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    Provider.of<BookingProvider>(context, listen: false).resetBookingData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);

    // Get full screen height
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: _onMapCreated,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: provider.markers,
            polylines: provider.polylines,



            onTap: (LatLng location) async {
              if (provider.isChoosingOnMap) return; // Disable tap-to-set when choosing on map
              provider.isProgrammaticMove = true;
              _mapController?.animateCamera(CameraUpdate.newLatLng(location));
              await provider.getAddressFromLatLng(location, isPickup: true, animateCamera: false);
            },
            onCameraMove: (CameraPosition position) {
              if (provider.isChoosingOnMap) {
                _lastMapPosition = position.target;
              }
            },
            onCameraIdle: () async {
              if (provider.isChoosingOnMap) {
                LatLng? finalPosition = _lastMapPosition;
                if (finalPosition == null && _mapController != null) {
                  LatLngBounds bounds = await _mapController!.getVisibleRegion();
                  finalPosition = LatLng(
                    (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
                    (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
                  );
                }
                if (finalPosition != null) {
                  await provider.updateHoveredAddress(finalPosition);
                }
              }
            },
          ),

          Positioned(
            top: 50,
            left: 16,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: Theme.of(context).colorScheme.surface,
              child: SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).iconTheme.color ?? Colors.black, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 340,
            right: 16,
            child: AnimatedOpacity(
              opacity: provider.isChoosingOnMap ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Material(
                elevation: 4,
                shape: const CircleBorder(),
                color: Theme.of(context).colorScheme.surface,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    icon: Icon(Icons.my_location_rounded, color: Theme.of(context).primaryColor, size: 22),
                    onPressed: provider.isChoosingOnMap ? null : _goToCurrentLocation,
                  ),
                ),
              ),
            ),
          ),

          if (!provider.isChoosingOnMap)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: screenHeight * 0.8),
                child: const BookingFormWidget(),
              ),
            ),

          if (provider.isChoosingOnMap)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: _buildConfirmLocationPanel(provider),
            ),

          if (provider.isChoosingOnMap)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40), // Offset so pin tip points to center
                child: Icon(Icons.location_on, size: 50, color: Theme.of(context).iconTheme.color ?? Colors.black87),
              ),
            ),
        ],
      ),
      // If user wants to back out of "Choose on map", we can catch WillPop, but they can just confirm for now.
    );
  }
}