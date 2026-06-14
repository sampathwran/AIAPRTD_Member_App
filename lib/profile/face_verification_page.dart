import 'package:flutter/material.dart';

class FaceVerificationPage extends StatelessWidget {
  const FaceVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // මෙතන තමයි කැමරා ෆීඩ් එක එන්න ඕන (Camera Package එක පාවිච්චි කරන්න)
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: const Icon(Icons.face, size: 150, color: Colors.white30),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Column(
              children: [
                const Text("Align your face in the circle", style: TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Face Recognition logic here
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
                  child: const Text("SCAN FACE"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}