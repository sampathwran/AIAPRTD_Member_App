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

  final List<String> monthNames = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ];
  final String currentMonthName = monthNames[now.month - 1];
  final String currentYearStr = now.year.toString();

  // Calculate target month for fee validation
  // If today is < 5th, we check if the PREVIOUS month was paid (Grace Period).
  // If today is >= 5th, we check if the CURRENT month is paid.
  String targetMonthName = currentMonthName;
  String targetYearStr = currentYearStr;

  if (currentDay < 5) {
    int prevMonthIndex = now.month - 2;
    int prevYear = now.year;
    if (prevMonthIndex < 0) {
      prevMonthIndex = 11;
      prevYear -= 1;
    }
    targetMonthName = monthNames[prevMonthIndex];
    targetYearStr = prevYear.toString();
  }

  final List<dynamic> paymentHistory = data['payment_history'] ?? [];

  if (paymentHistory.isEmpty) {
    return {
      'isFeePaidValid': false,
      'reason': 'Membership Fee Not Paid 💰',
    };
  }

  bool hasPaidForTargetMonth = false;
  bool hasPaidForCurrentMonth = false;

  for (var payment in paymentHistory) {
    if (payment is Map) {
      final String pStatus =
          (payment['status'] ?? '').toString().trim().toLowerCase();
      if (pStatus == 'pending' || pStatus == 'rejected') continue;

      List<String> monthsToCheck = [];
      if (payment.containsKey('months') && payment['months'] is List) {
        monthsToCheck = (payment['months'] as List)
            .map((m) => m.toString().trim().toLowerCase())
            .toList();
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
      final String pReason = (payment['reason'] ?? payment['type'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      bool isMembershipPayment = (pReason.isEmpty ||
          pReason.contains('membership') ||
          pReason.contains('monthly') ||
          (pReason.contains('fee') && !pReason.contains('registration')));

      if (isMembershipPayment) {
        if (monthsToCheck.contains(currentMonthName.toLowerCase()) &&
            (pYear == currentYearStr || pYear.isEmpty)) {
          hasPaidForCurrentMonth = true;
        }
        if (monthsToCheck.contains(targetMonthName.toLowerCase()) &&
            (pYear == targetYearStr || pYear.isEmpty)) {
          hasPaidForTargetMonth = true;
        }
      }
    }
  }

  if (hasPaidForCurrentMonth) {
    return {
      'isFeePaidValid': true,
      'reason': '',
    };
  }

  if (!hasPaidForTargetMonth) {
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
