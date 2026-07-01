// ignore_for_file: spell_check_on_languages

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class KYCProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLocalLoading = false;
  bool get isLocalLoading => _isLocalLoading;

  // ==========================================================
  // ☁️ 🛠️ REAL FIREBASE STORAGE UPLOAD ENGINE
  // ==========================================================
  Future<String> _uploadToFirebaseStorage(File file, String path) async {
    try {
      final Reference storageRef = FirebaseStorage.instance.ref().child(path);
      final UploadTask uploadTask = storageRef.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("❌ Firebase Storage Upload Internal Error: $e");
      rethrow;
    }
  }

  // ==========================================================
  // 🚀 පියවර 1: FORM එක සහ ID CARDS යැවීම
  // ==========================================================
  Future<bool> submitOneTimeRegistrationDetails({
    required String membershipNo,
    required String fullName,
    required String email,
    required String mobile,
    required String nic,
    required String address,
    required String dob,
    required String religion,
    required String gender,
    required File idFrontFile,
    required File idBackFile,
    required String documentId,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    _isLocalLoading = true;
    notifyListeners();

    try {
      final urls = await Future.wait([
        _uploadToFirebaseStorage(
          idFrontFile,
          'id_cards/${membershipNo}_front.jpg',
        ),
        _uploadToFirebaseStorage(
          idBackFile,
          'id_cards/${membershipNo}_back.jpg',
        ),
      ]);

      final WriteBatch batch = _firestore.batch();

      final DocumentReference verifyRef =
      _firestore.collection('verify_kyc').doc(membershipNo);

      batch.set(verifyRef, {
        'membershipNo': membershipNo,
        'fullName': fullName,
        'user_email': email,
        'mobile': mobile,
        'nic': nic,
        'address': address,
        'dob': dob,
        'religion': religion,
        'gender': gender,
        'idCardFrontUrl': urls[0],
        'idCardBackUrl': urls[1],
        'faceVerificationUrl': '',
        'kycApprovalStatus': 'pending',
        'faceKycStatus': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      final DocumentReference memberRef =
      _firestore.collection('member').doc(documentId);

      batch.update(memberRef, {
        'kycApprovalStatus': 'pending',
        'faceKycStatus': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      _isLocalLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint("❌ KYC Submission Error: $e");

      _isLocalLoading = false;
      notifyListeners();

      return false;
    }
  }

  // ==========================================================
  // 📸 🎯 පියවර 2: FACE UPLOAD
  // ==========================================================
  Future<bool> saveFaceVerification(
      String membershipNo,
      String documentId,
      File faceFile,
      ) async {
    _isLocalLoading = true;
    notifyListeners();

    try {
      final String path = 'kyc_selfies/$membershipNo.jpg';
      final String faceUrl = await _uploadToFirebaseStorage(faceFile, path);

      final WriteBatch batch = _firestore.batch();

      batch.set(
        _firestore.collection('verify_kyc').doc(membershipNo),
        {
          'faceVerificationUrl': faceUrl,
          'faceKycStatus': 'approved',
          'faceVerifiedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.set(
        _firestore.collection('member').doc(documentId),
        {
          'faceVerificationUrl': faceUrl,

          // ✅ Admin approval නැතුව auto approve
          'faceKycStatus': 'approved',
          'faceVerifiedAt': FieldValue.serverTimestamp(),

          // optional
          'personalKycStatus': 'approved',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      _isLocalLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint("❌ Face Verification Save Error: $e");

      _isLocalLoading = false;
      notifyListeners();

      return false;
    }
  }

  // ==========================================================
  // 🖼️ PROFILE IMAGE REQUEST MANAGER
  // ==========================================================
  Future<bool> submitProfileImageRequest(
      String memNo,
      File imageFile,
      ) async {
    _isLocalLoading = true;
    notifyListeners();

    try {
      final String path = 'profile_requests/$memNo.jpg';
      final String imageUrl = await _uploadToFirebaseStorage(imageFile, path);

      // ✅ IMPORTANT FIX:
      // SetOptions(merge: true) අයින් කළා.
      // එහෙම නොකළොත් පරණ approved/rejected status එක merge වෙලා
      // auto approve වගේ issue එන්න පුළුවන්.
      await _firestore.collection('profile_image_requests').doc(memNo).set({
        'membershipNo': memNo,
        'newImageUrl': imageUrl,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'approvedAt': null,
        'approvedBy': null,
        'rejectedAt': null,
        'rejectedBy': null,
        'rejectReason': null,
      });

      _isLocalLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint("❌ Profile Request Error: $e");

      _isLocalLoading = false;
      notifyListeners();

      return false;
    }
  }
}