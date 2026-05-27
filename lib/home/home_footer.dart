import 'package:flutter/material.dart';

class HomeFooter extends StatelessWidget {
  final bool isSharingLocation;
  final VoidCallback onToggleLocation;

  const HomeFooter({
    super.key,
    required this.isSharingLocation,
    required this.onToggleLocation,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSharingLocation ? Colors.red : const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 5,
      ),
      icon: Icon(isSharingLocation ? Icons.location_disabled : Icons.location_searching),
      label: Text(
        isSharingLocation ? 'Stop Sharing Location' : 'Start Sharing Live Location',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onPressed: onToggleLocation,
    );
  }
}