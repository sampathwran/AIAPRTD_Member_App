import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/booking_provider.dart';
import 'package:aiaprtd_member/features/home/location_search_sheet.dart';

class FlatRateFormWidget extends StatelessWidget {
  const FlatRateFormWidget({super.key});

  void _openSearchSheet(BuildContext context,
      {required bool isPickup, int dropIndex = 0}) {
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // PICKUP Location
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              width: 50,
              child: Text("PICKUP",
                  style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 11)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: provider.pickupController,
                readOnly: true,
                maxLines: 1,
                minLines: 1,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87),
                onTap: () => _openSearchSheet(context, isPickup: true),
                decoration: InputDecoration(
                  hintText: "Your Location",
                  border: InputBorder.none,
                  isDense: true,
                  hintStyle: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),

        // Vertical Separator
        Row(
          children: [
            const SizedBox(width: 25),
            Container(height: 5, width: 1, color: Colors.grey.shade300),
            const Expanded(
                child: Divider(
                    color: Color(0xFFF1F5F9),
                    thickness: 1.5,
                    indent: 30,
                    endIndent: 20)),
          ],
        ),

        // Multiple DROP Locations
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.dropControllers.length,
          itemBuilder: (context, index) {
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 50,
                      child: Text("DROP",
                          style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: provider.dropControllers[index],
                        readOnly: true,
                        maxLines: 1,
                        minLines: 1,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87),
                        onTap: () => _openSearchSheet(context,
                            isPickup: false, dropIndex: index),
                        decoration: InputDecoration(
                          hintText: "Where are you going?",
                          border: InputBorder.none,
                          isDense: true,
                          hintStyle: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    if (index > 0)
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => provider.removeDropLocation(index),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () => provider.addDropLocation(),
                      ),
                  ],
                ),
                if (index < provider.dropControllers.length - 1)
                  Row(
                    children: [
                      const SizedBox(width: 25),
                      Container(height: 5, width: 1, color: Colors.grey.shade300),
                      const Expanded(
                          child: Divider(
                              color: Color(0xFFF1F5F9),
                              thickness: 1.5,
                              indent: 30,
                              endIndent: 20)),
                    ],
                  ),
              ],
            );
          },
        ),

        const SizedBox(height: 2),
        const Divider(height: 2),
        const SizedBox(height: 4),
        
        // Prices Section
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      const Text("Passenger Price", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: provider.flatPassengerPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: "Rs. ",
                      hintText: "e.g. 20000",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_car, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      const Text("Driver Price", style: TextStyle(fontSize: 12, color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: provider.flatDriverPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: "Rs. ",
                      hintText: "e.g. 15000",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
