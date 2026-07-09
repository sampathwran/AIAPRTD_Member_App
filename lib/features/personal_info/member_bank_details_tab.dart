// ignore_for_file: spell_check_on_languages

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart'; // 💡 NEW: Local Auth package

import 'package:aiaprtd_member/core/providers/payment_provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';

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

  final List<String> _sriLankaBanks = [
    "Amana Bank",
    "Bank of Ceylon (BOC)",
    "Cargills Bank",
    "Commercial Bank",
    "DFCC Bank",
    "Habib Bank",
    "Hatton National Bank (HNB)",
    "HDFC Bank",
    "National Development Bank (NDB)",
    "Nations Trust Bank (NTB)",
    "Pan Asia Bank",
    "People's Bank",
    "Sampath Bank",
    "Sanasa Development Bank (SDB)",
    "Seylan Bank",
    "Standard Chartered Bank",
    "State Bank of India (SBI)",
    "Union Bank",
  ];

  final LocalAuthentication auth = LocalAuthentication(); // 💡 NEW: Auth instance

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

  // 💡 NEW: Face ID / Fingerprint Auth Function
  Future<void> _authenticateAndEdit() async {
    if (_isEditing) {
      // If already editing, just cancel without auth
      setState(() {
        _isEditing = false;
      });
      return;
    }

    bool authenticated = false;
    try {
      final bool isSupported = await auth.isDeviceSupported();
      if (!isSupported) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Security Warning: Your device does not support screen lock. You cannot edit bank details."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      authenticated = await auth.authenticate(
        localizedReason: 'Verify your identity to edit bank details',
        biometricOnly: false, // Allows PIN/Pattern as fallback
        persistAcrossBackgrounding: true, 
      );
    } on PlatformException catch (e) {
      debugPrint("Auth Error: $e");
      if (!mounted) return;
      
      String errorMessage = "Security verification failed.";
      
      // Checking common error codes for missing screen lock
      if (e.code == 'NotEnrolled' || e.code == 'PasscodeNotSet' || e.code == 'NotAvailable') {
        errorMessage = "Please set up a Screen Lock (PIN, Password, or Fingerprint) in your phone settings to edit bank details securely.";
      } else {
        errorMessage = "Error: ${e.message} (${e.code}).";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    if (authenticated) {
      if (!mounted) return;
      setState(() {
        _isEditing = true;
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Authentication required to edit details."),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = Provider.of<PaymentProvider>(context);
    final bankData = paymentProvider.bankData;

    // 💡 Check if data already exists
    final bool hasData = bankData != null &&
        bankData['accountNumber'] != null &&
        bankData['accountNumber'].toString().trim().isNotEmpty;

    // 💡 Form is shown only if Edit is pressed or if there is no data
    final bool showForm = _isEditing || !hasData;

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
            _buildBankCard(),

            const SizedBox(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Bank Account Information",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                // Show Edit/Cancel button only if there is data (New users shouldn't see this)
                if (hasData)
                  TextButton.icon(
                    onPressed: _authenticateAndEdit, // 💡 FIXED: Now requires Auth to Edit
                    icon: Icon(_isEditing ? Icons.close : Icons.security_rounded, size: 18),
                    label: Text(_isEditing ? "Cancel" : "Verify & Edit"),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // 💡 Load these only when the form needs to be shown
            if (showForm) ...[
              _buildTextField(
                controller: _holderNameController,
                label: "Account Holder Name",
                icon: Icons.person_outline,
                enabled: true, // If shown, it must be typable
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _bankNameController.text.isNotEmpty && _sriLankaBanks.contains(_bankNameController.text)
                    ? _bankNameController.text
                    : null,
                decoration: InputDecoration(
                  labelText: "Bank Name",
                  prefixIcon: const Icon(Icons.account_balance_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _sriLankaBanks.map((bank) {
                  return DropdownMenuItem(
                    value: bank,
                    child: Text(bank, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    _bankNameController.text = val;
                  }
                },
                validator: (v) => v == null || v.isEmpty ? "Please select a bank" : null,
                isExpanded: true,
              ),

              const SizedBox(height: 15),

              _buildTextField(
                controller: _branchController,
                label: "Branch Name",
                icon: Icons.location_on_outlined,
                enabled: true,
              ),

              const SizedBox(height: 15),

              _buildTextField(
                controller: _branchCodeController,
                label: "Branch Code",
                icon: Icons.numbers_rounded,
                enabled: true,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 15),

              _buildTextField(
                controller: _accountNoController,
                label: "Account Number",
                icon: Icons.pin_outlined,
                enabled: true,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
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
                            "Bank details updated successfully! ✅",
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );

                      setState(() {
                        _isEditing = false;
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Failed to update bank details"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: paymentProvider.isLocalLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Save Bank Details",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
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
          gradient: LinearGradient(
            colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
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
                Flexible(
                  child: Text(
                    widget.membershipNo,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                maskedAccount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            _cardSmallText(
              "BANK NAME",
              _bankNameController.text.isEmpty
                  ? "N/A"
                  : _bankNameController.text,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _cardSmallText(
                    "BRANCH",
                    _branchController.text.isEmpty
                        ? "N/A"
                        : _branchController.text,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _cardSmallText(
                    "BRANCH CODE",
                    _branchCodeController.text.isEmpty
                        ? "N/A"
                        : _branchCodeController.text,
                    alignRight: true,
                  ),
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