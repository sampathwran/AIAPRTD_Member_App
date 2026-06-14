import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class VehicleInfoProvider with ChangeNotifier {
  Map<String, dynamic>? _vehicleData;
  bool _isLoading = false;

  Map<String, dynamic>? get vehicleData => _vehicleData;
  bool get isLoading => _isLoading;

  // 1. Vehicle දත්ත ලබා ගැනීම
  Future<void> fetchVehicleData(String membershipNo) async {
    _isLoading = true;
    notifyListeners();
    try {
      var doc = await FirebaseFirestore.instance.collection('vehicles').doc(membershipNo).get();
      if (doc.exists) {
        _vehicleData = doc.data() as Map<String, dynamic>;
      } else {
        _vehicleData = null;
      }
    } catch (e) {
      debugPrint("Error fetching vehicle data: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  // 2. අලුත් වාහනයක් සඳහා ඉල්ලීමක් යැවීම
  Future<void> requestAddVehicle(String membershipNo, Map<String, dynamic> details) async {
    try {
      await FirebaseFirestore.instance.collection('vehicles').doc(membershipNo).set({
        'membershipNo': membershipNo,
        'details': details,
        'status': 'pending',
        'canEdit': true,
        'documents': [
          {'status': 'empty', 'reason': '', 'url': ''},
          {'status': 'empty', 'reason': '', 'url': ''},
          {'status': 'empty', 'reason': '', 'url': ''},
          {'status': 'empty', 'reason': '', 'url': ''},
        ],
        'vehiclePhotos': {},
        'timestamp': FieldValue.serverTimestamp(),
      });
      await fetchVehicleData(membershipNo);
    } catch (e) {
      debugPrint("Error in requestAddVehicle: $e");
    }
  }

  // 3. Document Status එක සහ Reason එක update කිරීම
  Future<void> updateDocumentStatus(String membershipNo, int docIndex, String newStatus, String? reason) async {
    if (_vehicleData != null) {
      List documents = List.from(_vehicleData!['documents'] ?? []);
      if (docIndex >= 0 && docIndex < documents.length) {
        documents[docIndex]['status'] = newStatus;
        documents[docIndex]['reason'] = reason;

        bool isPending = (newStatus == 'pending');

        await FirebaseFirestore.instance.collection('vehicles').doc(membershipNo).update({
          'documents': documents,
          'canEdit': !isPending,
        });

        // දත්ත Local එකේ Update කරලා listeners දැනුවත් කරන්න
        _vehicleData!['documents'] = documents;
        _vehicleData!['canEdit'] = !isPending;
        notifyListeners();
      }
    }
  }

  // 4. Vehicle Photo එක Storage එකට Upload කර Firestore එක Update කිරීම
  Future<void> uploadVehiclePhoto(String membershipNo, String label, String filePath) async {
    try {
      File imageFile = File(filePath);
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('vehicle_photos/$membershipNo/$label.jpg');

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      if (_vehicleData != null) {
        Map<String, dynamic> currentPhotos = Map<String, dynamic>.from(_vehicleData!['vehiclePhotos'] ?? {});
        currentPhotos[label] = {
          'url': imageUrl,
          'status': 'pending'
        };

        await FirebaseFirestore.instance.collection('vehicles').doc(membershipNo).update({
          'vehiclePhotos': currentPhotos,
          'canEdit': false,
        });

        // දත්ත අලුත් කරලා UI එක Refresh කරන්න
        _vehicleData!['vehiclePhotos'] = currentPhotos;
        _vehicleData!['canEdit'] = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error uploading photo: $e");
    }
  }

  // 5. Compliance Document එකක් Storage එකට Upload කර Firestore එක Update කිරීම
  Future<void> uploadDocument(String membershipNo, int docIndex, String filePath) async {
    try {
      File imageFile = File(filePath);
      String fileName = "doc_$docIndex.jpg";
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('compliance_docs/$membershipNo/$fileName');

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      if (_vehicleData != null) {
        List documents = List.from(_vehicleData!['documents'] ?? []);

        documents[docIndex] = {
          'status': 'pending',
          'reason': '',
          'url': downloadUrl
        };

        await FirebaseFirestore.instance.collection('vehicles').doc(membershipNo).update({
          'documents': documents,
          'canEdit': false,
        });

        // මෙතන අනිවාර්යයෙන්ම local data update වෙන්න ඕනේ
        _vehicleData!['documents'] = documents;
        _vehicleData!['canEdit'] = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error uploading document: $e");
    }
  }
}