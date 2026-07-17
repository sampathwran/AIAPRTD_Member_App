// ignore_for_file: spell_check_on_languages, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/core/providers/vehicle_provider.dart';
import 'package:aiaprtd_member/features/profile/member_status/membership_fee_status_check.dart';
import 'package:aiaprtd_member/features/profile/member_status/personal_kyc_checker.dart'; 
import 'package:aiaprtd_member/features/profile/member_status/vehicle_status_check.dart';

class OnlineStatusController {
  
  static Map<String, dynamic> checkSystemActive(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);

    final Map<String, dynamic> activeData = {};
    if (profileProvider.memberData != null) {
      try {
        activeData.addAll(Map<String, dynamic>.from(profileProvider.memberData as Map));
      } catch (_) {}
    }
    if (vehicleProvider.vehicleData != null) {
      activeData.addAll(vehicleProvider.vehicleData!);
    }

    final feeCheck = checkMembershipFeeStatus(activeData);
    if (feeCheck['isFeePaidValid'] == false) {
      return {'isActive': false, 'reason': feeCheck['reason'] ?? 'Membership fee verification required.'};
    }

    final kycCheck = PersonalKYCChecker.checkKYCStatus(activeData);
    if (kycCheck['isVerified'] == false) {
      return {'isActive': false, 'reason': kycCheck['reason'] ?? 'Personal profile or face verification pending.'};
    }

    final vehicleCheck = checkMemberSystemStatus(activeData);
    if (vehicleCheck['isActive'] == false) {
      return {'isActive': false, 'reason': vehicleCheck['reason'] ?? 'Vehicle verification pending.'};
    }

    return {'isActive': true, 'reason': 'Active'};
  }
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

    // --- 1. No checks needed when going OFFLINE ---
    if (currentOnlineState) {
      bool success = await profileProvider.toggleDriverStatus(false);
      if (context.mounted && success) {
        onStateChanged();
      }
      return;
    }

    // --- 2. Check status when going ONLINE (Same logic as Badge) ---

    // Combine Member Data + Vehicle Data like StatusBadgeWidget
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

    // Check 1: Fee Status (Is payment done?)
    final feeCheck = checkMembershipFeeStatus(activeData);
    if (feeCheck['isFeePaidValid'] == false) {
      isSystemActive = false;
      errorMessage = feeCheck['reason'] ?? 'Membership fee verification required.';
    }

    // Check 2: KYC Status (Is verification done?)
    if (isSystemActive) { // Only check if previous is active
      final kycCheck = PersonalKYCChecker.checkKYCStatus(activeData);
      if (kycCheck['isVerified'] == false) {
        isSystemActive = false;
        errorMessage = kycCheck['reason'] ?? 'Personal profile or face verification pending.';
      }
    }

    // Check 3: Vehicle/System Status (Are vehicle details correct?)
    if (isSystemActive) {
      final vehicleCheck = checkMemberSystemStatus(activeData);
      if (vehicleCheck['isActive'] == false) {
        isSystemActive = false;
        errorMessage = vehicleCheck['reason'] ?? 'Vehicle verification pending.';
      }
    }

    // --- 3. If checks fail (Block going ONLINE) ---
    if (!isSystemActive) {
      debugPrint("❌ BLOCKED: $errorMessage");

      // Blink the StatusBadgeWidget
      if (badgeKey != null && badgeKey.currentState != null) {
        (badgeKey.currentState as dynamic).triggerReasonVisibility();
      }

      if (playSound != null) await playSound('sounds/error_sound.mp3');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage), // Show the specific error
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return; // Stop execution here
    }

    // --- 4. If all checks pass (Go ONLINE) ---
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