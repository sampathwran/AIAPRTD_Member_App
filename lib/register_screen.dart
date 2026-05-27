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

  // 🔗 ඔයාගේ වෙබ් සයිට් එකේ මූලික URL එක
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
      _showSnackBar('කරුණාකර පළමුව ඊමේල් ලිපිනය ඇතුළත් කරන්න.');
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
        _showSnackBar('Verification Code එක ඔයාගේ ඊමේල් එකට යැව්වා.', isError: false);
      } else {
        _showSnackBar(data['message'] ?? 'OTP යැවීම අසමත් විය.');
      }
    } catch (e) {
      _showSnackBar('ජාල සම්බන්ධතා දෝෂයකි. නැවත උත්සාහ කරන්න.');
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
          'whatsapp': _whatsappController.text.trim(), // 👈 මෙන්න වට්ස්ඇප් අංකය API එකට එකතු කළා!
        },
      );

      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        String memberId = data['membership_no'] ?? '';
        _showSuccessDialog(memberId);
      } else {
        _showSnackBar(data['message'] ?? 'ලියාපදිංචි වීම අසමත් විය.');
      }
    } catch (e) {
      _showSnackBar('දත්ත යැවීමේදී දෝෂයක් සිදුවිය.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // සන්තෝෂජනක පණිවිඩය පෙන්වන ඩයලොග් එක
  void _showSuccessDialog(String membershipId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('🎉 සාර්ථකයි!', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ඔබගේ ගිණුම සාර්ථකව සාදන ලදී. ඔබගේ සාමාජික අංකය:', textAlign: TextAlign.center),
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
              const Text('විස්තර සහ උපදෙස් ඇතුළත් ඊමේල් පණිවිඩයක් ඔබ වෙත එවා ඇත. ගිණුම සක්‍රීය කරගැනීමට එහි ඇති උපදෙස් පිළිපදින්න.', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('නියමයි', style: TextStyle(fontWeight: FontWeight.bold)),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Member Registration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'CREATE NEW ACCOUNT',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), letterSpacing: 1.5),
                ),
                const SizedBox(height: 5),
                const Text('Please verify your email to continue', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 25),

                // ✉️ 1. Email Input Field
                TextFormField(
                  controller: _emailController,
                  enabled: !_otpSent,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration('Email Address', Icons.email_outlined).copyWith(
                    suffixIcon: !_otpSent
                        ? TextButton(
                      onPressed: _isLoading ? null : _sendOTP,
                      child: const Text('Send OTP', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
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

                // 🔓 OTP ලැබුණු පසු විවෘත වන කොටස
                if (_otpSent) ...[
                  // 🔢 2. OTP Code Input
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: _buildInputDecoration('Enter 6-Digit OTP Code', Icons.pin),
                    validator: (value) => value!.trim().length != 6 ? 'Enter valid 6-digit OTP' : null,
                  ),
                  const SizedBox(height: 15),

                  // 👤 3. First Name Input
                  TextFormField(
                    controller: _firstNameController,
                    decoration: _buildInputDecoration('First Name', Icons.person_outline),
                    validator: (value) => value!.trim().isEmpty ? 'Enter your first name' : null,
                  ),
                  const SizedBox(height: 15),

                  // 👤 4. Last Name Input
                  TextFormField(
                    controller: _lastNameController,
                    decoration: _buildInputDecoration('Last Name', Icons.person_outline),
                    validator: (value) => value!.trim().isEmpty ? 'Enter your last name' : null,
                  ),
                  const SizedBox(height: 15),

                  // 💬 5. WhatsApp Number Input
                  TextFormField(
                    controller: _whatsappController,
                    keyboardType: TextInputType.phone,
                    decoration: _buildInputDecoration('WhatsApp Number', Icons.phone_android_outlined),
                    validator: (value) => value!.trim().isEmpty ? 'Enter your WhatsApp number' : null,
                  ),
                  const SizedBox(height: 15),

                  // 🔑 6. Password Input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _buildInputDecoration('Password', Icons.lock_outline).copyWith(
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
                    decoration: _buildInputDecoration('Confirm Password', Icons.lock_clock_outlined).copyWith(
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
                          : const Text('REGISTER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
      ),
    );
  }
}