import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'booking_form_widget.dart';
import '../providers/booking_provider.dart';

class CreateJobPage extends StatefulWidget {
  const CreateJobPage({super.key});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  GoogleMapController? _mapController;

  bool _isDraggingMap = false;
  LatLng? _currentMapCenter;

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
        const SnackBar(content: Text("කරුණාකර Phone එකේ Location (GPS) On කරන්න.")),
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
          const SnackBar(content: Text("Location ගන්න Permission දෙන්න.")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location Permission සම්පූර්ණයෙන්ම Deny කරලා තියෙන්නේ. Settings වලින් On කරන්න.")),
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

    // ෆෝන් එකේ සම්පූර්ණ උස ගන්නවා
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

            onCameraMoveStarted: () {
              setState(() => _isDraggingMap = true);
            },

            onCameraMove: (CameraPosition position) {
              _currentMapCenter = position.target;
            },

            onCameraIdle: () async {
              setState(() => _isDraggingMap = false);

              if (provider.isProgrammaticMove) {
                provider.isProgrammaticMove = false;
              } else {
                if (_currentMapCenter != null) {
                  await provider.getAddressFromLatLng(
                    _currentMapCenter!,
                    isPickup: true,
                    animateCamera: false,
                  );
                }
              }
            },

            onTap: (LatLng location) async {
              provider.isProgrammaticMove = true;
              _mapController?.animateCamera(CameraUpdate.newLatLng(location));
              await provider.getAddressFromLatLng(location, isPickup: true, animateCamera: false);
            },
          ),

          Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: _isDraggingMap ? 40.0 : 25.0),
              child: Icon(
                Icons.location_on,
                size: 50,
                color: Colors.red,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 50,
            left: 16,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: Colors.white,
              child: SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 340,
            right: 16,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: Colors.white,
              child: SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  icon: const Icon(Icons.my_location_rounded, color: Colors.blue, size: 22),
                  onPressed: _goToCurrentLocation,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: ConstrainedBox(
              // 💡 𝗙𝗜𝗫𝗘𝗗: උපරිම උස ෆෝන් එකේ උසින් 80% කට සීමා කළා.
              // දැන් ඉඩ මදි වුණොත් Auto පල්ලෙහාට Scroll වෙන්න පටන් ගන්නවා!
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.8,
              ),
              child: const BookingFormWidget(),
            ),
          ),
        ],
      ),
    );
  }
}