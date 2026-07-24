// ignore_for_file: spell_check_on_languages, spell_check_on_word

import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class VehicleProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ==========================================
  // 1. MEMBER VEHICLE MANAGEMENT
  // ==========================================
  Map<String, dynamic>? _vehicleData;
  bool _isLoading = false;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _vehicleSubscription;
  String? _currentMembershipNo;

  Map<String, dynamic>? get vehicleData => _vehicleData;
  bool get isLoading => _isLoading;

  Future<void> fetchVehicleData(String membershipNo) async {
    final String cleanMembershipNo = membershipNo.trim();
    if (cleanMembershipNo.isEmpty || cleanMembershipNo == 'N/A') {
      _vehicleData = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    if (_currentMembershipNo == cleanMembershipNo && _vehicleSubscription != null) {
      return;
    }
    await _vehicleSubscription?.cancel();
    _currentMembershipNo = cleanMembershipNo;
    _isLoading = true;
    notifyListeners();

    _vehicleSubscription = _firestore.collection('vehicles').doc(cleanMembershipNo).snapshots().listen(
          (snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          _vehicleData = Map<String, dynamic>.from(snapshot.data()!);
        } else {
          _vehicleData = null;
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _vehicleData = null;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> requestAddVehicle(String membershipNo, Map<String, dynamic> details) async {
    try {
      await _firestore.collection('vehicles').doc(membershipNo).set({
        'membershipNo': membershipNo,
        'details': details,
        'status': 'pending',
        'canEdit': true,
        'documents': [
          {'status': 'empty', 'reason': '', 'url': ''},
          {'status': 'empty', 'reason': '', 'url': ''},
          {'status': 'empty', 'reason': '', 'url': ''},
          {'status': 'empty', 'reason': '', 'url': ''},
          {'status': 'empty', 'reason': '', 'url': ''},
        ],
        'vehiclePhotos': {},
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await fetchVehicleData(membershipNo);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateDocumentStatus(String membershipNo, int docIndex, String newStatus, String? reason) async {
    try {
      final DocumentReference<Map<String, dynamic>> reference = _firestore.collection('vehicles').doc(membershipNo);
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await reference.get();
      if (!snapshot.exists || snapshot.data() == null) throw Exception('Vehicle data not found');

      final List<dynamic> documents = List<dynamic>.from(snapshot.data()!['documents'] ?? []);
      if (docIndex < 0 || docIndex >= documents.length) throw Exception('Invalid document index');

      final Map<String, dynamic> document = documents[docIndex] is Map
          ? Map<String, dynamic>.from(documents[docIndex])
          : <String, dynamic>{};
      document['status'] = newStatus;
      document['reason'] = reason ?? '';
      documents[docIndex] = document;

      await reference.update({'documents': documents});
    } catch (error) {
      rethrow;
    }
  }

  Future<void> uploadVehiclePhoto(String membershipNo, String label, String filePath) async {
    try {
      final File imageFile = File(filePath);
      final Reference storageReference = _storage.ref().child('vehicle_photos/$membershipNo/$label.jpg');
      final TaskSnapshot uploadSnapshot = await storageReference.putFile(imageFile);
      final String imageUrl = await uploadSnapshot.ref.getDownloadURL();

      final WriteBatch batch = _firestore.batch();
      
      batch.update(_firestore.collection('vehicles').doc(membershipNo), {
        'vehiclePhotos.$label.url': imageUrl,
        'vehiclePhotos.$label.status': 'pending',
        'vehiclePhotos.$label.reason': '',
        'status': 'pending', // 💡 Send back to Admin request queue
      });

      // Update new Single Source of Truth collection
      batch.set(_firestore.collection('member_inactive_reasons').doc(membershipNo), {
        label: 'pending_approval',
        'status': 'INACTIVE',
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> uploadDocument(String membershipNo, int docIndex, String filePath) async {
    try {
      final File imageFile = File(filePath);
      final Reference storageReference = _storage.ref().child('compliance_docs/$membershipNo/doc_$docIndex.jpg');
      final TaskSnapshot uploadSnapshot = await storageReference.putFile(imageFile);
      final String downloadUrl = await uploadSnapshot.ref.getDownloadURL();
      final DocumentReference<Map<String, dynamic>> reference = _firestore.collection('vehicles').doc(membershipNo);
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await reference.get();

      if (!snapshot.exists || snapshot.data() == null) throw Exception('Vehicle data not found');
      final List<dynamic> documents = List<dynamic>.from(snapshot.data()!['documents'] ?? []);

      // 💡 FIXED: Added { } block to the while loop
      while (documents.length < 5) {
        documents.add({'status': 'empty', 'reason': '', 'url': ''});
      }

      if (docIndex < 0 || docIndex >= documents.length) throw Exception('Invalid document index');

      documents[docIndex] = {'status': 'pending', 'reason': '', 'url': downloadUrl};
      
      final WriteBatch batch = _firestore.batch();
      
      batch.update(reference, {
        'documents': documents,
        'status': 'pending', // 💡 Send back to Admin request queue
      });

      String fieldName = '';
      if (docIndex == 0) fieldName = 'revenue_licence';
      else if (docIndex == 1) fieldName = 'insurance_policy';
      else if (docIndex == 2) fieldName = 'vehicle_registration_document';
      else if (docIndex == 3 || docIndex == 4) fieldName = 'driving_licence';

      if (fieldName.isNotEmpty) {
        batch.set(_firestore.collection('member_inactive_reasons').doc(membershipNo), {
          fieldName: 'pending_approval',
          'status': 'INACTIVE',
        }, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> clearVehicleData() async {
    await _vehicleSubscription?.cancel();
    _vehicleSubscription = null;
    _currentMembershipNo = null;
    _vehicleData = null;
    _isLoading = false;
    notifyListeners();
  }


  // ==========================================
  // 2. VEHICLE CATEGORIES & FARES
  // ==========================================
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> get vehicles => _vehicles;

  bool _isCategoriesLoading = false;
  bool get isCategoriesLoading => _isCategoriesLoading;

  int _selectedVehicleIndex = 0;
  int get selectedVehicleIndex => _selectedVehicleIndex;

  StreamSubscription<QuerySnapshot>? _ratesSubscription;

  Future<void> fetchVehiclesFromFirebase() async {
    _isCategoriesLoading = true;
    notifyListeners();

    final List<String> customOrder = [
      'budget',
      'mini',
      'sedan',
      '6_seater',
      '9_seater',
      '14_seater',
    ];

    try {
      await _ratesSubscription?.cancel();

      _ratesSubscription = _firestore.collection('rates').snapshots().listen(
              (snapshot) {
            if (snapshot.docs.isNotEmpty) {
              _vehicles = snapshot.docs.map((doc) {
                // 💡 FIXED: Removed unnecessary cast. doc.data() is already a Map.
                final data = doc.data();
                return {
                  "id": doc.id,
                  "name": data['name'] ?? 'Unknown',
                  "baseFare": (data['baseFare'] ?? 0).toDouble(),
                  "baseDistance": (data['baseDistance'] ?? 0).toDouble(),
                  "perKm": (data['perKm'] ?? 0).toDouble(),
                  "perMinute": (data['perMinute'] ?? 0).toDouble(),
                  "nightFarePct": (data['nightFarePct'] ?? 0).toDouble(),
                  "peakFarePct": (data['peakFarePct'] ?? 0).toDouble(),
                  "image": data['image'] ?? '',
                };
              }).toList();

              _vehicles.sort((a, b) {
                int indexA = customOrder.indexOf(a['id']);
                int indexB = customOrder.indexOf(b['id']);

                if (indexA == -1) indexA = 999;
                if (indexB == -1) indexB = 999;

                return indexA.compareTo(indexB);
              });

            } else {
              _vehicles = _getDummyCategories();
            }

            _isCategoriesLoading = false;
            notifyListeners();
          },
          onError: (error) {
            debugPrint("❌ Error listening to rates: $error");
            _vehicles = _getDummyCategories();
            _isCategoriesLoading = false;
            notifyListeners();
          }
      );
    } catch (e) {
      debugPrint("Error setting up rates stream: $e");
      _vehicles = _getDummyCategories();
      _isCategoriesLoading = false;
      notifyListeners();
    }
  }

  void selectVehicle(int index) {
    _selectedVehicleIndex = index;
    notifyListeners();
  }

  double calculateEstimateFare(double distanceKm, int vehicleIndex) {
    if (_vehicles.isEmpty || vehicleIndex >= _vehicles.length) return 0.0;

    final vehicle = _vehicles[vehicleIndex];
    double baseFare = vehicle['baseFare'];
    double baseDistance = vehicle['baseDistance'] ?? 0;
    double perKm = vehicle['perKm'];

    if (distanceKm <= baseDistance) {
      return baseFare;
    } else {
      double extraDistance = distanceKm - baseDistance;
      return baseFare + (extraDistance * perKm);
    }
  }

  List<Map<String, dynamic>> _getDummyCategories() {
    return [
      {"id": "budget", "name": "Budget (Alto)", "baseFare": 500.0, "baseDistance": 4.0, "perKm": 115.0, "image": ""},
      {"id": "mini", "name": "Mini (Axia)", "baseFare": 600.0, "baseDistance": 4.0, "perKm": 120.0, "image": ""},
    ];
  }

  @override
  void dispose() {
    _vehicleSubscription?.cancel();
    _ratesSubscription?.cancel();
    super.dispose();
  }
}