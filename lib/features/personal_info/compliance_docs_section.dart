// ignore_for_file: spell_check_on_languages, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:aiaprtd_member/core/providers/vehicle_provider.dart';

class ComplianceDocsSection extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool canEdit;
  final String membershipNo;

  const ComplianceDocsSection({
    super.key,
    required this.data,
    required this.canEdit,
    required this.membershipNo,
  });

  static List<String> get _documentTitles => [
    'profile.revenue_license'.tr(),
    'profile.insurance_policy'.tr(),
    'profile.registration_document'.tr(),
    'profile.driving_license_front'.tr(),
    'profile.driving_license_back'.tr(),
  ];

// =========================================================================
// 📄 DOCUMENTS
// =========================================================================
  List<Map<String, dynamic>> get _documents {
    final dynamic rawDocuments =
        data['documents'] ?? data['complianceDocuments'] ?? [];

    final List<Map<String, dynamic>> documents = List.generate(
      _documentTitles.length,
      (index) => {
        'status': 'empty',
        'docIndex': index,
      },
    );

    if (rawDocuments is List) {
      for (int index = 0;
          index < rawDocuments.length && index < documents.length;
          index++) {
        if (rawDocuments[index] is Map) {
          documents[index] = {
            'status': 'empty',
            'docIndex': index,
            ...Map<String, dynamic>.from(rawDocuments[index]),
          };
        }
      }
    }

    return documents;
  }

