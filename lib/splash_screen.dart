import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart'; // 💡 පරණ comment එක අයින් කරා, Audioplayers පාවිච්චි කරන්න
import 'providers/profile_provider.dart';      // 💡 අලුත් ProfileProvider එක
import 'home/home_page.dart';
import 'login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home/active_booking_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  final String _fullText = "AIAPRTD";
  String _displayedText = "";
  Timer? _characterTimer;

  bool _showSubTitle = false;

  @override
  void initState() {
    super.initState();
    _startSplashLogic();
  }

  void _startSplashLogic() async {
    // 🎵 සවුන්ඩ් එක ප්ලේ වෙනවා
    _audioPlayer.play(AssetSource('sounds/intro.mp3')).catchError((e) {
      debugPrint("Sound play error: $e");
    });

    // ⏱️ Typewriter Effect ඇනිමේෂන් එක
    int charIndex = 0;
    _characterTimer = Timer.periodic(const Duration(milliseconds: 550), (timer) {
      if (charIndex < _fullText.length) {
        if (mounted) {
          setState(() {
            _displayedText += _fullText[charIndex];
          });
        }
        charIndex++;
      } else {
        _characterTimer?.cancel();
      }
    });

    await Future.delayed(const Duration(seconds: 4));
    if (mounted) setState(() => _showSubTitle = true);

    await Future.delayed(const Duration(seconds: 3));
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    if (!mounted) return;

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    try {
      // 💡 මෙතනදී ProfileProvider එක පාවිච්චි කරනවා
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      bool dataLoaded = await profileProvider.fetchAndStoreMemberData();

      if (dataLoaded && mounted) {
        try {
          String myMemberNo = profileProvider.memberNo;
          QuerySnapshot activeTrips = await FirebaseFirestore.instance.collection('all_bookings')
            .where('acceptedBy', isEqualTo: myMemberNo)
            .get();
          
          DocumentSnapshot? activeTripDoc;
          for (var doc in activeTrips.docs) {
            var data = doc.data() as Map<String, dynamic>;
            String status = data['status']?.toString().toLowerCase() ?? '';
            if (status == 'accepted' || status == 'arrived' || status == 'started' || status == 'ongoing') {
              activeTripDoc = doc;
              break;
            }
          }
          
          if (activeTripDoc != null && mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ActiveBookingPage(
                  bookingData: activeTripDoc!.data() as Map<String, dynamic>,
                  bookingId: activeTripDoc.id,
                ),
              ),
            );
            return;
          }
        } catch (e) {
          debugPrint("Error checking active trips: $e");
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching profile data: $e");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _characterTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 150, height: 150,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_taxi_rounded, size: 100, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 50,
              child: Text(
                _displayedText,
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), letterSpacing: 4.0),
              ),
            ),
            const SizedBox(height: 10),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: _showSubTitle ? 1.0 : 0.0,
              child: const Text('Member Management System', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black54, letterSpacing: 1.0)),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A))),
          ],
        ),
      ),
    );
  }
}