import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdChatPage extends StatefulWidget {
  final String adId;
  final String ownerId;
  final String adTitle;

  const AdChatPage({super.key, required this.adId, required this.ownerId, required this.adTitle});

  @override
  State<AdChatPage> createState() => _AdChatPageState();
}

class _AdChatPageState extends State<AdChatPage> {
  final TextEditingController _msgController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  String get _chatRoomId {
    // Unique chat room for this Ad between the owner and the current user
    // If the current user IS the owner, they shouldn't chat with themselves, 
    // but we handle this logically (hide chat button for owner on AdDetails).
    List<String> ids = [currentUserId, widget.ownerId];
    ids.sort();
    return "${widget.adId}_${ids[0]}_${ids[1]}";
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final msg = text.trim();
    _msgController.clear();

    await FirebaseFirestore.instance
        .collection('marketplace_chats')
        .doc(_chatRoomId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'text': msg,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update metadata for the chat room
    await FirebaseFirestore.instance.collection('marketplace_chats').doc(_chatRoomId).set({
      'adId': widget.adId,
      'adTitle': widget.adTitle,
      'participants': [currentUserId, widget.ownerId],
      'lastMessage': msg,
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Chat", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.adTitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Pre-defined quick messages
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: Colors.grey.shade100,
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickMsg("Is this still available?"),
                _buildQuickMsg("Can we negotiate the price?"),
                _buildQuickMsg("Where are you located?"),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('marketplace_chats')
                  .doc(_chatRoomId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages yet. Send a message to start!", style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final msgData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    final isMe = msgData['senderId'] == currentUserId;
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          msgData['text'] ?? '',
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Input Box
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () => _sendMessage(_msgController.text),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuickMsg(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 12)),
        onPressed: () => _sendMessage(text),
      ),
    );
  }
}