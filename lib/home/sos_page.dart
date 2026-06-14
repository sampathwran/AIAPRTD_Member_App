import 'package:flutter/material.dart';

class SosPage extends StatelessWidget {
  const SosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("SOS Emergency", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 100),
              const SizedBox(height: 20),
              const Text(
                "Emergency Assistance",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              const Text(
                "Press and hold the button below to send an emergency alert to the admin and nearby members.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 60),

              // SOS Button
              GestureDetector(
                onLongPress: () {
                  _triggerSos(context);
                },
                child: Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 10)],
                  ),
                  child: const Center(
                    child: Text(
                      "HOLD TO SEND\nSOS",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SOS Logic එක ක්‍රියාත්මක වන තැන
  void _triggerSos(BuildContext context) {
    // මෙතන තමයි ඔයාගේ API call එක හෝ Location/Alert logic එක තියෙන්න ඕනේ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("SOS Alert Sent Successfully!"),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}