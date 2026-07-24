// ignore_for_file: spell_check_on_languages

import 'package:flutter/material.dart';

/// 💰 Checks a driver's 'payment_history' array,
/// Logic engine to verify if the membership fee for the current month is paid before the 5th.
Map<String, dynamic> checkMembershipFeeStatus(Map<String, dynamic>? data) {
  // 1. Safety check: If data is null or empty, return inactive safely.
  if (data == null || data.isEmpty) {
    return {
      'isFeePaidValid': false,
      'reason': 'Membership fee verification required.',
    };
  }

  // 2. Get the current date and time from the system
  final DateTime now = DateTime.now();
  final int currentDay = now.day;

  // 3. Get the current month name and year
  final List<String> monthNames = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];
  final String currentMonthName = monthNames[now.month - 1];
  final String currentYearStr = now.year.toString();

  // 4. Safely read payment_history from Firestore
  final List<dynamic> paymentHistory = data['payment_history'] ?? [];

  // ==========================================================
  // ⚠️ CRITICAL UX AUTOMATION LOGIC:
  // If no payments have ever been made
  // ==========================================================
  if (paymentHistory.isEmpty) {
    return {
      'isFeePaidValid': false,
      'reason': 'Membership Fee Not Paid 💰',
    };
  }

  // 5. Search through the array to check if the membership fee for the current month is paid
  bool hasPaidForCurrentMonth = false;

  debugPrint('🔍 [MembershipFeeCheck] Checking for month: $currentMonthName, year: $currentYearStr');
  debugPrint('🔍 [MembershipFeeCheck] Total payments in history: ${paymentHistory.length}');

  for (var payment in paymentHistory) {
    if (payment is Map) {
      final String pStatus = (payment['status'] ?? '').toString().trim().toLowerCase();
      
      if (pStatus == 'pending' || pStatus == 'rejected') {
        debugPrint('🔍 [MembershipFeeCheck] Skipping payment due to status: $pStatus');
        continue;
      }

      List<String> monthsToCheck = [];
      if (payment.containsKey('months') && payment['months'] is List) {
        monthsToCheck = (payment['months'] as List).map((m) => m.toString().trim().toLowerCase()).toList();
      } else {
        String mStr = (payment['month'] ?? '').toString().trim().toLowerCase();
        monthsToCheck = [mStr];

        if (int.tryParse(mStr) != null) {
          int mInt = int.parse(mStr);
          if (mInt >= 1 && mInt <= 12) {
            monthsToCheck.add(monthNames[mInt - 1].toLowerCase());
          }
        }
      }

      final String pYear = (payment['year'] ?? '').toString().trim();
      final String pReason = (payment['reason'] ?? payment['type'] ?? '').toString().trim().toLowerCase();

      bool isMembershipPayment = (pReason.isEmpty ||
          pReason.contains('membership') ||
          pReason.contains('monthly') ||
          (pReason.contains('fee') && !pReason.contains('registration')));

      debugPrint('🔍 [MembershipFeeCheck] Found payment: Month=$monthsToCheck, Year=$pYear, Reason=$pReason, isMembership=$isMembershipPayment');

      if (monthsToCheck.contains(currentMonthName.toLowerCase()) &&
          (pYear == currentYearStr || pYear.isEmpty) &&
          isMembershipPayment) {
        hasPaidForCurrentMonth = true;
        debugPrint('✅ [MembershipFeeCheck] Valid payment found for current month!');
        break; 
      }
    }
  }

  if (currentDay >= 5 && !hasPaidForCurrentMonth) {
    debugPrint('❌ [MembershipFeeCheck] No valid payment found. Day is $currentDay (>=5). Blocking.');
    return {
      'isFeePaidValid': false,
      'reason': 'Pending Membership Fee 💰',
    };
  }

  debugPrint('✅ [MembershipFeeCheck] Fee is valid or within grace period.');
  return {
    'isFeePaidValid': true,
    'reason': '',
  };
}