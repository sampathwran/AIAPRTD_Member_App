import 'package:flutter/material.dart';

class AppVolumePage extends StatelessWidget {
  const AppVolumePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("App Usage & Volume", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Volume Control Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  const Text("Usage Intensity", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 15),
                  Slider(
                    value: 0.7,
                    onChanged: (val) {},
                    activeColor: Colors.blue,
                  ),
                  const Text("70% Capacity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Statistics Summary
            _buildSection("Usage Statistics", [
              _buildTile(Icons.speed, "Processing Speed", "High (Optimal)"),
              _buildTile(Icons.data_usage, "Data Volume", "1.2 GB / 5 GB"),
              _buildTile(Icons.history, "Request Count", "450 Requests"),
            ]),

            const SizedBox(height: 20),

            // Logs / Recent Activity
            _buildSection("Recent Logs", [
              _buildTile(Icons.sync, "Sync Completed", "2 mins ago"),
              _buildTile(Icons.cloud_upload, "Data Uploaded", "15 mins ago"),
            ]),
          ],
        ),
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.blue, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
      trailing: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
    );
  }
}