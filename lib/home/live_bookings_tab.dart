import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/profile_provider.dart';
import 'active_booking_page.dart';

class LiveBookingsTab extends StatelessWidget {
  final List<QueryDocumentSnapshot> bookings;

  const LiveBookingsTab({super.key, required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flash_on_rounded, size: 60, color: Colors.orange.shade100),
            const SizedBox(height: 16),
            const Text("No Live Bookings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            const Text("Bookings starting within 30 mins appear here.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        var data = bookings[index].data() as Map<String, dynamic>;
        String docId = bookings[index].id;

        return _buildLiveCard(context, data, docId);
      },
    );
  }

  Widget _buildLiveCard(BuildContext context, Map<String, dynamic> data, String docId) {
    String pickup = data['pickupAddress'] ?? 'Unknown Pickup';
    String drop = data['dropAddress'] ?? 'Unknown Drop';
    String price = data['estimatedPrice']?.toString() ?? '0.00';
    String date = data['date'] ?? 'Today';
    String time = data['time'] ?? 'N/A';
    String paymentMethod = data['paymentMethod'] ?? 'Cash';

    // 💡 වර්තමාන Member ගේ Membership Number එක ගන්නවා
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final myMembershipNo = profileProvider.memberData?['membershipNo']?.toString() ?? 'Unknown_Member';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade300, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.orange.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🛡️ Top Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified, color: Colors.blue, size: 18),
                    const SizedBox(width: 6),
                    const Text("Verified Member", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
                  child: const Text("LIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📅 Date & Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.grey.shade700, size: 18),
                        const SizedBox(width: 6),
                        Text("$date • $time", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                      ],
                    ),
                    Text("Rs. $price", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 16),

                // 📍 Locations
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.my_location, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(pickup, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(left: 9, top: 4, bottom: 4),
                  height: 15, width: 2, color: Colors.grey.shade300,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(drop, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),

                // 💳 Payment
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(paymentMethod.toLowerCase() == 'card' ? Icons.credit_card : Icons.money, color: Colors.grey.shade600, size: 18),
                        const SizedBox(width: 6),
                        Text(paymentMethod.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text("View on Map"),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ==========================================
                // 🟢 🎯 Swipe to Accept Button
                // ==========================================
                SwipeToAcceptButton(
                  onAccept: () async {
                    try {
                      final docRef = FirebaseFirestore.instance.collection('all_bookings').doc(docId);

                      // 💡 100% ආරක්ෂිත Firebase Transaction
                      await FirebaseFirestore.instance.runTransaction((transaction) async {
                        DocumentSnapshot snapshot = await transaction.get(docRef);

                        if (!snapshot.exists) throw Exception("Booking not found");

                        var currentData = snapshot.data() as Map<String, dynamic>;

                        if (currentData['status'] == 'pending') {
                          // 🟢 මම සාර්ථකව Booking එක ගත්තා
                          transaction.update(docRef, {
                            'status': 'accepted',
                            'acceptedBy': myMembershipNo,
                          });
                        } else {
                          // 🔴 කවුරුහරි කලින් අරගෙන!
                          String takenBy = currentData['acceptedBy'] ?? 'Another Member';
                          throw Exception("TAKEN:$takenBy");
                        }
                      });

                      // සාර්ථකව ගත්තම notification එක පෙන්නලා අලුත් Page එකට යනවා
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("✅ You accepted the ride successfully!"),
                          backgroundColor: Colors.green,
                        ));

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ActiveBookingPage(bookingData: data, bookingId: docId)),
                        );
                      }
                      return true;

                    } catch (e) {
                      if (e.toString().contains("TAKEN:")) {
                        String takenBy = e.toString().split("TAKEN:")[1];
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("🚨 Ride was already taken by: $takenBy"),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 4),
                          ));
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text("❌ Failed to accept booking."),
                            backgroundColor: Colors.red,
                          ));
                        }
                      }
                      return false;
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 🚀 CUSTOM SWIPE TO ACCEPT BUTTON (සම්පූර්ණ කේතය)
// ==========================================
class SwipeToAcceptButton extends StatefulWidget {
  final Future<bool> Function() onAccept;
  const SwipeToAcceptButton({super.key, required this.onAccept});

  @override
  State<SwipeToAcceptButton> createState() => _SwipeToAcceptButtonState();
}

class _SwipeToAcceptButtonState extends State<SwipeToAcceptButton> {
  double _dragPosition = 0.0;
  bool _isLoading = false;
  bool _isAccepted = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          // ඇඟිල්ලෙන් අදින්න පුළුවන් උපරිම දුර (Button එකේ පළල - අදින රවුමේ පළල)
          double maxDrag = constraints.maxWidth - 60;

          return Container(
            height: 60,
            decoration: BoxDecoration(
              color: _isAccepted ? Colors.green : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _isAccepted ? Colors.green : Colors.blue, width: 2),
            ),
            child: Stack(
              children: [
                // 1. Text eka (Swipe to Accept >>>)
                Center(
                  child: Text(
                    _isAccepted
                        ? "ACCEPTED!"
                        : (_isLoading ? "Processing..." : "Swipe to Accept >>>"),
                    style: TextStyle(
                      color: _isAccepted ? Colors.white : Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                // 2. අදින රවුම (Draggable Thumb)
                if (!_isAccepted && !_isLoading)
                  Positioned(
                    left: _dragPosition,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _dragPosition += details.primaryDelta!;
                          // සීමාවෙන් පිට යන්න දෙන්නේ නෑ
                          if (_dragPosition < 0) _dragPosition = 0;
                          if (_dragPosition > maxDrag) _dragPosition = maxDrag;
                        });
                      },
                      onHorizontalDragEnd: (details) async {
                        // 80% කට වඩා ඇදලා නම් Accept කරනවා
                        if (_dragPosition > maxDrag * 0.8) {
                          setState(() {
                            _dragPosition = maxDrag;
                            _isLoading = true; // Processing වෙනවා කියලා පෙන්නනවා
                          });

                          // Firebase Function එක Call කරනවා
                          bool success = await widget.onAccept();

                          if (success) {
                            setState(() {
                              _isAccepted = true;
                              _isLoading = false;
                            });
                          } else {
                            // Error එකක් ආවොත් ආපහු මුලට යනවා
                            setState(() {
                              _dragPosition = 0.0;
                              _isLoading = false;
                            });
                          }
                        } else {
                          // 80% කට වඩා ඇදලා නැත්නම් ආපහු මුලට පනිනවා
                          setState(() {
                            _dragPosition = 0.0;
                          });
                        }
                      },
                      child: Container(
                        width: 60,
                        height: 56, // Border එක නිසා පොඩ්ඩක් අඩුයි
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(Icons.double_arrow, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
    );
  }
}