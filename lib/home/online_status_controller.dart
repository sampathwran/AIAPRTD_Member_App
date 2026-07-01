// ignore_for_file: spell_check_on_languages, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
import '../providers/vehicle_provider.dart';
import '../profile/membership_fee_status_check.dart';
import '../profile/personal_kyc_checker.dart'; // 💡 KYC Checker එකත් import කරගන්න
import '../profile/vehicle_status_check.dart';

class OnlineStatusController {
  static Future<void> toggleStatus({
    required BuildContext context,
    required bool currentOnlineState,
    required VoidCallback onStateChanged,
    GlobalKey<State>? badgeKey,
    Future<void> Function(String)? playSound,
    dynamic currentPosition,
    double? currentHeading,
  }) async {

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);

    if (profileProvider.isLocalLoading) return;

    final data = profileProvider.memberData;

    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile data syncing. Please wait!"), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    // --- 1. OFFLINE යද්දී කිසිම චෙක් එකක් ඕනේ නෑ ---
    if (currentOnlineState) {
      bool success = await profileProvider.toggleDriverStatus(false);
      if (context.mounted && success) {
        onStateChanged();
      }
      return;
    }

    // --- 2. ONLINE යද්දී STATUS එක චෙක් කිරීම (Badge ලොජික් එකමයි) ---

    // StatusBadgeWidget එකේ වගේම Member Data + Vehicle Data එකතු කරගන්නවා
    final Map<String, dynamic> activeData = {};
    try {
      activeData.addAll(Map<String, dynamic>.from(data as Map));
    } catch (e) {
      debugPrint("Warning: memberData is not a Map.");
    }

    if (vehicleProvider.vehicleData != null) {
      activeData.addAll(vehicleProvider.vehicleData!);
    }

    bool isSystemActive = true;
    String errorMessage = "";

    // 🔴 Check 1: Fee Status (ගෙවීම් කරලාද?)
    final feeCheck = checkMembershipFeeStatus(activeData);
    if (feeCheck['isFeePaidValid'] == false) {
      isSystemActive = false;
      errorMessage = feeCheck['reason'] ?? 'Membership fee verification required.';
    }

    // 🔴 Check 2: KYC Status (සත්‍යාපනය කරලාද?)
    if (isSystemActive) { // කලින් එක හරි නම් විතරක් මේක බලනවා
      final kycCheck = PersonalKYCChecker.checkKYCStatus(activeData);
      if (kycCheck['isVerified'] == false) {
        isSystemActive = false;
        errorMessage = kycCheck['reason'] ?? 'Personal profile or face verification pending.';
      }
    }

    // 🔴 Check 3: Vehicle/System Status (වාහනේ විස්තර හරිද?)
    if (isSystemActive) {
      final vehicleCheck = checkMemberSystemStatus(activeData);
      if (vehicleCheck['isActive'] == false) {
        isSystemActive = false;
        errorMessage = vehicleCheck['reason'] ?? 'Vehicle verification pending.';
      }
    }

    // --- 3. පරීක්ෂණ අසමත් නම් (ONLINE යන්න දෙන්නේ නෑ) ---
    if (!isSystemActive) {
      debugPrint("❌ BLOCKED: $errorMessage");

      // අර StatusBadgeWidget එක blink කරවනවා (triggerReasonVisibility)
      if (badgeKey != null && badgeKey.currentState != null) {
        (badgeKey.currentState as dynamic).triggerReasonVisibility();
      }

      if (playSound != null) await playSound('sounds/error_sound.mp3');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage), // මොකක්ද අවුල කියලා යටින් පෙන්වනවා
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return; // ⛔ මෙතනින් නවතිනවා!
    }

    // --- 4. පරීක්ෂණ සියල්ල සමත් නම් (ONLINE යනවා) ---
    if (playSound != null) await playSound('sounds/go_sound.mp3');

    bool success = await profileProvider.toggleDriverStatus(true);

    if (!context.mounted) return;

    if (success) {
      if (currentPosition != null && currentHeading != null) {
        await profileProvider.updateLiveLocation(
          currentPosition.latitude,
          currentPosition.longitude,
          currentHeading,
        );
      }
      onStateChanged();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connection error. Failed to go online!"), behavior: SnackBarBehavior.floating),
      );
    }
  }
}