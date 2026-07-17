// ignore_for_file: spell_check_on_languages

const List<String> requiredComplianceDocs = [
  'Revenue License',
  'Insurance Policy',
  'Registration Document',
  'Driving License (Front)',
  'Driving License (Back)',
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

      if (_isDocumentExpired(item)) {
        return {
          'isActive': false,
          'reason': '$requiredDoc is expired',
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

      if (_isDocumentExpired(item)) {
        return {
          'isActive': false,
          'reason': '$title is expired',
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

bool _isDocumentExpired(Map<dynamic, dynamic> document) {
  final dynamic rawReviewData = document['reviewData'];

  final Map<String, dynamic> reviewData = rawReviewData is Map
      ? Map<String, dynamic>.from(rawReviewData)
      : <String, dynamic>{};

  final String? expiryDate = (reviewData['Expiry Date'] ??
          reviewData['expiryDate'] ??
          reviewData['expiry_date'] ??
          document['Expiry Date'] ??
          document['expiryDate'] ??
          document['expiry_date'])
      ?.toString();

  if (expiryDate == null || expiryDate.trim().isEmpty) {
    return false;
  }

  try {
    final String date = expiryDate.trim();

    final List<String> parts = date.contains('.')
        ? date.split('.')
        : date.contains('/')
            ? date.split('/')
            : date.split('-');

    if (parts.length != 3) {
      return false;
    }

    late DateTime expiry;

    if (parts[0].length == 4) {
      expiry = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } else {
      expiry = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    return expiry.isBefore(today);
  } catch (_) {
    return false;
  }
}