// ignore_for_file: spell_check_on_languages

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

  for (var payment in paymentHistory) {
    if (payment is Map) {
      final String pStatus = (payment['status'] ?? '').toString().trim().toLowerCase();
      // Only consider approved or completed payments (skip pending/rejected)
      if (pStatus == 'pending' || pStatus == 'rejected') {
        continue;
      }

      List<String> monthsToCheck = [];
      if (payment.containsKey('months') && payment['months'] is List) {
        monthsToCheck = (payment['months'] as List).map((m) => m.toString().trim().toLowerCase()).toList();
      } else {
        String mStr = (payment['month'] ?? '').toString().trim().toLowerCase();
        monthsToCheck = [mStr];

        // If the month is stored as a number (e.g. "7" or "07")
        if (int.tryParse(mStr) != null) {
          int mInt = int.parse(mStr);
          if (mInt >= 1 && mInt <= 12) {
            monthsToCheck.add(monthNames[mInt - 1].toLowerCase());
          }
        }
      }

      final String pYear = (payment['year'] ?? '').toString().trim();
      final String pReason = (payment['reason'] ?? payment['type'] ?? '').toString().trim().toLowerCase();

      bool isMembershipPayment = pReason.isEmpty ||
          pReason.contains('membership') ||
          pReason.contains('fee') ||
          pReason.contains('monthly');

      if (monthsToCheck.contains(currentMonthName.toLowerCase()) &&
          (pYear == currentYearStr || pYear.isEmpty) &&
          isMembershipPayment) {
        hasPaidForCurrentMonth = true;
        break; // Stop the loop since a valid payment is found
      }
    }
  }

  // ==========================================================
  // ⚠️ Block if the day is >= 5 AND no payment is made for current month
  // ==========================================================
  if (currentDay >= 5 && !hasPaidForCurrentMonth) {
    return {
      'isFeePaidValid': false,
      'reason': 'Pending Membership Fee 💰',
    };
  }

  // 🟢 If within the grace period (1st-4th) OR paid successfully
  return {
    'isFeePaidValid': true,
    'reason': '',
  };
}