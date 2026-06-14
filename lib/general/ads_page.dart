import 'package:flutter/material.dart';

class AdsPage extends StatelessWidget {
  const AdsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Marketplace Ads", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Product Image
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: NetworkImage("https://images.unsplash.com/photo-1593642632823-8f785ba67e45?q=80&w=1000"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Product Title & Price
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("High Performance Laptop", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            const Text("LKR 150,000.00", style: TextStyle(fontSize: 20, color: Colors.blue, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            const Text("Used for 6 months, in excellent condition with original box and charger included.",
                style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 25),

            // Action Buttons (Bid & Chat)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showBidDialog(context),
                    icon: const Icon(Icons.gavel),
                    label: const Text("Place Bid"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {}, // Chat logic here
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text("Chat Owner"),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(15)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // Current Bids
            _buildSection("Live Bidding", [
              _buildTile(Icons.person, "Nimal Perera", "LKR 155,000.00"),
              _buildTile(Icons.person, "Kamal Silva", "LKR 152,000.00"),
            ]),
          ],
        ),
      ),
    );
  }

  void _showBidDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Place Your Bid"),
        content: const TextField(keyboardType: TextInputType.number, decoration: InputDecoration(hintText: "Enter your bid amount")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Submit")),
        ],
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8),
          child: Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey, letterSpacing: 1.2)),
        ),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))]),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: Colors.blue.withValues(alpha: 0.1), child: Icon(icon, color: Colors.blue)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
    );
  }
}