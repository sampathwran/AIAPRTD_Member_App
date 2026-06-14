import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../member_provider.dart';

class ImageUploadPage extends StatefulWidget {
  final String membershipNo;
  const ImageUploadPage({super.key, required this.membershipNo});

  @override
  State<ImageUploadPage> createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
    if (mounted) Navigator.pop(context); // BottomSheet එක වැසීමට
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Material( // මෙතන Material එකක් එකතු කළා - දෝෂය නිවැරදි කිරීමට
        child: SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MemberProvider>(context);
    final isUploading = provider.isLoading;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Edit Profile Picture"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue.shade100, width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 100,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                      child: _selectedImage == null
                          ? const Icon(Icons.person, size: 100, color: Colors.blue)
                          : null,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showPicker(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 25),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Save Button Section
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.all(30),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                    final provider = Provider.of<MemberProvider>(context, listen: false);

                    bool success = await provider.submitProfileImageRequest(
                      widget.membershipNo,
                      _selectedImage!,
                    );

                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Profile image request sent successfully!")),
                      );
                      Navigator.pop(context);
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to upload. Please try again.")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SAVE PROFILE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}