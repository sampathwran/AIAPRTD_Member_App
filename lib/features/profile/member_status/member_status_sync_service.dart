import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:aiaprtd_member/features/profile/member_status/profile_status_evaluator.dart';

class MemberStatusSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> syncStatusToFirestore(Map<String, dynamic> memberData, {String? memberId}) async {
    try {
      final String id = memberId ?? memberData['uid']?.toString() ?? memberData['id']?.toString() ?? '';
      
      if (id.isEmpty) {
        debugPrint('⚠️ Cannot sync status: Member ID is missing');
        return;
      }

      final Map<String, dynamic> statusResult = calculateMemberStatus(memberData);
      final bool isActive = statusResult['isActive'] == true;
      final List<String> reasons = (statusResult['reasons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

      // Extract admin block specific info
      final String blockStatus = memberData['adminBlockStatus']?.toString().toLowerCase() ?? 'none';
      final String blockReason = memberData['adminBlockReason']?.toString() ?? '';

      final Map<String, dynamic> syncData = {
        'isActive': isActive,
        'reasons': reasons,
        'adminBlockStatus': blockStatus,
        'adminBlockReason': blockReason,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('member_statuses').doc(id).set(syncData, SetOptions(merge: true));
      debugPrint('✅ Member status successfully synced for $id. Active: $isActive');

    } catch (e) {
      debugPrint('❌ Error syncing member status to Firestore: $e');
    }
  }
}
