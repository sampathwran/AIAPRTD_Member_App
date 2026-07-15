// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLocalLoading = false;
  bool get isLocalLoading => _isLocalLoading;

  // ==========================================================
  // 📱 0. DEVICE ID GENERATION
  // ==========================================================
  Future<String> getPersistentDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('persistent_device_id');
    if (deviceId == null) {
      deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000000)}';
      await prefs.setString('persistent_device_id', deviceId);
    }
    return deviceId;
  }

  // ==========================================================
  // 📱 1. OTP REQUEST ENGINE FOR MOBILE NUMBER UPDATE
  // ==========================================================
  Future<bool> requestProfileUpdateOtp({
    required String documentId,
    required String newMobile
  }) async {
    _isLocalLoading = true;
    notifyListeners();

    try {
      int otp = 100000 + (DateTime.now().millisecondsSinceEpoch % 900000);

      // Insert Mobile OTP directly into a Temp Field in the Member doc
      await _firestore.collection('member').doc(documentId).set({
        'temp_otp': otp.toString(),
        'temp_mobile': newMobile,
        'otp_generated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _isLocalLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("❌ OTP Request Error: $e");
      _isLocalLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==========================================================
  // 🔐 2. OTP VERIFICATION & WP SYNCING
  // ==========================================================
  Future<bool> verifyOtpAndUpdateMobile({
    required String documentId,
    required String membershipNo,
    required String newMobile,
    required String otp
  }) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    _isLocalLoading = true;
    notifyListeners();

    try {
      var reqDoc = await _firestore.collection('member').doc(documentId).get();
      if (!reqDoc.exists) {
        _isLocalLoading = false;
        notifyListeners();
        return false;
      }

      final data = reqDoc.data()!;
      if (otp.trim() == (data['temp_otp'] ?? '').trim()) {

        // 1. Update Firestore Profile (Delete Temp data and save the new number)
        await _firestore.collection('member').doc(documentId).update({
          'mobile': newMobile,
          'temp_otp': FieldValue.delete(),
          'temp_mobile': FieldValue.delete(),
        });

        // 2. Real-time WordPress Sync
        final url = Uri.parse('https://aiaprtd.lk/wp-json/aiaprtd-sync/v1/update-profile');
        await http.post(url, body: {
          'membership_no': membershipNo,
          'mobile': newMobile
        }).catchError((e) {
          debugPrint("⚠️ WP Sync Error (Ignored): $e");
          return http.Response('Error', 500);
        });

        _isLocalLoading = false;
        notifyListeners();
        return true;
      }

      _isLocalLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint("❌ OTP Error: $e");
      _isLocalLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==========================================================
  // 🔐 3. SINGLE DEVICE ENFORCEMENT TOKEN UPDATER (NEW ✅)
  // ==========================================================

  // 💡 Method to insert new Device ID/Token into Firestore after successful login
  Future<bool> updateDeviceToken({
    required String collectionSource,
    required String documentId,
    required String currentDeviceToken,
  }) async {
    try {
      debugPrint("🔄 [AuthProvider] Updating device token for security sync...");
      
      final docRef = _firestore.collection(collectionSource).doc(documentId);
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        final previousToken = data['currentDeviceToken']?.toString();
        
        Map<String, dynamic> updates = {
          'currentDeviceToken': currentDeviceToken, // 👈 Insert new phone's ID into Firestore
        };
        
        // If the token is different, it means they logged in from a new device!
        // We reset face verification so they can't go online until they verify again.
        if (previousToken != null && previousToken.isNotEmpty && previousToken != currentDeviceToken) {
           debugPrint("⚠️ [AuthProvider] New device detected! Resetting face verification.");
           updates['faceKycStatus'] = 'pending';
           updates['isOnline'] = false; // Force them offline just in case
        }

        await docRef.update(updates);
        debugPrint("✅ [AuthProvider] Device token successfully bound to Firestore session.");
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ [AuthProvider] Device Token Sync Error: $e");
      return false;
    }
  }

  // =========================================================================
  // 🚪 4. SECURE LOGOUT LOGIC
  // =========================================================================
  Future<void> signOut() async {
    _isLocalLoading = true;
    notifyListeners();

    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("Sign Out Error: $e");
    } finally {
      _isLocalLoading = false;
      notifyListeners();
    }
  }
}