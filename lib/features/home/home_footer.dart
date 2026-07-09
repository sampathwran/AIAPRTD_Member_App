// ignore_for_file: spell_check_on_languages, spell_check_on_word
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: depend_on_referenced_packages
import 'package:audioplayers/audioplayers.dart';

import 'package:aiaprtd_member/core/providers/profile_provider.dart';

// Shortcuts and Widgets
import 'package:aiaprtd_member/features/home/scheduled_button.dart';
import 'package:aiaprtd_member/features/home/create_job_button.dart';
import 'package:aiaprtd_member/features/home/road_pickup_button.dart';
import 'package:aiaprtd_member/features/home/acceptance_widget.dart';
import 'package:aiaprtd_member/features/home/rating_widget.dart';
import 'package:aiaprtd_member/features/home/cancellation_widget.dart';
import 'package:aiaprtd_member/features/profile/status_badge_widget.dart';
import 'package:aiaprtd_member/features/profile/membership_fee_status_check.dart';
import 'package:aiaprtd_member/features/profile/personal_kyc_checker.dart';
import 'package:aiaprtd_member/features/profile/vehicle_status_check.dart';
import 'package:aiaprtd_member/core/providers/vehicle_provider.dart';

class HomeFooter extends StatefulWidget {
  final bool isSharingLocation;
  final VoidCallback onToggleLocation;
  final GlobalKey<State>? badgeKey;

  const HomeFooter({
    super.key,
    required this.isSharingLocation,
    required this.onToggleLocation,
    this.badgeKey,
  });

  @override
  State<HomeFooter> createState() => _HomeFooterState();
}

class _HomeFooterState extends State<HomeFooter> {
  late final AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playInternalSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/off_sound.mp3'));
    } catch (_) {
      try {
        await _audioPlayer.play(AssetSource('assets/sounds/off_sound.mp3'));
      } catch (e) {
        debugPrint("❌ In-built Audio Player Error: $e");
      }
    }
  }

  void _handleCreateBooking(BuildContext context) {
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

    String? blockReason;

    final kycCheck = PersonalKYCChecker.checkKYCStatus(activeData);
    if (kycCheck['isVerified'] == false) {
      blockReason = kycCheck['reason']?.toString() ?? 'Personal profile or face verification pending.';
    }

    if (blockReason == null) {
      final vehicleCheck = checkMemberSystemStatus(activeData);
      if (vehicleCheck['isActive'] == false) {
        blockReason = vehicleCheck['reason']?.toString() ?? 'Vehicle verification pending.';
      }
    }

    if (blockReason != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Action Required", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text("Please complete the following requirements before creating a booking:\n\n$blockReason"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    final feeStatus = checkMembershipFeeStatus(activeData);
    if (feeStatus['isFeePaidValid'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Reminder: ${feeStatus['reason']} Please settle it soon."),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    Navigator.pushNamed(context, '/create-job');
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.14,
      minChildSize: 0.14,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.08),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 50, height: 6,
                    decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10)
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Consumer<ProfileProvider>(
                  builder: (context, profileProvider, child) {
                    final data = profileProvider.memberData;
                    if (data == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: StatusBadgeWidget(
                        key: widget.badgeKey,
                        memberData: data,
                      ),
                    );
                  },
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: widget.isSharingLocation ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        boxShadow: widget.isSharingLocation
                            ? [BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 6)]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isSharingLocation ? "You're online" : "You're offline",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: widget.isSharingLocation ? Colors.green.shade700 : const Color(0xFF64748B)
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ==========================================================
                // 📊 STATISTICS SECTION
                // ==========================================================
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDarkMode ? const Color(0xFF333333) : const Color(0xFFF1F5F9)),
                  ),
                  child: Consumer<ProfileProvider>(
                    builder: (context, profileProvider, child) {
                      final memberData = profileProvider.memberData ?? {};

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          AcceptanceWidget(memberData: memberData),
                          Container(width: 1, height: 30, color: isDarkMode ? Colors.grey[700] : const Color(0xFFE2E8F0)),
                          RatingWidget(memberData: memberData),
                          Container(width: 1, height: 30, color: isDarkMode ? Colors.grey[700] : const Color(0xFFE2E8F0)),
                          CancellationWidget(memberData: memberData),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),
                Divider(height: 30, thickness: 1, color: isDarkMode ? Colors.grey[800] : const Color(0xFFF1F5F9)),

                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Shortcuts", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : const Color(0xFF0F172A))),
                  ),
                ),

                ScheduledButton(onTap: () => Navigator.pushNamed(context, '/scheduled')),
                Divider(indent: 20, endIndent: 20, color: isDarkMode ? Colors.grey[850] : const Color(0xFFF8FAFC)),
                CreateJobButton(onTap: () => _handleCreateBooking(context)),
                Divider(indent: 20, endIndent: 20, color: isDarkMode ? Colors.grey[850] : const Color(0xFFF8FAFC)),
                RoadPickupButton(onTap: () => Navigator.pushNamed(context, '/road-pickup')),

                Consumer<ProfileProvider>(
                  builder: (context, profileProvider, child) {
                    if (!widget.isSharingLocation) return const SizedBox(height: 32);

                    return Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 32),
                      child: GestureDetector(
                        onTap: profileProvider.isLocalLoading
                            ? null
                            : () async {
                          final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
                          await _playInternalSound();

                          bool success = await profileProvider.toggleDriverStatus(false);

                          if (success) {
                            widget.onToggleLocation();
                          } else {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                  content: Text("Failed to go offline. Try again! ❌"),
                                  behavior: SnackBarBehavior.floating
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade400, Colors.red.shade600],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Center(
                            child: profileProvider.isLocalLoading
                                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                                : const Text(
                              "OFF",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}