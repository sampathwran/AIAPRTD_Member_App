import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aiaprtd_member/core/providers/vehicle_provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/core/providers/payment_provider.dart';
import 'member_status_tracker.dart';

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

class _StatusBadgeWidgetState extends State<StatusBadgeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  String _lastSyncedDataString = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchVehicleDataInitial();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.4).animate(_animationController);
  }

  void _fetchVehicleDataInitial() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String? membershipNo = widget.memberData['membershipNo']?.toString();
      if (membershipNo != null && membershipNo.trim().isNotEmpty) {
        Provider.of<VehicleProvider>(context, listen: false).fetchVehicleData(membershipNo);
        // We do not need to fetch paymentData explicitly here if it's already fetched
        // but let's safely fetch it if needed.
        Provider.of<PaymentProvider>(context, listen: false).streamPaymentData(membershipNo).listen((_) {});
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _mergeMemberData(Map<String, dynamic>? vehicleData, Map<String, dynamic>? feeData) {
    final Map<String, dynamic> activeData = Map<String, dynamic>.from(widget.memberData);
    if (vehicleData != null) {
      final safeVehicleData = Map<String, dynamic>.from(vehicleData);
      safeVehicleData.remove('payment_history');
      safeVehicleData.remove('pending_payments');
      safeVehicleData.remove('status');
      safeVehicleData.remove('profile_status');
      activeData.addAll(safeVehicleData);
    }
    if (feeData != null) activeData.addAll(feeData);
    return activeData;
  }

  @override
  Widget build(BuildContext context) {
    final String membershipNo = widget.memberData['membershipNo']?.toString() ?? '';

    return Consumer2<VehicleProvider, PaymentProvider>(
      builder: (context, vehicleProvider, paymentProvider, child) {
        
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('app_membership_fee').doc(membershipNo).snapshots(),
          builder: (context, appFeeSnapshot) {

            // 💡 MERGE ALL DATA
            final Map<String, dynamic> activeData = _mergeMemberData(vehicleProvider.vehicleData, paymentProvider.paymentData);
            
            // 🔥 Inject real-time payment history from app_membership_fee
            if (appFeeSnapshot.hasData && appFeeSnapshot.data!.exists) {
              final appFeeData = appFeeSnapshot.data!.data()!;
              List<dynamic> combinedHistory = List.from(activeData['payment_history'] ?? []);
              if (appFeeData['payment_history'] is List) {
                combinedHistory.addAll(appFeeData['payment_history']);
              }
              activeData['payment_history'] = combinedHistory;
            }

            final String currentDataString = activeData.toString();

            if (membershipNo.isNotEmpty && vehicleProvider.vehicleData != null) {
              if (currentDataString != _lastSyncedDataString) {
                _lastSyncedDataString = currentDataString;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    MemberStatusTracker.syncStatusIssuesToFirebase(
                      membershipNo: membershipNo,
                      activeData: activeData,
                    );
                  }
                });
              }
            }

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('member_inactive_reasons').doc(membershipNo).snapshots(),
              builder: (context, snapshot) {

                // Firebase Status එක අනුව වැඩේ තීරණය කරමු
                final bool isFirebaseInactive = snapshot.hasData &&
                    snapshot.data!.exists &&
                    snapshot.data!['status'] == 'INACTIVE';

                final List<dynamic> issues = (snapshot.data?.data()?['issues'] as List<dynamic>?) ?? [];
                final String reason = issues.isNotEmpty ? issues.first['reason'].toString() : 'Account Inactive';

                // Status එක අනුව Driver Online/Offline ටොගල් කිරීම
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
                  if (isFirebaseInactive && profileProvider.isOnline) {
                    profileProvider.toggleDriverStatus(false);
                  }
                });

                if (!widget.isProfileView && !isFirebaseInactive) return const SizedBox.shrink();

                return FadeTransition(
                  opacity: widget.isProfileView ? const AlwaysStoppedAnimation<double>(1) : _opacityAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isFirebaseInactive) _buildActiveBadge(),
                        if (isFirebaseInactive) ...[
                          _buildInactiveBadge(),
                          const SizedBox(height: 8),
                          _buildReasonBox(reason),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          }
        );
      },
    );
  }

  Widget _buildActiveBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade300)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.verified_rounded, size: 16, color: Colors.green.shade700),
      const SizedBox(width: 6),
      Text('ACTIVE MEMBER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.green.shade900)),
    ]),
  );

  Widget _buildInactiveBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.shade200)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.dangerous_rounded, size: 14, color: Colors.red.shade700),
      const SizedBox(width: 6),
      Text('INACTIVE MEMBER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.red.shade900)),
    ]),
  );

  Widget _buildReasonBox(String reason) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.red.shade100)),
    child: Row(children: [
      Icon(Icons.error_outline_rounded, size: 20, color: Colors.red.shade700),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Action Required:', style: TextStyle(fontSize: 11, color: Colors.red.shade400, fontWeight: FontWeight.bold)),
        Text(reason, style: TextStyle(fontSize: 13, color: Colors.red.shade900, fontWeight: FontWeight.w700)),
      ])),
    ]),
  );
}