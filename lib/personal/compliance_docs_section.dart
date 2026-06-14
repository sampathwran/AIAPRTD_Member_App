import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'vehicle_info_provider.dart';

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

  int? _getRemainingDays(String? expiryDate) {
    if (expiryDate == null || expiryDate.isEmpty) return null;
    try {
      final parts = expiryDate.split('.');
      if (parts.length != 3) return null;
      final expiry = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return expiry.difference(DateTime.now()).inDays;
    } catch (_) {
      return null;
    }
  }

  Color _getExpiryColor(int? days) {
    if (days == null) return Colors.grey;
    if (days <= 0) return Colors.red;
    if (days <= 30) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        title: const Text("Compliance Documents", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        children: [
          _buildDocTile(context, 'Revenue License', 0),
          _buildDocTile(context, 'Insurance Policy', 1),
          _buildDocTile(context, 'Registration Document', 2),
          _buildDocTile(context, 'Driving License', 3),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDocTile(BuildContext context, String title, int index) {
    final List<dynamic> documents = data['documents'] ?? [];
    final docData = index < documents.length ? documents[index] : {'status': 'empty'};
    final String status = docData['status'] ?? 'empty';
    final String? reason = docData['reason'];
    final Map<String, dynamic> reviewData = Map<String, dynamic>.from(docData['reviewData'] ?? {});
    final String? expiryDate = reviewData['Expiry Date'];
    final int? remainingDays = _getRemainingDays(expiryDate);
    final bool showExpiry = index != 2;

    IconData trailingIcon;
    Color iconColor;

    switch (status) {
      case 'pending':
        trailingIcon = Icons.lock;
        iconColor = Colors.orange;
        break;
      case 'approved':
        trailingIcon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'rejected':
        trailingIcon = Icons.camera_alt;
        iconColor = Colors.red;
        break;
      default:
        trailingIcon = Icons.camera_alt;
        iconColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.grey.shade50),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.12),
          child: Icon(Icons.description, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text("Status: ${status.toUpperCase()}", style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 12)),
            if (showExpiry && expiryDate != null && expiryDate.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: _getExpiryColor(remainingDays).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: _getExpiryColor(remainingDays)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          remainingDays != null && remainingDays <= 30 ? "Expires in $remainingDays days" : "Expiry Date: $expiryDate",
                          style: TextStyle(color: _getExpiryColor(remainingDays), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (status == 'rejected' && reason != null && reason.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 6), child: Text("Reason: $reason", style: const TextStyle(color: Colors.red, fontSize: 11))),
          ],
        ),
        trailing: Icon(trailingIcon, color: iconColor),
        onTap: (status == 'pending' || status == 'approved')
            ? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot edit while status is $status")))
            : () => _handleSourceSelection(context, index),
      ),
    );
  }

  Future<void> _handleSourceSelection(BuildContext context, int index) async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Document Source"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, ImageSource.camera), child: const Text("Camera")),
          TextButton(onPressed: () => Navigator.pop(context, ImageSource.gallery), child: const Text("Gallery")),
        ],
      ),
    );

    if (source != null) {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null && context.mounted) {
        showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

        await Provider.of<VehicleInfoProvider>(context, listen: false).uploadDocument(membershipNo, index, image.path);

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Document uploaded successfully!")));
        }
      }
    }
  }
}