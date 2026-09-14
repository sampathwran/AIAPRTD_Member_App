import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/app_errors.dart';

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

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final inputText = _inputController.text.trim();
    String? targetEmail;

    try {
      // Find the corresponding Email from member collection using Document ID
      final userDoc = await FirebaseFirestore.instance.collection('member').doc(inputText).get();

      if (userDoc.exists) {
        final data = userDoc.data();
        targetEmail = (data?['email'] as String?) ?? (data?['user_email'] as String?);
      } 
      
      // Fallback query just in case the ID case doesn't match perfectly
      if (targetEmail == null || targetEmail.isEmpty) {
        final userQuery = await FirebaseFirestore.instance
            .collection('member')
            .where('membershipNo', isEqualTo: inputText)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final data = userQuery.docs.first.data();
          targetEmail = (data['email'] as String?) ?? (data['user_email'] as String?);
        }
      }

      if (targetEmail == null || targetEmail.isEmpty) {
        _showErrorSnackbar("Membership number not found. Please check and try again.");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Actually send the link to the email via Firebase Auth
      await FirebaseAuth.instance.sendPasswordResetEmail(email: targetEmail);
      
      final String successMessage = 
          "A password reset link has been sent to your email address. Please check your Inbox and Spam folders.\n\n"
          "à¶¸à·”à¶»à¶´à¶¯à¶º à¶ºà·…à·’ à·ƒà·à¶šà·ƒà·“à¶¸à·š à·ƒà¶¶à·à¶³à·’à¶º (Link) à¶”à¶¶à¶œà·š à¶½à·’à¶ºà·à¶´à¶¯à·’à¶‚à¶ à·’ à¶Šà¶¸à·šà¶½à·Š à¶½à·’à¶´à·’à¶±à¶ºà¶§ à¶ºà·€à· à¶‡à¶­. à¶šà¶»à·”à¶«à·à¶šà¶» à¶”à¶¶à¶œà·š à¶Šà¶¸à·šà¶½à·Š à¶œà·’à¶«à·”à¶¸à·š Inbox à·ƒà·„ Spam à·†à·à¶½à·Šà¶©à¶» à¶´à¶»à·“à¶šà·Šà·‚à· à¶šà¶»à¶±à·Šà¶±.\n\n"
          "à®•à®Ÿà®µà¯à®šà¯à®šà¯Šà®²à¯ à®®à¯€à®Ÿà¯à®Ÿà®®à¯ˆà®ªà¯à®ªà¯ à®‡à®£à¯ˆà®ªà¯à®ªà¯ à®‰à®™à¯à®•à®³à¯ à®ªà®¤à®¿à®µà¯à®šà¯†à®¯à¯à®¯à®ªà¯à®ªà®Ÿà¯à®Ÿ à®®à®¿à®©à¯à®©à®žà¯à®šà®²à¯ à®®à¯à®•à®µà®°à®¿à®•à¯à®•à¯ à®…à®©à¯à®ªà¯à®ªà®ªà¯à®ªà®Ÿà¯à®Ÿà¯à®³à¯à®³à®¤à¯. à®¤à®¯à®µà¯à®šà¯†à®¯à¯à®¤à¯ à®‰à®™à¯à®•à®³à¯ Inbox à®®à®±à¯à®±à¯à®®à¯ Spam à®•à¯‹à®ªà¯à®ªà¯à®±à¯ˆà®•à®³à¯ˆ à®šà®°à®¿à®ªà®¾à®°à¯à®•à¯à®•à®µà¯à®®à¯.";
          
      _showSuccessSnackbar(successMessage);
      _inputController.clear();
      
    } on FirebaseAuthException catch (e) {
      String errorMsg = "An error occurred. Please try again.";
      if (e.code == 'user-not-found') {
        errorMsg = "Account not found.";
      } else if (e.code == 'too-many-requests') {
        errorMsg = "Too many attempts. Please try again later.";
      }
      _showErrorSnackbar(errorMsg);
    } catch (e) {
      _showErrorSnackbar("An error occurred. Please try again.");
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
        title: Text('auth.reset_password'.tr()),
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
                    'Enter your Membership Number below to reset your password.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 35),
                TextFormField(
                  controller: _inputController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'Membership No',
                    hintText: 'e.g. AIAPRTD-25-xxxx',
                    prefixIcon: Icon(Icons.person_outline_rounded,
                        color: colorScheme.primary, size: 22),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your membership number';
                    }
                    if (value.trim().length < 4) {
                      return 'Please enter a valid membership number';
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
                        : Text('auth.send_reset_details'.tr()),
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



