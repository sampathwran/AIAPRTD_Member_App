import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class HomeMapBody extends StatefulWidget {
  const HomeMapBody({super.key});

  @override
  State<HomeMapBody> createState() => _HomeMapBodyState();
}

class _HomeMapBodyState extends State<HomeMapBody> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;

  // 🌍 ලංකාවේ මැද ලොකේෂන් එක (මැප් එක මුලින්ම ලෝඩ් වෙද්දී පෙනෙන්න)
  static const LatLng _initialCenter = LatLng(7.8731, 80.7718);

  @override
  void initState() {
    super.initState();
    _determinePosition(); // ඇප් එක ඕපන් වෙද්දීම ලොකේෂන් චෙක් කරනවා
  }

  // 📡 Phone එකේ Location Permissions චෙක් කරලා කරන්ට් ලොකේෂන් එක ගන්නා ෆන්ක්ෂන් එක
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // GPS ඔන් ද බලනවා
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLoading = false);
      _showSnackBar('Please enable your location services (GPS).');
      return;
    }

    // පර්මිෂන් චෙක් කරනවා
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoading = false);
        _showSnackBar('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _isLoading = false);
      _showSnackBar('Location permissions are permanently denied.');
      return;
    }

    // 🎯 හැමදේම හරි නම් කරන්ට් ලොකේෂන් එක ගන්නවා
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });

        // 🎥 ගත්තු ගමන් කැමරාව යූසර් ඉන්න තැනට Zoom කරනවා
        _animateToCurrentLocation();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showSnackBar('Error fetching location: $e');
    }
  }

  // 🎥 යූසර් ඉන්න තැනට කැමරාව ලස්සනට Move/Zoom කරන මෙතඩ් එක
  Future<void> _animateToCurrentLocation() async {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 15.0, // 👈 මචං මෙතනින් තමයි Zoom එක පාලනය කරන්නේ (15.0 කියන්නේ සුපිරි ගාණක්)
          ),
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // මැප් එක එනකන් ලෝඩර් එකක්
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition != null
              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
              : _initialCenter,
          zoom: _currentPosition != null ? 15.0 : 7.0,
        ),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        myLocationEnabled: true, // 🔵 නිල් පාටින් මගේ ලොකේෂන් තිත පෙන්වනවා
        myLocationButtonEnabled: false, // ❌ Default බටන් එක අයින් කරනවා අපේ එක දාන්න ඕන හින්දා
      ),

      // 🎯 📍 උඹ ඉල්ලපු සුපිරිම "My Location Icon" බටන් එක!
      floatingActionButton: _isLoading
          ? null
          : Padding(
        padding: const EdgeInsets.only(bottom: 90.0), // 💡 Footer Button එකට උඩින් හිටින්න Margin එකක් දැම්මා
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF1E3A8A), // සංගමයේ නිල් පාට
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          onPressed: () async {
            // බටන් එක එබුවාම ආයෙත් අලුත්ම ලොකේෂන් එක අරන් කැමරාව Zoom කරනවා මචං
            await _determinePosition();
          },
          child: const Icon(Icons.my_location_rounded),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}