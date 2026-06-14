import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  final String rating;
  const RatingWidget({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Icon(Icons.star, color: Colors.amber, size: 18),
          ],
        ),
        const Text("Rating", style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}