// ignore_for_file: spell_check_on_languages, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/vehicle_provider.dart';

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

static const List<String> _documentTitles = [
'Revenue License',
'Insurance Policy',
'Registration Document',
'Driving License',
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
for (
int index = 0;
index < rawDocuments.length && index < documents.length;
index++
) {
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
return 'Expiry Date: $expiryDate';
}

if (remainingDays < 0) {
final int expiredDays = remainingDays.abs();

if (expiredDays == 1) {
return 'Expired 1 day ago';
}

return 'Expired $expiredDays days ago';
}

if (remainingDays == 0) {
return 'Expires Today';
}

if (remainingDays == 1) {
return 'Expires in 1 day';
}

if (remainingDays <= 20) {
return 'Expires in $remainingDays days';
}

return 'Expiry Date: $expiryDate';
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
if (title == 'Registration Document') {
return false;
}

// Approved document එක expire වෙලා හෝ
// expire වෙන්න දින 30ක් හෝ අඩු නම් නැවත upload කරන්න පුළුවන්.
return remainingDays != null && remainingDays <= 30;
}

return false;
}

// =========================================================================
// 🖼️ MAIN UI
// =========================================================================
@override
Widget build(BuildContext context) {
return Card(
elevation: 3,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(18),
),
child: ExpansionTile(
title: const Text(
'Compliance Documents',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
children: [
for (int index = 0; index < _documentTitles.length; index++)
_buildDocumentTile(
context,
_documentTitles[index],
index,
),
const SizedBox(height: 8),
],
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

final String? expiryDate = _getExpiryDate(document);
final int? remainingDays = _getRemainingDays(expiryDate);

final bool canUpload = _canUpload(
title: title,
status: status,
remainingDays: remainingDays,
);

final Color statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
child: ListTile(
leading: Icon(
Icons.description,
color: statusColor,
),
title: Text(
title,
style: const TextStyle(
fontWeight: FontWeight.w600,
),
),
subtitle: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const SizedBox(height: 4),

Text(
'Status: ${status.toUpperCase()}',
style: TextStyle(
color: statusColor,
fontWeight: FontWeight.bold,
fontSize: 12,
),
),

if (title != 'Registration Document' &&
expiryDate != null &&
expiryDate.trim().isNotEmpty)
Padding(
padding: const EdgeInsets.only(top: 4),
child: Text(
_getExpiryText(
expiryDate,
remainingDays,
),
style: TextStyle(
color: _getExpiryColor(remainingDays, isDark),
fontSize: 12,
fontWeight:
remainingDays != null && remainingDays <= 20
? FontWeight.bold
    : FontWeight.normal,
),
),
),
],
),
trailing: Icon(
canUpload
? Icons.camera_alt_rounded
    : Icons.lock_outline_rounded,
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
title: const Text('Select Document Source'),
children: [
SimpleDialogOption(
onPressed: () {
Navigator.pop(
dialogContext,
ImageSource.camera,
);
},
child: const Row(
children: [
Icon(
Icons.camera_alt,
color: Colors.blue,
),
SizedBox(width: 12),
Text('Take a Photo'),
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
child: const Row(
children: [
Icon(
Icons.photo_library,
color: Colors.green,
),
SizedBox(width: 12),
Text('Choose from Gallery'),
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
content: Text('Upload failed: $error'),
backgroundColor: Colors.red,
),
);
}
}
}
