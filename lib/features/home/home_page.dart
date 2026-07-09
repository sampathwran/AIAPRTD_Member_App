// ignore_for_file: spell_check_on_languages, spell_check_on_word
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ignore: depend_on_referenced_packages
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';

import 'package:aiaprtd_member/core/providers/community_assistance_provider.dart';
import 'package:aiaprtd_member/features/home/widgets/help_alert_overlay.dart';
import 'package:aiaprtd_member/features/home/widgets/requester_status_overlay.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';

import 'package:aiaprtd_member/features/home/home_header.dart';
import 'package:aiaprtd_member/features/home/home_footer.dart';
import 'package:aiaprtd_member/features/home/online_button_widget.dart';
import 'package:aiaprtd_member/features/home/widgets/meter/mini_meter_widget.dart';

// Neutral Grey Theme - easy on the eyes
const String _mapStyle = '''
[
  { "elementType": "geometry", "stylers": [{"color": "#e0e0e0"}] },
  { "elementType": "labels.icon", "stylers": [{"visibility": "off"}] },
  { "elementType": "labels.text.fill", "stylers": [{"color": "#616161"}] },
  { "elementType": "labels.text.stroke", "stylers": [{"color": "#e0e0e0"}] },
  { "featureType": "administrative.land_parcel", "elementType": "labels.text.fill", "stylers": [{"color": "#9e9e9e"}] },
  { "featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#d5d5d5"}] },
  { "featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}] },
  { "featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#c8d6cd"}] },
  { "featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}] },
  { "featureType": "road", "elementType": "geometry", "stylers": [{"color": "#ffffff"}] },
  { "featureType": "road.arterial", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}] },
  { "featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#c5c5c5"}] },
  { "featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#616161"}] },
  { "featureType": "road.local", "elementType": "labels.text.fill", "stylers": [{"color": "#9e9e9e"}] },
  { "featureType": "transit.line", "elementType": "geometry", "stylers": [{"color": "#d5d5d5"}] },
  { "featureType": "transit.station", "elementType": "geometry", "stylers": [{"color": "#e0e0e0"}] },
  { "featureType": "water", "elementType": "geometry", "stylers": [{"color": "#b8cce4"}] },
  { "featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#9e9e9e"}] }
]
''';