// =========================================================================
// 📅 EXPIRY DATE
// =========================================================================
  String? _getExpiryDate(Map<String, dynamic> document) {
    final dynamic rawReviewData = document['reviewData'];

    final Map<String, dynamic> reviewData = rawReviewData is Map
        ? Map<String, dynamic>.from(rawReviewData)
        : <String, dynamic>{};

    return (reviewData['Expiry Date'] ??
            reviewData['expiryDate'] ??
            reviewData['expiry_date'] ??
            document['Expiry Date'] ??
            document['expiryDate'] ??
            document['expiry_date'])
        ?.toString();
  }

  int? _getRemainingDays(String? expiryDate) {
    if (expiryDate == null || expiryDate.trim().isEmpty) {
      return null;
    }

    try {
      final String date = expiryDate.trim();

      final List<String> parts = date.contains('.')
          ? date.split('.')
          : date.contains('/')
              ? date.split('/')
              : date.split('-');

      if (parts.length != 3) {
        return null;
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

      final DateTime today = DateTime(
        now.year,
        now.month,
        now.day,
      );

      return expiry.difference(today).inDays;
    } catch (_) {
      return null;
    }
  }

  String _getExpiryText(
    String expiryDate,
    int? remainingDays,
  ) {
    if (remainingDays == null) {
      return "${'profile.expiry_date_prefix'.tr()}$expiryDate";
    }

    if (remainingDays < 0) {
      final int expiredDays = remainingDays.abs();

      if (expiredDays == 1) {
        return 'profile.expired_1_day_ago'.tr();
      }

      return 'profile.expired_days_ago'.tr().replaceFirst('{}', expiredDays.toString());
    }

    if (remainingDays == 0) {
      return 'profile.expires_today'.tr();
    }

    if (remainingDays == 1) {
      return 'Expires in 1 day';
    }

    if (remainingDays <= 20) {
      return 'Expires in $remainingDays days';
    }

    return "${'profile.expiry_date_prefix'.tr()}$expiryDate";
  }

  Color _getExpiryColor(int? remainingDays, bool isDark) {
    if (remainingDays == null) {
      return isDark ? Colors.grey[400]! : Colors.black54;
    }

    if (remainingDays <= 0) {
      return Colors.red;
    }

    if (remainingDays <= 20) {
      return Colors.orange;
    }

    return isDark ? Colors.grey[400]! : Colors.black54;
  }

// =========================================================================
// 🔐 CAMERA / LOCK
// =========================================================================
  bool _canUpload({
    required String title,
    required String status,
    required int? remainingDays,
  }) {
    if (status == 'empty' || status == 'rejected') {
      return true;
    }

    if (status == 'pending') {
      return false;
    }

    if (status == 'approved') {
      if (title == 'profile.registration_document'.tr()) {
        return false;
      }

// If Approved document is expired or
// will expire in 30 days or less, user can upload again.
      return remainingDays != null && remainingDays <= 30;
    }

    return false;
  }

// =========================================================================
// 🖼️ MAIN UI
// =========================================================================
  @override
  Widget build(BuildContext context) {
    bool shouldMerge = false;
    Map<String, dynamic>? backDoc;

    if (_documents.length >= 5) {
      final frontDoc = _documents[3];
      backDoc = _documents[4];

      final frontStatus =
          frontDoc['status']?.toString().trim().toLowerCase() ?? 'empty';
      final backStatus =
          backDoc['status']?.toString().trim().toLowerCase() ?? 'empty';

      String? frontExpiry = _getExpiryDate(frontDoc);
      final backExpiry = _getExpiryDate(backDoc);
      if (frontExpiry == null || frontExpiry.isEmpty) frontExpiry = backExpiry;


      final frontRemaining = _getRemainingDays(frontExpiry);
      final backRemaining = _getRemainingDays(backExpiry);

      final canUploadFront = _canUpload(
          title: 'profile.driving_license_front'.tr(),
          status: frontStatus,
          remainingDays: frontRemaining);
      final canUploadBack = _canUpload(
          title: 'profile.driving_license_back'.tr(),
          status: backStatus,
          remainingDays: backRemaining);

      if (frontStatus == 'approved' &&
          backStatus == 'approved' &&
          !canUploadFront &&
          !canUploadBack) {
        shouldMerge = true;
      }
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ExpansionTile(
        title: Text(
          'profile.compliance_documents'.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        children: [
          for (int index = 0; index < 3; index++)
            if (index < _documentTitles.length)
              _buildDocumentTile(
                context,
                _documentTitles[index],
                index,
              ),
          if (shouldMerge && backDoc != null)
            _buildMergedDrivingLicenseTile(context, backDoc)
          else ...[
            if (_documentTitles.length > 3)
              _buildDocumentTile(context, _documentTitles[3], 3),
            if (_documentTitles.length > 4)
              _buildDocumentTile(context, _documentTitles[4], 4),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

// =========================================================================
// 📄 MERGED DOCUMENT TILE
// =========================================================================
  Widget _buildMergedDrivingLicenseTile(
      BuildContext context, Map<String, dynamic> document) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String? expiryDate = _getExpiryDate(document);



    final int? remainingDays = _getRemainingDays(expiryDate);

    const Color statusColor = Colors.green;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Icon(
          Icons.badge_rounded,
          color: statusColor,
        ),
        title: Text(
          'Driving License',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Status: APPROVED',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (expiryDate != null && expiryDate.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _getExpiryText(
                      expiryDate,
                      remainingDays,
                    ),
                    style: TextStyle(
                      color: _getExpiryColor(remainingDays, isDark),
                      fontSize: 12,
                      fontWeight: remainingDays != null && remainingDays <= 20
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
          ],
        ),
        trailing: Icon(
          Icons.lock_outline_rounded,
          color: statusColor,
        ),
        onTap: null, // No tap action on merged tile
      ),
    );
  }

// =========================================================================
// 📄 DOCUMENT TILE
// =========================================================================
  Widget _buildDocumentTile(
    BuildContext context,
    String title,
    int index,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Map<String, dynamic> document = _documents[index];

    final String status =
        document['status']?.toString().trim().toLowerCase() ?? 'empty';

    String? expiryDate = _getExpiryDate(document);
    if (index == 3 && (expiryDate == null || expiryDate.trim().isEmpty) && _documents.length > 4) {
      expiryDate = _getExpiryDate(_documents[4]);
    }
    final int? remainingDays = _getRemainingDays(expiryDate);

    final bool canUpload = _canUpload(
      title: title,
      status: status,
      remainingDays: remainingDays,
    );

    final Color statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Icon(
          Icons.description,
          color: statusColor,
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Status: ${status.toUpperCase()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (title != 'profile.registration_document'.tr() &&
                expiryDate != null &&
                expiryDate.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _getExpiryText(
                      expiryDate,
                      remainingDays,
                    ),
                    style: TextStyle(
                      color: _getExpiryColor(remainingDays, isDark),
                      fontSize: 12,
                      fontWeight: remainingDays != null && remainingDays <= 20
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
          ],
        ),
        trailing: Icon(
          canUpload ? Icons.camera_alt_rounded : Icons.lock_outline_rounded,
          color: canUpload ? Colors.blue : statusColor,
        ),
        onTap: canUpload
            ? () => _selectAndUploadImage(
                  context,
                  index,
                )
            : null,
      ),
    );
  }

// =========================================================================
// 🎨 STATUS COLOR
// =========================================================================
  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;

      case 'pending':
        return Colors.orange;

      case 'rejected':
        return Colors.red;

      default:
        return Colors.blue;
    }
  }

// =========================================================================
// 📸 SELECT AND UPLOAD IMAGE
// =========================================================================
  Future<void> _selectAndUploadImage(
    BuildContext context,
    int index,
  ) async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: Text('profile.select_document_source'.tr()),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  ImageSource.camera,
                );
              },
              child: Row(
                children: [
                  Icon(
                    Icons.camera_alt,
                    color: Colors.blue,
                  ),
                  SizedBox(width: 12),
                  Text('profile.take_photo'.tr()),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  ImageSource.gallery,
                );
              },
              child: Row(
                children: [
                  Icon(
                    Icons.photo_library,
                    color: Colors.green,
                  ),
                  SizedBox(width: 12),
                  Text('profile.choose_from_gallery'.tr()),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (source == null) return;

    final XFile? image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
    );

    if (image == null || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) {
        return const PopScope(
          canPop: false,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );

    try {
      await Provider.of<VehicleProvider>(
        context,
        listen: false,
      ).uploadDocument(
        membershipNo,
        index,
        image.path,
      );

      if (!context.mounted) return;

      Navigator.of(
        context,
        rootNavigator: true,
      ).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_documentTitles[index]} submitted for approval.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      Navigator.of(
        context,
        rootNavigator: true,
      ).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${'profile.upload_failed'.tr()}: $error"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}