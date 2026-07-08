import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class BookingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  
  const BookingCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    String tripId = data['tripId'] ?? data['bookingId'] ?? 'N/A';
    String tripType = data['tripType'] ?? 'One way';
    String status = data['status'] ?? 'Unknown';
    String startAddress = data['startAddress'] ?? (data['pickupLocation'] != null ? data['pickupLocation']['address'] : null) ?? 'N/A';
    String endAddress = data['endAddress'] ?? (data['dropLocation'] != null ? data['dropLocation']['address'] : null) ?? 'N/A';
    
    double fare = 0.0;
    var rawFare = data['totalFare'] ?? data['estimateFare'];
    if (rawFare is num) {
      fare = rawFare.toDouble();
    } else if (rawFare is String) {
      fare = double.tryParse(rawFare) ?? 0.0;
    }
    
    String vehicleCategory = data['vehicleCategory'] ?? (data['vehicle'] != null ? data['vehicle']['name'] : null) ?? 'Mini';
    
    DateTime? pickupTime;
    if (data['pickupTime'] != null) {
      pickupTime = DateTime.tryParse(data['pickupTime'].toString());
    }

    // Determine status color
    Color statusColor = Colors.grey;
    if (status.toLowerCase() == 'pending') statusColor = Colors.orange;
    if (status.toLowerCase() == 'ongoing' || status.toLowerCase() == 'accepted') statusColor = Colors.blue;
    if (status.toLowerCase() == 'completed' || status.toLowerCase() == 'collected') statusColor = Colors.green;
    if (status.toLowerCase() == 'cancelled') statusColor = Colors.red;

    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Trip ID and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  tripId,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Date & Vehicle Row
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, size: 16, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pickupTime != null ? DateFormat('MMM dd, yyyy - hh:mm a').format(pickupTime) : 'N/A',
                        style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.directions_car, size: 16, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        "$vehicleCategory ($tripType)",
                        style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          ),
          
          // Locations
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(Icons.circle, color: Colors.blue, size: 12),
                  Container(height: 20, width: 2, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  const Icon(Icons.location_on, color: Colors.red, size: 14),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startAddress,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      endAddress,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Fare
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total Fare", style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey, fontWeight: FontWeight.bold)),
                Text("LKR ${fare.toStringAsFixed(2)}", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          
          if (status.toLowerCase() == 'pending' || status.toLowerCase() == 'upcoming' || status.toLowerCase() == 'scheduled') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showCancelDialog(context, tripId, data['memberId']),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Cancel Booking", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String tripId, String? memberId) {
    final TextEditingController reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Cancel Booking"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Are you sure you want to cancel this booking? Please provide a reason."),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: "Reason for cancellation",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                if (!isSubmitting)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close", style: TextStyle(color: Colors.grey)),
                  ),
                isSubmitting
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          if (reasonController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please enter a reason")),
                            );
                            return;
                          }

                          setState(() => isSubmitting = true);
                          
                          try {
                            String reason = reasonController.text.trim();
                            Map<String, dynamic> updates = {
                              'status': 'Cancelled',
                              'cancelReason': reason,
                              'cancelledBy': 'Member',
                              'cancelledAt': FieldValue.serverTimestamp(),
                            };

                            // Update all_bookings
                            await FirebaseFirestore.instance.collection('all_bookings').doc(tripId).set(updates, SetOptions(merge: true));
                            
                            // Update my_bookings
                            if (memberId != null) {
                              await FirebaseFirestore.instance
                                  .collection('members')
                                  .doc(memberId)
                                  .collection('my_bookings')
                                  .doc(tripId)
                                  .set(updates, SetOptions(merge: true));
                                  
                              // Update dayly_trips
                              DateTime? createdAt;
                              if (data['timestamp'] is Timestamp) {
                                createdAt = (data['timestamp'] as Timestamp).toDate();
                              } else if (data['createdAt'] is Timestamp) {
                                createdAt = (data['createdAt'] as Timestamp).toDate();
                              }
                              
                              if (createdAt != null) {
                                String dateStr = "${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}";
                                await FirebaseFirestore.instance
                                    .collection('dayly_trips')
                                    .doc(dateStr)
                                    .collection(memberId)
                                    .doc(tripId)
                                    .set(updates, SetOptions(merge: true))
                                    .catchError((e) => debugPrint("dayly_trips not found, skipping.")); // Catch error if doc doesn't exist yet
                              }
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Booking cancelled successfully"), backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            setState(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error cancelling: $e")),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text("Confirm Cancel", style: TextStyle(color: Colors.white)),
                      ),
              ],
            );
          },
        );
      },
    );
  }
}
