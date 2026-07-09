// ==========================================
// 1. IMPORTS SECTION
// ==========================================
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/features/auth/register_screen.dart';
import 'package:aiaprtd_member/features/auth/forgot_password_screen.dart';
import 'package:aiaprtd_member/features/settings/privacy_policy_screen.dart';
import 'package:aiaprtd_member/features/settings/terms_conditions_screen.dart';
import 'package:aiaprtd_member/features/auth/first_time_login_screen.dart';
import 'package:aiaprtd_member/features/home/home_page.dart';

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

      // If Membership No is entered instead of an email
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

      // Firebase Login
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: targetEmail,
        password: password,
      );

      if (!mounted) return;

      if (userCredential.user != null) {
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

        // Fetch data into Provider
        bool dataLoaded = await profileProvider.fetchAndStoreMemberData();

        if (!mounted) return;

        if (dataLoaded) {
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
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: size.width > 600 ? size.width * 0.2 : 30.0, 
              vertical: 20.0
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/logo.png',
                  width: 140,
                  height: 140,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.local_taxi_rounded, size: 90, color: colorScheme.primary);
                  },
                ),
                const SizedBox(height: 15),

                Text(
                  'AIAPRTD MEMBER',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.primary,
                    letterSpacing: 1.5,
                  ),

                ),
                const SizedBox(height: 5),

                Text(
                  'Sign in to continue',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 40),

                // Username/Email Field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Membership No / Email',
                    prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 20),

                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_open_outlined, color: colorScheme.primary),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: theme.iconTheme.color),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                      );
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                // Terms & Conditions Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      activeColor: colorScheme.primary,
                      onChanged: (bool? value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium,
                          children: [
                            const TextSpan(text: 'I accept the '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
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
                              style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
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

                // LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('LOGIN'),
                  ),
                ),
                const SizedBox(height: 20),

                // First Time Login Link
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const FirstTimeLoginScreen()),
                    );
                  },
                  child: Text(
                    'First time login? Click here',
                    style: TextStyle(
                      color: colorScheme.secondary, 
                      decoration: TextDecoration.underline, 
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Register Link
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      const TextSpan(text: "Don't have an account? "),
                      TextSpan(
                        text: "Register",
                        style: TextStyle(
                          color: colorScheme.primary,
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