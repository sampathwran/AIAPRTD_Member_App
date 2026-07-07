import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../profile/my_booking_page.dart';
import 'chat_page.dart';

class PassengerActiveTripBanner extends StatefulWidget {
  const PassengerActiveTripBanner({super.key});

  @override
  State<PassengerActiveTripBanner> createState() => _PassengerActiveTripBannerState();
}

class _PassengerActiveTripBannerState extends State<PassengerActiveTripBanner> {
  double _x = 16.0;
  double _y = 200.0;

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final String memberId = profileProvider.memberNo;

    if (memberId == 'N/A' || memberId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('all_bookings')
          .where('memberId', isEqualTo: memberId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        // Find the active trip
        var activeDocs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String status = data['status']?.toString().toLowerCase() ?? '';
          String tripState = data['tripState']?.toString().toLowerCase() ?? '';
          
          // Only show for actively ongoing/accepted trips
          if (status == 'ongoing' || status == 'accepted' || tripState == 'accepted' || tripState == 'arrived' || tripState == 'started') {
            return true;
          }
          return false;
        }).toList();

        if (activeDocs.isEmpty) return const SizedBox.shrink();

        var activeBooking = activeDocs.first;
        String bookingId = activeBooking.id;
        
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .doc(bookingId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .snapshots(),
          builder: (context, chatSnapshot) {
            bool hasUnread = false;
            String latestMessage = "";
            
            if (chatSnapshot.hasData && chatSnapshot.data!.docs.isNotEmpty) {
               var d = chatSnapshot.data!.docs.first.data() as Map<String, dynamic>;
               if (d['senderId'] != memberId && (d['isRead'] == false)) {
                 hasUnread = true;
                 latestMessage = d['text'] ?? "New Message";
               }
            }

            return Positioned(
              left: _x,
              top: _y,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _x += details.delta.dx;
                    _y += details.delta.dy;
                  });
                },
                onTap: () {
                  // Click anywhere on the bubble to go to the Chat
                  if (hasUnread) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(
                      tripId: bookingId,
                      otherUserName: "Driver", // We can fetch driver name later if needed
                      otherUserId: "Driver ID",
                    )));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookingPage(initialIndex: 1)));
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasUnread) ...[
                      // Speech Bubble showing the message
                      Container(
                        margin: const EdgeInsets.only(bottom: 8, left: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        constraints: const BoxConstraints(maxWidth: 220),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                            bottomLeft: Radius.circular(4),
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5))
                          ],
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Driver says:",
                              style: TextStyle(color: Colors.blue.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              latestMessage,
                              style: const TextStyle(color: Colors.black87, fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Floating Car Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: hasUnread ? Colors.red.shade500 : Colors.blue.shade600,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.directions_car,
                            color: Colors.white,
                            size: 28,
                          ),
                          if (hasUnread)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.red.shade500, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
