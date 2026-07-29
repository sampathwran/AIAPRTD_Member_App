import 'dart:convert';

void main() {
  final Map<String, dynamic> data = {
    'payment_history': [
      {
        'amount': '500',
        'approvedAt': '2026-07-20T15:32:26.618',
        'date': '2026-07-07',
        'id': '6a4d302c5ac44',
        'month': 'May',
        'reason': 'Monthly Membership Fee',
        'source': 'web',
        'status': 'approved',
        'type': 'Bank Transfer'
      },
      {
        'amount': '500',
        'approvedAt': '2026-07-27T23:07:00.225',
        'date': '2026-07-27',
        'id': '6a678b8985bb4',
        'month': 'August',
        'reason': 'Monthly Membership Fee',
        'source': 'web',
        'status': 'approved',
        'type': 'Free Membership Fee',
        'year': '2026'
      },
      {
        'amount': '500',
        'approvedAt': '2026-07-27T23:09:22.057',
        'date': '2026-07-27',
        'id': '6a678b8985baa',
        'month': 'July',
        'reason': 'Monthly Membership Fee',
        'source': 'web',
        'status': 'approved',
        'type': 'Free Membership Fee',
        'year': '2026'
      },
      {
        'amount': '500',
        'approvedAt': '2026-07-27T23:12:17.083',
        'date': '2026-07-27',
        'id': '6a67983f114d8',
        'month': 'June',
        'reason': 'Monthly Membership Fee',
        'source': 'web',
        'status': 'approved',
        'type': 'Free Membership Fee',
        'year': '2026'
      }
    ]
  };

  final result = checkMembershipFeeStatus(data);
  print(jsonEncode(result));
}

Map<String, dynamic> checkMembershipFeeStatus(Map<String, dynamic> data) {
  final DateTime now = DateTime.now(); // 2026-07-27
  final int currentDay = now.day;
  final List<String> monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  final String currentMonthName = monthNames[now.month - 1];
  final String currentYearStr = now.year.toString();

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
      'reason': 'Membership Fee Not Paid',
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
      'reason': 'Pending Membership Fee',
    };
  }

  return {
    'isFeePaidValid': true,
    'reason': '',
  };
}
