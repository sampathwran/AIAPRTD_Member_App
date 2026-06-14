import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // මේවා තමයි අපිට එන notification දත්ත (Backend එකෙන් එනවා නම් මේක List එකකින් ගන්න)
    final List<Map<String, dynamic>> notifications = [
      {"title": "New Ride Request", "body": "You have a new ride request from Colombo 07.", "time": "5m ago", "isRead": false},
      {"title": "Membership Renewed", "body": "Your membership has been successfully renewed.", "time": "2h ago", "isRead": true},
      {"title": "Payment Received", "body": "You received a payment of LKR 1,500.00.", "time": "1d ago", "isRead": true},
      {"title": "App Update", "body": "A new version of the app is available.", "time": "2d ago", "isRead": true},
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.done_all),
            tooltip: "Mark all as read",
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final note = notifications[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: note['isRead'] ? Colors.white : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: note['isRead'] ? Colors.grey.shade200 : Colors.blue.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: note['isRead'] ? Colors.grey.shade200 : Colors.blue.shade100,
                child: Icon(
                  note['isRead'] ? Icons.notifications_none : Icons.notifications_active,
                  color: note['isRead'] ? Colors.grey : Colors.blue,
                ),
              ),
              title: Text(
                note['title'],
                style: TextStyle(fontWeight: note['isRead'] ? FontWeight.w500 : FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note['body']),
                  const SizedBox(height: 5),
                  Text(note['time'], style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}