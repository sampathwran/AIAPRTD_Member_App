Map<String, dynamic> checkAdminBlockStatus(Map<String, dynamic>? memberData) {
  if (memberData == null || memberData.isEmpty) {
    return {
      'isActive': false,
      'reason': 'Profile data not found.',
    };
  }

  // Use the adminBlockStatus field as defined in the plan: 'none', 'temporary', 'permanent'
  final String blockStatus = memberData['adminBlockStatus']?.toString().toLowerCase() ?? 'none';
  final String blockReason = memberData['adminBlockReason']?.toString() ?? 'Account blocked by Admin';
  
  // Legacy status fallbacks
  final String adminApproval = memberData['adminApproval']?.toString().toLowerCase() ?? '';
  final String mainStatus = memberData['profile_status']?.toString().toLowerCase() ?? memberData['status']?.toString().toLowerCase() ?? '';
  final String legacyReason = memberData['inactiveReason']?.toString() ?? memberData['rejectionReason']?.toString() ?? 'Account has been restricted by Admin.';

  if (blockStatus == 'temporary' || blockStatus == 'permanent') {
    return {
      'isActive': false,
      'reason': blockReason.isNotEmpty ? blockReason : 'Account has been blocked by Admin.',
    };
  }

  // Handle legacy rejection / block
  if (adminApproval == 'rejected' || mainStatus == 'blocked' || mainStatus == 'rejected') {
    return {
      'isActive': false,
      'reason': legacyReason,
    };
  }

  return {
    'isActive': true,
    'reason': '',
  };
}
