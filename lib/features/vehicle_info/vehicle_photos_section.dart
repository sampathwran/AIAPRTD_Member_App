// ignore_for_file: spell_check_on_languages
import 'package:flutter/foundation.dart'; // for debugPrint
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aiaprtd_member/core/providers/vehicle_provider.dart';

class VehiclePhotosSection extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool canEdit;
  final String membershipNo;

  const VehiclePhotosSection({
    super.key,
    required this.data,
    required this.canEdit,
    required this.membershipNo,
  });

  Future<void> _pickImage(BuildContext context, String label) async {
    if (kDebugMode) {
      debugPrint("🚀 Called _pickImage: $label");
    }

    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Upload $label Photo", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text("Select image source from below:"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.camera_alt_rounded, size: 18), SizedBox(width: 4), Text("Camera")],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.image_rounded, size: 18), SizedBox(width: 4), Text("Gallery")],
            ),
          ),
        ],
      ),
    );

    if (source != null) {
      final image = await ImagePicker().pickImage(source: source, imageQuality: 85);
      if (image != null && context.mounted) {
        Provider.of<VehicleProvider>(context, listen: false)
            .uploadVehiclePhoto(membershipNo, label, image.path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Uploading $label photo... ⏳"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getAssetPlaceholder(String label) {
    switch (label) {
      case 'Front': return 'assets/front.png';
      case 'Back': return 'assets/back.png';
      case 'Left Side': return 'assets/left_side.png';
      case 'Right Side': return 'assets/right_side.png';
      case 'Interior': return 'assets/interior.png';
      default: return 'assets/front.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final List<String> photoLabels = ['Front', 'Back', 'Left Side', 'Right Side', 'Interior'];

    final Map<String, dynamic> photos = data['vehiclePhotos'] != null
        ? Map<String, dynamic>.from(data['vehiclePhotos'])
        : {};

    bool allApproved = photoLabels.isNotEmpty && photoLabels.every((label) =>
    photos[label] != null && photos[label]['status'] == 'approved');

    if (allApproved) return const SizedBox.shrink();

    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemWidth = (screenWidth - 76 - 16) / 2;
    final double itemHeight = itemWidth * 0.75;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.camera_enhance_rounded, color: colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  "Vehicle Inspection Photos",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: isDark ? Colors.white : const Color(0xff1B2735)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Please upload clear photos of your vehicle from the angles below.",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.start,
              children: photoLabels.map((label) {
                final photoData = photos[label];
                final String status = photoData?['status'] ?? 'none';
                final String? reason = photoData?['reason'];
                final String? url = photoData?['url'];

                Color borderColor = Colors.grey.shade200;
                Color badgeColor = Colors.grey;
                IconData statusIcon = Icons.cloud_upload_rounded;

                if (status == 'rejected') {
                  borderColor = Colors.red.shade300;
                  badgeColor = Colors.red;
                  statusIcon = Icons.error_outline_rounded;
                } else if (status == 'pending') {
                  borderColor = Colors.orange.shade300;
                  badgeColor = Colors.orange;
                  statusIcon = Icons.hourglass_empty_rounded;
                } else if (status == 'approved') {
                  borderColor = Colors.green.shade300;
                  badgeColor = Colors.green;
                  statusIcon = Icons.check_circle_outline_rounded;
                }

                final bool hasOnlineImage = url != null && url.isNotEmpty && url.startsWith('http');

                return SizedBox(
                  width: itemWidth,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _pickImage(context, label),
                        // 💡 🎯 FIXED: added opaque, works perfectly now
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: itemHeight,
                          decoration: BoxDecoration(
                            color: isDark ? theme.scaffoldBackgroundColor : Colors.grey.shade50,
                            border: Border.all(color: borderColor, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            children: [
                              if (!hasOnlineImage)
                                Center(
                                  child: Opacity(
                                    opacity: 0.25,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Image.asset(
                                        _getAssetPlaceholder(label),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),

                              if (hasOnlineImage)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: CachedNetworkImage(
                                    imageUrl: url,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => const Center(
                                      child: Icon(Icons.broken_image_rounded, color: Colors.red),
                                    ),
                                  ),
                                ),

                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(statusIcon, color: Colors.white, size: 12),
                                ),
                              ),

                              if (status == 'pending')
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 24),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xff1B2735)),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (status == 'rejected' && reason != null && reason.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          child: Text(
                            reason,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}