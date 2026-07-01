import 'package:flutter/material.dart';

class MyBookingPage extends StatelessWidget {
  const MyBookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text("My Bookings", style: TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            indicatorWeight: 3,
            tabs: [
              Tab(text: "Upcoming"),
              Tab(text: "Past Bookings"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _EmptyBookingState(
                title: "No Upcoming Bookings",
                subtitle: "You don't have any scheduled rides yet."
            ),
            _EmptyBookingState(
                title: "No Past Bookings",
                subtitle: "Your past booking history will appear here."
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBookingState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyBookingState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.library_books_outlined, size: 60, color: Colors.blue.shade400),
          ),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}