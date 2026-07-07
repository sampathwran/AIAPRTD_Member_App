import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import 'chat_list_page.dart';
import '../main.dart' as import_main;

class GlobalChatButton extends StatefulWidget {
  const GlobalChatButton({super.key});

  @override
  State<GlobalChatButton> createState() => _GlobalChatButtonState();
}

class _GlobalChatButtonState extends State<GlobalChatButton> {
  double _x = 16.0;
  double _y = 120.0; // Slightly below the header

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final String memberId = profileProvider.memberNo;

    if (memberId == 'N/A' || memberId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
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
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        // Find active trips
        var activeDocs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String status = data['status']?.toString().toLowerCase() ?? '';
          String tripState = data['tripState']?.toString().toLowerCase() ?? '';
          
          if (status == 'ongoing' || status == 'accepted' || tripState == 'accepted' || tripState == 'arrived' || tripState == 'started') {
            return true;
          }
          return false;
        }).toList();

        // IF THERE ARE NO ACTIVE TRIPS, DO NOT SHOW THE CHAT BUBBLE AT ALL
        if (activeDocs.isEmpty) return const SizedBox.shrink();
        
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
              import_main.navigatorKey.currentState?.push(
                MaterialPageRoute(builder: (context) => const ChatListPage())
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.chat, color: Colors.white, size: 28),
                  ),
                ),
                if (activeDocs.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        '${activeDocs.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
