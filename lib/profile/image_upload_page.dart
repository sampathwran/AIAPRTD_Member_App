// ignore_for_file: spell_check_on_word, unused_local_variable
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

// 💡 FIXED: පරණ MemberProvider එක අයින් කරලා අලුත් KYCProvider එක ඇඩ් කළා
import '../providers/kyc_provider.dart';

class ImageUploadPage extends StatefulWidget {
  final String membershipNo;
  const ImageUploadPage({super.key, required this.membershipNo});

  @override
  State<ImageUploadPage> createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isVerifyingFace = false;

  // 🧠 STEP 1: Strict System Level Face & Liveness Verification
  Future<bool> _detectFace(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);

    // 🛡️ සිකියුරිටි අප්ඩේට් එක: Classification සහ Tracking ඔන් කළා
    final faceDetector = FaceDetector(options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableClassification: true,
      enableTracking: true,
    ));

    try {
      final List<Face> faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      // මුහුණක් තියෙන්නත් ඕනේ, ඒ වගේම ඒක එක මුහුණක් විතරක් වෙන්නත් ඕනේ
      if (faces.isNotEmpty && faces.length == 1) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error detecting face: $e");
      await faceDetector.close();
      return false;
    }
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF1E3A8A)),
                title: const Text("Take a Selfie"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF1E3A8A)),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      preferredCameraDevice: CameraDevice.front,
    );

    if (pickedFile != null) {
      setState(() {
        _isVerifyingFace = true;
        _selectedImage = null;
      });

      File tempFile = File(pickedFile.path);

      bool hasFace = await _detectFace(tempFile);

      if (!mounted) return;

      setState(() => _isVerifyingFace = false);

      if (hasFace) {
        setState(() => _selectedImage = tempFile);
        _showSnackBar("Live Face Verification Passed! Ready to send to Admin.", Colors.green);
      } else {
        _showSnackBar("Face Verification Failed! Please take a clear selfie in good lighting.", Colors.redAccent);
      }
    }
  }

  void _showSnackBar(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
      backgroundColor: bg,
      duration: const Duration(seconds: 4),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // 💡 FIXED: MemberProvider වෙනුවට KYCProvider පාවිච්චි කරනවා
    final provider = Provider.of<KYCProvider>(context);
    final isUploading = provider.isLocalLoading; // 💡 KYCProvider එකේ තියෙන්නේ isLocalLoading

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Update Profile Picture", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _isVerifyingFace
                  ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A))),
                  SizedBox(height: 15),
                  Text("Scanning Face Liveness... Please wait...", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                ],
              )
                  : Stack(
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
                          ? const Icon(Icons.person, size: 100, color: Color(0xFF1E3A8A))
                          : null,
                    ),
                  ),

                  // 💡 ෆොටෝ එක වෙනස් කරන බටන් එක
                  GestureDetector(
                    onTap: isUploading ? null : _showImageSourceDialog,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
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
          if (_selectedImage != null && !_isVerifyingFace)
            Container(
              padding: const EdgeInsets.all(30),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                    // 💡 FIXED: async gap warning එක නිසා variables කලින්ම ගන්නවා
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final kycProvider = Provider.of<KYCProvider>(context, listen: false);

                    bool success = await kycProvider.submitProfileImageRequest(
                      widget.membershipNo,
                      _selectedImage!,
                    );

                    if (!context.mounted) return; // 💡 FIXED

                    if (success) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.admin_panel_settings, color: Colors.white),
                              SizedBox(width: 10),
                              Expanded(child: Text("Sent for Admin Face Verification! Profile will update once approved.")),
                            ],
                          ),
                          backgroundColor: Colors.orange.shade700,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                      navigator.pop();
                    } else {
                      _showSnackBar("Failed to send request. Please try again.", Colors.redAccent);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SEND FOR VERIFICATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}