import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // අනිවාර්යයෙන්ම මේක Import කරන්න

// ඔයාගේ Checkers ටික හරියට Import කරගන්න
import 'package:aiaprtd_member/features/profile/member_status/membership_fee_status_check.dart';
import 'package:aiaprtd_member/features/profile/member_status/personal_kyc_checker.dart';
import 'package:aiaprtd_member/features/profile/member_status/profile_image_status_check.dart';
import 'package:aiaprtd_member/features/profile/member_status/admin_block_status_check.dart';

class MemberStatusTracker {

  static Future<void> syncStatusIssuesToFirebase({
    required String membershipNo,
    required Map<String, dynamic> activeData,
  }) async {
    print("🚀 [TRACKER] Started for Member: $membershipNo");

    if (membershipNo.isEmpty) {
      print("⚠️ [TRACKER] Membership No is empty. Stopping.");
      return;
    }

    try {
      List<Map<String, dynamic>> issues = [];

      // 1. Membership Fee
      final Map<String, dynamic> feeCheck = checkMembershipFeeStatus(activeData);
      if (feeCheck['isFeePaidValid'] == false) {
        issues.add({
          'category': 'Membership Fee',
          'issue_type': 'Payment Issue',
          'reason': feeCheck['reason'] ?? 'Pending Membership Fee 💰'
        });
      }

      // 2. KYC Check
      final Map<String, dynamic> kycCheck = PersonalKYCChecker.checkKYCStatus(activeData);
      if (kycCheck['isVerified'] == false) {
        issues.add({
          'category': 'KYC & Verification',
          'issue_type': 'Pending / Rejected',
          'reason': kycCheck['reason'] ?? 'Personal profile or face verification pending.'
        });
      }

      // 3. Profile Image Check
      final Map<String, dynamic> imageCheck = checkProfileImageStatus(activeData);
      if (imageCheck['isActive'] == false) {
        issues.add({
          'category': 'Profile Image',
          'issue_type': 'Missing / Invalid',
          'reason': imageCheck['reason'] ?? 'Profile image is missing or invalid.'
        });
      }

      // 4. Admin Block Check
      final Map<String, dynamic> blockCheck = checkAdminBlockStatus(activeData);
      if (blockCheck['isActive'] == false) {
        issues.add({
          'category': 'Admin Action',
          'issue_type': 'Blocked',
          'reason': blockCheck['reason'] ?? 'Account blocked by Admin.'
        });
      }

      // 5. Granular Document Checks (Replaces General Vehicle Check for better Firebase insights)
      _evaluateGranularDocument(issues, 'Driving License', 'Driving License (Front)', activeData);
      _evaluateGranularDocument(issues, 'Revenue License', 'Revenue License', activeData);
      _evaluateGranularDocument(issues, 'Vehicle Insurance', 'Insurance Policy', activeData);
      _evaluateGranularDocument(issues, 'Registration Document', 'Registration Document', activeData);

      // Special case for NIC
      final String kycStatus = activeData['kycApprovalStatus']?.toString().toLowerCase() ?? 'none';
      if (kycStatus == 'none' || kycStatus.isEmpty) {
        issues.add({
          'category': 'Document Issue',
          'document_name': 'National Identity Card (NIC)',
          'issue_type': 'Empty',
          'reason': 'National Identity Card (NIC) is missing or not uploaded.'
        });
      } else if (kycStatus == 'pending') {
        issues.add({
          'category': 'Document Issue',
          'document_name': 'National Identity Card (NIC)',
          'issue_type': 'Pending',
          'reason': 'National Identity Card (NIC) is waiting for admin verification.'
        });
      }

      print("🔍 [TRACKER] Total issues found: ${issues.length}");
      print("⏳ [TRACKER] Saving to Firebase with UID...");

      // ලොග් වෙලා ඉන්න කෙනාගේ UID එක ගන්නවා
      final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

      // Firebase එකට Update කිරීම
      final docRef = FirebaseFirestore.instance.collection('member_inactive_reasons').doc(membershipNo);

      if (issues.isNotEmpty) {
        await docRef.set({
          'membershipNo': membershipNo,
          'uid': currentUid,
          'status': 'INACTIVE',
          'total_issues': issues.length,
          'issues': issues,
          'last_updated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await docRef.set({
          'membershipNo': membershipNo,
          'uid': currentUid,
          'status': 'ACTIVE',
          'total_issues': 0,
          'issues': [],
          'last_updated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      print("✅ [TRACKER] Successfully saved to Firebase for $membershipNo");

    } catch (e, stacktrace) {
      print("❌ [TRACKER] CRITICAL ERROR: $e");
      print("❌ [TRACKER] STACKTRACE: $stacktrace");
    }
  }

  static void _evaluateGranularDocument(List<Map<String, dynamic>> issues, String displayName, String systemName, Map<String, dynamic> activeData) {
    final dynamic rawDocuments = activeData['documents'] ?? activeData['complianceDocuments'];
    String status = 'empty';
    String? expiryDate;

    // The backend stores vehicle documents in a strict index-based array, not by title.
    final List<String> requiredDocs = [
      'Revenue License',
      'Insurance Policy',
      'Registration Document',
      'Driving License (Front)',
      'Driving License (Back)',
    ];

    if (rawDocuments is List) {
      int index = requiredDocs.indexOf(systemName);
      if (index != -1 && index < rawDocuments.length) {
        final doc = rawDocuments[index];
        if (doc is Map) {
          status = doc['status']?.toString().toLowerCase() ?? 'empty';
          expiryDate = _extractExpiryDate(doc);
        }
      }
    } else if (rawDocuments is Map) {
      final doc = rawDocuments[systemName];
      if (doc is Map) {
        status = doc['status']?.toString().toLowerCase() ?? 'empty';
        expiryDate = _extractExpiryDate(doc);
      }
    }

    status = status.trim();

    if (status == 'empty' || status == 'null' || status.isEmpty) {
      issues.add({
        'category': 'Document Issue',
        'document_name': displayName,
        'issue_type': 'Empty',
        'reason': '$displayName is missing or not uploaded.',
      });
      return;
    }

    if (status == 'pending') {
      issues.add({
        'category': 'Document Issue',
        'document_name': displayName,
        'issue_type': 'Pending',
        'reason': '$displayName is waiting for admin verification.',
      });
      return;
    }

    if (status == 'rejected') {
      issues.add({
        'category': 'Document Issue',
        'document_name': displayName,
        'issue_type': 'Rejected',
        'reason': '$displayName was rejected by admin.',
      });
      return;
    }

    if (expiryDate != null && expiryDate.isNotEmpty) {
      try {
        final String date = expiryDate.trim();
        final List<String> parts = date.contains('.') ? date.split('.') : date.contains('/') ? date.split('/') : date.split('-');
        if (parts.length == 3) {
          late DateTime expiry;
          if (parts[0].length == 4) {
            expiry = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          } else {
            expiry = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          }
          final DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
          if (expiry.isBefore(today)) {
            issues.add({
              'category': 'Document Issue',
              'document_name': displayName,
              'issue_type': 'Expired',
              'reason': '$displayName expired.',
            });
          }
        }
      } catch (e) {
        // Ignore date parsing errors
      }
    }
  }

  static String? _extractExpiryDate(Map<dynamic, dynamic> document) {
    final dynamic rawReviewData = document['reviewData'];
    final Map<String, dynamic> reviewData = rawReviewData is Map ? Map<String, dynamic>.from(rawReviewData) : <String, dynamic>{};
    return (reviewData['Expiry Date'] ?? reviewData['expiryDate'] ?? reviewData['expiry_date'] ?? document['Expiry Date'] ?? document['expiryDate'] ?? document['expiry_date'])?.toString();
  }
}