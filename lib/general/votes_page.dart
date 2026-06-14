import 'package:flutter/material.dart';

class VotesPage extends StatelessWidget {
  const VotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // මේවා තමයි දැනට තියෙන පවතින ඡන්ද විමසීම් (Polls)
    final List<Map<String, dynamic>> polls = [
      {"title": "Annual Event Venue", "desc": "Choose the location for our annual meeting.", "status": "Active"},
      {"title": "Committee Member Selection", "desc": "Vote for the new committee members.", "status": "Active"},
      {"title": "Charity Project 2026", "desc": "Select the project for this year.", "status": "Closed"},
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Voting & Polls", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: polls.length,
        itemBuilder: (context, index) {
          final poll = polls[index];
          bool isActive = poll['status'] == "Active";

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(poll['status'], style: TextStyle(color: isActive ? Colors.blue : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                    if (isActive) const Icon(Icons.how_to_vote, color: Colors.blue, size: 20),
                  ],
                ),
                const SizedBox(height: 10),
                Text(poll['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 5),
                Text(poll['desc'], style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 15),
                if (isActive)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showVoteOptions(context, poll['title']),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      child: const Text("Cast Your Vote"),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showVoteOptions(BuildContext context, String pollTitle) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Vote for: $pollTitle", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            ListTile(title: const Text("Option A"), leading: const Radio(value: 1, groupValue: 0, onChanged: null)),
            ListTile(title: const Text("Option B"), leading: const Radio(value: 2, groupValue: 0, onChanged: null)),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Submit Vote")),
          ],
        ),
      ),
    );
  }
}