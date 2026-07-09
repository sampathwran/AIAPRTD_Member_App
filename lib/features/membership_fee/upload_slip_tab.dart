// ignore_for_file: spell_check_on_languages
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/core/providers/payment_provider.dart';

class UploadSlipTab extends StatefulWidget {
  final bool isDark;
  const UploadSlipTab({super.key, required this.isDark});

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
    final isDark = widget.isDark;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: isDark ? ThemeData.dark() : ThemeData.light(),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitSlip(BuildContext context) async {
    if (_selectedMonths.isEmpty || _selectedDate == null || _selectedFile == null) {
      _showSnackBar("Please select months, date and slip image! ❌", Colors.red.shade600);
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
      _showSnackBar("Slip uploaded successfully! Pending admin approval. ✅", Colors.green.shade600);
      setState(() {
        _selectedFile = null;
        _fileName = null;
        _selectedMonths.clear();
        _selectedDate = null;
      });
    } else {
      if (!context.mounted) return;
      _showSnackBar("Upload failed. Please try again. ❌", Colors.red.shade600);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<PaymentProvider>().isLoading;
    final isDark = widget.isDark;

    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.blueGrey;
    final cardBgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final cardBorderColor = isDark ? Colors.white12 : Colors.grey.shade300;
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.blue.withValues(alpha: 0.3) : Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: isDark ? Colors.blue.shade300 : Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Upload a clear photo or screenshot of your bank transfer slip.",
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.blue.shade200 : Colors.blue.shade900, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ========================================================
          // MONTH SELECTION
          // ========================================================
          Text("Payment For Month(s)", style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _months.map((month) {
              final isSelected = _selectedMonths.contains(month);
              return FilterChip(
                label: Text(month),
                selected: isSelected,
                showCheckmark: false,
                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                selectedColor: isDark ? Colors.blue.shade700 : Colors.blue.shade100,
                side: BorderSide(
                  color: isSelected 
                      ? (isDark ? Colors.blue.shade400 : Colors.blue.shade400) 
                      : (isDark ? Colors.white12 : Colors.grey.shade300)
                ),
                labelStyle: TextStyle(
                  color: isSelected 
                      ? (isDark ? Colors.white : Colors.blue.shade900) 
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  setState(() {
                    selected ? _selectedMonths.add(month) : _selectedMonths.remove(month);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ========================================================
          // DATE SELECTION
          // ========================================================
          Text("Payment Date", style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15)),
          const SizedBox(height: 12),
          Material(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _selectPaymentDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: cardBorderColor),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: subtitleColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDate == null ? "Select Payment Date" : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                        style: TextStyle(
                          color: _selectedDate == null ? subtitleColor : textColor,
                          fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.bold,
                          fontSize: 15
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subtitleColor),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ========================================================
          // IMAGE SELECTION
          // ========================================================
          Text("Slip Image", style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15)),
          const SizedBox(height: 12),
          InkWell(
            onTap: isLoading ? null : _pickImage,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 200, width: double.infinity,
              decoration: BoxDecoration(
                color: _selectedFile == null 
                    ? (isDark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.05))
                    : (isDark ? Colors.green.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedFile == null 
                      ? (isDark ? Colors.blue.shade700 : Colors.blue.shade300) 
                      : (isDark ? Colors.green.shade700 : Colors.green.shade400), 
                  width: 2,
                  style: BorderStyle.solid
                ),
                image: _selectedFile != null
                    ? DecorationImage(
                        image: FileImage(_selectedFile!), 
                        fit: BoxFit.cover, 
                        colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.5), BlendMode.darken)
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedFile == null ? Icons.add_photo_alternate_rounded : Icons.check_circle_rounded, 
                    size: 60, 
                    color: _selectedFile == null 
                        ? (isDark ? Colors.blue.shade300 : Colors.blue) 
                        : Colors.white
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedFile == null ? "Tap to select a photo" : "Image Selected!", 
                    style: TextStyle(
                      color: _selectedFile == null 
                          ? (isDark ? Colors.blue.shade200 : Colors.blue) 
                          : Colors.white, 
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                    )
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _fileName ?? "JPG or PNG only", 
                    textAlign: TextAlign.center, 
                    style: TextStyle(
                      color: _selectedFile == null 
                          ? (isDark ? Colors.blue.shade200.withValues(alpha: 0.7) : Colors.blueGrey) 
                          : Colors.white70, 
                      fontSize: 13
                    )
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          
          // ========================================================
          // SUBMIT BUTTON
          // ========================================================
          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.blue.shade700 : Colors.blue.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
              ),
              onPressed: isLoading ? null : () => _submitSlip(context),
              child: isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Text("Submit Payment Slip", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}