const String _darkMapStyle = '''
[
  { "elementType": "geometry", "stylers": [{"color": "#212121"}] },
  { "elementType": "labels.icon", "stylers": [{"visibility": "off"}] },
  { "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}] },
  { "elementType": "labels.text.stroke", "stylers": [{"color": "#212121"}] },
  { "featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#757575"}] },
  { "featureType": "administrative.country", "elementType": "labels.text.fill", "stylers": [{"color": "#9e9e9e"}] },
  { "featureType": "administrative.land_parcel", "stylers": [{"visibility": "off"}] },
  { "featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#bdbdbd"}] },
  { "featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}] },
  { "featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#181818"}] },
  { "featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#616161"}] },
  { "featureType": "poi.park", "elementType": "labels.text.stroke", "stylers": [{"color": "#1b1b1b"}] },
  { "featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "#2c2c2c"}] },
  { "featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#8a8a8a"}] },
  { "featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#373737"}] },
  { "featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#3c3c3c"}] },
  { "featureType": "road.highway.controlled_access", "elementType": "geometry", "stylers": [{"color": "#4e4e4e"}] },
  { "featureType": "road.local", "elementType": "labels.text.fill", "stylers": [{"color": "#616161"}] },
  { "featureType": "transit", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}] },
  { "featureType": "water", "elementType": "geometry", "stylers": [{"color": "#000000"}] },
  { "featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#3d3d3d"}] }
]
''';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final User? _user = FirebaseAuth.instance.currentUser;
  GoogleMapController? _mapController;
  Position? _currentPosition;
  double _currentHeading = 0.0;
  bool _isLoading = true;
  bool _isSharingLocation = false;
  bool _isFirstLocationFound = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  BitmapDescriptor _customLocationIcon = BitmapDescriptor.defaultMarker;
  final Set<Marker> _markers = {};

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<CompassEvent>? _compassStreamSubscription;

  DateTime? _lastFirebaseUpdateTime;

  final GlobalKey<State> _footerBadgeKey = GlobalKey<State>();

  @override
  void initState() {
    super.initState();
    _createCustomMarker();
    _checkPermissionsAndStartTracking();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
        await profileProvider.fetchAndStoreMemberData();
        if (!mounted) return;

        String myCurrentPhoneToken = "phone_fcm_token_or_unique_id";
        profileProvider.listenToDeviceSession(context, myCurrentPhoneToken);
        
        Provider.of<CommunityAssistanceProvider>(context, listen: false)
            .startListeningForRequests(profileProvider);
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _compassStreamSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound(String assetPath) async {
    try {
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint("Sound play error: $e");
    }
  }

  void _updateCamera() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 15.5,
            bearing: _currentHeading,
            tilt: 0.0,
          ),
        ),
      );
    }
  }

  Future<void> _createCustomMarker() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 110.0;
    const double center = size / 2;

    final Paint blueDotPaint = Paint()
      ..color = const Color(0xFF2196F3).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(center, center), size * 0.22, blueDotPaint);

    final Paint coreBluePaint = Paint()
      ..color = const Color(0xFF1976D2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(center, center), size * 0.12, coreBluePaint);

    final Paint arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Path path = Path();
    path.moveTo(center, center - (size * 0.14));
    path.lineTo(center - (size * 0.08), center + (size * 0.06));
    path.lineTo(center, center + (size * 0.01));
    path.lineTo(center + (size * 0.08), center + (size * 0.06));
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

  void _syncLocationToFirebase(double lat, double lng, double bearing) {
    if (!_isSharingLocation) return;

    final now = DateTime.now();
    if (_lastFirebaseUpdateTime == null ||
        now.difference(_lastFirebaseUpdateTime!).inSeconds >= 3) {

      _lastFirebaseUpdateTime = now;

      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      profileProvider.updateLiveLocation(lat, lng, bearing);
    }
  }

  Future<void> _checkPermissionsAndStartTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) setState(() => _isLoading = false);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    try {
      Position? cachedPosition = await Geolocator.getLastKnownPosition();

      if (cachedPosition != null && mounted) {
        setState(() {
          _currentPosition = cachedPosition;
          _isLoading = false;
          _isFirstLocationFound = true;
        });
      } else {
        Position initPosition = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
        if (mounted) {
          setState(() {
            _currentPosition = initPosition;
            _isLoading = false;
            _isFirstLocationFound = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching location: $e");
      if (mounted) setState(() => _isLoading = false);
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
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

      if (!_isFirstLocationFound && _mapController != null) {
        _updateCamera();
        _isFirstLocationFound = true;
      }
      _syncLocationToFirebase(position.latitude, position.longitude, _currentHeading);
    });

    _compassStreamSubscription = FlutterCompass.events!.listen((CompassEvent event) {
      if (event.heading != null && mounted) {
        final double heading = event.heading!;
        if ((heading - _currentHeading).abs() > 10) {
          setState(() {
            _currentHeading = heading;
            if (_currentPosition != null) {
              _markers.clear();
              _markers.add(Marker(
                markerId: const MarkerId('driver_location'),
                position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                rotation: heading,
                flat: true,
                anchor: const Offset(0.5, 0.5),
                icon: _customLocationIcon,
              ));
            }
          });
          if (_currentPosition != null) {
            _syncLocationToFirebase(_currentPosition!.latitude, _currentPosition!.longitude, heading);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Reactively update map style when theme changes
    if (_mapController != null) {
      _mapController!.setMapStyle(isDarkMode ? _darkMapStyle : _mapStyle);
    }

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
              zoom: 15.5,
              bearing: 0.0,
              tilt: 0.0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _mapController!.setMapStyle(isDarkMode ? _darkMapStyle : _mapStyle);
              if (_currentPosition != null) _updateCamera();
            },
            zoomControlsEnabled: false,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            markers: _markers,
          ),
          Positioned(top: 50, left: 16, right: 16, child: HomeHeader(user: _user)),
          const Positioned(top: 130, left: 0, right: 0, child: MiniMeterWidget()),
            Positioned(
              bottom: 210,
              right: 20,
              child: FloatingActionButton(
                onPressed: () => Navigator.pushNamed(context, '/sos'),
                backgroundColor: Colors.orange.shade700,
                child: const Icon(Icons.handshake, color: Colors.white, size: 30),
              ),
            ),
          Positioned(
            bottom: 140, // Adjusted My Location button
            right: 20,
            child: SizedBox(
              width: 56,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).cardColor,
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                  shadowColor: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.2),
                  elevation: 4,
                ),
                onPressed: _updateCamera,
                child: const Icon(Icons.my_location, color: Colors.blue),
              ),
            ),
          ),
          Positioned(
            bottom: 125, // Adjusted GO Button
            left: 0,
            right: 0,
            child: Center(
              child: OnlineButtonWidget(
                isSharingLocation: _isSharingLocation,
                currentHeading: _currentHeading,
                currentPosition: _currentPosition,
                playSound: _playSound,
                footerBadgeKey: _footerBadgeKey,
                onStatusChanged: (status) {
                  setState(() => _isSharingLocation = status);
                },
              ),
            ),
          ),
          // Community Assistance Nearby Alert Overlay
          const HelpAlertOverlay(),
          const RequesterStatusOverlay(),
          HomeFooter(
            isSharingLocation: _isSharingLocation,
            badgeKey: _footerBadgeKey,
            onToggleLocation: () {
              setState(() => _isSharingLocation = !_isSharingLocation);
            },
          ),
        ],
      ),
    );
  }
}
