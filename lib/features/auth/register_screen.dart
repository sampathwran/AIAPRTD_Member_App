import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aiaprtd_member/core/utils/app_errors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Your website base URL
  final String _baseUrl = 'https://aiaprtd.lk/wp-json/aiaprtd/v1';

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // States
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  String? _verificationId;

  // ==========================================
  // 1. FIREBASE PHONE AUTH (SEND SMS)
  // ==========================================
  Future<void> _verifyPhoneAndRegister() async {
    if (!_formKey.currentState!.validate()) return;

    // Phone number must have country code. If not, add +94
    String phone = _whatsappController.text.trim();
    if (phone.startsWith('0')) {
      phone = '+94${phone.substring(1)}';
    } else if (!phone.startsWith('+')) {
      phone = '+$phone';
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution (rarely triggers on iOS, sometimes on Android)
          await _signInAndRegisterWP(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('======================================');
          debugPrint('🔥 FIREBASE AUTH VERIFICATION FAILED 🔥');
          debugPrint('Error Code: ${e.code}');
          debugPrint('Error Message: ${e.message}');
          debugPrint('======================================');
          setState(() => _isLoading = false);
          String errorMsg = AppErrors.genericError;
          if (e.code == 'too-many-requests' || e.message?.contains('39') == true || e.message?.contains('17499') == true) {
            errorMsg = AppErrors.tooManyRequests;
          } else if (e.code == 'invalid-phone-number') {
            errorMsg = 'Invalid phone number format.';
          }
          _showSnackBar(errorMsg);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isLoading = false;
            _verificationId = verificationId;
          });
          _showSnackBar('SMS Code sent to $phone', isError: false);
          _showOTPDialog();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      debugPrint('======================================');
      debugPrint('💥 UNEXPECTED REGISTRATION ERROR 💥');
      debugPrint('Error: $e');
      debugPrint('======================================');
      setState(() => _isLoading = false);
      _showSnackBar(AppErrors.genericError);
    }
  }

  // ==========================================
  // 2. OTP DIALOG TO ENTER SMS CODE
  // ==========================================
  void _showOTPDialog() {
    final _otpController = TextEditingController();
    bool _isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('auth.enter_sms_code'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('auth.enter_6_digit'.tr()),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'auth.6_digit_code'.tr(),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isVerifying
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text('auth.cancel'.tr()),
                ),
                ElevatedButton(
                  onPressed: _isVerifying
                      ? null
                      : () async {
                          if (_otpController.text.length != 6) {
                            _showSnackBar('Enter a valid 6-digit code.');
                            return;
                          }
                          setDialogState(() => _isVerifying = true);
                          
                          try {
                            PhoneAuthCredential credential =
                                PhoneAuthProvider.credential(
                              verificationId: _verificationId!,
                              smsCode: _otpController.text.trim(),
                            );
                            
                            // Close dialog first
                            Navigator.of(dialogContext).pop();
                            
                            // Show loading on main screen
                            setState(() => _isLoading = true);
                            
                            await _signInAndRegisterWP(credential);
                          } catch (e) {
                            setDialogState(() => _isVerifying = false);
                            _showSnackBar(AppErrors.invalidOtp);
                          }
                        },
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('auth.verify'.tr()),
                ),
              ],
            );
          }
        );
      },
    );
  }

  // ==========================================
  // 3. REGISTER USER TO FIREBASE (NO WORDPRESS)
  // ==========================================
  Future<void> _signInAndRegisterWP(PhoneAuthCredential credential) async {
    try {
      // 1. Sign in or Link Firebase Phone Auth
      User? user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
         try {
           UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
           user = userCredential.user;
         } on FirebaseAuthException catch (e) {
            if (e.code == 'session-expired' && FirebaseAuth.instance.currentUser != null) {
                user = FirebaseAuth.instance.currentUser;
            } else {
                rethrow;
            }
         }
      }
      
      // 2. Link Email & Password to the authenticated phone session
      if (user != null) {
          AuthCredential emailCred = EmailAuthProvider.credential(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
          try {
             await user.linkWithCredential(emailCred);
          } on FirebaseAuthException catch (e) {
             if (e.code == 'credential-already-in-use' || e.code == 'email-already-in-use') {
                 try {
                     UserCredential existingUser = await FirebaseAuth.instance.signInWithCredential(emailCred);
                     user = existingUser.user;
                 } catch (signInErr) {
                     _showSnackBar(AppErrors.genericError);
                     return;
                 }
             } else {
                 rethrow;
             }
          }
      }

      if (user == null) {
          _showSnackBar(AppErrors.genericError);
          return;
      }

      // 3. Generate a new Membership Number locally from Firestore
      final currentYear = DateTime.now().year.toString().substring(2);
      String prefix = currentYear;
      final qs = await FirebaseFirestore.instance.collection('member')
          .where('membershipNo', isGreaterThanOrEqualTo: 'AIAPRTD-$prefix-')
          .where('membershipNo', isLessThan: 'AIAPRTD-$prefix-\uf8ff')
          .get();

      List<int> existingNumbers = [];
      for (var doc in qs.docs) {
        String memNo = doc.id; 
        List<String> parts = memNo.split('-');
        if (parts.length >= 3) {
          int? number = int.tryParse(parts[2]);
          if (number != null) {
            existingNumbers.add(number);
          }
        }
      }

      int nextNumber = 1;
      if (existingNumbers.isNotEmpty) {
        nextNumber = existingNumbers.reduce((a, b) => a > b ? a : b) + 1;
      }
      
      String newMembershipNo = 'AIAPRTD-$prefix-${nextNumber.toString().padLeft(4, '0')}';

      // 4. Save to Firestore
      String email = _emailController.text.trim();
      String phone = _whatsappController.text.trim();
      String fcmToken = '';
      try {
         fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
      } catch(e) {}

      Map<String, dynamic> memberData = {
          'id': newMembershipNo,
          'membershipNo': newMembershipNo,
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'user_email': email,
          'email': email,
          'whatsapp': phone,
          'whatsapp_number': phone,
          'mobile': phone,
          'mobile_number': phone,
          'phone': phone,
          'contact_no': phone,
          'status': 'Active', 
          'platform': 'AIAPRTD',
          'firebaseUid': user.uid,
          'fcmToken': fcmToken,
          'registeredAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('member')
          .doc(newMembershipNo)
          .set(memberData, SetOptions(merge: true));

      _showSuccessDialog(newMembershipNo);

    } catch (e) {
      debugPrint('======================================');
      debugPrint('💥 FIREBASE REGISTRATION FAILED 💥');
      debugPrint('Error: $e');
      debugPrint('======================================');
      _showSnackBar(AppErrors.genericError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Dialog showing success message
  void _showSuccessDialog(String membershipId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('ðŸŽ‰ Success!',
              style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('auth.account_created'.tr(),
                  textAlign: TextAlign.center),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(membershipId,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              ),
              const SizedBox(height: 15),
              Text(
                  'An email with details and instructions has been sent to you. Follow the instructions to activate your account.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close Dialog
                Navigator.of(context).pop(); // Go back to login screen
              },
              child: Text('auth.awesome'.tr(), style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : Colors.green),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ==========================================
  // 4. UI DESIGN SECTION
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('auth.member_registration'.tr()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'CREATE NEW ACCOUNT',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.primary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text('auth.we_will_verify'.tr(),
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 25),

                // ðŸ‘¤ 1. First Name Input
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'auth.first_name'.tr(),
                    prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary),
                  ),
                  validator: (value) => value!.trim().isEmpty ? 'Enter your first name' : null,
                ),
                const SizedBox(height: 15),

                // ðŸ‘¤ 2. Last Name Input
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'auth.last_name'.tr(),
                    prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary),
                  ),
                  validator: (value) => value!.trim().isEmpty ? 'Enter your last name' : null,
                ),
                const SizedBox(height: 15),

                // âœ‰ï¸ 3. Email Input Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'auth.email_address'.tr(),
                    prefixIcon: Icon(Icons.email_outlined, color: colorScheme.primary),
                  ),
                  validator: (value) {
                    if (value!.trim().isEmpty) return 'Enter your email';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // ðŸ’¬ 4. WhatsApp Number Input
                TextFormField(
                  controller: _whatsappController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'auth.whatsapp_number'.tr(),
                    prefixIcon: Icon(Icons.phone_android_outlined, color: colorScheme.primary),
                  ),
                  validator: (value) {
                    if (value!.trim().isEmpty) return 'Enter your WhatsApp number';
                    if (value.trim().length < 9) return 'Enter a valid phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // ðŸ”‘ 5. Password Input
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'auth.password'.tr(),
                    prefixIcon: Icon(Icons.lock_outline, color: colorScheme.primary),
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 15),

                // ðŸ”’ 6. Confirm Password Input
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'auth.confirm_password'.tr(),
                    prefixIcon: Icon(Icons.lock_clock_outlined, color: colorScheme.primary),
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) return 'Confirm your password';
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 35),

                // ðŸš€ REGISTER Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: _isLoading ? null : _verifyPhoneAndRegister,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('auth.verify_phone_register'.tr(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
