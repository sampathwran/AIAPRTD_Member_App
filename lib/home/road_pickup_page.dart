import 'package:flutter/material.dart';

class RoadPickupPage extends StatelessWidget { // Class නම මෙහෙම විය යුතුයි
  const RoadPickupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Road Pickup")),
      body: const Center(child: Text("Road Pickup Page")),
    );
  }
}