// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/core/providers/vehicle_provider.dart';
import 'package:aiaprtd_member/features/profile/member_status/vehicle_status_check.dart';
import 'package:aiaprtd_member/features/profile/member_status/membership_fee_status_check.dart';

class OnlineButtonWidget extends StatelessWidget {
  final bool isSharingLocation;
  final double currentHeading;
  final dynamic currentPosition;
  final Function(bool) onStatusChanged;
  final Future<void> Function(String) playSound;
  final GlobalKey<State>? footerBadgeKey;

  const OnlineButtonWidget({
    super.key,
    required this.isSharingLocation,
    required this.currentHeading,
    required this.currentPosition,
    required this.onStatusChanged,
    required this.playSound,
    this.footerBadgeKey,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        final bool isOnline = isSharingLocation;

        if (isOnline) return const SizedBox.shrink();

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            debugPrint("\n🚀 === GO BUTTON PRESSED ===");

            if (provider.isLocalLoading) {
              debugPrint("❌ BLOCKED 0: provider.isLocalLoading is TRUE. (Still loading)");
              return;
            }
            debugPrint("✅ Check 0 Passed: Not loading locally.");

            final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);

            if (provider.memberData == null) {
              debugPrint("❌ BLOCKED 1: provider.memberData is NULL.");
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text("Loading profile data, please wait... ⏳"), behavior: SnackBarBehavior.floating),
              );
              return;
            }
            debugPrint("✅ Check 1 Passed: memberData is available.");

            // 1. Fee Status Check
            debugPrint("🔍 Checking Membership Fee Status...");
            final feeStatusResult = checkMembershipFeeStatus(provider.memberData!);
            debugPrint("   -> Fee Result: $feeStatusResult");

            if (feeStatusResult['isFeePaidValid'] == false) {
              debugPrint("❌ BLOCKED 2: Fee is not paid or invalid.");
              if (footerBadgeKey != null && footerBadgeKey!.currentState != null) {
                // ignore: avoid_dynamic_calls
                (footerBadgeKey!.currentState as dynamic).triggerReasonVisibility();
              }

              try {
                await playSound('sounds/error_sound.mp3');
              } catch (e) {
                debugPrint("   -> Sound play error: $e");
              }

              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text("Online features locked! Pending Membership Fee 💰"),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.redAccent,
                ),
              );
              return;
            }
            debugPrint("✅ Check 2 Passed: Fee Status is valid.");

            // Merge Data
            debugPrint("🔍 Merging Vehicle Data...");
            final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
            final Map<String, dynamic> combinedData = Map<String, dynamic>.from(provider.memberData!);

            if (vehicleProvider.vehicleData != null) {
              combinedData.addAll(vehicleProvider.vehicleData!);
              debugPrint("   -> Vehicle Data added to combinedData.");
            } else {
              debugPrint("   -> ⚠️ Warning: Vehicle Data is NULL.");
            }

            // 2. Vehicle & System Status Check
            debugPrint("🔍 Checking System Status (Vehicle etc.)...");
            final status = checkMemberSystemStatus(combinedData);
            debugPrint("   -> System Status Result: $status");

            if (!status['isActive']) {
              debugPrint("❌ BLOCKED 3: System Status is NOT active. Reason: ${status['reason']}");
              if (footerBadgeKey != null && footerBadgeKey!.currentState != null) {
                // ignore: avoid_dynamic_calls
                (footerBadgeKey!.currentState as dynamic).triggerReasonVisibility();
              }
              try {
                await playSound('sounds/error_sound.mp3');
              } catch (e) {
                debugPrint("   -> Sound play error: $e");
              }
              // Added SnackBar here for better visibility
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(status['reason']?.toString() ?? "System verification failed!"),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.redAccent,
                ),
              );
              return;
            }
            debugPrint("✅ Check 3 Passed: System Status is active.");

            // 3. Play Sound
            debugPrint("🔊 Playing GO sound...");
            try {
              await playSound('sounds/go_sound.mp3');
            } catch (e) {
              debugPrint("   -> GO Sound play error: $e");
            }

            // 4. Online Status Update
            debugPrint("🌐 Calling provider.toggleDriverStatus(true)...");
            bool success = await provider.toggleDriverStatus(true);
            debugPrint("   -> toggleDriverStatus returned: $success");

            if (success) {
              debugPrint("✅ SUCCESS: Driver went online!");
              if (currentPosition != null) {
                debugPrint("📍 Updating Live Location...");
                await provider.updateLiveLocation(
                  currentPosition.latitude,
                  currentPosition.longitude,
                  currentHeading,
                );
              } else {
                debugPrint("⚠️ Warning: currentPosition is NULL, location not updated.");
              }
              onStatusChanged(true);
            } else {
              debugPrint("❌ BLOCKED 4: Failed to update status on Firebase.");
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text("Failed to go online. Try again! ❌"), behavior: SnackBarBehavior.floating),
              );
            }
            debugPrint("🏁 === GO BUTTON TAP FINISHED ===\n");
          },
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade300, Colors.blue.shade600],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Center(
              child: provider.isLocalLoading
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                  : const Text(
                "GO",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}