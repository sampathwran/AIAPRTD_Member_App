import 'package:flutter/material.dart';

class SupportTicketsPage extends StatelessWidget {
  const SupportTicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // මේවා තමයි පැමිණිලි වල දත්ත (Backend එකෙන් එනවා නම් මෙතන List එකක් වෙන්න ඕනේ)
    final List<Map<String, String>> tickets = [
      {"id": "#TKT-9921", "issue": "Payment not received", "status": "Pending"},
      {"id": "#TKT-9910", "issue": "App login error", "status": "Resolved"},
      {"id": "#TKT-9850", "issue": "Vehicle update delay", "status": "In Progress"},
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Support Tickets", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTicketDialog(context),
        icon: const Icon(Icons.add),
        label: const Text("New Ticket"),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          Color statusColor = ticket['status'] == "Resolved" ? Colors.green : (ticket['status'] == "In Progress" ? Colors.orange : Colors.red);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket['id']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 5),
                    Text(ticket['issue']!, style: const TextStyle(fontSize: 15)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(ticket['status']!, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // අලුත් පැමිණිල්ලක් යැවීමට Dialog එක
  void _showCreateTicketDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create Support Ticket"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: "Issue Title")),
            SizedBox(height: 10),
            TextField(maxLines: 3, decoration: InputDecoration(labelText: "Description")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Submit")),
        ],
      ),
    );
  }
}