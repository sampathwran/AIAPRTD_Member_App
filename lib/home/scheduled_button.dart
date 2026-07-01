import 'package:flutter/material.dart';

class ScheduledButton extends StatelessWidget {
  final VoidCallback onTap;
  const ScheduledButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE3F2FD),
          child: Icon(Icons.calendar_month, color: Color(0xFF1E3A8A)),
        ),
        title: const Text(
          "Scheduled Bookings",
          style: TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1, // 💡 තනි පේළියට සීමා කළා
          overflow: TextOverflow.ellipsis, // 💡 ඉඩ මදි වුණොත් අගට තිත් 3ක් එන විදිහට හැදුවා
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}