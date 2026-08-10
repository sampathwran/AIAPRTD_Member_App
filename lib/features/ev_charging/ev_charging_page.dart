import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/ev_station.dart';

class EvChargingPage extends StatefulWidget {
  const EvChargingPage({super.key});

  @override
  State<EvChargingPage> createState() => _EvChargingPageState();
}

class _EvChargingPageState extends State<EvChargingPage> {
  final Completer<GoogleMapController> _controller = Completer();
  
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(6.9271, 79.8612),
    zoom: 9.0,
  );

  List<EvStation> _stations = [];
  Map<String, Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStations();
  }

  Color _getProviderColor(String provider) {
    final p = provider.toLowerCase().replaceAll(' ', '');
    if (p.contains('chargenet')) return const Color(0xFF1976D2); // Blue
    if (p.contains('ceb')) return const Color(0xFFD32F2F); // Red
    if (p.contains('spark')) return const Color(0xFFF57C00); // Orange
    if (p.contains('vegapoint') || p.contains('vega')) return const Color(0xFF388E3C); // Green
    if (p.contains('evclub')) return const Color(0xFF7B1FA2); // Purple
    return const Color(0xFF00796B); // Teal (Default)
  }

  Future<BitmapDescriptor> _getCustomMarker(Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    const double size = 120.0;
    
    // Draw circle background
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, paint);
    
    // Draw inner white circle
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 8, Paint()..color = Colors.white);
    
    // Draw icon inside
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.ev_station.codePoint),
      style: TextStyle(
        fontSize: size * 0.6,
        fontFamily: Icons.ev_station.fontFamily,
        package: Icons.ev_station.fontPackage,
        color: color,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );
    
    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();
    
    return BitmapDescriptor.fromBytes(uint8List);
  }

  Future<void> _fetchStations() async {
    FirebaseFirestore.instance
        .collection('ev_charging_stations')
        .snapshots()
        .listen((snapshot) async {
      if (!mounted) return;
      
      List<EvStation> newStations = [];
      Map<String, Marker> newMarkers = {};
      
      for (var doc in snapshot.docs) {
        final station = EvStation.fromFirestore(doc);
        newStations.add(station);
        
        final Color providerColor = _getProviderColor(station.provider);
        final BitmapDescriptor markerIcon = await _getCustomMarker(providerColor);

        newMarkers[station.id] = Marker(
          markerId: MarkerId(station.id),
          position: LatLng(station.latitude, station.longitude),
          icon: markerIcon,
          infoWindow: InfoWindow(
            title: station.name,
            snippet: '${station.provider} | Tap for details',
          ),
          onTap: () => _showStationDetails(station),
        );
      }
      
      setState(() {
        _stations = newStations;
        _markers = newMarkers;
        _isLoading = false;
      });
    }, onError: (e) {
      debugPrint("Error fetching stations: $e");
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _showStationDetails(EvStation initialStation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('ev_charging_stations').doc(initialStation.id).snapshots(),
          builder: (context, snapshot) {
            // Fallback to initial station if stream hasn't yielded yet or document is missing
            EvStation station = initialStation;
            if (snapshot.hasData && snapshot.data!.exists) {
              station = EvStation.fromFirestore(snapshot.data!);
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (station.imageUrl != null && station.imageUrl!.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              station.imageUrl!,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: double.infinity,
                                height: 180,
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          station.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(station.provider, style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                        const SizedBox(height: 16),
                        if (station.address.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, color: Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(station.address)),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (station.description != null && station.description!.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.yellow[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.yellow[300]!),
                            ),
                            child: Text(
                              station.description!,
                              style: TextStyle(color: Colors.brown[800], fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Legacy top-level price is now hidden to favor charger-level prices
                        const SizedBox(height: 24),
                        const Text('Charging Points', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 12),
                        ...station.chargers.map((charger) => _buildChargerCard(station, charger)).toList(),
                        if (station.chargers.isEmpty)
                          const Text("No detailed charger information available."),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${station.latitude},${station.longitude}');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not launch maps')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.directions),
                            label: const Text('Get Directions'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChargerCard(EvStation station, EvCharger charger) {
    Color statusColor = Colors.green;
    IconData statusIcon = Icons.check_circle;
    
    if (charger.status == 'In Use') {
      statusColor = Colors.orange;
      statusIcon = Icons.ev_station;
    } else if (charger.status == 'Broken' || charger.status == 'Offline') {
      statusColor = Colors.red;
      statusIcon = Icons.warning;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.electrical_services, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(charger.name ?? charger.type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (charger.name != null)
                        Text(charger.type, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      Text('${charger.powerKw} kW', style: TextStyle(color: Colors.grey[600])),
                      if (charger.pricePerKwh > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Rs.${charger.pricePerKwh}/kWh', 
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800], fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(charger.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildReportButton(station, charger, 'Available', Colors.green, Icons.check),
                _buildReportButton(station, charger, 'In Use', Colors.orange, Icons.ev_station),
                _buildReportButton(station, charger, 'Broken', Colors.red, Icons.build),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildReportButton(EvStation station, EvCharger charger, String status, Color color, IconData icon) {
    bool isCurrent = charger.status == status;
    return InkWell(
      onTap: () => _reportStatus(station, charger, status),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrent ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isCurrent ? color : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isCurrent ? Colors.white : color),
            const SizedBox(width: 4),
            Text(
              status,
              style: TextStyle(
                color: isCurrent ? Colors.white : Colors.grey[700],
                fontSize: 12,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reportStatus(EvStation station, EvCharger charger, String newStatus) async {
    if (charger.status == newStatus) return;

    try {
      // Find the charger in the list and update it
      List<dynamic> updatedChargers = station.chargers.map((c) {
        if (c.id == charger.id) {
          return {
            'id': c.id,
            'name': c.name,
            'type': c.type,
            'powerKw': c.powerKw,
            'status': newStatus,
            'pricePerKwh': c.pricePerKwh,
          };
        }
        return c.toJson();
      }).toList();

      final docRef = FirebaseFirestore.instance.collection('ev_charging_stations').doc(station.id);
      await docRef.update({'chargers': updatedChargers});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EV Charging Points'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: Set<Marker>.of(_markers.values),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          if (_isLoading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
