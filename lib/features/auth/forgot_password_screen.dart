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

  // How to send Reset Link via Firebase Auth + Firestore
  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final inputText = _inputController.text.trim();
    String? targetEmail;

    try {
      // 1. Check if the user entered an email
      if (inputText.contains('@')) {
        targetEmail = inputText;
      } else {
        // 2. If it's a member number, find the corresponding Email from 'member' collection
        final userQuery = await FirebaseFirestore.instance
            .collection('member') // Set collection name to 'member'
            .where('membership_no', isEqualTo: inputText) // Membership number field in database
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          targetEmail = userQuery.docs.first.get('email') as String?; // Email field in database
        } else {
          _showErrorSnackbar('Membership number not found. Please check and try again.');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // 3. Actually send the link to the email via Firebase Auth
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Reset Password'),
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
                      color: theme.cardTheme.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_reset_rounded,
                        size: 55,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Forgot Password?',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    'Enter your registered email address or Membership Number below to reset your password.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
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
                    hintText: 'example@domain.com or MEM12345',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: colorScheme.primary, size: 22),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Send Reset Details'),
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