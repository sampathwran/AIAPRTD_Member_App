// ==========================================
// 1. IMPORTS SECTION
// ==========================================
import 'dart:async'; // StreamSubscription පාවිච්චි කරන්න අවශ්‍යයි
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ==========================================
// 2. MEMBER PROVIDER CLASS SECTION
// ==========================================
class MemberProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // මෙම්බර්ගේ දත්ත සහ Loading ස්ටේට් එක
  Map<String, dynamic>? _memberData;
  bool _isLoading = false;

  // Real-time updates අහගෙන ඉන්න Stream සබ්ස්ක්‍රිප්ෂන් එක
  StreamSubscription<QuerySnapshot>? _memberStreamSubscription;

  // ==========================================
  // 3. GETTERS SECTION (ඇප් එකේ ඕනෑම තැනකට දත්ත දෙන ඒවා)
  // ==========================================
  Map<String, dynamic>? get memberData => _memberData;
  bool get isLoading => _isLoading;

  // මෙම්බර්ගේ දැනට තියෙන Active/Inactive ස්ටේටස් එක කෙලින්ම ගන්න Getter එකක්
  String get memberStatus => _memberData?['status'] ?? 'inactive';

  // මෙම්බර්ගේ නම කෙලින්ම ගන්න Getter එකක්
  String get memberFullName => _memberData?['fullName'] ?? 'Member';

  // ==========================================
  // 4. DATA FETCH & AUTO SYNC LOGIC SECTION
  // ==========================================

  /// 🔄 Firestore එකෙන් දත්ත අරන් ස්ටෑන්ඩ්බයි තියාගන්න සහ Auto Sync (Real-time) කරන්න
  Future<bool> fetchAndStoreMemberData() async {
    _isLoading = true;
    notifyListeners();

    // කලින් තිබ්බ සබ්ස්ක්‍රිප්ෂන් එකක් තියෙනවා නම් ඒක අයින් කරනවා
    await _cancelActiveStream();

    try {
      User? currentUser = _auth.currentUser;

      if (currentUser != null && currentUser.email != null) {
        // Completer එකක් පාවිච්චි කරන්නේ මුල්ම පාර දත්ත ටික එනකන් Splash Screen එකට බලාගෙන ඉන්න ඉඩ දෙන්න
        final Completer<bool> completer = Completer<bool>();

        // 🔎 Email එක හරහා Firestore එකේ 'member' collection එකට 'Stream' එකක් දානවා (Real-time Sync)
        _memberStreamSubscription = _firestore
            .collection('member')
            .where('user_email', isEqualTo: currentUser.email)
            .limit(1)
            .snapshots() // 👈 මෙතනින් තමයි ඩේටා බේස් එක වෙනස් වෙද්දීම ඇප් එකටත් ලයිව් අප්ඩේට් එවන්නේ
            .listen(
              (querySnapshot) {
            if (querySnapshot.docs.isNotEmpty) {
              // 💾 දත්ත ලැබුණා! ඒ ටික ස්ටෑන්ඩ්බයි සේව් කරගන්නවා
              _memberData = querySnapshot.docs.first.data();
              _isLoading = false;
              notifyListeners();

              // මුල්ම පාර සාර්ථකව දත්ත ආවා කියලා Splash Screen එකට දන්වනවා
              if (!completer.isCompleted) {
                completer.complete(true);
              }
            } else {
              // යූසර් කෙනෙක් ඉන්නවා හැබැයි Firestore එකේ දත්ත නැත්නම්
              _isLoading = false;
              notifyListeners();
              if (!completer.isCompleted) completer.complete(false);
            }
          },
          onError: (error) {
            _isLoading = false;
            notifyListeners();
            if (!completer.isCompleted) completer.complete(false);
          },
        );

        // පළමු දත්ත හුවමාරුව ඉවර වෙනකන් මෙතනින් රඳවා තබා ගන්නවා
        return await completer.future;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // 5. CLEANUP & LOGOUT LOGIC SECTION
  // ==========================================

  /// 🚪 ලොග් අවුට් වෙද්දී හෝ ඇප් එක වහද්දී දත්ත Clear කරලා Stream නවත්වන්න
  Future<void> clearMemberData() async {
    await _cancelActiveStream();
    _memberData = null;
    _isLoading = false;
    notifyListeners();
  }

  /// 🔐 බැක්ග්‍රවුන්ඩ් එකෙන් දත්ත අහගෙන ඉන්න එක නවත්වන රහස් ෆන්ක්ෂන් එක
  Future<void> _cancelActiveStream() async {
    if (_memberStreamSubscription != null) {
      await _memberStreamSubscription!.cancel();
      _memberStreamSubscription = null;
    }
  }

  @override
  void dispose() {
    _cancelActiveStream(); // Provider එක මැරුණොත් Stream එකත් වහනවා
    super.dispose();
  }
}