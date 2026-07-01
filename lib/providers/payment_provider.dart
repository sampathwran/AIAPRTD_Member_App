// ignore_for_file: spell_check_on_languages

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PaymentProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isLoading = false;
  bool _isLocalLoading = false;

  Map<String, dynamic>? _paymentData;
  Map<String, dynamic>? _bankData;

  bool get isLoading => _isLoading;
  bool get isLocalLoading => _isLocalLoading;
  Map<String, dynamic>? get paymentData => _paymentData;
  Map<String, dynamic>? get bankData => _bankData;
  List<dynamic> get paymentHistory => _paymentData?['payment_history'] ?? [];

  Stream<DocumentSnapshot> streamPaymentData(String membershipNo) {
    return _firestore
        .collection('payments')
        .doc(membershipNo)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        _paymentData = snapshot.data() as Map<String, dynamic>;
        Future.microtask(() => notifyListeners());
      }
      return snapshot;
    });
  }

  Future<bool> uploadPaymentSlip({
    required String membershipNo,
    required File file,
    required String fileName,
    required List<String> paymentMonths,
    required DateTime paymentDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      final Reference ref =
      _storage.ref().child('payment_slips/${membershipNo}_$timestamp.jpg');

      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      final String slipUrl = await snapshot.ref.getDownloadURL();

      final Map<String, dynamic> newPaymentRecord = {
        'months': paymentMonths,
        'paymentDate': paymentDate.toIso8601String(),
        'fileName': fileName,
        'slipUrl': slipUrl,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('payments').doc(membershipNo).set({
        'membershipNo': membershipNo,
        'lastUpdated': FieldValue.serverTimestamp(),
        'payment_history': FieldValue.arrayUnion([newPaymentRecord]),
      }, SetOptions(merge: true));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("❌ SLIP UPLOAD ERROR: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // =========================================================================
  // 🏦 BANK DETAILS METHODS
  // =========================================================================
  Future<void> fetchBankDetails(String membershipNo) async {
    _isLoading = true;
    notifyListeners();

    try {
      final doc =
      await _firestore.collection('payments').doc('${membershipNo}_bank').get();

      if (doc.exists && doc.data() != null) {
        _bankData = doc.data();

        final pendingDoc =
        await _firestore.collection('verify_bank').doc(membershipNo).get();

        if (pendingDoc.exists && pendingDoc.data() != null) {
          final pendingData = pendingDoc.data()!;
          final pendingStatus =
              pendingData['status']?.toString().toLowerCase() ?? '';

          if (pendingStatus == 'pending') {
            _bankData = {
              ...?_bankData,
              'bankUpdateStatus': 'pending',
              'pendingBankData': pendingData,
            };
          }
        }
      } else {
        final pendingDoc =
        await _firestore.collection('verify_bank').doc(membershipNo).get();

        if (pendingDoc.exists && pendingDoc.data() != null) {
          final pendingData = pendingDoc.data()!;
          final pendingStatus =
              pendingData['status']?.toString().toLowerCase() ?? '';

          if (pendingStatus == 'pending') {
            _bankData = {
              'membershipNo': membershipNo,
              'bankUpdateStatus': 'pending',
              'pendingBankData': pendingData,
            };
          } else {
            _bankData = null;
          }
        } else {
          _bankData = null;
        }
      }
    } catch (e) {
      debugPrint("Error fetching bank details: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // Direct update - use only from admin approval / trusted side
  Future<bool> updateBankDetails({
    required String membershipNo,
    required String bankName,
    required String branchName,
    required String branchCode,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    _isLocalLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('payments').doc('${membershipNo}_bank').set({
        'membershipNo': membershipNo,
        'bankName': bankName,
        'branchName': branchName,
        'branchCode': branchCode,
        'accountNumber': accountNumber,
        'accountHolderName': accountHolderName,
        'bankUpdateStatus': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _bankData = {
        'membershipNo': membershipNo,
        'bankName': bankName,
        'branchName': branchName,
        'branchCode': branchCode,
        'accountNumber': accountNumber,
        'accountHolderName': accountHolderName,
        'bankUpdateStatus': 'approved',
      };

      _isLocalLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error updating bank details: $e");
      _isLocalLoading = false;
      notifyListeners();
      return false;
    }
  }

  // =========================================================================
  // ⏳ REQUEST BANK DETAILS UPDATE - ADMIN APPROVAL REQUIRED
  // =========================================================================
  Future<bool> requestBankDetailsUpdate({
    required String documentId,
    required String membershipNo,
    required String bankName,
    required String branchName,
    required String branchCode,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    _isLocalLoading = true;
    notifyListeners();

    try {
      final WriteBatch batch = _firestore.batch();

      final DocumentReference verifyRef =
      _firestore.collection('verify_bank').doc(membershipNo);

      final DocumentReference memberRef =
      _firestore.collection('member').doc(documentId);

      final DocumentReference bankRef =
      _firestore.collection('payments').doc('${membershipNo}_bank');

      batch.set(verifyRef, {
        'documentId': documentId,
        'membershipNo': membershipNo,
        'bankName': bankName,
        'branchName': branchName,
        'branchCode': branchCode,
        'accountNumber': accountNumber,
        'accountHolderName': accountHolderName,
        'status': 'pending',
        'bankUpdateStatus': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'approvedAt': null,
        'approvedBy': null,
        'rejectedAt': null,
        'rejectedBy': null,
        'rejectReason': null,
      });

      batch.set(bankRef, {
        'membershipNo': membershipNo,
        'bankUpdateStatus': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      batch.set(memberRef, {
        'bankUpdateStatus': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      _bankData = {
        ...?_bankData,
        'membershipNo': membershipNo,
        'bankUpdateStatus': 'pending',
        'pendingBankData': {
          'documentId': documentId,
          'membershipNo': membershipNo,
          'bankName': bankName,
          'branchName': branchName,
          'branchCode': branchCode,
          'accountNumber': accountNumber,
          'accountHolderName': accountHolderName,
          'status': 'pending',
          'bankUpdateStatus': 'pending',
        },
      };

      _isLocalLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("❌ Bank Update Request Error: $e");

      _isLocalLoading = false;
      notifyListeners();
      return false;
    }
  }
}