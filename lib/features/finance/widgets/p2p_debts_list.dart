import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/finance_provider.dart';
import 'package:aiaprtd_member/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:aiaprtd_member/features/finance/widgets/bank_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class P2PDebtsList extends StatelessWidget {
  final bool isPayable;

  const P2PDebtsList({super.key, required this.isPayable});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, financeProv, child) {
        final debts =
            isPayable ? financeProv.p2pPayables : financeProv.p2pReceivables;

        if (debts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPayable ? Icons.check_circle_outline : Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  isPayable
                      ? "You don't owe any members."
                      : "No members owe you anything.",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: debts.length,
          itemBuilder: (context, index) {
            final debt = debts[index];
            final amount = debt['amount'] ?? 0.0;
            final status = debt['status'] ?? 'pending';
            final paymentMethod = debt['paymentMethod'];

            final date = (debt['createdAt'] != null)
                ? DateFormat('MMM dd, yyyy - hh:mm a')
                    .format(debt['createdAt'].toDate())
                : 'Unknown Date';

            if (status == 'settled' || status == 'received') {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: Colors.green.shade50,
                elevation: 0,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green.shade600, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPayable
                                  ? "Paid to: ${debt['creditorId']}"
                                  : "Received from: ${debt['debtorId']}",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.green.shade900),
                            ),
                            Text(
                                "Trip: ${debt['tripId']} • Rs ${amount.toStringAsFixed(2)}",
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green.shade700)),
                          ],
                        ),
                      ),
                      Text("Settled",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.green.shade700)),
                    ],
                  ),
                ),
              );
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: Column(
                children: [
                  ListTile(
                    onTap: () => _handleDebtTap(context, financeProv, debt),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          isPayable ? Colors.red.shade50 : Colors.blue.shade50,
                      child: Icon(
                        isPayable ? Icons.arrow_outward : Icons.call_received,
                        color: isPayable
                            ? Colors.red.shade400
                            : Colors.blue.shade400,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      isPayable
                          ? "Pay to: ${debt['creditorId']}"
                          : "Receive from: ${debt['debtorId']}",
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text("Trip: ${debt['tripId']}",
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600)),
                        Text(date,
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade500)),
                        if (paymentMethod != null &&
                            paymentMethod.toString().trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            paymentMethod == 'union'
                                ? "Method: Pay to Union"
                                : "Method: Pay to Creditor",
                            style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w500),
                          ),
                        ]
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Rs ${amount.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isPayable ? Colors.red : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildStatusBadge(status),
                      ],
                    ),
                  ),
                  if (!isPayable) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: (paymentMethod == null ||
                              paymentMethod.toString().trim().isEmpty)
                          ? Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _showConfirmActionDialog(
                                      context,
                                      "Send Bank Details",
                                      "Are you sure you want to send your bank details?",
                                      () => _sendBankDetails(
                                          context, financeProv, debt),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                          color: Colors.blue.shade200),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      minimumSize: const Size(0, 32),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                    ),
                                    child: const Text("Send Bank Details",
                                        style: TextStyle(
                                            fontSize: 11, color: Colors.blue)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _showConfirmActionDialog(
                                      context,
                                      "Pay to Union",
                                      "Ask member to pay the Union account?",
                                      () => _payToUnion(
                                          context, financeProv, debt),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                          color: Colors.green.shade200),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      minimumSize: const Size(0, 32),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                    ),
                                    child: const Text("Pay to Union",
                                        style: TextStyle(
                                            fontSize: 11, color: Colors.green)),
                                  ),
                                ),
                              ],
                            )
                          : SizedBox(
                              width: double.infinity,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () => _showConfirmActionDialog(
                                  context,
                                  "Mark as Received",
                                  "Are you sure you have received this payment?",
                                  () async {
                                    try {
                                      await financeProv
                                          .settleP2PDebt(debt['debtId']);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    "Payment marked as received.")));
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text("Error: $e")));
                                      }
                                    }
                                  },
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 0),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                  elevation: 0,
                                ),
                                child: const Text("Mark as Received",
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                    ),
                  ],
                  if (isPayable &&
                      paymentMethod != null &&
                      paymentMethod.toString().trim().isNotEmpty &&
                      status != 'settled' &&
                      status != 'slip_uploaded' &&
                      status != 'pending_admin_verification') ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton.icon(
                          onPressed: () => _showUploadSlipBottomSheet(
                              context, financeProv, debt),
                          icon: const Icon(Icons.upload_file, size: 16),
                          label: const Text("Upload Payment Slip",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'settled':
        color = Colors.green;
        text = "Settled";
        break;
      case 'slip_uploaded':
        color = Colors.purple;
        text = "Verification Pending";
        break;
      case 'pending_admin_verification':
        color = Colors.purple;
        text = "Admin Review";
        break;
      case 'awaiting_payment':
        color = Colors.orange;
        text = "Awaiting Payment";
        break;
      default:
        color = Colors.grey.shade600;
        text = "Pending Method";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _handleDebtTap(BuildContext context, FinanceProvider financeProv,
      Map<String, dynamic> debt) {
    final status = debt['status'] ?? 'pending';
    final paymentMethod = debt['paymentMethod'];

    // UI Debug
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            "Tapped! ID: ${debt['debtId']} Status: $status PM: $paymentMethod")));

    debugPrint("DEBUG TAPPED - isPayable: $isPayable");
    debugPrint(
        "DEBUG TAPPED - debtId: ${debt['debtId']} / doc.id: ${debt['id']}");
    debugPrint("DEBUG TAPPED - status: $status");
    debugPrint("DEBUG TAPPED - paymentMethod: '$paymentMethod'");

    if (isPayable) {
      if (status == 'settled') return;
      if (status == 'slip_uploaded' || status == 'pending_admin_verification') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text("Payment slip already uploaded. Awaiting verification.")));
        return;
      }
      if (paymentMethod == null || paymentMethod.toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text("Waiting for the creditor to select a payment method.")));
        return;
      }
      _showUploadSlipBottomSheet(context, financeProv, debt);
    } else {
      if (status == 'settled') return;
      if (status == 'pending_admin_verification') {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Awaiting Admin verification.")));
        return;
      }
      if (status == 'slip_uploaded') {
        _showConfirmPaymentDialog(context, financeProv, debt);
        return;
      }
      if (paymentMethod != null && paymentMethod.toString().trim().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Waiting for debtor to upload payment slip.")));
      }
    }
  }

  Future<void> _sendBankDetails(BuildContext context,
      FinanceProvider financeProv, Map<String, dynamic> debt) async {
    final debtId = debt['debtId'];
    final debtorId = debt['debtorId'];
    final creditorId = debt['creditorId'];
    final amount = debt['amount']?.toString() ?? '0.00';
    final tripId = debt['tripId'] ?? '';

    try {
      // Get bank details first
      final bankDetails = await financeProv.getMemberBankDetails(creditorId);
      if (bankDetails == null ||
          bankDetails.isEmpty ||
          (bankDetails['accountNumber'] == null &&
              bankDetails['account_number'] == null)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  "Please save your bank details in Personal Info tab first.")));
        }
        return;
      }

      await financeProv.updatePaymentMethod(debtId, 'own_account');

      final bankName =
          bankDetails['bankName'] ?? bankDetails['bank_name'] ?? 'N/A';
      final accNo = bankDetails['accountNumber'] ??
          bankDetails['account_number'] ??
          'N/A';
      final accName =
          bankDetails['accountName'] ?? bankDetails['account_name'] ?? 'N/A';
      final branch = bankDetails['branch'] ?? 'N/A';

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Payment Details from $creditorId',
        'message':
            'Please transfer Rs.$amount for trip $tripId to:\nBank: $bankName\nAcc Name: $accName\nAcc No: $accNo\nBranch: $branch',
        'targetType': 'specific',
        'targetMembers': [debtorId],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Bank details sent to member.")));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _payToUnion(BuildContext context, FinanceProvider financeProv,
      Map<String, dynamic> debt) async {
    final debtId = debt['debtId'];
    final debtorId = debt['debtorId'];
    final amount = debt['amount']?.toString() ?? '0.00';
    final tripId = debt['tripId'] ?? '';

    try {
      await financeProv.updatePaymentMethod(debtId, 'union');

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Payment Instruction',
        'message':
            'Please pay the commission of Rs.$amount for trip $tripId to the Union Bank Account.',
        'targetType': 'specific',
        'targetMembers': [debtorId],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Instruction sent to member.")));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _showConfirmActionDialog(BuildContext context, String title,
      String content, VoidCallback onConfirm) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(fontSize: 14)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text("Cancel", style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  void _showUploadSlipBottomSheet(BuildContext context,
      FinanceProvider financeProv, Map<String, dynamic> debt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        File? selectedImage;
        bool isUploading = false;
        Map<String, dynamic>? creditorBankDetails;
        bool isLoadingBankDetails = debt['paymentMethod'] == 'own_account';

        return StatefulBuilder(
          builder: (ctx, setState) {
            // Fetch bank details if needed when opened
            if (isLoadingBankDetails && creditorBankDetails == null) {
              financeProv
                  .getMemberBankDetails(debt['creditorId'])
                  .then((details) {
                if (ctx.mounted) {
                  setState(() {
                    creditorBankDetails = details;
                    isLoadingBankDetails = false;
                  });
                }
              });
            }

            Future<void> pickImage(ImageSource source) async {
              final picker = ImagePicker();
              final pickedFile =
                  await picker.pickImage(source: source, imageQuality: 70);
              if (pickedFile != null)
                setState(() => selectedImage = File(pickedFile.path));
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 30,
                top: 25,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  Text("Pay Rs ${debt['amount'].toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  if (debt['paymentMethod'] == 'union')
                    BankDetailsCard(bank: financeProv.unionBankDetails)
                  else if (isLoadingBankDetails)
                    const CircularProgressIndicator()
                  else if (creditorBankDetails != null)
                    BankDetailsCard(bank: creditorBankDetails!)
                  else
                    const Text(
                        "Creditor has not saved their bank details. Please contact them.",
                        style: TextStyle(color: Colors.red)),
                  const SizedBox(height: 25),
                  if (selectedImage != null) ...[
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(selectedImage!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel,
                              color: Colors.white, size: 30),
                          onPressed: () => setState(() => selectedImage = null),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text("Camera"),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text("Gallery"),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: (selectedImage == null ||
                              isUploading ||
                              (debt['paymentMethod'] == 'own_account' &&
                                  creditorBankDetails == null))
                          ? null
                          : () async {
                              setState(() => isUploading = true);
                              try {
                                await financeProv.uploadP2PSlip(debt['debtId'],
                                    selectedImage!, debt['paymentMethod']);
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Payment slip uploaded!')));
                                }
                              } catch (e) {
                                if (ctx.mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Upload failed: $e')));
                              } finally {
                                if (ctx.mounted)
                                  setState(() => isUploading = false);
                              }
                            },
                      child: isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Submit Payment Slip",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showConfirmPaymentDialog(BuildContext context,
      FinanceProvider financeProv, Map<String, dynamic> debt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Payment"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Please review the payment slip below. Has the amount been credited to your account?"),
            const SizedBox(height: 15),
            if (debt['slipUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(debt['slipUrl'],
                    height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await financeProv.settleP2PDebt(debt['debtId']);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Marked as Settled!"),
                        backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Error settling debt."),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Yes, Received",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
