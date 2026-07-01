// ignore_for_file: spell_check_on_languages
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
import '../providers/payment_provider.dart';

class UploadSlipTab extends StatefulWidget {
  const UploadSlipTab({super.key});

  @override
  State<UploadSlipTab> createState() => _UploadSlipTabState();
}

class _UploadSlipTabState extends State<UploadSlipTab> {
  File? _selectedFile;
  String? _fileName;
  final List<String> _selectedMonths = [];
  DateTime? _selectedDate;

  final List<String> _months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
          _fileName = image.name;
        });
      }
    } catch (e) {
      debugPrint("Image picking error: $e");
    }
  }

  Future<void> _selectPaymentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitSlip(BuildContext context) async {
    if (_selectedMonths.isEmpty || _selectedDate == null || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select months, date and slip image! ❌"), backgroundColor: Colors.red),
      );
      return;
    }

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final String membershipNo = profileProvider.memberData?['membershipNo'] ?? '';

    if (membershipNo.isEmpty) return;

    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    bool success = await paymentProvider.uploadPaymentSlip(
      membershipNo: membershipNo,
      file: _selectedFile!,
      fileName: _fileName!,
      paymentMonths: _selectedMonths,
      paymentDate: _selectedDate!,
    );

    if (success) {
      await profileProvider.fetchAndStoreMemberData();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Slip uploaded successfully! Pending admin approval. ✅"), backgroundColor: Colors.green),
      );
      setState(() {
        _selectedFile = null;
        _fileName = null;
        _selectedMonths.clear();
        _selectedDate = null;
      });
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload failed. Please try again. ❌"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<PaymentProvider>().isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Upload a photo or screenshot of your bank transfer slip.", style: TextStyle(fontSize: 14, color: Colors.blueGrey)),
          const SizedBox(height: 20),
          const Text("Payment For Month(s)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _months.map((month) {
              return FilterChip(
                label: Text(month),
                selected: _selectedMonths.contains(month),
                onSelected: (selected) {
                  setState(() {
                    selected ? _selectedMonths.add(month) : _selectedMonths.remove(month);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text("Payment Date", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectPaymentDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_selectedDate == null ? "Select Payment Date" : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}")),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: isLoading ? null : _pickImage,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 200, width: double.infinity,
              decoration: BoxDecoration(
                color: _selectedFile == null ? Colors.blue.withValues(alpha: 0.05) : Colors.green.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _selectedFile == null ? Colors.blue.withValues(alpha: 0.5) : Colors.green, width: 2),
                image: _selectedFile != null
                    ? DecorationImage(image: FileImage(_selectedFile!), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken))
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_selectedFile == null ? Icons.add_photo_alternate : Icons.check_circle, size: 60, color: _selectedFile == null ? Colors.blue : Colors.white),
                  const SizedBox(height: 10),
                  Text(_selectedFile == null ? "Tap to select a photo" : "Image Selected!", style: TextStyle(color: _selectedFile == null ? Colors.blue : Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(_fileName ?? "JPG or PNG only", textAlign: TextAlign.center, style: TextStyle(color: _selectedFile == null ? Colors.grey : Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: isLoading ? null : () => _submitSlip(context),
              child: isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Submit Payment Slip", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}