import 'package:flutter/material.dart';

class ImageUploadPage extends StatelessWidget {
  const ImageUploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Profile Picture")),
      body: const Center(child: Text("Image Upload Page")),
    );
  }
}