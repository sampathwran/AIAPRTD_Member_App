// ignore_for_file: spell_check_on_languages

/// 💰 ඩ්රයිවර් කෙනෙක්ගේ 'payment_history' array එක පරික්ෂා කර,
/// වත්මන් මාසයට අදාළ සාමාජික ගාස්තුව 5 වෙනිදාට පෙර ගෙවා ඇත්දැයි බලන සුපිරි ලොජික් එන්ජිම.
Map<String, dynamic> checkMembershipFeeStatus(Map<String, dynamic>? data) {

  // ⚠️ 1. ආරක්ෂිත පියවරක්: ඩේටා මුකුත්ම නැත්නම් (Null නම්) බොරුවට බ්ලොක් කරන්නේ නැතුව true කරනවා මචං
  if (data == null || data.isEmpty) {
    return {
      'isFeePaidValid': true,
      'reason': '',
    };
  }

  // 🎯 2. 💡 CRITICAL FIX: Firestore එකෙන් තවම payment_history කියන Key එක ලැබිලා නැත්නම් (Data Loading පමාව),
  // ඩ්රයිවර්ව බොරුවට බ්ලොක් කරන්නේ නැතුව ඩේටා එනකම් ඔන්ලයින් යාමට අවසර දෙනවා මචං!
  if (!data.containsKey('payment_history') || data['payment_history'] == null) {
    return {
      'isFeePaidValid': true, // 👈 ඇප් එක ඕපන් වෙච්ච ගමන්ම ඔන්ලයින් යන්න දෙන්නේ මෙන්න මේ ලයින් එක නිසයි මචං!
      'reason': '',
    };
  }

  // 📅 3. වත්මන් දිනය සහ වේලාව සිස්ටම් එකෙන් ගන්නවා මචං
  final DateTime now = DateTime.now();
  final int currentDay = now.day; // මාසයේ වත්මන් දිනය (1 - 31)

  // 🗓️ 4. වත්මන් මාසයේ නම ඉංග්රීසියෙන් ලබාගන්නවා
  final List<String> monthNames = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];
  final String currentMonthName = monthNames[now.month - 1]; // වත්මන් මාසයේ නම
  final String currentYearStr = now.year.toString(); // වත්මන් අවුරුද්ද

  // 🔄 5. Firestore එකෙන් payment_history array එක ආරක්ෂිතව කියවා ගන්නවා
  final List<dynamic> paymentHistory = data['payment_history'];

  // 🔍 6. වත්මන් මාසයට අදාළ සාමාජික ගාස්තුව ගෙවා ඇත්දැයි array එක ඇතුළේ පීරලා සොයනවා මචං
  bool hasPaidForCurrentMonth = false;

  for (var payment in paymentHistory) {
    if (payment is Map) {
      final String pMonth = (payment['month'] ?? '').toString().toLowerCase();
      final String pYear = (payment['year'] ?? '').toString();
      final String pReason = (payment['reason'] ?? '').toString().toLowerCase();

      // 🎯 වත්මන් මාසය සමානද, අවුරුද්ද සමානද, සහ reason එක 'monthly membership fee' ද කියා බලනවා
      if (pMonth == currentMonthName.toLowerCase() &&
          pYear == currentYearStr &&
          pReason.contains('monthly membership fee')) {
        hasPaidForCurrentMonth = true;
        break; // ගෙවීම හමු වූ නිසා ලූප් එක නතර කරනවා
      }
    }
  }

  // ==========================================================
  // ⚠️ 🎯 CRITICAL UX AUTOMATION LOGIC:
  // මාසයේ දිනය 5 හෝ 5ට වැඩි නම් සහ වත්මන් මාසයට අදාළව ගෙවීමක් කර නැත්නම් විතරක්ම බ්ලොක් කරයි!
  // ==========================================================
  if (currentDay >= 5 && !hasPaidForCurrentMonth) {
    return {
      'isFeePaidValid': false,
      'reason': 'Pending Membership Fee 💰',
    };
  }

  // 🟢 මාසයේ 1-4 දින අතර සහන කාලයේ සිටී නම් හෝ ගෙවීම් නිවැරදිව කර ඇත්නම්:
  return {
    'isFeePaidValid': true,
    'reason': '',
  };
}