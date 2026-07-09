import 'package:flutter/material.dart';

class SosPage extends StatelessWidget {
  const SosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SOS Alert"), backgroundColor: Colors.red),
      body: const Center(
        child: Text("SOS Page - SOS Logic should be implemented here"),
      ),
    );
  }
}