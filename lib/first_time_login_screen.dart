import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // 🔄 පියවරවල් හැන්ඩ්ල් කරන්න (0 = Check User, 1 = Password Setup)
  int _currentStep = 0;
  String? _targetEmail;
  String? _targetUid;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 🔎 1. Firestore එකේ Membership No හෝ Email එක තියෙනවාදැයි එකවර සෙවීම (OR Query)
  Future<void> _checkMemberInFirestore() async {
    String input = _identifierController.text.trim();
    if (input.isEmpty) {
      _showSnackBar("Please enter your Membership Number or Email Address", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);
    debugPrint("🔍 Checking Firestore (OR Query) for: $input");

    try {
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

      if (querySnapshot.docs.isEmpty) {
        debugPrint("❌ No record found in Firestore for this Input!");
        _showSnackBar("No pre-registered account found with this Membership No/Email.", Colors.redAccent);
        return;
      }

      // Record එක හමුවුණා!
      var memberData = querySnapshot.docs.first.data() as Map<String, dynamic>;
      _targetEmail = memberData['user_email'] ?? memberData['email'];
      _targetUid = querySnapshot.docs.first.id;

      if (_targetEmail == null || _targetEmail!.isEmpty) {
        _showSnackBar("Associated email not found in record. Contact Admin.", Colors.redAccent);
        return;
      }

      debugPrint("✅ Admin Record Found! Matched Email: $_targetEmail");

      setState(() {
        _currentStep = 1; // ඊළඟ පියවරට (පාස්වර්ඩ් දාන තැනට) යනවා
      });

    } catch (e) {
      debugPrint("❌ Error: $e");
      _showSnackBar("Error checking record: ${e.toString()}", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🚀 2. Firebase Auth එකේ Account එක අලුතින්ම හදලා Activate කිරීම
  Future<void> _submitFirstTimeDetails() async {
    debugPrint("🚀 Submit button clicked!");

    if (!_formKey.currentState!.validate()) {
      debugPrint("❌ Form validation failed!");
      return;
    }

    debugPrint("✅ Validation passed. Starting account creation...");
    setState(() => _isLoading = true);

    try {
      // 🔐 A. Firebase Auth එකේ යූසර්ව අලුතින්ම හදනවා
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _targetEmail!,
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        debugPrint("✅ Auth User Created! UID: ${user.uid}");

        // 🗄️ B. Firestore එකේ දැනටමත් තියෙන ඩොකියුමන්ට් එකට අලුත් විස්තර එකතු කරනවා (නම අයින් කලා මචං)
        await FirebaseFirestore.instance.collection('member').doc(_targetUid).set({
          'auth_uid': user.uid, // සැබෑ Auth UID එක
          'email': user.email,
          'isProfileComplete': true, // ආයෙ මේ පේජ් එක පෙන්නන්නේ නෑ
          'activatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

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

              // 🔄 STEP 0: MEMBERSHIP NO / EMAIL එක ගහලා චෙක් කරන කොටස
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

              // 🔄 STEP 1: අලුත් පාස්වර්ඩ් එක සෙට් කරන කොටස
              if (_currentStep == 1) ...[
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