// ignore_for_file: spell_check_on_languages, spell_check_on_word

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/core/providers/auth_provider.dart';
import 'package:aiaprtd_member/features/profile/face_verification_page.dart';

class PersonalDetailsTab extends StatefulWidget {
  const PersonalDetailsTab({super.key});

  @override
  State<PersonalDetailsTab> createState() => _PersonalDetailsTabState();
}

class _PersonalDetailsTabState extends State<PersonalDetailsTab> {
  late TextEditingController _phoneController;
  final TextEditingController _otpController = TextEditingController();

  bool _isEditingPhone = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final provider = Provider.of<ProfileProvider>(context, listen: false);
      final data = provider.memberData;

      if (data != null) {
        _phoneController.text = data['mobile']?.toString() ?? '';
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showOtpDialog(String documentId, String membershipNo, String newMobile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isVerifying = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.blue),
                  SizedBox(width: 10),
                  Text(
                    "Verification Required",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "We have sent a 6-digit OTP code to your registered email address to verify your new mobile number.",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                    decoration: InputDecoration(
                      hintText: "000000",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade300,
                        letterSpacing: 4,
                      ),
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying
                      ? null
                      : () {
                    _otpController.clear();
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isVerifying
                      ? null
                      : () async {
                    final String otp = _otpController.text.trim();
                    if (otp.length < 6) return;

                    setDialogState(() {
                      isVerifying = true;
                    });

                    final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                    final profileProvider =
                    Provider.of<ProfileProvider>(context, listen: false);

                    bool isSuccess = false;

                    try {
                      isSuccess =
                      await authProvider.verifyOtpAndUpdateMobile(
                        documentId: documentId,
                        membershipNo: membershipNo,
                        newMobile: newMobile,
                        otp: otp,
                      );
                    } catch (e) {
                      debugPrint("💡 OTP Verification UI Error: $e");
                    }

                    if (!dialogContext.mounted) return;

                    setDialogState(() {
                      isVerifying = false;
                    });

                    if (isSuccess) {
                      Navigator.pop(dialogContext);

                      setState(() {
                        _isEditingPhone = false;
                        _phoneController.text = newMobile;
                        _otpController.clear();
                      });

                      await profileProvider.fetchAndStoreMemberData();

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Phone number verified and updated successfully! 🎉",
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Invalid OTP code. Please try again! ❌",
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  child: isVerifying
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    "Verify & Save",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        if (profileProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = profileProvider.memberData;

        if (data == null) {
          return const Center(child: Text("Profile data not found! ❌"));
        }

        final String documentId = profileProvider.documentId;

        final String fullName = data['fullName']?.toString() ?? 'No Name';
        final String email = data['user_email']?.toString() ?? 'No Email';
        final String mobile = data['mobile']?.toString() ?? 'No Mobile';
        final String address = data['address']?.toString() ?? 'No Address';
        final String membershipNo =
            data['membershipNo']?.toString() ?? profileProvider.documentId;
        final String nic = data['nic']?.toString() ?? 'N/A';
        final String dob = data['dob']?.toString() ?? 'N/A';
        final String gender = data['gender']?.toString() ?? 'N/A';
        final String religion = data['religion']?.toString() ?? 'N/A';

        final String faceUrl = data['faceVerificationUrl']?.toString() ?? '';

        final String faceStatus =
            data['faceKycStatus']?.toString().toLowerCase() ?? 'none';

        final String kycApprovalStatus =
            data['kycApprovalStatus']?.toString().toLowerCase() ??
                data['kycStatus']?.toString().toLowerCase() ??
                'none';

        final String mainStatus =
            data['status']?.toString().toLowerCase() ?? 'pending';

        final bool isDetailsSubmitted =
            data['isDetailsSubmitted'] == true ||
                kycApprovalStatus == 'pending' ||
                kycApprovalStatus == 'approved';

        final bool isFaceApproved = faceStatus == 'approved';
        final bool isFacePending = faceStatus == 'pending'; // 💡 NEW: Check pending face

        final bool isAdminApproved =
            kycApprovalStatus == 'approved';

        // 💡 NEW: Show "Action Required" only if it's not fully Approved and not Pending
        final bool showActionRequiredBanner =
            (!isDetailsSubmitted) || (!isFaceApproved && !isFacePending);

        if (!_isEditingPhone && _phoneController.text != mobile) {
          _phoneController.text = mobile;
        }

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        return ListView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          children: [
            if (showActionRequiredBanner)
              _buildActionRequiredBanner(
                membershipNo: membershipNo,
                documentId: documentId,
                isDetailsSubmitted: isDetailsSubmitted,
                isFaceApproved: isFaceApproved,
              )
            else if (!isAdminApproved)
              _buildPendingApprovalBanner(),

            _buildSection("Basic Info", [
              _buildReadOnlyTile(Icons.person_outline, "Full Name", fullName, isDark, colorScheme),
              Divider(
                height: 1,
                indent: 55,
                endIndent: 15,
              ),
              _buildReadOnlyTile(Icons.email_outlined, "Email", email, isDark, colorScheme),
            ], isDark, theme),

            const SizedBox(height: 20),

            _buildSection("Identity Info", [
              _buildReadOnlyTile(Icons.badge_outlined, "NIC Number", nic, isDark, colorScheme),
              Divider(
                height: 1,
                indent: 55,
                endIndent: 15,
              ),
              _buildReadOnlyTile(Icons.cake_outlined, "Date of Birth", dob, isDark, colorScheme),
              Divider(
                height: 1,
                indent: 55,
                endIndent: 15,
              ),
              _buildReadOnlyTile(
                gender.toLowerCase() == 'male'
                    ? Icons.male_outlined
                    : Icons.female_outlined,
                "Gender",
                gender,
                isDark,
                colorScheme,
              ),
              Divider(
                height: 1,
                indent: 55,
                endIndent: 15,
              ),
              _buildReadOnlyTile(
                Icons.auto_awesome_outlined,
                "Religion",
                religion,
                isDark,
                colorScheme,
              ),
            ], isDark, theme),

            const SizedBox(height: 20),

            _buildSection("Contact & Account Info", [
              _buildPhoneTile(
                documentId: documentId,
                membershipNo: membershipNo,
                mobile: mobile,
                isDark: isDark,
                colorScheme: colorScheme,
              ),
              Divider(
                height: 1,
                indent: 55,
                endIndent: 15,
              ),
              _buildReadOnlyTile(Icons.location_on_outlined, "Address", address, isDark, colorScheme),
            ], isDark, theme),

            if (faceUrl.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSection("Face Verification", [
                _buildReadOnlyTile(
                  Icons.face_retouching_natural_rounded,
                  "Face Status",
                  // 💡 NEW: Show "Pending Approval" if face status is Pending
                  isFaceApproved
                      ? "Verified Successfully ✅"
                      : (isFacePending ? "Pending Approval ⏳" : "Failed ❌"),
                  isDark,
                  colorScheme,
                ),
              ], isDark, theme),
            ],

            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  Widget _buildActionRequiredBanner({
    required String membershipNo,
    required String documentId,
    required bool isDetailsSubmitted,
    required bool isFaceApproved,
  }) {
    String message;

    if (!isDetailsSubmitted && !isFaceApproved) {
      message =
      "Please complete your One-Time Registration & Face Verification to fully activate your account. 📋";
    } else if (!isDetailsSubmitted) {
      message =
      "Please complete your One-Time Registration details to fully activate your account.";
    } else {
      message =
      "Please complete your live Face Verification to fully activate your account.";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.redAccent),
              const SizedBox(width: 10),
              Text(
                "Action Required!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.red.shade800,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (!isFaceApproved) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.face_retouching_natural, size: 20),
                label: const Text(
                  "Verify Face Now",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FaceVerificationPage(
                        membershipNo: membershipNo,
                        documentId: documentId,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingApprovalBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.pending_actions_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              // 💡 NEW: Beautified the display message
              "Your KYC details and Face Verification are pending admin approval. You will be notified once approved.",
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneTile({
    required String documentId,
    required String membershipNo,
    required String mobile,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.phone_outlined, color: colorScheme.primary, size: 22),
      ),
      title: const Text(
        "Phone Number",
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: _isEditingPhone
          ? Padding(
        padding: const EdgeInsets.only(top: 4),
        child: TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          autofocus: true,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: colorScheme.primary),
            ),
          ),
        ),
      )
          : Text(
        mobile,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      trailing: _isSaving
          ? const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : _isEditingPhone
          ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 24,
            ),
            onPressed: () async {
              final String inputMobile = _phoneController.text.trim();

              if (inputMobile.isEmpty || inputMobile == mobile) {
                setState(() {
                  _isEditingPhone = false;
                });
                return;
              }

              setState(() {
                _isSaving = true;
              });

              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final authProvider =
              Provider.of<AuthProvider>(context, listen: false);

              bool otpSent = false;

              try {
                otpSent = await authProvider.requestProfileUpdateOtp(
                  documentId: documentId,
                  newMobile: inputMobile,
                );
              } catch (e) {
                debugPrint("💡 OTP Request UI Error: $e");
              }

              if (!context.mounted) return;

              setState(() {
                _isSaving = false;
              });

              if (otpSent) {
                _showOtpDialog(documentId, membershipNo, inputMobile);
              } else {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Failed to send OTP. Please try again! ❌",
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.cancel_rounded,
              color: Colors.redAccent,
              size: 24,
            ),
            onPressed: () {
              setState(() {
                _phoneController.text = mobile;
                _isEditingPhone = false;
              });
            },
          ),
        ],
      )
          : IconButton(
        icon: const Icon(
          Icons.edit_square,
          color: Colors.blueGrey,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _isEditingPhone = true;
          });
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.blueGrey,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildReadOnlyTile(IconData icon, String title, String subtitle, bool isDark, ColorScheme colorScheme) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}