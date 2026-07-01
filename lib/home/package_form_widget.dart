import 'package:flutter/material.dart';

class PackageFormWidget extends StatelessWidget {
  const PackageFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "Package Delivery - Coming Soon!",
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