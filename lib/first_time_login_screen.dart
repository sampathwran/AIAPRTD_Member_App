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
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isObscureText = true; // 👁️ To toggle password visibility

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 💾 Save details to Firestore and update password
  Future<void> _submitFirstTimeDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {

        // 1️⃣ 🔐 Update user password in Firebase Auth
        await user.updatePassword(_passwordController.text.trim());

        // 2️⃣ 🗄️ Save profile details to Firestore 'member' collection
        await FirebaseFirestore.instance.collection('member').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'fullName': _nameController.text.trim(),
          'isProfileComplete': true, // Setting true so user won't see this screen again
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (!mounted) return; // 🛡️ Async Gap check

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile and password updated successfully!')),
        );

        // ✅ Redirect to HomePage using named route
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMsg = 'An error occurred. Please try again.';
      if (e.code == 'weak-password') {
        errorMsg = 'The password provided is too weak. Min 6 characters required.';
      } else if (e.code == 'requires-recent-login') {
        errorMsg = 'Security sensitive operation. Please log out and log in again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activate Account'),
        backgroundColor: const Color(0xFF1E3A8A), // Association Blue
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
                child: Icon(
                  Icons.lock_reset_rounded,
                  size: 90,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 15),
              const Center(
                child: Text(
                  'Welcome!\nSince this is your first login, you must update your profile name and set a new password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                ),
              ),
              const SizedBox(height: 35),

              // 👤 Full Name Field
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person,
                validator: (val) => val!.trim().isEmpty ? 'Please enter your full name' : null,
              ),
              const SizedBox(height: 20),

              // 🔑 New Password Field
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

              // 🔑 Confirm Password Field
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

              // 🚀 Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _submitFirstTimeDetails,
                  child: const Text(
                    'Submit & Save',
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 Reusable Text Field Builder
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
            color: Colors.grey,
          ),
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