import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aiaprtd_member/features/profile/member_status/membership_fee_status_check.dart';

class MemberStatusTracker {
  static Future<void> syncStatusIssuesToFirebase({
    required String membershipNo,
    required Map<String, dynamic> activeData,
  }) async {
    print("🚀 [TRACKER] Syncing for Member: $membershipNo");

    if (membershipNo.isEmpty) {
      print("⚠️ [TRACKER] Membership No is empty. Stopping.");
      return;
    }

    try {
      final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final docRef = FirebaseFirestore.instance.collection('member_inactive_reasons').doc(membershipNo);
      
      // Helpers
      String getDocStatus(String systemName) {
        final dynamic rawDocs = activeData['documents'] ?? activeData['complianceDocuments'];
        String status = 'missing';
        if (rawDocs is List) {
          final List<String> requiredDocs = ['Revenue License', 'Insurance Policy', 'Registration Document', 'Driving License (Front)', 'Driving License (Back)'];
          int index = requiredDocs.indexOf(systemName);
          if (index != -1 && index < rawDocs.length) {
            final doc = rawDocs[index];
            if (doc is Map) status = doc['status']?.toString().toLowerCase() ?? 'missing';
          }
        } else if (rawDocs is Map) {
          final doc = rawDocs[systemName];
          if (doc is Map) status = doc['status']?.toString().toLowerCase() ?? 'missing';
        }
        if (status == 'empty' || status == 'null' || status.isEmpty) return 'missing';
        if (status == 'pending') return 'pending_approval';
        return status;
      }

      String getVehicleImgStatus(String systemName) {
        final dynamic rawDocs = activeData['vehiclePhotos'] ?? activeData['documents']; 
        String status = 'missing';
        if (rawDocs is Map) {
          final doc = rawDocs[systemName];
          if (doc is Map) status = doc['status']?.toString().toLowerCase() ?? 'missing';
          else if (doc != null && doc.toString().isNotEmpty) status = 'approved'; 
        }
        if (status == 'missing' && activeData[systemName] != null && activeData[systemName].toString().isNotEmpty) {
           status = 'approved';
        }
        if (status == 'empty' || status == 'null' || status.isEmpty) return 'missing';
        if (status == 'pending') return 'pending_approval';
        return status;
      }

      // Evaluations
      final profileImageUrl = activeData['profileImageUrl']?.toString() ?? activeData['imageUrl']?.toString() ?? '';
      String profileImageStatus = profileImageUrl.trim().isNotEmpty ? 'approved' : 'missing';

      final kycStatusStr = activeData['kycApprovalStatus']?.toString().toLowerCase() ?? 'none';
      String kycStatus = (kycStatusStr == 'approved') ? 'approved' : (kycStatusStr == 'pending' ? 'pending_approval' : (kycStatusStr == 'rejected' ? 'rejected' : 'missing'));
      String nicStatus = kycStatus; 

      final faceStatusStr = activeData['faceKycStatus']?.toString().toLowerCase() ?? 'none';
      String faceStatus = (faceStatusStr == 'approved') ? 'approved' : (faceStatusStr == 'pending' ? 'pending_approval' : (faceStatusStr == 'rejected' ? 'rejected' : 'missing'));

      final String blockStatus = activeData['adminBlockStatus']?.toString().toLowerCase() ?? 'none';
      final String legacyApproval = activeData['adminApproval']?.toString().toLowerCase() ?? '';
      final String legacyMainStatus = activeData['profile_status']?.toString().toLowerCase() ?? activeData['status']?.toString().toLowerCase() ?? '';
      
      bool adminBlockTemp = blockStatus == 'temporary' || legacyMainStatus == 'blocked';
      bool adminBlockPerm = blockStatus == 'permanent' || legacyApproval == 'rejected' || legacyMainStatus == 'rejected';

      final Map<String, dynamic> feeCheck = checkMembershipFeeStatus(activeData);
      String feeStatus = (feeCheck['isFeePaidValid'] == true) ? 'approved' : 'pending_approval';

      // Update Firebase Single Source of Truth
      await docRef.set({
        'profile_image': profileImageStatus,
        'kyc_details': kycStatus,
        'id_card_image': nicStatus,
        'face_verification': faceStatus,
        'revenue_licence': getDocStatus('Revenue License'),
        'insurance_policy': getDocStatus('Insurance Policy'),
        'vehicle_registration_document': getDocStatus('Registration Document'),
        'driving_licence': getDocStatus('Driving License (Front)'),
        'vehicle_image_front': getVehicleImgStatus('Front'),
        'vehicle_image_back': getVehicleImgStatus('Back'),
        'vehicle_image_right_side': getVehicleImgStatus('Right Side'),
        'vehicle_image_left_side': getVehicleImgStatus('Left Side'),
        'vehicle_image_interior': getVehicleImgStatus('Interior'),
        
        // Remove old incorrect keys that might have been added directly by vehicle_provider
        'Front': FieldValue.delete(),
        'Back': FieldValue.delete(),
        'Right Side': FieldValue.delete(),
        'Left Side': FieldValue.delete(),
        'Interior': FieldValue.delete(),

        'membership_fee': feeStatus,
        'admin_block_temporarily': adminBlockTemp,
        'admin_block_permanently': adminBlockPerm,
        'membershipNo': membershipNo,
        'uid': currentUid,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("✅ [TRACKER] Successfully synced all fields for $membershipNo");

    } catch (e, stacktrace) {
      print("❌ [TRACKER] CRITICAL ERROR: $e");
      print("❌ [TRACKER] STACKTRACE: $stacktrace");
    }
  }
}