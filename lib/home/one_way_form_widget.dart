import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import 'location_search_sheet.dart';

class OneWayFormWidget extends StatelessWidget {
  const OneWayFormWidget({super.key});

  // 💡 Bottom Sheet එක open කරන function එක
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

  // 💡 Location එක Save කරන Dialog එක
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
        // 💡 1. Return Trip Option (Form එකේ උඩින්ම දැම්මා)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              if (provider.currentPickupLatLng == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("කරුණාකර මුලින්ම Pickup Location එක තෝරන්න.")),
                );
                return;
              }
              // 💡 Provider එකේ හදපු makeReturnTrip function එක Call වෙනවා
              provider.makeReturnTrip();
            },
            icon: const Icon(Icons.sync_alt_rounded, size: 16, color: Colors.blue),
            label: const Text("Return", style: TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 💡 PICKUP Location Row
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
                onTap: () => _openSearchSheet(context, isPickup: true),
                decoration: const InputDecoration(
                  hintText: "Your Location",
                  border: InputBorder.none,
                  isDense: true,
                  hintStyle: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_border_rounded, color: Colors.black87),
              onPressed: () => _showSaveLocationDialog(context, provider),
            ),
          ],
        ),

        // 💡 Vertical Separator
        Row(
          children: [
            const SizedBox(width: 25),
            Container(height: 20, width: 1, color: Colors.grey.shade300),
            const Expanded(child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5, indent: 30, endIndent: 20)),
          ],
        ),

        // 💡 DROP Locations List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: provider.dropControllers.length,
          itemBuilder: (context, index) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 50,
                  child: Text(index == 0 ? "DROP" : "DROP ${index + 1}", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: provider.dropControllers[index],
                    readOnly: true,
                    onTap: () => _openSearchSheet(context, isPickup: false, dropIndex: index),
                    decoration: InputDecoration(
                      hintText: "Where are you going?",
                      border: InputBorder.none,
                      isDense: true,
                      hintStyle: TextStyle(fontSize: 16, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),

                // 💡 2. Action Icons (Add/Remove)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Remove Icon (Drop එකකට වඩා තියෙනවා නම් හැම එකටම පෙන්වනවා)
                    if (provider.dropControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 24),
                        onPressed: () => provider.removeDropLocation(index),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),

                    // Add Icon (අන්තිම Drop එකට විතරක් පෙන්වනවා)
                    if (index == provider.dropControllers.length - 1)
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.black87, size: 28),
                        onPressed: () => provider.addDropLocation(),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}