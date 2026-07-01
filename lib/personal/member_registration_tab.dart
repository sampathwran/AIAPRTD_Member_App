// ignore_for_file: spell_check_on_languages

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
import '../providers/kyc_provider.dart';
import '../profile/face_verification_page.dart';

class MemberRegistrationTab extends StatefulWidget {
  const MemberRegistrationTab({super.key});

  @override
  State<MemberRegistrationTab> createState() => _MemberRegistrationTabState();
}

class _MemberRegistrationTabState extends State<MemberRegistrationTab> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _nicController = TextEditingController();
  final _dobController = TextEditingController();

  String? _selectedReligion;
  String? _selectedGender;

  File? _idFrontImage;
  File? _idBackImage;

  final ImagePicker _picker = ImagePicker();

  final List<String> _religions = [
    "Buddhism",
    "Hinduism",
    "Islam",
    "Christianity",
    "Other",
  ];

  final List<String> _genders = [
    "Male",
    "Female",
    "Other",
  ];

  bool _dataLoadedToForm = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_dataLoadedToForm) return;

    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final data = provider.memberData;

    if (data != null) {
      _fullNameController.text = data['fullName']?.toString() ?? '';
      _emailController.text = data['user_email']?.toString() ?? '';
      _mobileController.text = data['mobile']?.toString() ?? '';
      _nicController.text = data['nic']?.toString() ?? '';
      _dobController.text = data['dob']?.toString() ?? '';
      _addressController.text = data['address']?.toString() ?? '';

      final religion = data['religion']?.toString();
      final gender = data['gender']?.toString();

      if (religion != null && _religions.contains(religion)) {
        _selectedReligion = religion;
      }

      if (gender != null && _genders.contains(gender)) {
        _selectedGender = gender;
      }

      _dataLoadedToForm = true;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _nicController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    FocusScope.of(context).unfocus();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E3A8A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate =
          "${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}";

      setState(() {
        _dobController.text = formattedDate;
      });
    }
  }

  Future<void> _captureImage(int type) async {
    FocusScope.of(context).unfocus();

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() {
        if (type == 1) {
          _idFrontImage = File(pickedFile.path);
        } else {
          _idBackImage = File(pickedFile.path);
        }
      });
    } catch (e) {
      debugPrint("Camera Error: $e");

      if (!mounted) return;
      _showSnackBar("Camera error. Please try again.", Colors.redAccent);
    }
  }

  Future<void> _submitForm({
    required String membershipNo,
    required String documentId,
  }) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_idFrontImage == null || _idBackImage == null) {
      _showSnackBar(
        "Please capture both ID Card Front & Back.",
        Colors.redAccent,
      );
      return;
    }

    final confirm = await _showConfirmDialog();

    if (confirm != true) return;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
      ),
    );

    final kycProvider = Provider.of<KYCProvider>(context, listen: false);

    final success = await kycProvider.submitOneTimeRegistrationDetails(
      membershipNo: membershipNo,
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      mobile: _mobileController.text.trim(),
      nic: _nicController.text.trim(),
      address: _addressController.text.trim(),
      dob: _dobController.text.trim(),
      religion: _selectedReligion!,
      gender: _selectedGender!,
      idFrontFile: _idFrontImage!,
      idBackFile: _idBackImage!,
      documentId: documentId,
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FaceVerificationPage(
            membershipNo: membershipNo,
            documentId: documentId,
          ),
        ),
      );
    } else {
      _showSnackBar(
        "Failed to submit data. Please try again.",
        Colors.redAccent,
      );
    }
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Confirm Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "These details will be sent for admin approval. They will not be permanently saved until admin approves them.",
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final data = profileProvider.memberData;

        if (data == null) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
          );
        }

        final String documentId = profileProvider.documentId;
        final String membershipNo = data['membershipNo']?.toString() ?? '';

        final String kycApprovalStatus =
            data['kycApprovalStatus']?.toString().toLowerCase() ??
                data['kycStatus']?.toString().toLowerCase() ??
                'none';

        final String faceStatus =
            data['faceKycStatus']?.toString().toLowerCase() ?? 'pending';

        final String mainStatus =
            data['status']?.toString().toLowerCase() ?? 'pending';

        final bool isAdminApproved =
            kycApprovalStatus == 'approved' || mainStatus == 'active';

        final bool isPending =
            kycApprovalStatus == 'pending' ||
                data['isDetailsSubmitted'] == true;

        final bool isRejected = kycApprovalStatus == 'rejected';

        final bool isFaceApproved = faceStatus == 'approved';

        final bool isFullyVerified = isAdminApproved && isFaceApproved;

        if (isPending || isAdminApproved || isRejected) {
          return _buildStatusScreen(
            context: context,
            membershipNo: membershipNo,
            documentId: documentId,
            isFullyVerified: isFullyVerified,
            isAdminApproved: isAdminApproved,
            isFaceApproved: isFaceApproved,
            isRejected: isRejected,
            rejectReason: data['kycRejectReason']?.toString(),
          );
        }

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 18),

                  _sectionTitle("Step 1: Identity & Contact"),

                  _buildCardSection([
                    _buildTextField(
                      controller: _fullNameController,
                      label: "Full Name",
                      icon: Icons.person_outline,
                      validatorText: "Enter your full name",
                    ),
                    _divider(),
                    _buildTextField(
                      controller: _nicController,
                      label: "NIC Number",
                      icon: Icons.badge_outlined,
                      validatorText: "Enter your NIC number",
                    ),
                    _divider(),
                    _buildTextField(
                      controller: _mobileController,
                      label: "Mobile Number",
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validatorText: "Enter your mobile number",
                    ),
                    _divider(),
                    _buildTextField(
                      controller: _emailController,
                      label: "Email Address",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validatorText: "Enter your email",
                    ),
                  ]),

                  const SizedBox(height: 22),
                  _sectionTitle("Step 2: Personal Details"),

                  _buildCardSection([
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      decoration: _inputDecoration(
                        "Date of Birth",
                        Icons.calendar_month_outlined,
                        suffixIcon: Icons.touch_app_rounded,
                      ),
                      validator: (v) =>
                      v == null || v.isEmpty ? "Select your date of birth" : null,
                    ),
                    _divider(),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: _dropdownDecoration("Select Gender"),
                      items: _genders
                          .map(
                            (g) => DropdownMenuItem(
                          value: g,
                          child: Text(g),
                        ),
                      )
                          .toList(),
                      onChanged: (v) {
                        setState(() => _selectedGender = v);
                      },
                      validator: (v) => v == null ? "Select your gender" : null,
                    ),
                    _divider(),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedReligion,
                      decoration: _dropdownDecoration("Select Religion"),
                      items: _religions
                          .map(
                            (r) => DropdownMenuItem(
                          value: r,
                          child: Text(r),
                        ),
                      )
                          .toList(),
                      onChanged: (v) {
                        setState(() => _selectedReligion = v);
                      },
                      validator: (v) => v == null ? "Select your religion" : null,
                    ),
                    _divider(),

                    _buildTextField(
                      controller: _addressController,
                      label: "Permanent Address",
                      icon: Icons.home_outlined,
                      maxLines: 2,
                      validatorText: "Enter your address",
                    ),
                  ]),

                  const SizedBox(height: 22),
                  _sectionTitle("Step 3: Upload Official Identity Cards"),

                  _buildImageCaptureTile(
                    title: "Capture ID Card Front",
                    subtitle: "Take a clear real-time photo of NIC front side",
                    imageFile: _idFrontImage,
                    icon: Icons.credit_card_rounded,
                    onTap: () => _captureImage(1),
                  ),

                  const SizedBox(height: 15),

                  _buildImageCaptureTile(
                    title: "Capture ID Card Back",
                    subtitle: "Take a clear real-time photo of NIC back side",
                    imageFile: _idBackImage,
                    icon: Icons.credit_card_rounded,
                    onTap: () => _captureImage(2),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                      ),
                      onPressed: () => _submitForm(
                        membershipNo: membershipNo,
                        documentId: documentId,
                      ),
                      icon: const Icon(Icons.verified_user_rounded),
                      label: const Text(
                        "Submit & Continue Face Scan",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusScreen({
    required BuildContext context,
    required String membershipNo,
    required String documentId,
    required bool isFullyVerified,
    required bool isAdminApproved,
    required bool isFaceApproved,
    required bool isRejected,
    String? rejectReason,
  }) {
    final Color mainColor = isFullyVerified
        ? Colors.green
        : isRejected
        ? Colors.redAccent
        : Colors.orange;

    final IconData mainIcon = isFullyVerified
        ? Icons.verified_rounded
        : isRejected
        ? Icons.cancel_rounded
        : Icons.pending_actions_rounded;

    final String title = isFullyVerified
        ? "Profile Fully Verified"
        : isRejected
        ? "Verification Rejected"
        : "Verification in Progress";

    final String description = isFullyVerified
        ? "Your personal details and biometric scan are fully verified."
        : isRejected
        ? "Your submitted details were rejected. Please contact admin or submit correct details again."
        : "Your details are under admin review. Permanent changes will apply after approval.";

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(mainIcon, color: mainColor, size: 86),
            const SizedBox(height: 16),
            Text(
              "$title ${isFullyVerified ? '✅' : isRejected ? '❌' : '⏳'}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.45,
              ),
            ),
            if (isRejected && rejectReason != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Text(
                  "Reason: $rejectReason",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 30),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _statusTile(
                    title: "Personal Details Approval",
                    subtitle: isAdminApproved
                        ? "Approved by admin"
                        : isRejected
                        ? "Rejected by admin"
                        : "Pending admin review",
                    icon: Icons.domain_verification_rounded,
                    color: isAdminApproved
                        ? Colors.green
                        : isRejected
                        ? Colors.redAccent
                        : Colors.orange,
                    completed: isAdminApproved,
                  ),
                  const Divider(height: 1, indent: 65),
                  _statusTile(
                    title: "Biometric Face Scan",
                    subtitle: isFaceApproved
                        ? "Face scan verified"
                        : "Face scan required / pending",
                    icon: Icons.face_retouching_natural_rounded,
                    color: isFaceApproved ? Colors.blue : Colors.orange,
                    completed: isFaceApproved,
                    trailing: !isFaceApproved && isAdminApproved
                        ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 34),
                        padding:
                        const EdgeInsets.symmetric(horizontal: 12),
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
                      child: const Text(
                        "Scan Now",
                        style: TextStyle(fontSize: 11),
                      ),
                    )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool completed,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      trailing: trailing ??
          (completed
              ? Icon(Icons.check_circle, color: color)
              : Icon(Icons.hourglass_top_rounded, color: color)),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF2563EB),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.security_rounded, color: Colors.white, size: 30),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Review your web records and correct any mistakes. This is a one-time secure update. Admin approval is required before permanent save.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.blueGrey.shade700,
        ),
      ),
    );
  }

  Widget _buildCardSection(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String validatorText,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      decoration: _inputDecoration(label, icon),
      validator: (v) => v == null || v.trim().isEmpty ? validatorText : null,
    );
  }

  InputDecoration _inputDecoration(
      String label,
      IconData icon, {
        IconData suffixIcon = Icons.edit_rounded,
      }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Color(0xFF1E3A8A)),
      suffixIcon: Icon(suffixIcon, size: 16, color: Colors.grey),
      border: InputBorder.none,
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.check_circle_outline, color: Color(0xFF1E3A8A)),
      border: InputBorder.none,
    );
  }

  Widget _divider() {
    return const Divider(height: 1, color: Color(0xFFF1F5F9));
  }

  Widget _buildImageCaptureTile({
    required String title,
    required String subtitle,
    required File? imageFile,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: const Color(0xFF1E3A8A), size: 25),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 3),
                        Text(subtitle,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (imageFile != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.file(
                        imageFile,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.autorenew,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              "Retake",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  height: 62,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        "Tap to Open Camera",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}