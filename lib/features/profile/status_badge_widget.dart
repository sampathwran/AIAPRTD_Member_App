// ignore_for_file: spell_check_on_languages

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aiaprtd_member/features/profile/membership_fee_status_check.dart';
import 'package:aiaprtd_member/features/profile/personal_kyc_checker.dart';
import 'package:aiaprtd_member/features/profile/vehicle_status_check.dart';
import 'package:aiaprtd_member/core/providers/vehicle_provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';

class StatusBadgeWidget extends StatefulWidget {
  final Map<String, dynamic> memberData;
  final bool isProfileView;

  const StatusBadgeWidget({
    super.key,
    required this.memberData,
    this.isProfileView = false,
  });

  @override
  State<StatusBadgeWidget> createState() => _StatusBadgeWidgetState();
}

class _StatusBadgeWidgetState extends State<StatusBadgeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  Timer? _blinkTimer;
  Timer? _dismissTimer;

  bool _showErrorBlock = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.4,
    ).animate(_animationController);

    _showErrorBlock = widget.isProfileView;

    // Fetch vehicle data on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String? membershipNo =
      widget.memberData['membershipNo']?.toString();
      if (membershipNo != null && membershipNo.trim().isNotEmpty) {
        Provider.of<VehicleProvider>(context, listen: false)
            .fetchVehicleData(membershipNo);
      }
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _dismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _mergeMemberData(
      Map<String, dynamic>? vehicleData,
      ) {
    final Map<String, dynamic> activeData =
    Map<String, dynamic>.from(widget.memberData);

    if (vehicleData != null && vehicleData.isNotEmpty) {
      activeData.addAll(vehicleData);
    }

    return activeData;
  }

  Map<String, dynamic> _calculateStatus(
      Map<String, dynamic> activeData,
      ) {
    final Map<String, dynamic> feeCheck =
    checkMembershipFeeStatus(activeData);

    if (feeCheck['isFeePaidValid'] == false) {
      return {
        'isActive': false,
        'reason': feeCheck['reason'] ??
            'Membership fee verification required.',
        'source': 'fee',
      };
    }

    final Map<String, dynamic> kycCheck =
    PersonalKYCChecker.checkKYCStatus(activeData);

    if (kycCheck['isVerified'] == false) {
      return {
        'isActive': false,
        'reason': kycCheck['reason'] ??
            'Personal profile or face verification pending.',
        'source': 'kyc',
      };
    }

    final Map<String, dynamic> vehicleCheck =
    checkMemberSystemStatus(activeData);

    return {
      ...vehicleCheck,
      'source': 'vehicle',
    };
  }

  void triggerReasonVisibility() {
    if (widget.isProfileView) {
      return;
    }

    _blinkTimer?.cancel();
    _dismissTimer?.cancel();

    setState(() {
      _showErrorBlock = true;
    });

    _animationController.repeat(reverse: true);

    _blinkTimer = Timer(
      const Duration(seconds: 3),
          () {
        if (!mounted) {
          return;
        }

        _animationController.stop();
        _animationController.reset();
      },
    );

    _dismissTimer = Timer(
      const Duration(seconds: 10),
          () {
        if (!mounted) {
          return;
        }

        setState(() {
          _showErrorBlock = false;
        });
      },
    );
  }

  @override
  void didUpdateWidget(
      covariant StatusBadgeWidget oldWidget,
      ) {
    super.didUpdateWidget(oldWidget);

    if (widget.isProfileView && !_showErrorBlock) {
      setState(() {
        _showErrorBlock = true;
      });
    }

    // Fetch new vehicle data if member changes
    final oldNo = oldWidget.memberData['membershipNo']?.toString();
    final newNo = widget.memberData['membershipNo']?.toString();
    if (newNo != null && newNo.trim().isNotEmpty && newNo != oldNo) {
      Provider.of<VehicleProvider>(context, listen: false).fetchVehicleData(newNo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VehicleProvider>(
      builder: (
          context,
          vehicleProvider,
          child,
          ) {
        // Do not show error while fetching data
        if (vehicleProvider.isLoading && vehicleProvider.vehicleData == null) {
          if (widget.isProfileView) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final Map<String, dynamic> activeData =
        _mergeMemberData(vehicleProvider.vehicleData);

        final Map<String, dynamic> statusResult =
        _calculateStatus(activeData);

        final bool isActive = statusResult['isActive'] == true;
        final String reason = statusResult['reason']?.toString() ?? '';

        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

        if (!isActive && profileProvider.isOnline) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
             profileProvider.toggleDriverStatus(false);
          });
        }

        if (!widget.isProfileView) {
          if (isActive || !_showErrorBlock) {
            return const SizedBox.shrink();
          }
        }

        return FadeTransition(
          opacity: widget.isProfileView
              ? const AlwaysStoppedAnimation<double>(1)
              : _opacityAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActive && widget.isProfileView) _buildActiveBadge(),
                if (!isActive && _showErrorBlock) ...[
                  _buildInactiveBadge(),
                  const SizedBox(height: 8),
                  if (reason.isNotEmpty) _buildReasonBox(reason),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: 16,
            color: Colors.green.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            'ACTIVE MEMBER',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Colors.green.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.dangerous_rounded,
            size: 14,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            'INACTIVE MEMBER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Colors.red.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonBox(String reason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.red.shade100,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Action Required:',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reason,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}