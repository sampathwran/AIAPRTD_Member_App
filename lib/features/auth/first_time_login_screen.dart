import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:aiaprtd_member/core/providers/auth_provider.dart';

class FirstTimeLoginScreen extends StatefulWidget {
  const FirstTimeLoginScreen({super.key});

  @override
  State<FirstTimeLoginScreen> createState() => _FirstTimeLoginScreenState();
}

class _FirstTimeLoginScreenState extends State<FirstTimeLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // ✍️ Text field controllers
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isObscureText = true;

  // Handle steps (0 = Check User, 1 = OTP Verification, 2 = Password Setup)
  int _currentStep = 0;
  String? _targetEmail;
  String? _targetUid;
  String? _sourceCollection;
  String? _verificationId;
  String? _mobileNumber;
  Map<String, dynamic>? _memberData;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // 1. Check if Membership No exists and trigger SMS
  Future<void> _checkMemberInFirestore() async {
    String input = _identifierController.text.trim();
    if (input.isEmpty) {
      _showSnackBar("Please enter your Membership Number", Colors.redAccent);
      return;
    }

    if (input.contains('@')) {
      _showSnackBar("Please enter your Membership No (e.g. AIAPRTD-26-XXXX), not your Email.", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);
    debugPrint("🔍 Checking Firestore for: $input");

    try {
      // 1. Check 'member' collection first
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('member')
          .where('membershipNo', isEqualTo: input)
          .limit(1)
          .get();

      Map<String, dynamic>? memberData;
      String? targetUid;
      String? sourceCollection;

      if (querySnapshot.docs.isNotEmpty) {
        memberData = querySnapshot.docs.first.data() as Map<String, dynamic>;
        targetUid = querySnapshot.docs.first.id;
        sourceCollection = 'member';
      } else {
        // 2. Fallback to 'web_sync_member' collection
        QuerySnapshot webSyncSnapshot = await FirebaseFirestore.instance
            .collection('web_sync_member')
            .where('membershipNo', isEqualTo: input)
            .limit(1)
            .get();

        if (webSyncSnapshot.docs.isNotEmpty) {
          memberData = webSyncSnapshot.docs.first.data() as Map<String, dynamic>;
          targetUid = webSyncSnapshot.docs.first.id;
          sourceCollection = 'web_sync_member';
        }
      }

      if (memberData == null) {
        _showSnackBar("No pre-registered account found with this Membership No.", Colors.redAccent);
        setState(() => _isLoading = false);
        return;
      }

      // Record found! Extract details
      _memberData = memberData;
      _targetEmail = memberData['user_email'] ?? memberData['email'];
      _targetUid = targetUid;
      _sourceCollection = sourceCollection;
      
      String? rawMobile = memberData['mobile'] ?? 
                          memberData['mobile_number'] ?? 
                          memberData['whatsapp_number'] ?? 
                          memberData['whatsapp'] ?? 
                          memberData['phone'] ?? 
                          memberData['contact_no'];

      // Add a debug print and dialog to see EXACTLY what fields are in memberData!
      debugPrint("🔍 memberData fields: ${memberData.keys.toList()}");
      debugPrint("🔍 memberData values: $memberData");
      
      if (_targetEmail == null || _targetEmail!.isEmpty) {
        _showSnackBar("Associated email not found in record. Contact Admin.", Colors.redAccent);
        setState(() => _isLoading = false);
        return;
      }

      if (rawMobile == null || rawMobile.isEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text("Debug: Mobile Field Not Found"),
            content: SingleChildScrollView(
              child: Text("Available fields in Firestore:\n\n${memberData!.keys.join(', ')}\n\nValues:\n$memberData"),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text("OK"))]
          )
        );
        _showSnackBar("Associated Mobile Number not found in record. Contact Admin.", Colors.redAccent);
        setState(() => _isLoading = false);
        return;
      }

      // Format Mobile Number to E.164 (+94)
      _mobileNumber = rawMobile;
      if (_mobileNumber!.startsWith('0')) {
        _mobileNumber = '+94${_mobileNumber!.substring(1)}';
      } else if (!_mobileNumber!.startsWith('+')) {
        _mobileNumber = '+$_mobileNumber';
      }

      debugPrint("✅ Admin Record Found! Sending SMS to: $_mobileNumber");
      _showSnackBar("Sending SMS to $_mobileNumber...", Colors.green);

      // Trigger Firebase Phone Auth
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _mobileNumber!,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution (rarely happens on testing unless physical SIM matches)
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (mounted) {
              setState(() {
                _isLoading = false;
                _currentStep = 2; // Auto verified, jump to password!
              });
              _showSnackBar("Phone automatically verified!", Colors.green);
            }
          } catch (e) {
            debugPrint("Auto-verification sign-in failed: $e");
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showSnackBar(e.message ?? 'Phone verification failed.', Colors.redAccent);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _verificationId = verificationId;
              _currentStep = 1; // Go to OTP verification step
            });
            _showSnackBar('SMS Code sent to $_mobileNumber', Colors.green);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );

    } catch (e) {
      debugPrint("❌ Error: $e");
      _showSnackBar("Error checking record: ${e.toString()}", Colors.redAccent);
      setState(() => _isLoading = false);
    }
  }

  // 1.5 Verify OTP (Firebase SMS)
  Future<void> _verifyOtp() async {
    String inputOtp = _otpController.text.trim();
    if (inputOtp.isEmpty) {
      _showSnackBar("Please enter the SMS OTP", Colors.redAccent);
      return;
    }

    if (_verificationId == null) {
      _showSnackBar("Verification session expired. Please go back and try again.", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: inputOtp,
      );

      // Sign in temporarily with Phone Auth to prove they own the number
      await FirebaseAuth.instance.signInWithCredential(credential);

      setState(() {
        _currentStep = 2; // Go to password setup
      });
      _showSnackBar("Phone Verified!", Colors.green);
    } on FirebaseAuthException catch (e) {
      _showSnackBar("Invalid SMS OTP: ${e.message}", Colors.redAccent);
    } catch (e) {
      _showSnackBar("Error verifying OTP: $e", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. Create and Activate new Account in Firebase Auth
  Future<void> _submitFirstTimeDetails() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Because we signed in with Phone Auth in step 1.5, we have a currentUser!
      User? user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        // Fallback: If not signed in (e.g. timeout), just try to create normal account
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _targetEmail!,
          password: _passwordController.text.trim(),
        );
        user = userCredential.user;
      } else {
        // Link the existing Phone Auth session to an Email & Password so they can log in via Password later!
        AuthCredential emailCred = EmailAuthProvider.credential(
          email: _targetEmail!,
          password: _passwordController.text.trim(),
        );
        try {
          await user.linkWithCredential(emailCred);
        } on FirebaseAuthException catch (linkError) {
          if (linkError.code == 'credential-already-in-use' || linkError.code == 'email-already-in-use') {
             // If email already has an account, we might need to just update the password and sign in with email!
             _showSnackBar("Email already registered. You might just need to log in.", Colors.orange);
             // Sign out the phone auth so they can log in cleanly
             await FirebaseAuth.instance.signOut();
             Navigator.pushReplacementNamed(context, '/login');
             return;
          } else {
             rethrow;
          }
        }
      }

      if (user != null) {
        debugPrint("✅ Auth User Created/Linked! UID: ${user.uid}");

        // 🗄️ B. Firestore Update
        await FirebaseFirestore.instance
            .collection('web_sync_member')
            .doc(_targetUid)
            .set({
          'auth_uid': user.uid,
          'isProfileComplete': true,
          'activatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // CRITICAL FIX: ALWAYS copy activated web_sync_members into the 'member' collection!
        // This ensures they appear in the Admin Dashboard and can log in normally via login_screen.dart.
        if (_targetUid != null) {
            Map<String, dynamic> memberSyncData = {};
            if (_memberData != null) {
              memberSyncData = Map<String, dynamic>.from(_memberData!);
            }
            memberSyncData['auth_uid'] = user.uid;
            memberSyncData['isProfileComplete'] = true;
            memberSyncData['activatedAt'] = FieldValue.serverTimestamp();
            
            // Generate fullName if missing
            if (!memberSyncData.containsKey('fullName') || memberSyncData['fullName'] == null || memberSyncData['fullName'].toString().trim().isEmpty) {
               String fName = memberSyncData['firstName']?.toString() ?? memberSyncData['first_name']?.toString() ?? '';
               String lName = memberSyncData['lastName']?.toString() ?? memberSyncData['last_name']?.toString() ?? '';
               String combined = '$fName $lName'.trim();
               if (combined.isNotEmpty) {
                  memberSyncData['fullName'] = combined;
               }
            }
            
            // Set some default states for the Admin Dashboard
            if (!memberSyncData.containsKey('status')) memberSyncData['status'] = 'active member';
            if (!memberSyncData.containsKey('onlineStatus')) memberSyncData['onlineStatus'] = 'offline';
            
            // Set currentDeviceToken to avoid OTP on immediate login
            if (mounted) {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              memberSyncData['currentDeviceToken'] = await authProvider.getPersistentDeviceId();
              
              try {
                memberSyncData['fcmToken'] = await FirebaseMessaging.instance.getToken();
              } catch(e) {
                debugPrint("Error fetching FCM token: $e");
              }
            }

            await FirebaseFirestore.instance
                .collection('member')
                .doc(_targetUid)
                .set(memberSyncData, SetOptions(merge: true));
        }

        if (!mounted) return;
        _showSnackBar('Account Activated Successfully! Welcome.', Colors.green);
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("🔥 FirebaseAuthException: ${e.code} - ${e.message}");
      if (!mounted) return;
      String errorMsg = e.message ?? 'An error occurred';
      if (e.code == 'email-already-in-use') {
        errorMsg = 'This account is already activated. Please log in normally.';
      } else if (e.code == 'weak-password') {
        errorMsg = 'The password is too weak. Min 6 characters required.';
      }
      _showSnackBar(errorMsg, Colors.redAccent);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Error: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('auth.activate_account'.tr()),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Icon(Icons.lock_reset_rounded,
                          size: 90, color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 15),

                    // STEP 0: MEMBERSHIP NO check section
                    if (_currentStep == 0) ...[
                      Center(
                        child: Text(
                          'auth.welcome_activate'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 35),
                      _buildTextField(
                        controller: _identifierController,
                        label: 'e.g. AIAPRTD-26-XXXX',
                        icon: Icons.assignment_ind_outlined,
                        validator: (val) => val!.trim().isEmpty
                            ? 'Please enter your Membership No'
                            : null,
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _checkMemberInFirestore,
                          child: Text(
                            'Check Status & Send SMS',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],

                    // STEP 1: OTP Verification section
                    if (_currentStep == 1) ...[
                      Center(
                        child: Text(
                          "${'auth.sms_sent'.tr()}\n$_mobileNumber",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 35),
                      _buildTextField(
                        controller: _otpController,
                        label: 'SMS OTP Code',
                        icon: Icons.message,
                        validator: (val) =>
                            val!.trim().isEmpty ? 'Please enter the SMS OTP' : null,
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _verifyOtp,
                          child: Text(
                            'Verify OTP',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],

                    // STEP 2: Set new password section
                    if (_currentStep == 2) ...[
                      Center(
                        child: Text(
                          'auth.phone_verified'.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 35),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'New Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        validator: (val) {
                          if (val!.isEmpty) return 'Please enter a password';
                          if (val.length < 6)
                            return 'Password must be at least 6 characters long';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        label: 'auth.confirm_password'.tr(),
                        icon: Icons.lock,
                        isPassword: true,
                        validator: (val) {
                          if (val!.isEmpty)
                            return 'Please re-enter your password';
                          if (val != _passwordController.text)
                            return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _submitFirstTimeDetails,
                          child: Text(
                            'Activate & Save',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _isObscureText : false,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    _isObscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey),
                onPressed: () =>
                    setState(() => _isObscureText = !_isObscureText),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
