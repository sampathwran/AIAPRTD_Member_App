import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aiaprtd_member/core/services/mail_service.dart';

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

  bool _isLoading = false;
  bool _isObscureText = true;

  // Handle steps (0 = Check User, 1 = OTP Verification, 2 = Password Setup)
  int _currentStep = 0;
  String? _targetEmail;
  String? _targetUid;
  String? _sourceCollection;
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 1. Check if Membership No or Email exists in Firestore simultaneously (OR Query)
  Future<void> _checkMemberInFirestore() async {
    String input = _identifierController.text.trim();
    if (input.isEmpty) {
      _showSnackBar("Please enter your Membership Number or Email Address", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);
    debugPrint("🔍 Checking Firestore (OR Query) for: $input");

    try {
      // 1. Check 'member' collection first
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('member')
          .where(
        Filter.or(
          Filter('membershipNo', isEqualTo: input),
          Filter('user_email', isEqualTo: input),
        ),
      )
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
            .where(
          Filter.or(
            Filter('membershipNo', isEqualTo: input),
            Filter('user_email', isEqualTo: input),
          ),
        )
            .limit(1)
            .get();

        if (webSyncSnapshot.docs.isNotEmpty) {
          memberData = webSyncSnapshot.docs.first.data() as Map<String, dynamic>;
          targetUid = webSyncSnapshot.docs.first.id;
          sourceCollection = 'web_sync_member';
        }
      }

      if (memberData == null) {
        debugPrint("❌ No record found in Firestore for this Input!");
        _showSnackBar("No pre-registered account found with this Membership No/Email.", Colors.redAccent);
        return;
      }

      // Record found!
      _targetEmail = memberData['user_email'] ?? memberData['email'];
      _targetUid = targetUid;

      if (_targetEmail == null || _targetEmail!.isEmpty) {
        _showSnackBar("Associated email not found in record. Contact Admin.", Colors.redAccent);
        return;
      }

      debugPrint("✅ Admin Record Found! Matched Email: $_targetEmail");

      // Generate OTP and save to Firestore
      int otp = 100000 + (DateTime.now().millisecondsSinceEpoch % 900000);
      await FirebaseFirestore.instance.collection(sourceCollection!).doc(targetUid).set({
        'temp_otp': otp.toString(),
        'otp_generated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Send OTP via Email
      await MailService.sendOTP(
        toEmail: _targetEmail!,
        otp: otp.toString(),
      );

      _sourceCollection = sourceCollection;

      setState(() {
        _currentStep = 1; // Go to OTP verification step
      });

    } catch (e) {
      debugPrint("❌ Error: $e");
      _showSnackBar("Error checking record: ${e.toString()}", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 1.5 Verify OTP
  Future<void> _verifyOtp() async {
    String inputOtp = _otpController.text.trim();
    if (inputOtp.isEmpty) {
      _showSnackBar("Please enter the OTP", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      var doc = await FirebaseFirestore.instance.collection(_sourceCollection!).doc(_targetUid).get();
      if (!doc.exists) {
        _showSnackBar("Error: Record no longer exists", Colors.redAccent);
        return;
      }

      final data = doc.data()!;
      if (inputOtp == (data['temp_otp'] ?? '').toString().trim()) {
        // Correct OTP
        await FirebaseFirestore.instance.collection(_sourceCollection!).doc(_targetUid).update({
          'temp_otp': FieldValue.delete(),
        });
        setState(() {
          _currentStep = 2; // Go to password setup
        });
      } else {
        _showSnackBar("Invalid OTP. Please try again.", Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar("Error verifying OTP: $e", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. Create and Activate new Account in Firebase Auth
  Future<void> _submitFirstTimeDetails() async {
    debugPrint("🚀 Submit button clicked!");

    if (!_formKey.currentState!.validate()) {
      debugPrint("❌ Form validation failed!");
      return;
    }

    debugPrint("✅ Validation passed. Starting account creation...");
    setState(() => _isLoading = true);

    try {
      // A. Create new user in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _targetEmail!,
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        debugPrint("✅ Auth User Created! UID: ${user.uid}");

        // 🗄️ B. Firestore Update
        // If they are in 'member' collection, update their auth_uid
        // If they are only in 'web_sync_member', we DO NOT create a partial 'member' document 
        // to avoid breaking the ProfileProvider. The ProfileProvider will fall back to web_sync_member!
        // So we only update if they were found in the 'member' collection.
        // Or we can just update whichever collection they were found in to track activation.

        // Since we didn't save _sourceCollection to a state variable, we will query to be safe,
        // or we can just safely merge auth_uid into web_sync_member as well.
        // Actually, creating the Firebase Auth account is enough. When they login, ProfileProvider will handle it.
        // But let's write to web_sync_member just to be safe.
        await FirebaseFirestore.instance.collection('web_sync_member').doc(_targetUid).set({
          'auth_uid': user.uid, // Actual Auth UID
          'isProfileComplete': true,
          'activatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Try writing to member as well IF it exists (merge will only add to it, but wait, merge will create it if it doesn't exist!)
        // So let's NOT write to member collection. 
        // Just writing to web_sync_member is fine. ProfileProvider will find them by email.

        debugPrint("✅ Firestore write successful!");

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account Activated Successfully! Welcome.'), backgroundColor: Colors.green),
        );

        debugPrint("➡️ Navigating to /home...");
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        debugPrint("⚠️ Error: User object creation failed!");
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
      debugPrint("❌ General Error: ${e.toString()}");
      if (!mounted) return;
      _showSnackBar("Error: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("🏁 Finally block executed.");
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
        title: const Text('Activate Account'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(Icons.lock_reset_rounded, size: 90, color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(height: 15),

              // STEP 0: MEMBERSHIP NO / EMAIL check section
              if (_currentStep == 0) ...[
                const Center(
                  child: Text(
                    'Welcome!\nPlease enter your Membership Number or Register Email provided by Admin to activate your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                  ),
                ),
                const SizedBox(height: 35),
                _buildTextField(
                  controller: _identifierController,
                  label: 'Membership No / Email',
                  icon: Icons.assignment_ind_outlined,
                  validator: (val) => val!.trim().isEmpty ? 'Please enter your Membership No or Email' : null,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _checkMemberInFirestore,
                    child: const Text(
                      'Check Status',
                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],

              // STEP 1: OTP Verification section
              if (_currentStep == 1) ...[
                Center(
                  child: Text(
                    'We have sent a verification code to your email.\nPlease enter it below.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                  ),
                ),
                const SizedBox(height: 35),
                _buildTextField(
                  controller: _otpController,
                  label: 'OTP Code',
                  icon: Icons.password,
                  validator: (val) => val!.trim().isEmpty ? 'Please enter the OTP' : null,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _verifyOtp,
                    child: const Text(
                      'Verify OTP',
                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],

              // STEP 2: Set new password section
              if (_currentStep == 2) ...[
                Center(
                  child: Text(
                    'Account Verified for $_targetEmail.\nPlease set a new password to complete your activation.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
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
                    if (val.length < 6) return 'Password must be at least 6 characters long';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  icon: Icons.lock,
                  isPassword: true,
                  validator: (val) {
                    if (val!.isEmpty) return 'Please re-enter your password';
                    if (val != _passwordController.text) return 'Passwords do not match';
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submitFirstTimeDetails,
                    child: const Text(
                      'Activate & Save',
                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
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
          icon: Icon(_isObscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: () => setState(() => _isObscureText = !_isObscureText),
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