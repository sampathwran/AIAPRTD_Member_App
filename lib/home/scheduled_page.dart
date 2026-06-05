import 'package:flutter/material.dart';

class ScheduledPage extends StatelessWidget { // මේ Class නම හරියටම තියෙන්න ඕනේ
  const ScheduledPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scheduled Bookings")),
      body: const Center(child: Text("Scheduled Page")),
    );
  }
}