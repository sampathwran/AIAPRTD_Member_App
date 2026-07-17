Map<String, dynamic> checkProfileImageStatus(Map<String, dynamic>? memberData) {
  if (memberData == null || memberData.isEmpty) {
    return {
      'isActive': false,
      'reason': 'Profile data not found.',
    };
  }

  final String profileImageUrl = memberData['profileImageUrl']?.toString() ??
      memberData['imageUrl']?.toString() ??
      '';

  if (profileImageUrl.trim().isEmpty) {
    return {
      'isActive': false,
      'reason': 'Profile image is not uploaded.',
    };
  }

  return {
    'isActive': true,
    'reason': '',
  };
}
