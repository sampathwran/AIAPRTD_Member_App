// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// Provide the correct Path for your Providers here
import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/main.dart'; // For navigatorKey
// import '../providers/vehicle_provider.dart'; // Turn this on if you have a vehicle provider

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================================================================
  // 🔐 CENTRAL LOGOUT & SESSION CLEANER ENGINE
  // =========================================================================
  static Future<void> logout(BuildContext context) async {
    try {
      debugPrint("🔄 [AuthService] Logout session triggered. Cleaning memory...");

      // 1. Clear all data and Live Streams (Listeners) in ProfileProvider
      // Must use listen: false because it is called outside a widget
      Provider.of<ProfileProvider>(context, listen: false).clearUserData();

      // 2. (Optional) Clear vehicle provider if available:
      // Provider.of<VehicleProvider>(context, listen: false).clearVehicleData();

      // 3. Actual logout from Firebase Auth
      await _auth.signOut();

      // 4. Navigate using the navigatorKey from main.dart
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Logged out successfully! All sessions cleared. 🔐"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.blueGrey,
        ),
      );
    } catch (e) {
      debugPrint("❌ [AuthService] Critical Logout Error: $e");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error logging out: $e ❌"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}