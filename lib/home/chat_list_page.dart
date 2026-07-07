import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/profile_provider.dart';
import 'chat_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final String memberId = profileProvider.memberNo;

    if (memberId == 'N/A' || memberId.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Active Chats", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('all_bookings')
            .where(
              Filter.or(
                Filter('memberId', isEqualTo: memberId),
                Filter('acceptedBy', isEqualTo: memberId),
              ),
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          var activeTrips = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String status = data['status']?.toString().toLowerCase() ?? '';
            String tripState = data['tripState']?.toString().toLowerCase() ?? '';
            
            // Only ongoing / accepted trips
            if (status == 'ongoing' || status == 'accepted' || tripState == 'accepted' || tripState == 'arrived' || tripState == 'started') {
              return true;
            }
            return false;
          }).toList();

          if (activeTrips.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            itemCount: activeTrips.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              var tripDoc = activeTrips[index];
              return _buildChatTile(context, tripDoc, memberId);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No Active Chats",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          const Text("Chats will appear here when you have an active trip.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, QueryDocumentSnapshot tripDoc, String myMemberId) {
    var data = tripDoc.data() as Map<String, dynamic>;
    String tripId = tripDoc.id;
    
    bool isDriver = data['acceptedBy'] == myMemberId;
    String otherUserId = isDriver ? (data['memberId'] ?? 'Unknown Passenger') : (data['acceptedBy'] ?? 'Unknown Driver');
    String otherUserName = isDriver ? (data['passengerName'] ?? 'Passenger') : (data['driverName'] ?? 'Driver');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(tripId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, chatSnapshot) {
        String latestMessage = "Tap to view chat";
        bool hasUnread = false;
        String timeStr = "";

        if (chatSnapshot.hasData && chatSnapshot.data!.docs.isNotEmpty) {
           var msgData = chatSnapshot.data!.docs.first.data() as Map<String, dynamic>;
           latestMessage = msgData['text'] ?? "New Message";
           if (msgData['senderId'] != myMemberId && msgData['isRead'] == false) {
             hasUnread = true;
           }
           
           if (msgData['timestamp'] != null) {
             timeStr = DateFormat('hh:mm a').format((msgData['timestamp'] as Timestamp).toDate());
           }
        }

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: isDriver ? Colors.green.shade100 : Colors.blue.shade100,
                radius: 24,
                child: Icon(
                  isDriver ? Icons.person : Icons.directions_car,
                  color: isDriver ? Colors.green.shade700 : Colors.blue.shade700,
                ),
              ),
              if (hasUnread)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            otherUserName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Trip: $tripId",
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
              const SizedBox(height: 2),
              Text(
                latestMessage,
                style: TextStyle(
                  color: hasUnread ? Colors.black87 : Colors.grey.shade600,
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          trailing: timeStr.isNotEmpty
              ? Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey))
              : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  tripId: tripId,
                  otherUserName: otherUserName,
                  otherUserId: otherUserId,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
