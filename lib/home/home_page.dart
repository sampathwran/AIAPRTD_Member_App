import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';

import 'home_header.dart';
import 'home_footer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  GoogleMapController? _mapController;
  Position? _currentPosition;
  double _currentHeading = 0.0;
  bool _isLoading = true;
  bool _isSharingLocation = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  BitmapDescriptor _customLocationIcon = BitmapDescriptor.defaultMarker;
  final Set<Marker> _markers = {};

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<CompassEvent>? _compassStreamSubscription;

  @override
  void initState() {
    super.initState();
    _createCustomMarker();
    _checkPermissionsAndStartTracking();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _compassStreamSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound(String assetPath) async {
    await _audioPlayer.play(AssetSource(assetPath));
  }

  void _updateCamera() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 18.5,
            bearing: 0.0,
          ),
        ),
      );
    }
  }

  Future<void> _createCustomMarker() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 160.0;
    const double center = size / 2;

    final Paint blueDotPaint = Paint()..color = const Color(0xFF2196F3);
    canvas.drawCircle(const Offset(center, center), size * 0.14, blueDotPaint);

    final Paint arrowPaint = Paint()..color = Colors.white;
    final Path path = Path();
    path.moveTo(center, center - (size * 0.11));
    path.lineTo(center - (size * 0.06), center + (size * 0.04));
    path.lineTo(center, center);
    path.lineTo(center + (size * 0.06), center + (size * 0.04));
    path.close();
    canvas.drawPath(path, arrowPaint);

    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null && mounted) {
      setState(() {
        _customLocationIcon = BitmapDescriptor.bytes(byteData.buffer.asUint8List());
      });
    }
  }

  Future<void> _checkPermissionsAndStartTracking() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      ),
    ).listen((Position position) {
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _isLoading = false;
        _markers.clear();
        _markers.add(Marker(
          markerId: const MarkerId('driver_location'),
          position: LatLng(position.latitude, position.longitude),
          rotation: _currentHeading,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          icon: _customLocationIcon,
        ));
      });
    });

    _compassStreamSubscription = FlutterCompass.events!.listen((CompassEvent event) {
      if (event.heading != null && mounted) {
        setState(() => _currentHeading = event.heading!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(7.8731, 80.7718),
              zoom: 18.5,
            ),
            onMapCreated: (controller) => _mapController = controller,
            zoomControlsEnabled: false,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            markers: _markers,
          ),
          Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: HomeHeader(user: _user)),

          // SOS Button
          Positioned(
            bottom: 280,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/sos'),
              backgroundColor: Colors.red,
              child: const Text("SOS",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),

          // My Location Button (ElevatedButton එකක් විදියට දැම්මා පේන්න)
          Positioned(
            bottom: 200,
            right: 20,
            child: SizedBox(
              width: 56,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                ),
                onPressed: _updateCamera,
                child: const Icon(Icons.my_location, color: Colors.blue),
              ),
            ),
          ),

          if (!_isSharingLocation)
            Positioned(
              bottom: 200,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    _playSound('sounds/go_sound.mp3');
                    setState(() => _isSharingLocation = true);
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.blue.shade300,
                        Colors.blue.shade600
                      ]),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 10)
                      ],
                    ),
                    child: const Center(
                      child: Text("GO",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            ),
          HomeFooter(
            isSharingLocation: _isSharingLocation,
            onToggleLocation: () {
              _playSound(_isSharingLocation
                  ? 'sounds/off_sound.mp3'
                  : 'sounds/go_sound.mp3');
              setState(() => _isSharingLocation = !_isSharingLocation);
            },
          ),
        ],
      ),
    );
  }
}