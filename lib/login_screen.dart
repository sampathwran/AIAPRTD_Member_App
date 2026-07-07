// ==========================================
// 1. IMPORTS SECTION
// ==========================================
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

// 💡 FIXED: පරණ MemberProvider එක අයින් කරලා අලුත් ProfileProvider එක ඇඩ් කළා
import 'providers/profile_provider.dart';

import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';
import 'first_time_login_screen.dart';
import 'home/home_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _acceptTerms = false;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==========================================
  // 2. SMART FIREBASE LOGIN LOGIC
  // ==========================================
  void _handleLogin() async {
    String input = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }

    if (!_acceptTerms) {
      _showSnackBar("You must accept the Privacy Policy and Terms & Conditions");
      return;
    }

    setState(() => _isLoading = true);

    try {
      String targetEmail = input;

      // 🔍 ඊමේල් එකක් නැතුව Membership No එකක් ගැහුවොත් ඒකෙන් ඊමේල් එක හොයනවා
      if (!input.contains('@')) {
        // 1. Try checking the member collection first
        var querySnapshot = await FirebaseFirestore.instance
            .collection('member')
            .where('membershipNo', isEqualTo: input)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          targetEmail = querySnapshot.docs.first.data()['user_email'] ?? '';
        } else {
          // 2. Not found in member, try checking web_sync_member
          var webSyncSnapshot = await FirebaseFirestore.instance
              .collection('web_sync_member')
              .where('membershipNo', isEqualTo: input)
              .limit(1)
              .get();

          if (webSyncSnapshot.docs.isNotEmpty) {
            targetEmail = webSyncSnapshot.docs.first.data()['user_email'] ?? '';
          } else {
            _showSnackBar("No member found with this Membership Number.");
            setState(() => _isLoading = false);
            return;
          }
        }
      }

      if (targetEmail.isEmpty) {
        _showSnackBar("Could not find a valid email associated with this account.");
        setState(() => _isLoading = false);
        return;
      }

      // 🔐 Firebase එකට ලොග් වෙනවා (මේකෙන් Session එක ඔටෝම ෆෝන් එකේ සේව් වෙනවා)
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: targetEmail,
        password: password,
      );

      // 💡 FIXED: අලුත් Flutter එකට ගැලපෙන විදියට mounted චෙක් එක දැම්මා
      if (!mounted) return;

      if (userCredential.user != null) {
        // 💡 FIXED: ProfileProvider එක පාවිච්චි කරනවා
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

        // 🔄 Provider එකට ඩේටා ටික ගන්නවා
        bool dataLoaded = await profileProvider.fetchAndStoreMemberData();

        if (!mounted) return; // 💡 FIXED: Async gap warning එකට

        if (dataLoaded) {
          // 🚀 ඩේටා ලෝඩ් වුණා නම් කෙලින්ම HomePage එකට!
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          _showSnackBar("Auth Success, but failed to sync Firestore data. Please contact Admin.");
          await _auth.signOut();
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Login Failed. Please try again.";
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        errorMsg = "Invalid Login credentials. Please check your Email/ID and Password.";
      } else if (e.code == 'wrong-password') {
        errorMsg = "Incorrect password. Please try again.";
      } else if (e.code == 'too-many-requests') {
        errorMsg = "Too many attempts. Account temporarily locked.";
      }
      _showSnackBar("$errorMsg (${e.code})");
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==========================================
  // 3. UI DESIGN SECTION
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🖼️ සංගමයේ ලෝගෝ එක
                Image.asset(
                  'assets/images/logo.png',
                  width: 130,
                  height: 130,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.local_taxi_rounded, size: 90, color: Color(0xFF1E3A8A));
                  },
                ),
                const SizedBox(height: 15),

                const Text(
                  'AIAPRTD MEMBER APP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 5),

                const Text(
                  'Sign in to continue',
                  style: TextStyle(fontSize: 14, color: Colors.black45),
                ),
                const SizedBox(height: 40),

                // 📨 Username/Email Field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Membership No / Email',
                    prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF1E3A8A)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 🔒 Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_open_outlined, color: Color(0xFF1E3A8A)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 🔑 Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                // 📋 Terms & Conditions Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      activeColor: const Color(0xFF1E3A8A),
                      onChanged: (bool? value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13, color: Colors.black87, fontFamily: 'sans-serif'),
                          children: [
                            const TextSpan(text: 'I accept the '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                                  );
                                },
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const TermsConditionsScreen()),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // 🚀 LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'LOGIN',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 🆕 First Time Login Link
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const FirstTimeLoginScreen()),
                    );
                  },
                  child: const Text(
                    'First time login? Click here',
                    style: TextStyle(color: Colors.blueGrey, decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 15),

                // 📝 Register Link
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 15, color: Colors.black87, fontFamily: 'sans-serif'),
                    children: [
                      const TextSpan(text: "Don't have an account? "),
                      TextSpan(
                        text: "Register",
                        style: const TextStyle(
                          color: Color(0xFF1E3A8A),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}