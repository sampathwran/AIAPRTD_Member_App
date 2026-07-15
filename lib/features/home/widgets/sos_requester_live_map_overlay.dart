import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:aiaprtd_member/core/providers/sos_provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';

class SosRequesterLiveMapOverlay extends StatefulWidget {
  const SosRequesterLiveMapOverlay({super.key});

  @override
  State<SosRequesterLiveMapOverlay> createState() => _SosRequesterLiveMapOverlayState();
}

class _SosRequesterLiveMapOverlayState extends State<SosRequesterLiveMapOverlay> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final sosProvider = Provider.of<SosProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    // Only show to the requester when SOS is active and they have an active SOS ID
    if (!sosProvider.isSosActive || sosProvider.currentSosId == null) {
      return const SizedBox.shrink();
    }

    final String sosId = sosProvider.currentSosId!;
    final double currentLat = profileProvider.memberData?['latitude']?.toDouble() ?? 0.0;
    final double currentLng = profileProvider.memberData?['longitude']?.toDouble() ?? 0.0;

    if (currentLat == 0.0 || currentLng == 0.0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: kToolbarHeight + 10,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2)
            ],
            border: Border.all(color: Colors.grey.shade400, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sos_alerts')
                  .doc(sosId)
                  .collection('live_responders')
                  .snapshots(),
              builder: (context, snapshot) {
                Set<Marker> markers = {
                  Marker(
                    markerId: const MarkerId('my_location'),
                    position: LatLng(currentLat, currentLng),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  )
                };

                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final double lat = data['latitude'] ?? 0.0;
                    final double lng = data['longitude'] ?? 0.0;
                    if (lat != 0.0 && lng != 0.0) {
                      markers.add(
                        Marker(
                          markerId: MarkerId(doc.id),
                          position: LatLng(lat, lng),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        ),
                      );
                    }
                  }
                }

                // Move camera to fit all markers if map is initialized and we have responders
                if (_mapController != null && markers.length > 1) {
                  double minLat = currentLat, maxLat = currentLat;
                  double minLng = currentLng, maxLng = currentLng;
                  
                  for (var m in markers) {
                    if (m.position.latitude < minLat) minLat = m.position.latitude;
                    if (m.position.latitude > maxLat) maxLat = m.position.latitude;
                    if (m.position.longitude < minLng) minLng = m.position.longitude;
                    if (m.position.longitude > maxLng) maxLng = m.position.longitude;
                  }
                  
                  Future.microtask(() {
                    if (mounted) {
                      _mapController!.animateCamera(
                        CameraUpdate.newLatLngBounds(
                          LatLngBounds(
                            southwest: LatLng(minLat, minLng),
                            northeast: LatLng(maxLat, maxLng),
                          ),
                          20.0, // padding
                        )
                      );
                    }
                  });
                }

                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(currentLat, currentLng),
                    zoom: 15,
                  ),
                  markers: markers,
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (controller) => _mapController = controller,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
