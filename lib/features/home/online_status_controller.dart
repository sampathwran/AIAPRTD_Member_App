// ignore_for_file: spell_check_on_languages, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/core/providers/vehicle_provider.dart';
import 'package:aiaprtd_member/core/providers/payment_provider.dart';
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
    
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    if (paymentProvider.paymentData != null) {
      final Map<String, dynamic> pData = Map<String, dynamic>.from(paymentProvider.paymentData!);
      pData.remove('payment_history');
      activeData.addAll(pData);
    }

    // 🔴 DEBUG PRINT ADDED
    debugPrint("🔍 [FEE CHECK] Starting Fee Evaluation...");
    debugPrint("🔍 [FEE CHECK] Payment History from ActiveData: ${activeData['payment_history']}");

    final feeCheck = checkMembershipFeeStatus(activeData);
    
    // 🔴 DEBUG PRINT ADDED
    debugPrint("🔍 [FEE CHECK] Result: isFeePaidValid=${feeCheck['isFeePaidValid']}, Reason=${feeCheck['reason']}");

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
  
  static String? _getFirstPendingReason(Map<String, dynamic> data) {
    if (data['admin_block_permanently'] == true) return 'Account Permanently Blocked by Admin';
    if (data['admin_block_temporarily'] == true) return 'Account Temporarily Blocked by Admin';
    if (data['membership_fee'] != 'approved') return 'Pending Membership Fee 💰';

    final Map<String, String> requiredDocs = {
      'profile_image': 'Profile Image',
      'id_card_image': 'National Identity Card (NIC)',
      'face_verification': 'Face Verification',
      'kyc_details': 'Personal KYC Details',
      'revenue_licence': 'Revenue License',
      'insurance_policy': 'Insurance Policy',
      'vehicle_registration_document': 'Registration Document',
      'driving_licence': 'Driving License',
      'vehicle_image_front': 'Vehicle Front Image',
      'vehicle_image_back': 'Vehicle Back Image',
      'vehicle_image_right_side': 'Vehicle Right Side Image',
      'vehicle_image_left_side': 'Vehicle Left Side Image',
      'vehicle_image_interior': 'Vehicle Interior Image',
    };

    // First check for missing or rejected documents so the user knows what to upload next
    for (var entry in requiredDocs.entries) {
      if (data[entry.key] == 'missing' || data[entry.key] == 'rejected' || data[entry.key] == null) {
         return 'Pending ${entry.value}';
      }
    }

    // If all documents are at least uploaded, check if any are waiting for admin approval
    for (var entry in requiredDocs.entries) {
      if (data[entry.key] != 'approved') {
         return 'Pending Admin Approval for ${entry.value}';
      }
    }

    return null;
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

    // --- 2. Check status when going ONLINE ---
    final String membershipNo = data['membershipNo']?.toString() ?? '';
    if (membershipNo.isEmpty) return;

    final docSnapshot = await FirebaseFirestore.instance.collection('member_inactive_reasons').doc(membershipNo).get();
    
    if (!docSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Member status not initialized. Please wait!"), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final reasonData = docSnapshot.data()!;
    String? errorMessage = _getFirstPendingReason(reasonData);

    debugPrint("🔍 [TOGGLE STATUS] Database Error Message: $errorMessage");

    // Perform a live evaluation just in case the database is out of sync (e.g., fee expired today)
    if (errorMessage == null) {
      debugPrint("🔍 [TOGGLE STATUS] Database says OK. Running Live Evaluation...");
      final liveStatus = checkSystemActive(context);
      debugPrint("🔍 [TOGGLE STATUS] Live Status Result: ${liveStatus['isActive']}, Reason: ${liveStatus['reason']}");
      if (liveStatus['isActive'] == false) {
        errorMessage = liveStatus['reason']?.toString();
      }
    }

    // --- 3. If checks fail (Block going ONLINE) ---
    if (errorMessage != null) {
      debugPrint("❌ BLOCKED: $errorMessage");

      // UI indicator that they cannot go online
      // We removed triggerReasonVisibility from StatusBadgeWidget.

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