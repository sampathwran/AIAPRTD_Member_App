// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// 💡 ඔයාගේ Providers තියෙන නිවැරදි Path ටික මෙතනට දෙන්න මචං
import '../providers/profile_provider.dart';
// import '../providers/vehicle_provider.dart'; // 👈 වාහන ප්‍රොවයිඩර් එකක් තියෙනවා නම් මේකත් On කරගන්න

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================================================================
  // 🔐 CENTRAL LOGOUT & SESSION CLEANER ENGINE
  // =========================================================================
  static Future<void> logout(BuildContext context) async {
    try {
      debugPrint("🔄 [AuthService] Logout session triggered. Cleaning memory...");

      // 1️⃣ ProfileProvider එකේ දත්ත සහ Live Streams (Listeners) ඔක්කොම නැති කරලා දානවා
      // listen: false දාන්නම ඕනේ විජට් එකකට පිටින් කෝල් කරන නිසා
      Provider.of<ProfileProvider>(context, listen: false).clearUserData();

      // 2️⃣ (Optional) වාහන ප්‍රොවයිඩර් එකකුත් තියෙනවා නම් ඒකත් ක්ලීන් කරන්න:
      // Provider.of<VehicleProvider>(context, listen: false).clearVehicleData();

      // 3️⃣ Firebase Auth එකෙන් සැබෑ ලොග් අවුට් එක වෙනවා
      await _auth.signOut();

      if (!context.mounted) return;

      // 4️⃣ පරණ පිටු ඔක්කොම මකලා, ආපහු යන්න බැරි වෙන්නම Login එකට තල්ලු කරනවා
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login', // 👈 ඔයාගේ Login Route එක
            (route) => false,
      );

      // 🟢 සාර්ථකයි කියලා පොඩි මැසේජ් එකක් දාමු
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