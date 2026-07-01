// ignore_for_file: spell_check_on_languages

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/payment_provider.dart';
import '../providers/profile_provider.dart';

class BankDetailsTab extends StatefulWidget {
  final String membershipNo;

  const BankDetailsTab({super.key, required this.membershipNo});

  @override
  State<BankDetailsTab> createState() => _BankDetailsTabState();
}

class _BankDetailsTabState extends State<BankDetailsTab> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _branchCodeController = TextEditingController();
  final TextEditingController _accountNoController = TextEditingController();
  final TextEditingController _holderNameController = TextEditingController();

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<PaymentProvider>(context, listen: false)
          .fetchBankDetails(widget.membershipNo);
    });
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _branchController.dispose();
    _branchCodeController.dispose();
    _accountNoController.dispose();
    _holderNameController.dispose();
    super.dispose();
  }

  void _loadExistingData(Map<String, dynamic>? bankData) {
    if (bankData != null && !_isEditing) {
      _bankNameController.text = bankData['bankName']?.toString() ?? '';
      _branchController.text = bankData['branchName']?.toString() ?? '';
      _branchCodeController.text = bankData['branchCode']?.toString() ?? '';
      _accountNoController.text = bankData['accountNumber']?.toString() ?? '';
      _holderNameController.text =
          bankData['accountHolderName']?.toString() ?? '';
    }
  }

  String _maskAccountNumber(String accountNumber) {
    final clean = accountNumber.trim();

    if (clean.isEmpty) return "XXXX XXXX XXXX";
    if (clean.length <= 4) return clean;

    final last4 = clean.substring(clean.length - 4);
    return "XXXX XXXX $last4";
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = Provider.of<PaymentProvider>(context);
    final bankData = paymentProvider.bankData;

    final String bankUpdateStatus =
        bankData?['bankUpdateStatus']?.toString().toLowerCase() ?? 'approved';

    final bool isPending = bankUpdateStatus == 'pending';

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final String documentId = profileProvider.documentId;

    _loadExistingData(bankData);

    if (paymentProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPending) _buildPendingBanner(),

            _buildBankCard(),

            const SizedBox(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Bank Account Information",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (!isPending)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isEditing = !_isEditing;
                      });
                    },
                    icon: Icon(_isEditing ? Icons.close : Icons.edit, size: 18),
                    label: Text(_isEditing ? "Cancel" : "Edit"),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            _buildTextField(
              controller: _holderNameController,
              label: "Account Holder Name",
              icon: Icons.person_outline,
              enabled: _isEditing,
            ),

            const SizedBox(height: 15),

            _buildTextField(
              controller: _bankNameController,
              label: "Bank Name",
              icon: Icons.account_balance_outlined,
              enabled: _isEditing,
            ),

            const SizedBox(height: 15),

            _buildTextField(
              controller: _branchController,
              label: "Branch Name",
              icon: Icons.location_on_outlined,
              enabled: _isEditing,
            ),

            const SizedBox(height: 15),

            _buildTextField(
              controller: _branchCodeController,
              label: "Branch Code",
              icon: Icons.numbers_rounded,
              enabled: _isEditing,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 15),

            _buildTextField(
              controller: _accountNoController,
              label: "Account Number",
              icon: Icons.pin_outlined,
              enabled: _isEditing,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 25),

            if (_isEditing)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: paymentProvider.isLocalLoading
                      ? null
                      : () async {
                    if (!_formKey.currentState!.validate()) return;

                    final success =
                    await paymentProvider.requestBankDetailsUpdate(
                      documentId: documentId,
                      membershipNo: widget.membershipNo,
                      bankName: _bankNameController.text.trim(),
                      branchName: _branchController.text.trim(),
                      branchCode: _branchCodeController.text.trim(),
                      accountNumber: _accountNoController.text.trim(),
                      accountHolderName:
                      _holderNameController.text.trim(),
                    );

                    if (!context.mounted) return;

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Bank details submitted for admin review! ⏳",
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );

                      setState(() {
                        _isEditing = false;
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Failed to submit update request"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: paymentProvider.isLocalLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Submit for Admin Approval",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded,
              color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Your new bank details are under admin review. You cannot edit again until approved or rejected.",
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankCard() {
    final maskedAccount = _maskAccountNumber(_accountNoController.text);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.credit_card, color: Colors.white, size: 30),
                Text(
                  widget.membershipNo,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              maskedAccount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "ACCOUNT HOLDER",
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
            Text(
              _holderNameController.text.isEmpty
                  ? "N/A"
                  : _holderNameController.text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _cardSmallText(
                    "BANK / BRANCH",
                    _bankNameController.text.isEmpty
                        ? "N/A"
                        : "${_bankNameController.text} - ${_branchController.text}",
                  ),
                ),
                const SizedBox(width: 10),
                _cardSmallText(
                  "BRANCH CODE",
                  _branchCodeController.text.isEmpty
                      ? "N/A"
                      : _branchCodeController.text,
                  alignRight: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardSmallText(String title, String value, {bool alignRight = false}) {
    return Column(
      crossAxisAlignment:
      alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (v) => v == null || v.trim().isEmpty ? "Required Field" : null,
    );
  }
}