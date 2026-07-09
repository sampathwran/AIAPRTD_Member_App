import 'package:flutter/material.dart';

class RideHistoryPage extends StatelessWidget {
  const RideHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // These are the Ride history data we get
    final List<Map<String, dynamic>> rides = [
      {"date": "08 June 2026", "route": "Colombo 07 - Mount Lavinia", "amount": "LKR 850.00", "status": "Completed"},
      {"date": "07 June 2026", "route": "Fort - Borella", "amount": "LKR 450.00", "status": "Completed"},
      {"date": "06 June 2026", "route": "Nugegoda - Maharagama", "amount": "LKR 620.00", "status": "Cancelled"},
      {"date": "05 June 2026", "route": "Pettah - Colombo 03", "amount": "LKR 300.00", "status": "Completed"},
    ];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Ride History", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rides.length,
        itemBuilder: (context, index) {
          final ride = rides[index];
          bool isCompleted = ride['status'] == "Completed";

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (!isDark)
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(ride['date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? (isDark ? Colors.green.withValues(alpha: 0.2) : Colors.green.shade50)
                            : (isDark ? Colors.red.withValues(alpha: 0.2) : Colors.red.shade50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(ride['status'],
                          style: TextStyle(color: isCompleted ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(ride['route'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 5),
                Text(ride['amount'], style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        },
      ),
    );
  }
}