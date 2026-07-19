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

      await _firestore.runTransaction((transaction) async {
        DocumentReference driverRef = _firestore.collection('members').doc(driverId);
        DocumentSnapshot driverDoc = await transaction.get(driverRef);
        
        if (!driverDoc.exists) return;
        
        final driverData = driverDoc.data() as Map<String, dynamic>;
        double currentSavings = (driverData['savingsBalance'] ?? 0.0).toDouble();
        double currentAppUsage = (driverData['appUsageChargeBalance'] ?? 0.0).toDouble();
        
        // Calculate new app usage after this trip
        double newAppUsage = currentAppUsage + totalDriverCommission;
        double amountToSettle = 0.0;
        
        // Auto-settlement logic
        if (currentSavings >= 0.01 && newAppUsage >= 0.01) {
          double rawAmount = currentSavings < newAppUsage ? currentSavings : newAppUsage;
          amountToSettle = (rawAmount * 100).floorToDouble() / 100.0;
        }

        // Apply settlement if any
        if (amountToSettle > 0) {
          transaction.set(driverRef, {
            'appUsageChargeBalance': FieldValue.increment(totalDriverCommission - amountToSettle),
            'savingsBalance': FieldValue.increment(-amountToSettle),
          }, SetOptions(merge: true));
          
          // Create auto-settlement transaction log
          DocumentReference settleTxnRef = _firestore.collection('finance_transactions').doc();
          transaction.set(settleTxnRef, {
            'transactionId': settleTxnRef.id,
            'passengerId': driverId,
            'driverId': driverId,
            'amount': amountToSettle,
            'type': 'auto_settlement',
            'timestamp': FieldValue.serverTimestamp(),
          });
        } else {
          // No settlement, just add to usage charge
          transaction.set(driverRef, {
            'appUsageChargeBalance': FieldValue.increment(totalDriverCommission),
          }, SetOptions(merge: true));
        }

        // 3. Update Passenger's Savings Balance
        if (isAppBooking) {
          DocumentReference passengerRef = _firestore.collection('members').doc(passengerId);
          transaction.set(passengerRef, {
            'savingsBalance': FieldValue.increment(passengerSavings),
          }, SetOptions(merge: true));
        }

        // 4. Create Trip Transaction Record
        DocumentReference txnRef = _firestore.collection('finance_transactions').doc();
        transaction.set(txnRef, {
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
      });

      debugPrint("Trip Commission processed successfully for $tripId");
    } catch (e) {
      debugPrint("Error processing trip commission: $e");
    }
  }
}
