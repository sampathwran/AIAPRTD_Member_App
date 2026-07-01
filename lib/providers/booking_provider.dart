import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingProvider extends ChangeNotifier {
  String _tripType = 'One way';
  String get tripType => _tripType;

  final TextEditingController pickupController = TextEditingController();
  final List<TextEditingController> dropControllers = [TextEditingController()];

  Set<Marker> _markers = {};
  Set<Marker> get markers => _markers;

  Set<Polyline> _polylines = {};
  Set<Polyline> get polylines => _polylines;

  GoogleMapController? _mapController;

  final String _googleApiKey = "AIzaSyD2ZaITIFYTcb1fThVzChQYJ-cHm0aZ2iE";

  LatLng? currentPickupLatLng;
  List<LatLng?> dropLatLngs = [null];

  double totalDistanceKm = 0.0;

  // 💡 අලුතින් දැම්මා: Code එකෙන් Auto Zoom වෙද්දි Map එක Center වෙන එක (Pickup එක වෙනස් වෙන එක) නවත්තන්න.
  bool isProgrammaticMove = false;

  List<Map<String, dynamic>> savedLocations = [];
  List<Map<String, dynamic>> recentLocations = [];

  void setTripType(String type) {
    _tripType = type;
    notifyListeners();
  }

  void addDropLocation() {
    dropControllers.add(TextEditingController());
    dropLatLngs.add(null);
    notifyListeners();
  }

  void removeDropLocation(int index) {
    if (dropControllers.length > 1) {
      dropControllers[index].dispose();
      dropControllers.removeAt(index);
      dropLatLngs.removeAt(index);
      _markers.removeWhere((marker) => marker.markerId == MarkerId('drop_location_$index'));
      notifyListeners();
    }
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  // =========================================================================
  // 💡 1. Location එකක් සදාකාලිකවම Firestore එකේ Save කරන Function එක
  // =========================================================================
  Future<void> saveLocation(String name, LatLng location, String address) async {
    String? memberId = FirebaseAuth.instance.currentUser?.uid;

    if (memberId == null) {
      debugPrint("❌ User is not logged in!");
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance
          .collection('members')
          .doc(memberId)
          .collection('saved_locations')
          .doc();

      Map<String, dynamic> data = {
        "name": name,
        "address": address,
        "lat": location.latitude,
        "lng": location.longitude,
      };

      await docRef.set(data);

      data["id"] = docRef.id;
      savedLocations.add(data);

      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error saving location to Firestore: $e");
    }
  }

  // =========================================================================
  // 💡 2. Save කරපු Location එකක් Delete කරන Function එක
  // =========================================================================
  Future<void> deleteSavedLocation(String docId) async {
    String? memberId = FirebaseAuth.instance.currentUser?.uid;
    if (memberId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('members')
          .doc(memberId)
          .collection('saved_locations')
          .doc(docId)
          .delete();

      savedLocations.removeWhere((loc) => loc["id"] == docId);
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error deleting saved location: $e");
    }
  }

  void setPickupLocation(LatLng location, String address, {bool animateCamera = true}) {
    pickupController.text = address;
    currentPickupLatLng = location;

    _markers.removeWhere((m) => m.markerId == const MarkerId('pickup_location'));
    _markers.add(
      Marker(
        markerId: const MarkerId('pickup_location'),
        position: location,
        infoWindow: InfoWindow(title: 'Pickup: $address'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    if (animateCamera) {
      isProgrammaticMove = true; // 👈 දැම්මා
      _mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: location, zoom: 16)));
    }
    notifyListeners();
  }

  void setDropLocation(int index, LatLng location, String address, {bool animateCamera = true}) {
    dropControllers[index].text = address;
    dropLatLngs[index] = location;

    _markers.removeWhere((m) => m.markerId == MarkerId('drop_location_$index'));
    _markers.add(
      Marker(
        markerId: MarkerId('drop_location_$index'),
        position: location,
        infoWindow: InfoWindow(title: 'Drop: $address'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );

    if (animateCamera) {
      isProgrammaticMove = true; // 👈 දැම්මා
      _mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: location, zoom: 16)));
    }
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> searchLocations(String query) async {
    if (query.isEmpty) return [];

    final String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&components=country:lk&key=$_googleApiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          return predictions.map((p) => {
            "name": p['description'],
            "place_id": p['place_id'],
          }).toList();
        } else {
          debugPrint("Places API Error: ${data['status']} - ${data['error_message']}");
        }
      }
    } catch (e) {
      debugPrint("Error fetching places: $e");
    }
    return [];
  }

  Future<void> fetchPlaceDetailsAndSetLocation(String placeId, String address, {bool isPickup = true, int dropIndex = 0}) async {
    final String url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          final latLng = LatLng(location['lat'], location['lng']);

          if (isPickup) {
            setPickupLocation(latLng, address);
          } else {
            setDropLocation(dropIndex, latLng, address);
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching place details: $e");
    }
  }

  Future<void> getAddressFromLatLng(LatLng location, {bool isPickup = true, int dropIndex = 0, bool animateCamera = true}) async {
    final String url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${location.latitude},${location.longitude}&key=$_googleApiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          String address = data['results'][0]['formatted_address'];
          if (isPickup) {
            setPickupLocation(location, address, animateCamera: animateCamera);
          } else {
            setDropLocation(dropIndex, location, address, animateCamera: animateCamera);
          }
        }
      }
    } catch (e) {
      debugPrint("Error reverse geocoding: $e");
    }
  }

  // =========================================================================
  // 💡 අලුත් Route එක (Drops ඔක්කොම අතරේ ලයින් එක අඳිනවා)
  // =========================================================================
  Future<void> calculateRoute() async {
    if (currentPickupLatLng == null || dropLatLngs.isEmpty || dropLatLngs[0] == null) return;

    // හිස් නැති Drops ටික විතරක් අරගන්නවා
    List<LatLng> validDrops = dropLatLngs.where((d) => d != null).cast<LatLng>().toList();
    if (validDrops.isEmpty) return;

    LatLng origin = currentPickupLatLng!;
    LatLng destination = validDrops.last; // අන්තිම Drop එක

    String url = 'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&key=$_googleApiKey';

    // 💡 Drops ගොඩක් තියෙනවා නම් (Return/Multiple Drops), ඒ ඔක්කොම Waypoints විදිහට දානවා
    if (validDrops.length > 1) {
      List<LatLng> waypoints = validDrops.sublist(0, validDrops.length - 1);
      String waypointsStr = waypoints.map((w) => '${w.latitude},${w.longitude}').join('|');
      url += '&waypoints=$waypointsStr';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'].isNotEmpty) {

          // 💡 Total Distance එක ගණන් කරන්නේ කෑලි ඔක්කොගෙම දුර එකතු කරලා (Legs)
          double totalDistance = 0;
          final legs = data['routes'][0]['legs'] as List;
          for (var leg in legs) {
            totalDistance += leg['distance']['value'];
          }
          totalDistanceKm = totalDistance / 1000.0;

          String polylineEncoded = data['routes'][0]['overview_polyline']['points'];
          List<LatLng> polylineCoordinates = _decodePoly(polylineEncoded);

          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route_1'),
              color: Colors.blue,
              width: 5,
              points: polylineCoordinates,
            ),
          );

          // 💡 මාර්ක් කරපු හැම තැනක්ම පේන්න Map එක Zoom කරනවා
          List<LatLng> allPoints = [origin, ...validDrops];
          LatLngBounds bounds = _boundsFromLatLngList(allPoints);

          isProgrammaticMove = true; // 👈 Auto Zoom වෙන නිසා මේක True කරනවා
          _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));

          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error calculating route: $e");
    }
  }

  List<LatLng> _decodePoly(String poly) {
    var list = poly.codeUnits;
    var lList = <LatLng>[];
    int index = 0;
    int len = poly.length;
    int c = 0;
    do {
      var shift = 0;
      int result = 0;
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);
      if (result & 1 == 1) result = ~result;
      var result1 = (result >> 1) * 0.00001;
      var lat = result1;

      shift = 0;
      result = 0;
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);
      if (result & 1 == 1) result = ~result;
      var result2 = (result >> 1) * 0.00001;
      var lng = result2;

      if (lList.isEmpty) {
        lList.add(LatLng(lat, lng));
      } else {
        lList.add(LatLng(lList.last.latitude + lat, lList.last.longitude + lng));
      }
    } while (index < len);
    return lList;
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
  }

  Future<void> scheduleBooking({
    required String memberId,
    required String memberName,
    required DateTime pickupTime,
    required Map<String, dynamic> selectedVehicle,
    required double estimateFare,
    required String paymentMethod,
  }) async {
    String bookingId = "BKG-${DateTime.now().millisecondsSinceEpoch}";

    Map<String, dynamic> bookingData = {
      'bookingId': bookingId,
      'memberId': memberId,
      'memberName': memberName,
      'status': 'Pending',
      'tripType': _tripType,
      'pickupTime': pickupTime.toIso8601String(),
      'pickupLocation': {
        'address': pickupController.text,
        'lat': currentPickupLatLng?.latitude,
        'lng': currentPickupLatLng?.longitude,
      },
      'dropLocation': {
        'address': dropControllers[0].text,
        'lat': dropLatLngs[0]?.latitude,
        'lng': dropLatLngs[0]?.longitude,
      },
      'distanceKm': totalDistanceKm,
      'estimateFare': estimateFare,
      'vehicle': {
        'id': selectedVehicle['id'],
        'name': selectedVehicle['name'],
      },
      'paymentMethod': paymentMethod,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('all_bookings')
          .doc(bookingId)
          .set(bookingData);

      await FirebaseFirestore.instance
          .collection('members')
          .doc(memberId)
          .collection('my_bookings')
          .doc(bookingId)
          .set(bookingData);

    } catch (e) {
      debugPrint("❌ Error saving booking to Firestore: $e");
      rethrow;
    }
  }

  Future<void> fetchSavedLocations(String memberId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('members')
          .doc(memberId)
          .collection('saved_locations')
          .get();

      savedLocations = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "id": doc.id,
          "name": data['name'] ?? 'Saved Place',
          "address": data['address'] ?? '',
          "lat": (data['lat'] ?? 0.0).toDouble(),
          "lng": (data['lng'] ?? 0.0).toDouble(),
        };
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error fetching saved locations: $e");
    }
  }

  // =========================================================================
  // 💡 3. Page එකෙන් Back වෙද්දී Pickup/Drop ඔක්කොම Clear කරන Function එක
  // =========================================================================
  void resetBookingData() {
    pickupController.clear();
    currentPickupLatLng = null;

    for (int i = 1; i < dropControllers.length; i++) {
      dropControllers[i].dispose();
    }
    dropControllers.removeRange(1, dropControllers.length);
    dropControllers[0].clear();

    dropLatLngs.clear();
    dropLatLngs.add(null);

    _markers.clear();
    _polylines.clear();
    totalDistanceKm = 0.0;

    notifyListeners();
  }

  bool get isReadyToCalculateRoute {
    if (currentPickupLatLng == null) return false;
    if (dropLatLngs.isEmpty) return false;
    for (var latLng in dropLatLngs) {
      if (latLng == null) return false;
    }
    return true;
  }

  void makeReturnTrip() {
    if (currentPickupLatLng == null) return;

    if (dropControllers.length == 1) {
      addDropLocation();
    } else {
      int lastIndex = dropControllers.length - 1;
      if (dropLatLngs[lastIndex] != null && dropLatLngs[lastIndex] != currentPickupLatLng) {
        addDropLocation();
      }
    }

    int newLastIndex = dropControllers.length - 1;
    setDropLocation(newLastIndex, currentPickupLatLng!, pickupController.text);
  }
}