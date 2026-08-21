// ignore_for_file: spell_check_on_languages, spell_check_on_word
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: depend_on_referenced_packages, spell_check
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';

import 'package:aiaprtd_member/core/providers/community_assistance_provider.dart';
import 'package:aiaprtd_member/features/home/widgets/help_alert_overlay.dart';
import 'package:aiaprtd_member/features/home/widgets/requester_status_overlay.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/core/providers/auth_provider.dart';

import 'package:aiaprtd_member/features/home/home_header.dart';
import 'package:aiaprtd_member/features/home/home_footer.dart';
import 'package:aiaprtd_member/features/home/online_button_widget.dart';
import 'package:aiaprtd_member/features/home/widgets/meter/mini_meter_widget.dart';
import 'package:aiaprtd_member/core/providers/meter_provider.dart';
import 'package:aiaprtd_member/features/home/trip_summary_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aiaprtd_member/features/home/birthday_wishes_overlay.dart';
import 'package:aiaprtd_member/features/home/special_day_wishes_overlay.dart';

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
  bool _isFirstLocationFound = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  BitmapDescriptor _customLocationIcon = BitmapDescriptor.defaultMarker;
  final Set<Marker> _markers = {};

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<CompassEvent>? _compassStreamSubscription;

  DateTime? _lastFirebaseUpdateTime;

  StreamSubscription<QuerySnapshot>? _trafficReportsSubscription;
  final Set<Marker> _trafficMarkers = {};
  final Map<String, BitmapDescriptor> _trafficIcons = {};
  final List<Map<String, dynamic>> _activeTrafficReports = [];
  final Set<String> _alerted500mTrafficReports = {};
  final Set<String> _alerted200mTrafficReports = {};
  final AudioPlayer _alertAudioPlayer = AudioPlayer();

  final GlobalKey<State> _footerBadgeKey = GlobalKey<State>();
  
  bool _showBirthdayWishes = false;
  bool _showSpecialDayWishes = false;
  String _specialDayTitle = '';
  String _specialDayType = '';

  @override
  void initState() {
    super.initState();
    _createCustomMarker();
    _generateTrafficIcons();
    _checkPermissionsAndStartTracking();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final meterProvider =
            Provider.of<MeterProvider>(context, listen: false);
        await meterProvider.loadState();

        if (!mounted) return;

        if (meterProvider.isRunning) {
          Navigator.pushNamed(context, '/road-pickup');
        } else if (meterProvider.isTripCompleted) {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const TripSummaryPage()));
        }

        final profileProvider =
            Provider.of<ProfileProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        await profileProvider.fetchAndStoreMemberData();
        _checkBirthday();
        _checkSpecialDays();

        if (!mounted) return;

        String myCurrentPhoneToken = await authProvider.getPersistentDeviceId();
        if (!mounted) return;
        profileProvider.listenToDeviceSession(context, myCurrentPhoneToken);

        Provider.of<CommunityAssistanceProvider>(context, listen: false)
            .startListeningForRequests(profileProvider);
      }
    });

    _listenToTrafficReports();
  }

  void _listenToTrafficReports() {
    _trafficReportsSubscription = FirebaseFirestore.instance
        .collection('traffic_reports')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      
      final now = DateTime.now();
      _trafficMarkers.clear();
      _activeTrafficReports.clear();
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        final denials = data['denials'] ?? 0;
        if (denials >= 2) continue;

        Timestamp? reportedTs = data['lastVerifiedAt'] ?? data['reportedAt'];
        if (reportedTs != null) {
          final diff = now.difference(reportedTs.toDate());
          if (diff.inHours >= 4) continue;
        }

        final lat = data['latitude'];
        final lng = data['longitude'];
        final type = data['type'] as String? ?? 'unknown';

        _activeTrafficReports.add({
          'id': doc.id,
          'latitude': lat,
          'longitude': lng,
          'type': type,
        });

        _trafficMarkers.add(
          Marker(
            markerId: MarkerId('traffic_${doc.id}'),
            position: LatLng(lat, lng),
            icon: _trafficIcons[type] ?? BitmapDescriptor.defaultMarker,
            onTap: () => _showTrafficReportDetails(doc.id, data),
          ),
        );
      }
      _buildAllMarkers();
    });
  }

  void _showTrafficReportDetails(String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final type = data['type'] as String? ?? 'unknown';
        final confirmations = data['confirmations'] ?? 0;
        final denials = data['denials'] ?? 0;
        
        final userId = FirebaseAuth.instance.currentUser?.uid;
        final List<dynamic> votedUsers = data['votedUsers'] ?? [];
        final bool hasVoted = userId != null && votedUsers.contains(userId);

        double dist = 1000.0;
        if (_currentPosition != null) {
          dist = Geolocator.distanceBetween(
            _currentPosition!.latitude, _currentPosition!.longitude,
            data['latitude'], data['longitude'],
          );
        }
        final bool isCloseEnough = dist <= 500.0;

        final typeLabel = type == 'traffic_police' ? 'Traffic Police' : 
                          type == 'police_barrier' ? 'Police Barrier' : 'High Speed Check';
        
        Timestamp? ts = data['reportedAt'];
        String timeStr = 'Unknown';
        if (ts != null) {
          final diff = DateTime.now().difference(ts.toDate());
          if (diff.inMinutes < 60) timeStr = '${diff.inMinutes} mins ago';
          else timeStr = '${diff.inHours} hours ago';
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(typeLabel, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Reported $timeStr', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              
              if (hasVoted) ...[
                const Icon(Icons.check_circle, color: Colors.green, size: 40),
                const SizedBox(height: 8),
                const Text('You have already verified this.', style: TextStyle(fontSize: 16)),
              ] else if (!isCloseEnough) ...[
                const Icon(Icons.location_off, color: Colors.orange, size: 40),
                const SizedBox(height: 8),
                const Text('You must be within 500m to verify.', style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
              ] else ...[
                const Text('Is it still there?', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        if (userId != null) {
                          FirebaseFirestore.instance.collection('traffic_reports').doc(docId).update({
                            'denials': FieldValue.increment(1),
                            'lastVerifiedAt': FieldValue.serverTimestamp(),
                            'votedUsers': FieldValue.arrayUnion([userId]),
                          });
                        }
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks for verifying!')));
                      },
                      icon: const Icon(Icons.thumb_down, color: Colors.red),
                      label: Text('Not there ($denials)', style: const TextStyle(color: Colors.red)),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        if (userId != null) {
                          FirebaseFirestore.instance.collection('traffic_reports').doc(docId).update({
                            'confirmations': FieldValue.increment(1),
                            'lastVerifiedAt': FieldValue.serverTimestamp(),
                            'votedUsers': FieldValue.arrayUnion([userId]),
                          });
                        }
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks for verifying!')));
                      },
                      icon: const Icon(Icons.thumb_up),
                      label: Text('Still there ($confirmations)'),
                    ),
                  ],
                )
              ],
            ],
          ),
        );
      },
    );
  }

  void _buildAllMarkers() {
    if (!mounted) return;
    setState(() {
      _markers.clear();
      if (_currentPosition != null) {
        _markers.add(Marker(
          markerId: const MarkerId('driver_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          rotation: _currentHeading,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          icon: _customLocationIcon,
        ));
      }
      _markers.addAll(_trafficMarkers);
    });
  }

  Future<void> _checkBirthday() async {
    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final dobStr = profileProvider.memberData?['dob'] as String?;
      if (dobStr == null || dobStr.isEmpty) return;

      // Ensure it's in format like YYYY/MM/DD or YYYY-MM-DD
      DateTime dob;
      try {
        dob = DateTime.parse(dobStr.replaceAll('/', '-'));
      } catch (e) {
        return; // invalid date format
      }

      DateTime now = DateTime.now();
      if (now.month == dob.month && now.day == dob.day) {
        // It's their birthday! Check if we already showed it today
        final prefs = await SharedPreferences.getInstance();
        final lastShownDate = prefs.getString('last_birthday_shown_date');
        final todayStr = "${now.year}-${now.month}-${now.day}";

        if (lastShownDate != todayStr) {
          // Show birthday!
          setState(() {
            _showBirthdayWishes = true;
          });
          await prefs.setString('last_birthday_shown_date', todayStr);
        }
      }
    } catch (e) {
      debugPrint("Birthday check error: $e");
    }
  }

  Future<void> _checkSpecialDays() async {
    try {
      final now = DateTime.now();
      final todayMMDD =
          "${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final doc = await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('special_days')
          .get();

      if (doc.exists && doc.data() != null) {
        final List<dynamic> events = doc.data()!['events'] ?? [];
        for (var event in events) {
          if (event['date'] == todayMMDD && event['isActive'] == true) {
            
            // Check if we already showed it today
            final prefs = await SharedPreferences.getInstance();
            final lastShownKey = 'last_special_day_${event['type']}_shown_date';
            final todayStr = "${now.year}-${now.month}-${now.day}";
            final lastShownDate = prefs.getString(lastShownKey);

            if (lastShownDate != todayStr) {
              setState(() {
                _showSpecialDayWishes = true;
                _specialDayTitle = event['title'] ?? 'Happy Special Day!';
                _specialDayType = event['type'] ?? 'celebration';
              });
              await prefs.setString(lastShownKey, todayStr);
            }
            break; // Only show one special day at a time
          }
        }
      }
    } catch (e) {
      debugPrint("Special Days check error: $e");
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _compassStreamSubscription?.cancel();
    _trafficReportsSubscription?.cancel();
    _audioPlayer.dispose();
    _alertAudioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound(String assetPath) async {
    try {
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (_) {
      try {
        // Fallback for some Audioplayers versions where 'assets/' prefix is needed
        await _audioPlayer.play(AssetSource('assets/$assetPath'));
      } catch (e) {
        debugPrint("Sound play error: $e");
      }
    }
  }

  void _updateCamera() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target:
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
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

    final ui.Image image = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null && mounted) {
      setState(() {
        _customLocationIcon =
            BitmapDescriptor.bytes(byteData.buffer.asUint8List());
      });
    }
  }

  Future<void> _generateTrafficIcons() async {
    const int targetWidth = 50; // Reduced significantly for all icons

    try {
      final Uint8List policeBytes = await _getBytesFromAsset('assets/images/map_markers/traffic_police.png', targetWidth);
      _trafficIcons['traffic_police'] = BitmapDescriptor.bytes(policeBytes);
    } catch (e) {
      debugPrint("Error loading traffic_police icon: $e");
    }

    try {
      final Uint8List barrierBytes = await _getBytesFromAsset('assets/images/map_markers/police_barrier.png', 40); // Reduced size for barrier
      _trafficIcons['police_barrier'] = BitmapDescriptor.bytes(barrierBytes);
    } catch (e) {
      debugPrint("Error loading police_barrier icon: $e");
    }

    try {
      final Uint8List speedBytes = await _getBytesFromAsset('assets/images/map_markers/high_speed.png', targetWidth);
      _trafficIcons['high_speed'] = BitmapDescriptor.bytes(speedBytes);
    } catch (e) {
      debugPrint("Error loading high_speed icon: $e");
    }
  }

  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  void _checkTrafficAlerts(Position position) {
    for (final report in _activeTrafficReports) {
      final String id = report['id'];
      final double lat = report['latitude'];
      final double lng = report['longitude'];
      final String type = report['type'];

      final double dist = Geolocator.distanceBetween(
        position.latitude, position.longitude,
        lat, lng,
      );

      final String sound = type == 'traffic_police'
          ? 'sounds/police_alert.mp3'
          : type == 'police_barrier'
              ? 'sounds/barrier_alert.mp3'
              : 'sounds/speed_alert.mp3';

      // 500m alert - first warning
      if (dist <= 500 && !_alerted500mTrafficReports.contains(id)) {
        _alerted500mTrafficReports.add(id);
        _alertAudioPlayer.play(AssetSource(sound));
      }

      // 200m alert - close warning
      if (dist <= 200 && !_alerted200mTrafficReports.contains(id)) {
        _alerted200mTrafficReports.add(id);
        _alertAudioPlayer.play(AssetSource(sound));
      }

      // Reset when driver moves > 800m away
      if (dist > 800) {
        _alerted500mTrafficReports.remove(id);
        _alerted200mTrafficReports.remove(id);
      }
    }
  }

  void _syncLocationToFirebase(double lat, double lng, double bearing) {
    if (!mounted) return;
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    if (!profileProvider.isOnline) return;

    final now = DateTime.now();
    if (_lastFirebaseUpdateTime == null ||
        now.difference(_lastFirebaseUpdateTime!).inSeconds >= 3) {
      _lastFirebaseUpdateTime = now;

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

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
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
        Position initPosition = await Geolocator.getCurrentPosition(
            locationSettings: locationSettings);
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
      });
      _buildAllMarkers();
      _checkTrafficAlerts(position);

      if (!_isFirstLocationFound && _mapController != null) {
        _updateCamera();
        _isFirstLocationFound = true;
      }
      _syncLocationToFirebase(
          position.latitude, position.longitude, _currentHeading);
    });

    _compassStreamSubscription =
        FlutterCompass.events!.listen((CompassEvent event) {
      if (event.heading != null && mounted) {
        final double heading = event.heading!;
        if ((heading - _currentHeading).abs() > 10) {
          setState(() {
            _currentHeading = heading;
          });
          _buildAllMarkers();
          if (_currentPosition != null) {
            _syncLocationToFirebase(_currentPosition!.latitude,
                _currentPosition!.longitude, heading);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final profileProvider = context.watch<ProfileProvider>();
    final bool isOnline = profileProvider.isOnline;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null
                        ? LatLng(_currentPosition!.latitude,
                            _currentPosition!.longitude)
                        : const LatLng(7.8731, 80.7718),
                    zoom: 15.5,
                    bearing: 0.0,
                    tilt: 0.0,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_currentPosition != null) _updateCamera();
                  },
                  style: isDarkMode ? _darkMapStyle : _mapStyle,
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
                const Positioned(
                    top: 130, left: 0, right: 0, child: MiniMeterWidget()),
                Positioned(
                  bottom: 210,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: () => Navigator.pushNamed(context, '/sos'),
                    backgroundColor: Colors.orange.shade700,
                    child: const Icon(Icons.handshake,
                        color: Colors.white, size: 30),
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
                        shadowColor: Colors.black
                            .withValues(alpha: isDarkMode ? 0.4 : 0.2),
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
                      isSharingLocation: isOnline,
                      currentHeading: _currentHeading,
                      currentPosition: _currentPosition,
                      playSound: _playSound,
                      footerBadgeKey: _footerBadgeKey,
                      onStatusChanged: (status) {
                        // No-op, managed by profile provider now
                      },
                    ),
                  ),
                ),
                // Community Assistance Nearby Alert Overlay
                const HelpAlertOverlay(),
                const RequesterStatusOverlay(),
                HomeFooter(
                  isSharingLocation: isOnline,
                  badgeKey: _footerBadgeKey,
                  onToggleLocation: () {
                    // No-op, managed by profile provider now
                  },
                ),
                if (_showBirthdayWishes)
                  BirthdayWishesOverlay(
                    firstName: profileProvider.memberData?['firstName'] ?? '',
                    lastName: profileProvider.memberData?['lastName'] ?? '',
                    onClose: () {
                      setState(() {
                        _showBirthdayWishes = false;
                      });
                    },
                  )
                else if (_showSpecialDayWishes)
                  SpecialDayWishesOverlay(
                    title: _specialDayTitle,
                    type: _specialDayType,
                    onClose: () {
                      setState(() {
                        _showSpecialDayWishes = false;
                      });
                    },
                  ),
              ],
            ),
    );
  }
}
