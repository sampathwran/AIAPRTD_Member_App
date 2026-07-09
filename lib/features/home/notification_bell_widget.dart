import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/features/general/notification_page.dart';
import 'package:aiaprtd_member/core/services/notification_service.dart';

class NotificationBellWidget extends StatefulWidget {
  final Color bgColor;
  final Color borderColor;
  final Color shadowColor;
  final bool isDark;

  const NotificationBellWidget({
    super.key,
    required this.bgColor,
    required this.borderColor,
    required this.shadowColor,
    required this.isDark,
  });

  @override
  State<NotificationBellWidget> createState() => _NotificationBellWidgetState();
}

class _NotificationBellWidgetState extends State<NotificationBellWidget> {
  bool _serviceStarted = false;

  @override
  Widget build(BuildContext context) {
    final profileProv = context.watch<ProfileProvider>();
    final memberId = profileProv.documentId;

    if (memberId.isNotEmpty && !_serviceStarted) {
      NotificationService().startListening(memberId);
      _serviceStarted = true;
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData && memberId.isNotEmpty) {
          final now = DateTime.now();
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            
            final targetType = data['targetType'];
            final targetMembers = data['targetMembers'] as List<dynamic>? ?? [];
            if (targetType != 'all' && !targetMembers.contains(memberId)) continue;

            final scheduledAt = data['scheduledAt'] as Timestamp?;
            if (scheduledAt != null && scheduledAt.toDate().isAfter(now)) continue;

            final readBy = List<String>.from(data['readBy'] ?? []);
            if (!readBy.contains(memberId)) {
              unreadCount++;
            }
          }
        }

        if (unreadCount == 0) {
          return const SizedBox.shrink(); // Hide completely when read
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPage()));
          },
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: widget.bgColor,
              border: Border.all(color: widget.borderColor),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.isDark ? Colors.red.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  unreadCount > 0 ? Icons.notifications_active : Icons.notifications_none,
                  color: unreadCount > 0 ? Colors.red : (widget.isDark ? Colors.grey.shade400 : Colors.blueGrey),
                  size: 26,
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
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