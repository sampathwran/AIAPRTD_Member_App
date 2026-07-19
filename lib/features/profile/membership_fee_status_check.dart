// ignore_for_file: spell_check_on_languages

/// 💰 Checks a driver's 'payment_history' array,
/// Logic engine to verify if the membership fee for the current month is paid before the 5th.
Map<String, dynamic> checkMembershipFeeStatus(Map<String, dynamic>? data) {

  // 1. Safety check: If data is null or empty, return true instead of blocking incorrectly.
  if (data == null || data.isEmpty) {
    return {
      'isFeePaidValid': true,
      'reason': '',
    };
  }

  // 2. CRITICAL FIX: If 'payment_history' key is not yet received from Firestore (Data Loading delay),
  // allow going online until data arrives to prevent incorrect blocking!
  if (!data.containsKey('payment_history') || data['payment_history'] == null) {
    return {
      'isFeePaidValid': true, // This line allows going online immediately after opening the app!
      'reason': '',
    };
  }

  // 3. Get the current date and time from the system
  final DateTime now = DateTime.now();
  final int currentDay = now.day; // Current day of the month (1 - 31)

  // 4. Get the current month name in English
  final List<String> monthNames = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];
  final String currentMonthName = monthNames[now.month - 1]; // Current month name
  final String currentYearStr = now.year.toString(); // Current year

  // 5. Safely read both payment_history and pending_payments arrays from Firestore
  final List<dynamic> paymentHistory = data['payment_history'] ?? [];
  final List<dynamic> pendingPayments = data['pending_payments'] ?? [];
  final List<dynamic> allPaymentsToCheck = [...paymentHistory, ...pendingPayments];

  // 6. Search through the array to check if the membership fee for the current month is paid or pending
  bool hasPaidForCurrentMonth = false;

  for (var payment in allPaymentsToCheck) {
    if (payment is Map) {
      // Handle case where pending payments might have a 'months' array instead of a single 'month' string
      List<String> monthsToCheck = [];
      if (payment.containsKey('months') && payment['months'] is List) {
        monthsToCheck = (payment['months'] as List).map((m) => m.toString().trim().toLowerCase()).toList();
      } else {
        String mStr = (payment['month'] ?? '').toString().trim().toLowerCase();
        monthsToCheck = [mStr];
        
        // If the month is stored as a number (e.g. "7" or "07" for July)
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

      // Add detailed debugging print
      print("🔍 [FeeCheck] Checking Payment -> months: $monthsToCheck | year: '$pYear' | reason: '$pReason' | isMembership: $isMembershipPayment | currentMonthName: '${currentMonthName.toLowerCase()}' | currentYear: '$currentYearStr'");

      if (monthsToCheck.contains(currentMonthName.toLowerCase()) &&
          (pYear == currentYearStr || pYear.isEmpty) && // Pending payments sometimes might not have year set properly immediately
          isMembershipPayment) {
        hasPaidForCurrentMonth = true;
        print("✅ [FeeCheck] Payment matched for current month!");
        break; // Stop the loop since payment is found
      }
    } else {
      print("⚠️ [FeeCheck] Payment is not a Map: $payment");
    }
  }

  // ==========================================================
  // ⚠️ 🎯 CRITICAL UX AUTOMATION LOGIC:
  // Blocks only if the day of the month is >= 5 AND no payment is made for the current month!
  // ==========================================================
  if (currentDay >= 5 && !hasPaidForCurrentMonth) {
    return {
      'isFeePaidValid': false,
      'reason': 'Pending Membership Fee 💰',
    };
  }

  // 🟢 If within the grace period (1st-4th) or payments are made correctly:
  return {
    'isFeePaidValid': true,
    'reason': '',
  };
}