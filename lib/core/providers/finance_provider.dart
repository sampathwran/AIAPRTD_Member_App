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
        
        // Auto-settlement logic (only if amount is reasonably larger than 0.00)
        // We round down to 2 decimal places to avoid floating point bugs causing 0.01 charges
        if (_mySavingsBalance >= 0.01 && _myAppUsageChargeBalance >= 0.01) {
          _autoSettleOutstandingWithSavings(membershipNo, _mySavingsBalance, _myAppUsageChargeBalance);
        }

        // Refund negative outstanding balances to savings
        if (_myAppUsageChargeBalance <= -0.01) {
          _refundNegativeAppUsageToSavings(membershipNo, _myAppUsageChargeBalance);
        }

        notifyListeners();
      }
    }, onError: (e) {
      debugPrint("Error listening to finance balances: $e");
    });
  }

  Future<void> _autoSettleOutstandingWithSavings(String memberId, double savings, double outstanding) async {
    try {
      double rawAmount = savings < outstanding ? savings : outstanding;
      // Round to 2 decimal places to avoid 0.01 floating point residues
      double amountToSettle = (rawAmount * 100).floorToDouble() / 100.0;
      
      if (amountToSettle <= 0) return;
      
      WriteBatch batch = _firestore.batch();
      DocumentReference memberRef = _firestore.collection('members').doc(memberId);
      
      batch.set(memberRef, {
        'savingsBalance': FieldValue.increment(-amountToSettle),
        'appUsageChargeBalance': FieldValue.increment(-amountToSettle),
      }, SetOptions(merge: true));

      // Create transaction record for settlement
      DocumentReference txnRef = _firestore.collection('finance_transactions').doc();
      batch.set(txnRef, {
        'transactionId': txnRef.id,
        'passengerId': memberId, // For savings history
        'driverId': memberId, // For app usage history
        'amount': amountToSettle,
        'type': 'auto_settlement',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      debugPrint("Auto-settled LKR $amountToSettle outstanding with savings.");
    } catch (e) {
      debugPrint("Error auto-settling outstanding: $e");
    }
  }

  Future<void> _refundNegativeAppUsageToSavings(String memberId, double negativeOutstanding) async {
    try {
      double rawAmount = -negativeOutstanding; // Convert negative to positive
      double amountToRefund = (rawAmount * 100).floorToDouble() / 100.0;
      
      if (amountToRefund <= 0) return;
      
      WriteBatch batch = _firestore.batch();
      DocumentReference memberRef = _firestore.collection('members').doc(memberId);
      
      batch.set(memberRef, {
        'appUsageChargeBalance': FieldValue.increment(amountToRefund), // brings it back to 0
        'savingsBalance': FieldValue.increment(amountToRefund), // returns it to savings
      }, SetOptions(merge: true));

      // Create transaction record for refund
      DocumentReference txnRef = _firestore.collection('finance_transactions').doc();
      batch.set(txnRef, {
        'transactionId': txnRef.id,
        'passengerId': memberId, // For savings history
        'driverId': memberId, // For app usage history
        'amount': amountToRefund,
        'type': 'auto_settlement_refund',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      debugPrint("Refunded LKR $amountToRefund negative outstanding to savings.");
    } catch (e) {
      debugPrint("Error refunding negative outstanding: $e");
    }
  }

  /// Process the commission split at the end of an App Booking
  Future<void> processTripCommission({
    required String tripId,
    required double totalFare,
    required String driverId,
    required String passengerId, // Booking Member, empty if Road Pickup
  }) async {
    if (totalFare <= 0 || driverId.isEmpty) return;

    try {
      // 1. Fetch latest rates just to be sure
      await _fetchAdminFinanceSettings();

      final bool isAppBooking = passengerId.isNotEmpty;

      final double unionUsageCharge = totalFare * (_appUsageChargeRate / 100);
      final double passengerSavings = totalFare * (_memberSavingsRate / 100);
      
      // Driver pays 10% for App Booking, but only 3% (Union Charge) for Road Pickup
      final double totalDriverCommission = isAppBooking 
          ? totalFare * (_driverCommissionRate / 100) 
          : unionUsageCharge;

      WriteBatch batch = _firestore.batch();

      // 2. Update Driver's App Usage Charge Balance (They OWE this money to union)
      DocumentReference driverRef = _firestore.collection('members').doc(driverId);
      batch.set(driverRef, {
        'appUsageChargeBalance': FieldValue.increment(totalDriverCommission),
      }, SetOptions(merge: true));

      // 3. Update Passenger's Savings Balance
      if (isAppBooking) {
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
        'passengerSavings': isAppBooking ? passengerSavings : 0.0,
        'timestamp': FieldValue.serverTimestamp(),
        'type': isAppBooking ? 'app_booking_commission_split' : 'road_pickup_commission',
      });

      await batch.commit();
      debugPrint("Trip Commission processed successfully for $tripId");
    } catch (e) {
      debugPrint("Error processing trip commission: $e");
    }
  }
}
