import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'home/home_page.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 📝 අකුරෙන් අකුර පෙන්වන්න ලොජික් එක
  final String _fullText = "AIAPRTD";
  String _displayedText = ""; // 👈 මේක තමයි එකින් එක හැදෙන්නේ
  Timer? _characterTimer;

  bool _showSubTitle = false;

  @override
  void initState() {
    super.initState();
    // 🚀 ස්ප්ලෑෂ් ලොජික් එක ස්ටාර්ට් කරනවා
    _startSplashLogic();
  }

  void _startSplashLogic() async {
    // 🎵 සවුන්ඩ් එක ප්ලේ වෙනවා
    _audioPlayer.play(AssetSource('sounds/intro.mp3')).catchError((e) {
      print("Sound play error: $e");
    });

    // ⏱️ 🎯 අකුරෙන් අකුර ඇනිමේට් කරන කොටස (Typewriter Effect)
    // අකුරු 7ක් තියෙන නිසා, තත්පර 4ක් (මිලිසෙකන්ඩ් 4000) ඇතුළත බෙදිලා යන්න එක අකුරකට මිලිසෙකන්ඩ් 550ක් වගේ දෙනවා
    int charIndex = 0;
    _characterTimer = Timer.periodic(const Duration(milliseconds: 550), (timer) {
      if (charIndex < _fullText.length) {
        if (mounted) {
          setState(() {
            _displayedText += _fullText[charIndex]; // වමේ ඉඳන් අකුරෙන් අකුර එකතු වෙනවා
          });
        }
        charIndex++;
      } else {
        _characterTimer?.cancel(); // අකුරු ඔක්කොම වැටුණාම ටයිමර් එක නවත්තනවා
      }
    });

    // ⏱️ 1. මුළු අකුරු ටික ඇනිමේට් වෙලා ඉවර වෙනකන් හරියටම තත්පර 4ක් බලාගෙන ඉන්නවා
    await Future.delayed(const Duration(seconds: 4));

    // 📝 තත්පර 4ට පස්සේ "Member Management System" කෑල්ල පෙන්වනවා
    if (mounted) {
      setState(() {
        _showSubTitle = true;
      });
    }

    // ⏱️ 2. සබ්ටයිටල් එක වැටුණාට පස්සේ තව හරියටම තත්පර 3ක් රඳවාගෙන ඉන්නවා
    await Future.delayed(const Duration(seconds: 3));

    // 🔍 🚀 පේජ් එකට රීඩිරෙක්ට් වෙනවා
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _characterTimer?.cancel(); // 👈 මෙතනදී ටයිමර් එක ක්ලියර් කරනවා ලීක් වෙන්නැති වෙන්න
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
            // 🖼️ 1. LOGO
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.local_taxi_rounded, size: 100, color: Color(0xFF1E3A8A));
              },
            ),
            const SizedBox(height: 30),

            // 🎭 2. 🎯 AIAPRTD අකුරෙන් අකුර වමේ සිට දකුණට මැවෙන කොටස
            SizedBox(
              height: 50, // අකුරු මාරු වෙද්දී ලේඅවුට් එක ගැස්සෙන්නේ නැති වෙන්න ෆික්ස්ඩ් හයිට් එකක්
              child: Text(
                _displayedText, // 👈 ටයිමර් එකෙන් අප්ඩේට් වන ටෙක්ස්ට් එක
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                  letterSpacing: 4.0,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 📝 3. Member Management System
            AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: _showSubTitle ? 1.0 : 0.0,
              child: const Text(
                'Member Management System',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                  letterSpacing: 1.0,
                ),
              ),
            ),

            const SizedBox(height: 40),
            // පොඩි ලෝඩින් බාර් එකක්
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
            ),
          ],
        ),
      ),
    );
  }
}