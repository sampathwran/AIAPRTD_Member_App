import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/booking_provider.dart';
import 'package:aiaprtd_member/features/home/location_search_sheet.dart';

class OneWayFormWidget extends StatelessWidget {
  const OneWayFormWidget({super.key});

  // Open Bottom Sheet function
  void _openSearchSheet(BuildContext context, {required bool isPickup, int dropIndex = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationSearchSheet(
        isPickup: isPickup,
        dropIndex: dropIndex,
      ),
    );
  }

  // Save Location Dialog
  void _showSaveLocationDialog(BuildContext context, BookingProvider provider) {
    if (provider.pickupController.text.isEmpty || provider.currentPickupLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a pickup location first!")),
      );
      return;
    }

    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Save Location"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: "E.g., Home, Office, Gym",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                provider.saveLocation(
                  nameController.text,
                  provider.currentPickupLatLng!,
                  provider.pickupController.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${nameController.text} saved successfully!")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);

    return Column(
      children: [
        // 1. Return Trip Option (Removed as per user request)
        const SizedBox(height: 8),

        // PICKUP Location Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              width: 50,
              child: Text("PICKUP", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: provider.pickupController,
                readOnly: true,
                maxLines: 2,
                minLines: 1,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                onTap: () => _openSearchSheet(context, isPickup: true),
                decoration: const InputDecoration(
                  hintText: "Your Location",
                  border: InputBorder.none,
                  isDense: true,
                  hintStyle: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_border_rounded, color: Colors.black87),
              onPressed: () => _showSaveLocationDialog(context, provider),
            ),
          ],
        ),

        // Vertical Separator
        Row(
          children: [
            const SizedBox(width: 25),
            Container(height: 20, width: 1, color: Colors.grey.shade300),
            const Expanded(child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5, indent: 30, endIndent: 20)),
          ],
        ),

        // DROP Location (Single Drop Only)
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              width: 50,
              child: Text("DROP", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: provider.dropControllers.isNotEmpty ? provider.dropControllers[0] : TextEditingController(),
                readOnly: true,
                maxLines: 2,
                minLines: 1,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                onTap: () => _openSearchSheet(context, isPickup: false, dropIndex: 0),
                decoration: InputDecoration(
                  hintText: "Where are you going?",
                  border: InputBorder.none,
                  isDense: true,
                  hintStyle: TextStyle(fontSize: 15, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}