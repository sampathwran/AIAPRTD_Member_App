import 'package:flutter/material.dart';

class VehicleInfoPage extends StatelessWidget {
  const VehicleInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("vehicle Information"), // මෙතන ඒ ඒ පේජ් එකට ගැලපෙන නම දාන්න
      ),
      body: const Center(
        child: Text("vehicle Information Page Content"), // මෙතන ඒ පේජ් එකේ තියෙන්න ඕන දේවල් දාන්න
      ),
    );
  }
}