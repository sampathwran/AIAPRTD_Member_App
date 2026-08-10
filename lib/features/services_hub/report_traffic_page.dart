import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportTrafficPage extends StatefulWidget {
  const ReportTrafficPage({super.key});

  @override
  State<ReportTrafficPage> createState() => _ReportTrafficPageState();
}

class _ReportTrafficPageState extends State<ReportTrafficPage> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng _selectedLocation = const LatLng(6.9271, 79.8612); // Default to Colombo
  bool _isLoading = false;
  String _selectedType = 'traffic_police';

  final Map<String, String> _typeLabels = {
    'traffic_police': 'Traffic Police',
    'police_barrier': 'Police Barrier',
    'high_speed': 'High Speed',
  };

  void _onCameraMove(CameraPosition position) {
    _selectedLocation = position.target;
  }

  Future<void> _submitReport() async {
    setState(() => _isLoading = true);
    try {
      Position currentPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double distance = Geolocator.distanceBetween(
        currentPos.latitude, currentPos.longitude,
        _selectedLocation.latitude, _selectedLocation.longitude,
      );

      if (distance > 500.0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can only report locations within 500m of your current position.')),
          );
        }
        return;
      }
      
      final userId = FirebaseAuth.instance.currentUser?.uid;

      await FirebaseFirestore.instance.collection('traffic_reports').add({
        'type': _selectedType,
        'latitude': _selectedLocation.latitude,
        'longitude': _selectedLocation.longitude,
        'reportedAt': FieldValue.serverTimestamp(),
        'lastVerifiedAt': FieldValue.serverTimestamp(),
        'confirmations': 0,
        'denials': 0,
        'isActive': true,
        'votedUsers': userId != null ? [userId] : [],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully! Thank you for helping others.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Police / Traffic'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('What do you want to report?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: _typeLabels.entries.map((e) => ButtonSegment<String>(
                    value: e.key,
                    label: Text(e.value, style: const TextStyle(fontSize: 11)),
                  )).toList(),
                  selected: {_selectedType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedType = newSelection.first;
                    });
                  },
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('Move the map to point exactly where it is:', style: TextStyle(fontSize: 14)),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: 15,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  onCameraMove: _onCameraMove,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
                // Center Pin Overlay
                const Padding(
                  padding: EdgeInsets.only(bottom: 40.0), // Adjust for pin pointing to center
                  child: Icon(
                    Icons.location_on,
                    size: 50,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submitReport,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
