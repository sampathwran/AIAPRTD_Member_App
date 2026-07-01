import 'package:flutter/material.dart';

class ActiveBookingPage extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final String bookingId;

  const ActiveBookingPage({super.key, required this.bookingData, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    String pickup = bookingData['pickupAddress'] ?? 'Unknown Pickup';
    String price = bookingData['estimatedPrice']?.toString() ?? '0.00';
    String paymentMethod = bookingData['paymentMethod'] ?? 'Cash';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Active Ride", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.sos, color: Colors.red),
            onPressed: () {
              // 🚨 SOS Action
            },
          )
        ],
      ),
      body: Stack(
        children: [
          // ==========================================
          // 🗺️ 1. Google Map (Background)
          // ==========================================
          Container(
            color: Colors.grey.shade300,
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 80, color: Colors.white),
                  SizedBox(height: 10),
                  Text("Live Google Map Will Appear Here", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // ==========================================
          // 📄 2. Bottom Sheet (Ride & Passenger Details)
          // ==========================================
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 👤 Passenger Info & Contact
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Verified Member", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("⭐ 4.9 (Member)", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue), // Chat Button
                      ),
                      Container(
                        decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.phone, color: Colors.green), // Call Button
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),

                  // 📍 Next Location (Pickup)
                  const Text("Navigating to Pickup:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.my_location, color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(pickup, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 💳 Price & Payment Method
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(paymentMethod.toLowerCase() == 'card' ? Icons.credit_card : Icons.money, color: Colors.grey.shade700),
                            const SizedBox(width: 8),
                            Text(paymentMethod.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text("Rs. $price", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.green)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🧭 Navigation Button
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.navigation, color: Colors.white),
                    label: const Text("NAVIGATE TO PICKUP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}