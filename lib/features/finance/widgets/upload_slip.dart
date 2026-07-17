import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/finance_provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/core/theme/app_theme.dart';
import 'package:aiaprtd_member/features/finance/widgets/bank_details.dart';

void showUploadSlipDialog(BuildContext context) {
  final finance = Provider.of<FinanceProvider>(context, listen: false);
  final profile = Provider.of<ProfileProvider>(context, listen: false);
  final bank = finance.unionBankDetails;
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      bool isUploading = false;
      File? selectedImage;

      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickImage(ImageSource source) async {
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(
              source: source,
              imageQuality: 70,
            );
            if (pickedFile != null) {
              setState(() => selectedImage = File(pickedFile.path));
            }
          }

          Future<void> handleUpload() async {
            if (selectedImage == null) return;
            
            setState(() => isUploading = true);
            try {
              final String memNo = profile.memberNo;
              final double currentBalance = finance.myAppUsageChargeBalance;
              
              final String fileName = 'app_usage_slip_${memNo}_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final Reference ref = FirebaseStorage.instance.ref().child('app_usage_payments/$memNo/$fileName');
              
              final UploadTask uploadTask = ref.putFile(selectedImage!);
              final TaskSnapshot snapshot = await uploadTask;
              final String downloadUrl = await snapshot.ref.getDownloadURL();

              final docRef = FirebaseFirestore.instance.collection('app_usage_payments').doc();
              await docRef.set({
                'paymentId': docRef.id,
                'driverId': memNo,
                'amount': currentBalance, // Full balance is paid
                'imageUrl': downloadUrl,
                'status': 'pending',
                'timestamp': FieldValue.serverTimestamp(),
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment slip uploaded. Waiting for admin approval.')));
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload slip: $e')));
              }
            } finally {
              if (context.mounted) setState(() => isUploading = false);
            }
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 30,
              top: 25,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                const Text("Pay App Usage Charge", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                BankDetailsCard(bank: bank),
                const SizedBox(height: 15),
                
                // Commission Info Note
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Note: A ${finance.driverCommissionRate.toStringAsFixed(0)}% commission per trip is currently set by the Admin Panel. This percentage may change as determined by the Union.",
                          style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                
                if (selectedImage != null) ...[
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(selectedImage!, height: 150, width: double.infinity, fit: BoxFit.cover),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.white, size: 30),
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
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.image),
                          label: const Text("Gallery"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: isUploading || selectedImage == null ? null : handleUpload,
                    icon: isUploading ? const SizedBox.shrink() : const Icon(Icons.cloud_upload, color: Colors.white),
                    label: isUploading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Submit Bank Slip", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      );
    },
  );
}
