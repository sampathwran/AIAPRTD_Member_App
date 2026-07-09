import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "Just now";
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      if (diff.inDays == 1) return "Yesterday";
      if (diff.inDays < 7) return "${diff.inDays} days ago";
      return DateFormat('MMM dd').format(date);
    } else if (diff.inHours > 0) {
      return "${diff.inHours}h ago";
    } else if (diff.inMinutes > 0) {
      return "${diff.inMinutes}m ago";
    } else {
      return "Just now";
    }
  }

  void _markAsRead(String docId, String memberId) {
    FirebaseFirestore.instance.collection('notifications').doc(docId).update({
      'readBy': FieldValue.arrayUnion([memberId])
    }).catchError((e) => debugPrint("Failed to mark as read: $e"));
  }

  void _markAllAsRead(List<QueryDocumentSnapshot> docs, String memberId) {
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final readBy = List<String>.from(data['readBy'] ?? []);
      if (!readBy.contains(memberId)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([memberId])
        });
      }
    }
    batch.commit().catchError((e) => debugPrint("Failed to mark all as read: $e"));
  }

  @override
  Widget build(BuildContext context) {
    final profileProv = context.watch<ProfileProvider>();
    final memberId = profileProv.documentId;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (memberId.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? theme.appBarTheme.backgroundColor : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: isDark ? Colors.white : Colors.black)));

          var docs = snapshot.data?.docs ?? [];
          final now = DateTime.now();

          // Filter documents
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Check target
            final targetType = data['targetType'];
            final targetMembers = data['targetMembers'] as List<dynamic>? ?? [];
            if (targetType != 'all' && !targetMembers.contains(memberId)) {
              return false;
            }

            // Check if scheduled
            final scheduledAt = data['scheduledAt'] as Timestamp?;
            if (scheduledAt != null && scheduledAt.toDate().isAfter(now)) {
              return false; // Not yet time to show
            }

            return true;
          }).toList();

          // Sort by effective date (scheduledAt or createdAt)
          docs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final timeA = (dataA['scheduledAt'] ?? dataA['createdAt']) as Timestamp?;
            final timeB = (dataB['scheduledAt'] ?? dataB['createdAt']) as Timestamp?;
            if (timeA == null || timeB == null) return 0;
            return timeB.compareTo(timeA); // Descending
          });

          // Unread count check for Mark All As Read button
          final hasUnread = docs.any((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final readBy = List<String>.from(data['readBy'] ?? []);
            return !readBy.contains(memberId);
          });

          // Add Action manually to existing AppBar using Builder is tricky in Scaffold unless we re-build AppBar
          // Instead we can just place a button if there are unread
          
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("No Notifications", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey)),
                  const SizedBox(height: 8),
                  Text("You're all caught up!", style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey)),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (hasUnread)
                Padding(
                  padding: const EdgeInsets.only(right: 16, top: 8, bottom: 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _markAllAsRead(docs, memberId),
                      icon: const Icon(Icons.done_all, size: 18, color: Colors.blue),
                      label: const Text("Mark all as read", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final readBy = List<String>.from(data['readBy'] ?? []);
                    final bool isRead = readBy.contains(memberId);
                    final title = data['title'] ?? 'Notification';
                    final body = data['body'] ?? '';
                    final Timestamp? timeStamp = data['scheduledAt'] ?? data['createdAt'];

                    return GestureDetector(
                      onTap: () {
                        if (!isRead) _markAsRead(doc.id, memberId);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isRead 
                              ? (isDark ? theme.cardColor : Colors.white) 
                              : (isDark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue.shade50),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isRead 
                                ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200) 
                                : (isDark ? Colors.blue.shade800 : Colors.blue.shade200)
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: isRead 
                                ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200) 
                                : (isDark ? Colors.blue.shade800 : Colors.blue.shade100),
                            child: Icon(
                              isRead ? Icons.notifications_none : Icons.notifications_active,
                              color: isRead 
                                  ? (isDark ? Colors.grey.shade500 : Colors.grey) 
                                  : (isDark ? Colors.blue.shade200 : Colors.blue),
                            ),
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(body, style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.black87)),
                              const SizedBox(height: 8),
                              Text(_formatTime(timeStamp), style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade500 : Colors.blueGrey)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}