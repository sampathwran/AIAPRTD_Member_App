import 'package:flutter/material.dart';

class RoundFormWidget extends StatelessWidget {
  const RoundFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.sync_alt_rounded, size: 40, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "Round Trip - Coming Soon!",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}