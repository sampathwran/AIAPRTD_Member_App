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
  // 🚀 Step 1: Sending FORM and ID CARDS
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

      // 💡 NEW FIX: Used Set instead of Update.
      // So no error will occur even if the Document didn't exist before.
      batch.set(memberRef, {
        'kycApprovalStatus': 'pending',
        'faceKycStatus': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

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
  // 📸 🎯 Step 2: FACE UPLOAD (Send to Admin for Approval)
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

      // 💡 Fetch raw data from web_sync_member to include in the verify_kyc request
      final QuerySnapshot<Map<String, dynamic>> webSyncSnapshot = await _firestore
          .collection('web_sync_member')
          .where('membershipNo', isEqualTo: membershipNo)
          .limit(1)
          .get();

      Map<String, dynamic> rawData = {};
      if (webSyncSnapshot.docs.isNotEmpty) {
        rawData = webSyncSnapshot.docs.first.data();
      }

      final WriteBatch batch = _firestore.batch();

      // Send to verify_kyc for Admin Approval!
      batch.set(
        _firestore.collection('verify_kyc').doc(membershipNo),
        {
          ...rawData, // Include all the synced details for admin to review
          'membershipNo': membershipNo,
          'faceVerificationUrl': faceUrl,
          'kycApprovalStatus': 'pending', // 🔴 Waiting for admin
          'faceKycStatus': 'pending',     // 🔴 Waiting for admin
          'submittedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Update the app's member document so the UI knows it's pending
      batch.set(
        _firestore.collection('member').doc(documentId),
        {
          'kycApprovalStatus': 'pending',
          'faceKycStatus': 'pending',
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
      // Removed SetOptions(merge: true).
      // Otherwise the old approved/rejected status would merge
      // and it might cause an auto approve issue.
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