import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_header.dart';   // 👈 🎯 Imports ටික එකම ෆෝල්ඩරේ නිසා සරල කලා මචං
import 'home_map_body.dart'; // 👈 🎯
import 'home_footer.dart';   // 👈 🎯

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isSharingLocation = false;

  void _toggleLocationSharing() {
    setState(() {
      _isSharingLocation = !_isSharingLocation;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSharingLocation
            ? 'Live location sharing activated!'
            : 'Location sharing stopped.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Member Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Log Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. 🗺️ MAP BODY SECTION
          const HomeMapBody(),

          // 2. 👤 HEADER SECTION (Top User Card)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: HomeHeader(user: user),
          ),

          // 3. 💳 FOOTER SECTION (Bottom Button)
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: HomeFooter(
              isSharingLocation: _isSharingLocation,
              onToggleLocation: _toggleLocationSharing,
            ),
          ),
        ],
      ),
    );
  }
}