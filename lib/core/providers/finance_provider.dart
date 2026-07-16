import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FinanceProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double _driverCommissionRate = 10.0;
  double get driverCommissionRate => _driverCommissionRate;
  double _appUsageChargeRate = 3.0;
  double _memberSavingsRate = 7.0;
  double _monthlyMembershipFee = 500.0;
  double get monthlyMembershipFee => _monthlyMembershipFee;

  Map<String, dynamic> _unionBankDetails = {};
  Map<String, dynamic> get unionBankDetails => _unionBankDetails;

  double _mySavingsBalance = 0.0;
  double get mySavingsBalance => _mySavingsBalance;

  double _myAppUsageChargeBalance = 0.0;
  double get myAppUsageChargeBalance => _myAppUsageChargeBalance;

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
    _firestore.collection('members').doc(membershipNo).snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        _mySavingsBalance = (data['savingsBalance'] ?? 0.0).toDouble();
        _myAppUsageChargeBalance = (data['appUsageChargeBalance'] ?? 0.0).toDouble();
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint("Error listening to finance balances: $e");
    });
  }

  /// Process the commission split at the end of an App Booking
  Future<void> processTripCommission({
    required String tripId,
    required double totalFare,
    required String driverId,
    required String passengerId, // Booking Member
  }) async {
    if (totalFare <= 0 || driverId.isEmpty) return;

    try {
      // 1. Fetch latest rates just to be sure
      await _fetchAdminFinanceSettings();

      final double totalDriverCommission = totalFare * (_driverCommissionRate / 100);
      final double unionUsageCharge = totalFare * (_appUsageChargeRate / 100);
      final double passengerSavings = totalFare * (_memberSavingsRate / 100);

      WriteBatch batch = _firestore.batch();

      // 2. Update Driver's App Usage Charge Balance (They OWE this money to union)
      DocumentReference driverRef = _firestore.collection('members').doc(driverId);
      batch.set(driverRef, {
        'appUsageChargeBalance': FieldValue.increment(totalDriverCommission),
      }, SetOptions(merge: true));

      // 3. Update Passenger's Savings Balance
      if (passengerId.isNotEmpty) {
        DocumentReference passengerRef = _firestore.collection('members').doc(passengerId);
        batch.set(passengerRef, {
          'savingsBalance': FieldValue.increment(passengerSavings),
        }, SetOptions(merge: true));
      }

      // 4. Create Transaction Record
      DocumentReference txnRef = _firestore.collection('finance_transactions').doc();
      batch.set(txnRef, {
        'transactionId': txnRef.id,
        'tripId': tripId,
        'driverId': driverId,
        'passengerId': passengerId,
        'totalFare': totalFare,
        'driverCommission': totalDriverCommission,
        'unionUsageCharge': unionUsageCharge,
        'passengerSavings': passengerId.isNotEmpty ? passengerSavings : 0.0,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'app_booking_commission_split',
      });

      await batch.commit();
      debugPrint("Trip Commission processed successfully for $tripId");
    } catch (e) {
      debugPrint("Error processing trip commission: $e");
    }
  }
}
