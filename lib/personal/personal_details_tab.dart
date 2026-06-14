import 'package:flutter/material.dart';

class PersonalDetailsTab extends StatelessWidget {
  const PersonalDetailsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection("Basic Info", [
          _buildTile(Icons.person_outline, "Full Name", "John Doe"),
          _buildTile(Icons.email_outlined, "Email", "john.doe@example.com"),
          _buildTile(Icons.phone_outlined, "Phone", "+94 77 123 4567"),
        ]),
        const SizedBox(height: 20),
        _buildSection("Account Info", [
          _buildTile(Icons.badge_outlined, "Membership No", "SD2024-0015"),
          _buildTile(Icons.location_on_outlined, "Address", "Colombo, Sri Lanka"),
        ]),
      ],
    );
  }

  // Helper Widgets
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey)),
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
      title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }
}