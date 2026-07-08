import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class EmptyBookingState extends StatelessWidget {
  final String title;
  final String subtitle;

  const EmptyBookingState({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.library_books_outlined, size: 60, color: Colors.blue.shade400),
          ),
          const SizedBox(height: 24),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey)),
        ],
      ),
    );
  }
}
