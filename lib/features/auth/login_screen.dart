import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import '../../core/utils/app_errors.dart';
import '../../core/providers/auth_provider.dart' as app_auth;
import 'register_screen.dart';
import '../settings/privacy_policy_screen.dart';
import '../settings/terms_conditions_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;
  bool _acceptTerms = false;
  
  bool _otpSent = false;
  String? _verificationId;
  String? _targetUid;
  String? _targetMobile;
  Map<String, dynamic>? _memberData;

  void _showSnackBar(String message, [Color color = Colors.red]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleSendOTP() async {
    if (!_acceptTerms) {
      _showSnackBar('Please accept the Privacy Policy and Terms & Conditions.');
      return;
    }

    String input = _identifierController.text.trim();
    if (input.isEmpty) {
      _showSnackBar('Please enter your Membership Number or Mobile Number.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot? memberDoc;
      QuerySnapshot qs;

      // 1. Try Membership No
      if (input.toUpperCase().startsWith('AIAPRTD')) {
        memberDoc = await FirebaseFirestore.instance.collection('member').doc(input.toUpperCase()).get();
        if (!memberDoc.exists) memberDoc = null;
      }

      // 2. Try Exact Document ID match (fallback)
      if (memberDoc == null) {
        memberDoc = await FirebaseFirestore.instance.collection('member').doc(input).get();
        if (!memberDoc.exists) memberDoc = null;
      }

      // 3. Try Mobile Number Search
      if (memberDoc == null) {
        qs = await FirebaseFirestore.instance.collection('member').where('mobile', isEqualTo: input).limit(1).get();
        if (qs.docs.isNotEmpty) memberDoc = qs.docs.first;
      }
      if (memberDoc == null) {
        qs = await FirebaseFirestore.instance.collection('member').where('mobile_number', isEqualTo: input).limit(1).get();
        if (qs.docs.isNotEmpty) memberDoc = qs.docs.first;
      }
      if (memberDoc == null) {
        // Try int search just in case
        int? intInput = int.tryParse(input);
        if (intInput != null) {
          qs = await FirebaseFirestore.instance.collection('member').where('mobile', isEqualTo: intInput).limit(1).get();
          if (qs.docs.isNotEmpty) memberDoc = qs.docs.first;
        }
      }

      if (memberDoc == null) {
        _showSnackBar(AppErrors.invalidIdentifier, Colors.redAccent);
        setState(() => _isLoading = false);
        return;
      }

      _memberData = memberDoc.data() as Map<String, dynamic>? ?? {};
      _targetUid = memberDoc.id;

      // Check Account Status
      String profileStatus = _memberData!['profile_status']?.toString().toUpperCase() ?? '';
      if (profileStatus == 'DRIVER SUSPEND') {
        _showSnackBar(AppErrors.accountSuspended, Colors.redAccent);
        setState(() => _isLoading = false);
        return;
      }

      // Find Mobile
      String? rawMobile = _memberData!['mobile']?.toString() ?? _memberData!['mobile_number']?.toString();
      if (rawMobile == null || rawMobile.trim().isEmpty) {
        _showSnackBar(AppErrors.invalidPhoneFormat, Colors.orange);
        setState(() => _isLoading = false);
        return;
      }

      // Format Mobile Number to E.164 (+94)
      _targetMobile = rawMobile.trim();
      if (_targetMobile!.startsWith('0')) {
        _targetMobile = '+94${_targetMobile!.substring(1)}';
      } else if (!_targetMobile!.startsWith('+')) {
        _targetMobile = '+$_targetMobile';
      }

      _showSnackBar("Sending SMS to $_targetMobile...", Colors.green);

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _targetMobile!,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (mounted) _completeLogin();
          } catch (e) {
            debugPrint("Auto-verification sign-in failed: $e");
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() => _isLoading = false);
            if (e.code == 'too-many-requests') {
              _showSnackBar(AppErrors.tooManyRequests);
            } else {
              _showSnackBar(AppErrors.genericError);
            }
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _otpSent = true;
              _verificationId = verificationId;
            });
            _showSnackBar("OTP sent! Please check your messages.", Colors.green);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(AppErrors.genericError);
      }
    }
  }

  Future<void> _handleVerifyOTP() async {
    String otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showSnackBar("Please enter the OTP.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      await _completeLogin();

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (e.code == 'invalid-verification-code') {
          _showSnackBar("Incorrect OTP Code. Please try again.");
        } else {
          _showSnackBar(AppErrors.genericError);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(AppErrors.genericError);
      }
    }
  }

  Future<void> _completeLogin() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && _targetUid != null) {
      
      // Update the user's document with new device token & auth UID
      Map<String, dynamic> updateData = {
        'auth_uid': user.uid,
        'isProfileComplete': true,
      };

      try {
        final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
        updateData['currentDeviceToken'] = await authProvider.getPersistentDeviceId();
        updateData['fcmToken'] = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint("Error fetching tokens: $e");
      }

      await FirebaseFirestore.instance.collection('member').doc(_targetUid).set(updateData, SetOptions(merge: true));

      if (mounted) {
        _showSnackBar('Login Successful!', Colors.green);
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                  'Welcome to AIAPRTD',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.primary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 5),

                Text(
                  'Secure OTP Login',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 40),

                if (!_otpSent) ...[
                  TextField(
                    controller: _identifierController,
                    keyboardType: TextInputType.text,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Membership No. or Mobile',
                      hintText: 'e.g. AIAPRTD-26-XXXX or 077XXXXXXX',
                      prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 20),

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
                                recognizer: TapGestureRecognizer()..onTap = () {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
                                },
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                                recognizer: TapGestureRecognizer()..onTap = () {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TermsConditionsScreen()));
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSendOTP,
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Send SMS OTP'),
                    ),
                  ),
                ] else ...[
                  Text(
                    'OTP sent to $_targetMobile',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: TextStyle(color: colorScheme.onSurface, letterSpacing: 5, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: 'Enter OTP Code',
                      prefixIcon: Icon(Icons.message, color: colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleVerifyOTP,
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Verify & Login'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _isLoading ? null : () {
                      setState(() {
                        _otpSent = false;
                        _otpController.clear();
                      });
                    },
                    child: const Text('Change Phone Number'),
                  )
                ],
                const SizedBox(height: 30),

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
                        recognizer: TapGestureRecognizer()..onTap = () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterScreen()));
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

