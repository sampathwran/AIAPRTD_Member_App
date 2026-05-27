import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _inputController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  // 🔥 Firebase Auth + Firestore හරහා Reset Link එක යවන හැටි
  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final inputText = _inputController.text.trim();
    String? targetEmail;

    try {
      // 1️⃣ යූසර් ගැහුවේ ඊමේල් එකක්ද කියලා බලනවා
      if (inputText.contains('@')) {
        targetEmail = inputText;
      } else {
        // 2️⃣ මෙම්බර් අංකයක් නම් 'member' collection එකෙන් ඒකට අදාල Email එක හොයනවා
        final userQuery = await FirebaseFirestore.instance
            .collection('member') // 👈 ඔන්න මචං collection නම 'member' කලා
            .where('membership_no', isEqualTo: inputText) // 👈 ඩේටාබේස් එකේ මෙම්බර් අංකය තියෙන field එක
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          targetEmail = userQuery.docs.first.get('email') as String?; // 👈 ඩේටාබේස් එකේ email එක තියෙන field එක
        } else {
          _showErrorSnackbar('Membership number not found. Please check and try again.');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // 3️⃣ Firebase Auth හරහා ඇත්තටම ඊමේල් එකට ලින්ක් එක යවනවා
      if (targetEmail != null && targetEmail.isNotEmpty) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: targetEmail);
        _showSuccessSnackbar('Password reset link sent successfully to $targetEmail!');
        _inputController.clear();
      }

    } on FirebaseAuthException catch (e) {
      String errorMsg = 'An error occurred. Please try again.';
      if (e.code == 'user-not-found') {
        errorMsg = 'This email address is not registered in our system.';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'The email address format is invalid.';
      }
      _showErrorSnackbar(errorMsg);
    } catch (e) {
      _showErrorSnackbar('Something went wrong. Check your internet connection.');
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackbar(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(errorMessage)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E3A8A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Reset Password',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        size: 55,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Forgot Password?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    'Enter your registered email address or Membership Number below to reset your password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 35),
                TextFormField(
                  controller: _inputController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'Email or Membership Number',
                    labelStyle: const TextStyle(color: Colors.black54),
                    hintText: 'example@domain.com or MEM12345',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: primaryColor, size: 22),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red.shade400, width: 1),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red.shade600, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email or membership number';
                    }
                    final input = value.trim();
                    if (input.contains('@')) {
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(input)) {
                        return 'Please enter a valid email address';
                      }
                    } else {
                      if (input.length < 4) {
                        return 'Please enter a valid membership number';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primaryColor.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _isLoading ? 0 : 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Text(
                    'Send Reset Details',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.3),
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