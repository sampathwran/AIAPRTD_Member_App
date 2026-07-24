// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/features/home/online_status_controller.dart';

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

        return Container(
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () async {
                HapticFeedback.mediumImpact(); // Immediate tactile feedback
                debugPrint("\n🚀 === GO BUTTON PRESSED ===");

                await OnlineStatusController.toggleStatus(
                  context: context,
                  currentOnlineState: isOnline,
                  onStateChanged: () => onStatusChanged(!isOnline),
                  badgeKey: footerBadgeKey,
                  playSound: playSound,
                  currentPosition: currentPosition,
                  currentHeading: currentHeading,
                );
                
                debugPrint("🏁 === GO BUTTON TAP FINISHED ===\n");
              },
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
          ),
        );
      },
    );
  }
}