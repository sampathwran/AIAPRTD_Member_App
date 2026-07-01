// ignore_for_file: spell_check_on_languages

class PersonalKYCChecker {
  // =========================================================================
  // 👤 PERSONAL KYC + AUTO FACE VERIFICATION CHECKER
  // =========================================================================
  static Map<String, dynamic> checkKYCStatus(Map<String, dynamic>? memberData) {
    if (memberData == null || memberData.isEmpty) {
      return {
        'isVerified': false,
        'isFullyVerified': false,
        'isAdminApproved': false,
        'isFaceApproved': false,
        'showPendingScreen': false,
        'reason': "Loading profile data...",
      };
    }

    final bool isDetailsSubmitted =
        memberData['isDetailsSubmitted'] == true ||
            memberData['kycApprovalStatus']?.toString().toLowerCase() == 'pending';

    final String kycApproval =
        memberData['kycApprovalStatus']?.toString().toLowerCase() ?? 'none';

    final String mainStatus =
        memberData['status']?.toString().toLowerCase() ?? 'pending';

    final String faceStatus =
        memberData['faceKycStatus']?.toString().toLowerCase() ?? 'none';

    final bool isAdminApproved =
        kycApproval == 'approved' || mainStatus == 'active';

    // ✅ Face verification එකට admin approval ඕනේ නෑ.
    // profile image එකට match වෙලා app/backend එකෙන් approved කලොත් enough.
    final bool isFaceApproved = faceStatus == 'approved';

    final bool isAdminRejected = kycApproval == 'rejected';
    final bool isFaceRejected = faceStatus == 'rejected';

    final bool isRejected = isAdminRejected || isFaceRejected;

    // ✅ Final personal KYC verified වෙන්න දෙකම true ඕනේ:
    // 1. Personal details admin approved
    // 2. Face auto approved
    final bool isFullyVerified = isAdminApproved && isFaceApproved;

    final bool showPendingScreen =
        isDetailsSubmitted ||
            kycApproval == 'pending' ||
            faceStatus == 'pending' ||
            isRejected ||
            isFullyVerified;

    String reason;

    if (isRejected) {
      if (isAdminRejected && isFaceRejected) {
        reason = "Personal details and face verification rejected ❌";
      } else if (isAdminRejected) {
        reason = memberData['kycRejectReason']?.toString() ??
            "Personal details rejected by admin ❌";
      } else {
        reason = memberData['faceRejectReason']?.toString() ??
            "Face verification failed. Please scan again ❌";
      }
    } else if (isFullyVerified) {
      reason = "Profile fully verified ✅";
    } else if (!isDetailsSubmitted && kycApproval == 'none') {
      reason = "Please complete your one-time registration and face verification 📋";
    } else if (!isAdminApproved && !isFaceApproved) {
      reason = "Personal details pending admin approval and face scan pending ⏳";
    } else if (!isAdminApproved) {
      reason = "Personal details pending admin approval ⏳";
    } else if (!isFaceApproved) {
      reason = "Face verification pending. Please complete live face scan 📸";
    } else {
      reason = "Verification pending ⏳";
    }

    return {
      'isVerified': isFullyVerified,
      'isFullyVerified': isFullyVerified,
      'isAdminApproved': isAdminApproved,
      'isFaceApproved': isFaceApproved,
      'isRejected': isRejected,
      'isAdminRejected': isAdminRejected,
      'isFaceRejected': isFaceRejected,
      'showPendingScreen': showPendingScreen,
      'reason': reason,
    };
  }
}