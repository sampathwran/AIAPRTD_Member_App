import 'package:flutter/material.dart';

class AppVolumePage extends StatelessWidget {
  const AppVolumePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Earning"), // මෙතන ඒ ඒ පේජ් එකට ගැලපෙන නම දාන්න
      ),
      body: const Center(
        child: Text("Personal Information Page Content"), // මෙතන ඒ පේජ් එකේ තියෙන්න ඕන දේවල් දාන්න
      ),
    );
  }
}