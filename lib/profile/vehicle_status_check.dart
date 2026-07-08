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
    for (int i = 0; i < requiredComplianceDocs.length; i++) {
      final String requiredDoc = requiredComplianceDocs[i];

      if (i >= rawDocuments.length) {
        return {
          'isActive': false,
          'reason': '$requiredDoc not uploaded',
        };
      }

      final item = rawDocuments[i];

      if (item == null || item is! Map) {
        return {
          'isActive': false,
          'reason': '$requiredDoc not uploaded',
        };
      }

      final String status =
          item['status']?.toString().trim().toLowerCase() ?? 'empty';

      if (status == 'empty') {
        return {
          'isActive': false,
          'reason': '$requiredDoc not uploaded',
        };
      }

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
