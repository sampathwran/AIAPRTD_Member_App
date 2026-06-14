import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'vehicle_info_provider.dart';

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
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Upload $label Photo"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, ImageSource.camera), child: const Text("Camera")),
          TextButton(onPressed: () => Navigator.pop(context, ImageSource.gallery), child: const Text("Gallery")),
        ],
      ),
    );

    if (source != null) {
      final image = await ImagePicker().pickImage(source: source);
      if (image != null && context.mounted) {
        Provider.of<VehicleInfoProvider>(context, listen: false)
            .uploadVehiclePhoto(membershipNo, label, image.path);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Uploading $label...")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> photoLabels = ['Front', 'Back', 'Left Side', 'Right Side', 'Interior'];
    final Map<String, dynamic> photos = Map<String, dynamic>.from(data['vehiclePhotos'] ?? {});

    bool allApproved = photoLabels.isNotEmpty && photoLabels.every((label) =>
    photos[label] != null && photos[label]['status'] == 'approved');

    if (allApproved) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Vehicle Photos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 15),
            Wrap(
              spacing: 15,
              runSpacing: 15,
              children: photoLabels.map((label) {
                final photoData = photos[label];
                final String status = photoData?['status'] ?? 'none';
                final String? reason = photoData?['reason'];
                final String? url = photoData?['url'];

                Color borderColor = status == 'rejected' ? Colors.red : (status == 'pending' ? Colors.orange : Colors.grey.shade300);

                return Column(
                  children: [
                    GestureDetector(
                      onTap: () => _pickImage(context, label),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border.all(color: borderColor, width: 2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Stack(
                          children: [
                            if (url != null)
                              ClipRRect(borderRadius: BorderRadius.circular(13), child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover)),
                            if (url == null)
                              const Center(child: Icon(Icons.camera_alt, color: Colors.blueAccent)),

                            if (status == 'pending')
                              Container(decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(13)), child: const Center(child: Icon(Icons.access_time, color: Colors.white))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    if (status == 'rejected')
                      SizedBox(width: 100, child: Text(reason ?? "Rejected", style: const TextStyle(color: Colors.red, fontSize: 10), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}