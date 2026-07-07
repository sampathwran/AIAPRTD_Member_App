// ignore_for_file: spell_check_on_languages

const List<String> requiredComplianceDocs = [
  'Revenue License',
  'Insurance Policy',
  'Registration Document',
  'Driving License',
];

Map<String, dynamic> checkMemberSystemStatus(Map<String, dynamic>? memberData) {
  if (memberData == null || memberData.isEmpty) {
    return {
      'isActive': false,
      'reason': 'Vehicle documents not found',
    };
  }

  final dynamic rawDocuments =
      memberData['documents'] ?? memberData['complianceDocuments'];

  if (rawDocuments is List) {
    for (final String requiredDoc in requiredComplianceDocs) {
      // Find the document in the list by checking the title field
      final item = rawDocuments.firstWhere(
        (doc) => doc is Map && doc['title'] == requiredDoc,
        orElse: () => null,
      );

      if (item == null) {
        return {
          'isActive': false,
          'reason': '$requiredDoc not uploaded',
        };
      }

      final String status =
          item['status']?.toString().trim().toLowerCase() ?? 'empty';

      if (status == 'pending') {
        return {
          'isActive': false,
          'reason': '$requiredDoc pending admin approval',
        };
      }

      if (status == 'rejected') {
        return {
          'isActive': false,
          'reason': '$requiredDoc rejected',
        };
      }

      if (status != 'approved') {
        return {
          'isActive': false,
          'reason': '$requiredDoc not approved',
        };
      }
    }

    return {
      'isActive': true,
      'reason': 'Success',
    };
  }

  if (rawDocuments is Map) {
    for (final String title in requiredComplianceDocs) {
      final dynamic item = rawDocuments[title];

      if (item is! Map) {
        return {
          'isActive': false,
          'reason': '$title not uploaded',
        };
      }

      final String status =
          item['status']?.toString().trim().toLowerCase() ?? 'empty';

      if (status == 'pending') {
        return {
          'isActive': false,
          'reason': '$title pending admin approval',
        };
      }

      if (status == 'rejected') {
        return {
          'isActive': false,
          'reason': '$title rejected',
        };
      }

      if (status != 'approved') {
        return {
          'isActive': false,
          'reason': '$title not approved',
        };
      }
    }

    return {
      'isActive': true,
      'reason': 'Success',
    };
  }

  return {
    'isActive': false,
    'reason': 'Vehicle documents not found',
  };
}
