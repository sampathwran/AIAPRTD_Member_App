import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FinanceProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double _driverCommissionRate = 10.0;
  double get driverCommissionRate => _driverCommissionRate;
  double _appUsageChargeRate = 3.0;
  double _memberSavingsRate = 7.0;
  double _monthlyMembershipFee = 500.0;
  double get monthlyMembershipFee => _monthlyMembershipFee;

  double _appUsageLimit = 1000.0;
  double get appUsageLimit => _appUsageLimit;

  Map<String, dynamic> _unionBankDetails = {};
  Map<String, dynamic> get unionBankDetails => _unionBankDetails;

  double _mySavingsBalance = 0.0;
  double get mySavingsBalance => _mySavingsBalance;

  double _myAppUsageChargeBalance = 0.0;
  double get myAppUsageChargeBalance => _myAppUsageChargeBalance;

  List<Map<String, dynamic>> _p2pPayables = [];
  List<Map<String, dynamic>> get p2pPayables => _p2pPayables;

  List<Map<String, dynamic>> _p2pReceivables = [];
  List<Map<String, dynamic>> get p2pReceivables => _p2pReceivables;

  FinanceProvider() {
    _fetchAdminFinanceSettings();
  }

  /// Fetch global dynamic rates set by Admin
  Future<void> _fetchAdminFinanceSettings() async {
    try {
      final doc = await _firestore.collection('admin_settings').doc('finance').get();
      if (doc.exists) {
        final data = doc.data()!;
        _driverCommissionRate = (data['driverCommissionPercentage'] ?? 10.0).toDouble();
        _appUsageChargeRate = (data['appUsageChargePercentage'] ?? 3.0).toDouble();
        _memberSavingsRate = (data['memberSavingsPercentage'] ?? 7.0).toDouble();
        _monthlyMembershipFee = (data['monthlyMembershipFee'] ?? 500.0).toDouble();
        _appUsageLimit = (data['appUsageLimit'] ?? 1000.0).toDouble();
        
        _unionBankDetails = {
          'bankName': data['unionBankName'] ?? '',
          'accountName': data['unionBankAccountName'] ?? '',
          'accountNumber': data['unionBankAccountNumber'] ?? '',
          'branch': data['unionBankBranch'] ?? '',
        };
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching admin finance settings: $e");
    }
  }

  /// Listen to current member's finance data
  void listenToMyFinance(String membershipNo) {
    if (membershipNo.isEmpty) return;
    
    // Listen to member's document for balances
    _firestore.collection('member').doc(membershipNo).snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        _mySavingsBalance = (data['savingsBalance'] ?? 0.0).toDouble();
        _myAppUsageChargeBalance = (data['appUsageChargeBalance'] ?? 0.0).toDouble();
        
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint("Error listening to finance balances: $e");
    });
    
    _listenToP2PDebts(membershipNo);
  }

  void _listenToP2PDebts(String membershipNo) {
    final activeStatuses = ['pending', 'awaiting_payment', 'slip_uploaded', 'pending_admin_verification', 'settled'];

    // Helper to filter out settled records older than 30 days
    List<Map<String, dynamic>> filterAndSortDebts(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
      final now = DateTime.now();
      return docs.map((doc) {
        final data = doc.data();
        data['debtId'] = doc.id; // Ensure debtId is present for older records
        return data;
      }).where((data) {
        if (data['status'] == 'settled' && data['settledAt'] != null) {
          final settledDate = (data['settledAt'] as Timestamp).toDate();
          if (now.difference(settledDate).inDays > 30) return false;
        }
        return true;
      }).toList()..sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate); // Descending order
      });
    }

    // Payables: where I am the debtor
    _firestore.collection('p2p_debts')
      .where('debtorId', isEqualTo: membershipNo)
      .where('status', whereIn: activeStatuses)
      .snapshots().listen((snapshot) {
        _p2pPayables = filterAndSortDebts(snapshot.docs);
        notifyListeners();
      }, onError: (e) => debugPrint("Error listening to P2P Payables: $e"));

    // Receivables: where I am the creditor
    _firestore.collection('p2p_debts')
      .where('creditorId', isEqualTo: membershipNo)
      .where('status', whereIn: activeStatuses)
      .snapshots().listen((snapshot) {
        _p2pReceivables = filterAndSortDebts(snapshot.docs);
        notifyListeners();
      }, onError: (e) => debugPrint("Error listening to P2P Receivables: $e"));
  }

  Future<DocumentReference?> _getMemberRef(String membershipNo) async {
    final memberQuery = await _firestore.collection('member').where('membershipNo', isEqualTo: membershipNo).limit(1).get();
    if (memberQuery.docs.isNotEmpty) {
      return memberQuery.docs.first.reference;
    }
    final webSyncQuery = await _firestore.collection('web_sync_member').where('membershipNo', isEqualTo: membershipNo).limit(1).get();
    if (webSyncQuery.docs.isNotEmpty) {
      return webSyncQuery.docs.first.reference;
    }
    return null;
  }

  /// Process the commission split at the end of an App Booking
  Future<void> processTripCommission({
    required String tripId,
    required double totalFare,
    required String driverId,
    required String passengerId, // Booking Member (Requester), empty if Road Pickup
  }) async {
    if (totalFare <= 0 || driverId.isEmpty) return;

    try {
      // 1. Fetch latest rates just to be sure
      await _fetchAdminFinanceSettings();

      final bool isAppBooking = passengerId.isNotEmpty;
      final double unionUsageCharge = totalFare * (_appUsageChargeRate / 100);
      final double requesterCommission = totalFare * (_memberSavingsRate / 100); // 7%

      final DocumentReference? driverRef = await _getMemberRef(driverId);
      final DocumentReference? passengerRef = isAppBooking ? await _getMemberRef(passengerId) : null;

      if (driverRef == null) {
        debugPrint("❌ Driver reference not found for usage charge update.");
        return;
      }

      WriteBatch batch = _firestore.batch();

      // Add union usage charge (3%) to the driver's outstanding balance
      batch.set(driverRef, {
        'appUsageChargeBalance': FieldValue.increment(unionUsageCharge),
      }, SetOptions(merge: true));

      // Create Trip Transaction Record
      String dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      DocumentReference txnRef = _firestore
          .collection('finance_transactions')
          .doc(driverId)
          .collection('history')
          .doc(dateStr)
          .collection('transactions')
          .doc();
          
      batch.set(txnRef, {
        'transactionId': txnRef.id,
        'tripId': tripId,
        'driverId': driverId,
        'passengerId': passengerId,
        'totalFare': totalFare,
        'unionUsageCharge': unionUsageCharge,
        'requesterCommission': isAppBooking ? requesterCommission : 0.0,
        'timestamp': FieldValue.serverTimestamp(),
        'type': isAppBooking ? 'app_booking_commission_split' : 'road_pickup_commission',
      });

      // Add 7% P2P Debt if it's an app booking
      if (isAppBooking && passengerRef != null && driverId != passengerId) {
        DocumentReference p2pRef = _firestore.collection('p2p_debts').doc();
        batch.set(p2pRef, {
          'debtId': p2pRef.id,
          'debtorId': driverId, // The driver owes the money
          'creditorId': passengerId, // The requester is owed the money
          'amount': requesterCommission,
          'tripId': tripId,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      debugPrint("Trip Commission processed successfully for $tripId");
    } catch (e) {
      debugPrint("Error processing trip commission: $e");
    }
  }

  // Method to mark a P2P debt as settled (only for own_account)
  Future<void> settleP2PDebt(String debtId) async {
    try {
      await _firestore.collection('p2p_debts').doc(debtId).update({
        'status': 'settled',
        'settledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error settling P2P debt: $e");
      rethrow;
    }
  }

  // Set the payment method chosen by the creditor
  Future<void> updatePaymentMethod(String debtId, String method) async {
    try {
      debugPrint("Starting updatePaymentMethod for debtId: $debtId, method: $method");
      await _firestore.collection('p2p_debts').doc(debtId).update({
        'paymentMethod': method,
        'status': 'awaiting_payment',
      });
      debugPrint("Successfully updated payment method to $method for debt $debtId");
    } catch (e) {
      debugPrint("Error updating payment method: $e");
      rethrow;
    }
  }

  // Upload P2P Payment Slip by the debtor
  Future<String> uploadP2PSlip(String debtId, File imageFile, String paymentMethod) async {
    try {
      final String fileName = 'p2p_slip_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = FirebaseStorage.instance.ref().child('p2p_slips/$debtId/$fileName');
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      final newStatus = paymentMethod == 'union' ? 'pending_admin_verification' : 'slip_uploaded';

      await _firestore.collection('p2p_debts').doc(debtId).update({
        'slipUrl': downloadUrl,
        'status': newStatus,
        'uploadedAt': FieldValue.serverTimestamp(),
      });
      
      return downloadUrl;
    } catch (e) {
      debugPrint("Error uploading P2P slip: $e");
      rethrow;
    }
  }

  // Fetch Member Bank Details
  Future<Map<String, dynamic>?> getMemberBankDetails(String membershipNo) async {
    try {
      final doc = await _firestore.collection('payments').doc('${membershipNo}_bank').get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching member bank details: $e");
      return null;
    }
  }
}
