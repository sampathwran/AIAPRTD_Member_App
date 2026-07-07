import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class AdsProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Fetch Categories Stream
  Stream<QuerySnapshot> getCategoriesStream() {
    return FirebaseFirestore.instance.collection('marketplace_categories').orderBy('name').snapshots();
  }

  // Fetch Ads Stream
  Stream<QuerySnapshot> getAdsStream(String? category) {
    Query query = FirebaseFirestore.instance.collection('marketplace_ads')
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true);
        
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    return query.limit(20).snapshots();
  }

  // Get Location
  Future<Map<String, dynamic>> getCurrentLocation() async {
    _setLoading(true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Location permissions are denied';
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      );
      
      // Temporary fix to avoid geocoding package errors
      String address = "Lat: ${position.latitude.toStringAsFixed(3)}, Lng: ${position.longitude.toStringAsFixed(3)}";

      return {
        'success': true,
        'lat': position.latitude,
        'lng': position.longitude,
        'address': address
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    } finally {
      _setLoading(false);
    }
  }

  // Post Ad
  Future<Map<String, dynamic>> postAd({
    required List<File> imageFiles,
    required String title,
    required String price,
    required String category,
    required String description,
    required double lat,
    required double lng,
    required String address,
    required bool allowBidding,
    required String membershipNo,
  }) async {
    _setLoading(true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "User not logged in";

      // Fallback if 'N/A' or empty
      String safeMembershipNo = (membershipNo.isEmpty || membershipNo == 'N/A') ? user.uid : membershipNo;

      // Fetch user's ad count to determine folder index (1, 2, 3...)
      int adCount = 0;
      try {
        final userAdsSnapshot = await FirebaseFirestore.instance
            .collection('marketplace_ads')
            .where('ownerId', isEqualTo: user.uid)
            .get();
        adCount = userAdsSnapshot.docs.length;
      } catch (e) {
        debugPrint("Error fetching ad count: $e");
      }
      int adIndex = adCount + 1;

      List<String> imageUrls = [];

      // Upload Images
      for (var file in imageFiles) {
        final storageRef = FirebaseStorage.instance.ref()
            .child('marketplace_images')
            .child(safeMembershipNo)
            .child(adIndex.toString())
            .child('${DateTime.now().millisecondsSinceEpoch}_${imageUrls.length}.jpg');
        await storageRef.putFile(file);
        final url = await storageRef.getDownloadURL();
        imageUrls.add(url);
      }

      // Save to Firestore
      await FirebaseFirestore.instance.collection('marketplace_ads').add({
        'title': title,
        'price': price,
        'description': description,
        'category': category,
        'imageUrls': imageUrls,
        'lat': lat,
        'lng': lng,
        'address': address,
        'ownerId': user.uid,
        'allowBidding': allowBidding,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    } finally {
      _setLoading(false);
    }
  }
}
