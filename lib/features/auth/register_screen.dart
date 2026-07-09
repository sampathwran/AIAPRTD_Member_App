import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final _otpController = TextEditingController();

  // States
  bool _otpSent = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // ==========================================
  // 1. SEND OTP LOGIC (/send-otp)
  // ==========================================
  Future<void> _sendOTP() async {
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('Please enter email address first.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send-otp'),
        body: {'email': _emailController.text.trim()},
      );

      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        setState(() => _otpSent = true);
        _showSnackBar('Verification Code sent to your email.', isError: false);
      } else {
        _showSnackBar(data['message'] ?? 'Failed to send OTP.');
      }
    } catch (e) {
      _showSnackBar('Network connection error. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // 2. REGISTER USER LOGIC (/register) - UPDATED
  // ==========================================
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        body: {
          'email': _emailController.text.trim(),
          'otp': _otpController.text.trim(),
          'password': _passwordController.text,
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'whatsapp': _whatsappController.text.trim(), // Added WhatsApp number to API
        },
      );

      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        String memberId = data['membership_no'] ?? '';
        _showSuccessDialog(memberId);
      } else {
        _showSnackBar(data['message'] ?? 'Registration failed.');
      }
    } catch (e) {
      _showSnackBar('Error sending data.');
    } finally {
      setState(() => _isLoading = false);
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
          title: const Text('🎉 Success!', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your account has been created successfully. Your membership number:', textAlign: TextAlign.center),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(membershipId, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              ),
              const SizedBox(height: 15),
              const Text('An email with details and instructions has been sent to you. Follow the instructions to activate your account.', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Awesome', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.redAccent : Colors.green),
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
    _otpController.dispose();
    super.dispose();
  }

  // ==========================================
  // 3. UI DESIGN SECTION
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Member Registration'),
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
                Text('Please verify your email to continue', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 25),

                // ✉️ 1. Email Input Field
                TextFormField(
                  controller: _emailController,
                  enabled: !_otpSent,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined, color: colorScheme.primary),
                  ).copyWith(
                    suffixIcon: !_otpSent
                        ? TextButton(
                      onPressed: _isLoading ? null : _sendOTP,
                      child: Text('Send OTP', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                    )
                        : const Icon(Icons.check_circle, color: Colors.green),
                  ),
                  validator: (value) {
                    if (value!.trim().isEmpty) return 'Enter your email';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Section that opens after receiving OTP
                if (_otpSent) ...[
                  // 🔢 2. OTP Code Input
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Enter 6-Digit OTP Code',
                      prefixIcon: Icon(Icons.pin, color: colorScheme.primary),
                    ),
                    validator: (value) => value!.trim().length != 6 ? 'Enter valid 6-digit OTP' : null,
                  ),
                  const SizedBox(height: 15),

                  // 👤 3. First Name Input
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary),
                    ),
                    validator: (value) => value!.trim().isEmpty ? 'Enter your first name' : null,
                  ),
                  const SizedBox(height: 15),

                  // 👤 4. Last Name Input
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary),
                    ),
                    validator: (value) => value!.trim().isEmpty ? 'Enter your last name' : null,
                  ),
                  const SizedBox(height: 15),

                  // 💬 5. WhatsApp Number Input
                  TextFormField(
                    controller: _whatsappController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'WhatsApp Number',
                      prefixIcon: Icon(Icons.phone_android_outlined, color: colorScheme.primary),
                    ),
                    validator: (value) => value!.trim().isEmpty ? 'Enter your WhatsApp number' : null,
                  ),
                  const SizedBox(height: 15),

                  // 🔑 6. Password Input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
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

                  // 🔒 7. Confirm Password Input
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
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

                  // 🚀 REGISTER Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: _isLoading ? null : _registerUser,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('REGISTER'),
                    ),
                  ),
                ],

                if (_isLoading && !_otpSent)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}