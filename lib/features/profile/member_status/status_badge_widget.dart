import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/core/providers/payment_provider.dart';
import 'package:aiaprtd_member/core/providers/vehicle_provider.dart';
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
  String _lastDataHash = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchPaymentDataInitial();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.4).animate(_animationController);
  }

  void _fetchPaymentDataInitial() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String? membershipNo = widget.memberData['membershipNo']?.toString();
      if (membershipNo != null && membershipNo.trim().isNotEmpty) {
        Provider.of<PaymentProvider>(context, listen: false).streamPaymentData(membershipNo).listen((_) {});
        Provider.of<VehicleProvider>(context, listen: false).fetchVehicleData(membershipNo);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String? _getFirstPendingReason(Map<String, dynamic> data) {
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

    for (var entry in requiredDocs.entries) {
      if (data[entry.key] == 'missing' || data[entry.key] == 'rejected' || data[entry.key] == null) {
         return 'Pending ${entry.value}';
      }
    }

    for (var entry in requiredDocs.entries) {
      if (data[entry.key] != 'approved') {
         return 'Pending Admin Approval for ${entry.value}';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String membershipNo = widget.memberData['membershipNo']?.toString() ?? '';
    if (membershipNo.isEmpty) return const SizedBox.shrink();

    return Consumer2<PaymentProvider, VehicleProvider>(
      builder: (context, paymentProvider, vehicleProvider, child) {

            // Sync Fee & Vehicle Logic
            final Map<String, dynamic> evaluationData = Map<String, dynamic>.from(widget.memberData);
            
            if (paymentProvider.paymentData != null) {
              final Map<String, dynamic> pData = Map<String, dynamic>.from(paymentProvider.paymentData!);
              // ⚠️ Do not overwrite the merged 'payment_history' from ProfileProvider (which includes app_membership_fee)
              // with the older 'payment_history' from the payments collection.
              pData.remove('payment_history'); 
              evaluationData.addAll(pData);
            }
            if (vehicleProvider.vehicleData != null) {
              evaluationData.addAll(vehicleProvider.vehicleData!);
            }

            // Create a hash of fields that determine status to know when to sync
            final String currentDataHash = '${evaluationData['payment_history']}_${evaluationData['documents']}_${evaluationData['vehiclePhotos']}_${evaluationData['kycApprovalStatus']}_${evaluationData['faceKycStatus']}_${evaluationData['profileImageUrl']}_${evaluationData['adminBlockStatus']}';
            
            if (currentDataHash != _lastDataHash) {
              _lastDataHash = currentDataHash;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  MemberStatusTracker.syncStatusIssuesToFirebase(
                    membershipNo: membershipNo,
                    activeData: evaluationData,
                  );
                }
              });
            }

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('member_inactive_reasons').doc(membershipNo).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                
                if (!snapshot.data!.exists) {
                  return const SizedBox.shrink();
                }

                final data = snapshot.data!.data()!;
                final String? pendingReason = _getFirstPendingReason(data);
                final bool isInactive = pendingReason != null;
                final String reason = pendingReason ?? 'Active';

                if (!widget.isProfileView && !isInactive) return const SizedBox.shrink();

                return FadeTransition(
                  opacity: widget.isProfileView ? const AlwaysStoppedAnimation<double>(1) : _opacityAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isInactive) _buildActiveBadge(),
                        if (isInactive) ...[
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