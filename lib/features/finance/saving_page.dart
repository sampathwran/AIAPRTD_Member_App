import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/finance_provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/core/providers/payment_provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SavingPage extends StatefulWidget {
  const SavingPage({super.key});

  @override
  State<SavingPage> createState() => _SavingPageState();
}

class _SavingPageState extends State<SavingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = Provider.of<ProfileProvider>(context, listen: false);
      final finance = Provider.of<FinanceProvider>(context, listen: false);
      final payment = Provider.of<PaymentProvider>(context, listen: false);
      
      if (profile.memberNo.isNotEmpty) {
        finance.listenToMyFinance(profile.memberNo);
        payment.fetchBankDetails(profile.memberNo);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("My Savings", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.teal.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, financeProv, child) {
          final balance = financeProv.mySavingsBalance;
          
          return Column(
            children: [
              _buildBalanceCard(balance, context),
              
              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.payments_rounded,
                        label: "Pay Fee",
                        color: Colors.blue.shade600,
                        onTap: () => _handlePayMembershipFee(context, balance),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.account_balance_wallet_rounded,
                        label: "Withdraw",
                        color: Colors.orange.shade600,
                        onTap: () => _handleWithdraw(context, balance),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Savings History",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ),
              Expanded(
                child: _buildTransactionHistory(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(double balance, BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade600, Colors.teal.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Savings",
            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                "LKR ",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                NumberFormat('#,##0.00').format(balance),
                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "Earned from App Bookings",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistory() {
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('finance_transactions')
          .where('passengerId', isEqualTo: profile.memberNo)
          .orderBy('timestamp', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.savings_outlined, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text("No savings yet.", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            final type = data['type'] as String? ?? 'app_booking_commission_split';
            final amount = (type == 'app_booking_commission_split' ? data['passengerSavings'] : data['amount'] ?? 0.0).toDouble();
            final date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            
            final tripId = data['tripId'] as String? ?? 'N/A';
            final totalFare = (data['totalFare'] ?? 0.0).toDouble();
            final isEarning = type == 'app_booking_commission_split';

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isEarning ? Colors.teal.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEarning ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, 
                      color: isEarning ? Colors.teal : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isEarning ? "Shared Booking Reward" : "Withdrawal", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (isEarning && tripId != 'N/A') ...[
                          const SizedBox(height: 4),
                          Text("Trip ID: $tripId", style: const TextStyle(color: Colors.black54, fontSize: 13)),
                          Text("Total Fare: LKR ${NumberFormat('#,##0.00').format(totalFare)}", style: const TextStyle(color: Colors.black54, fontSize: 13)),
                        ],
                        const SizedBox(height: 4),
                        Text(DateFormat('MMM dd, yyyy • hh:mm a').format(date), 
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    "${isEarning ? '+' : '-'} LKR ${NumberFormat('#,##0.00').format(amount)}",
                    style: TextStyle(fontWeight: FontWeight.bold, color: isEarning ? Colors.teal : Colors.orange, fontSize: 16),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handlePayMembershipFee(BuildContext context, double balance) async {
    final financeProv = Provider.of<FinanceProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final monthlyFee = financeProv.monthlyMembershipFee; // Assume I added this to FinanceProvider

    if (balance < monthlyFee) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Insufficient savings. You need LKR $monthlyFee to pay the fee.')));
      return;
    }

    // Confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Pay Membership Fee"),
        content: Text("Are you sure you want to deduct LKR $monthlyFee from your savings to pay this month's fee?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text("Pay", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        final memNo = profile.memberNo;
        
        // 1. Deduct from savings
        batch.set(FirebaseFirestore.instance.collection('members').doc(memNo), {
          'savingsBalance': FieldValue.increment(-monthlyFee)
        }, SetOptions(merge: true));

        // 2. Add to payment history
        final monthName = DateFormat('MMMM').format(DateTime.now());
        final yearStr = DateTime.now().year.toString();
        
        batch.set(FirebaseFirestore.instance.collection('app_membership_fee').doc(memNo), {
          'payment_history': FieldValue.arrayUnion([{
            'month': monthName,
            'year': yearStr,
            'reason': 'Membership Fee',
            'amount': monthlyFee,
            'paid_via': 'savings',
            'date': DateTime.now().toIso8601String(),
          }])
        }, SetOptions(merge: true));

        // 3. Add transaction record
        final txnRef = FirebaseFirestore.instance.collection('finance_transactions').doc();
        batch.set(txnRef, {
          'transactionId': txnRef.id,
          'passengerId': memNo,
          'amount': monthlyFee,
          'type': 'fee_payment',
          'timestamp': FieldValue.serverTimestamp(),
        });

        await batch.commit();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membership Fee paid successfully!')));
        }
      } catch (e) {
        debugPrint("Error paying fee: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to pay fee. Try again later.')));
        }
      }
    }
  }

  void _handleWithdraw(BuildContext context, double balance) async {
    if (balance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No savings available to withdraw.')));
      return;
    }

    final payment = Provider.of<PaymentProvider>(context, listen: false);
    if (payment.bankData == null || payment.bankData!['bankName'] == null || payment.bankData!['bankName'].toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please complete your Bank Details in the Profile section first.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final profile = Provider.of<ProfileProvider>(context, listen: false);
    
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Withdraw Savings"),
        content: Text("Are you sure you want to request a withdrawal of LKR ${NumberFormat('#,##0.00').format(balance)} to your bank account?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Request", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final memNo = profile.memberNo;
        final reqRef = FirebaseFirestore.instance.collection('withdrawal_requests').doc();
        
        await reqRef.set({
          'requestId': reqRef.id,
          'memberId': memNo,
          'amount': balance,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
          'bankDetails': payment.bankData,
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal request sent to Admin.')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to request withdrawal: $e')));
        }
      }
    }
  }
}
