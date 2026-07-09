import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:aiaprtd_member/core/providers/booking_provider.dart';
import 'package:aiaprtd_member/core/providers/vehicle_provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';

class BookingSummaryWidget extends StatefulWidget {
  const BookingSummaryWidget({super.key});

  @override
  State<BookingSummaryWidget> createState() => _BookingSummaryWidgetState();
}

class _BookingSummaryWidgetState extends State<BookingSummaryWidget> {
  String _selectedPaymentMethod = "Cash";
  DateTime? _selectedDateTime;
  bool _isBooking = false;

  Future<void> _pickDateTime() async {
    DateTime now = DateTime.now();
    DateTime minAllowedTime = now.add(const Duration(minutes: 30));

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: minAllowedTime,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );

    if (pickedDate == null) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(minAllowedTime),
    );

    if (pickedTime == null) return;

    DateTime finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (finalDateTime.isBefore(minAllowedTime)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bookings must be scheduled at least 30 minutes in advance!"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _selectedDateTime = finalDateTime;
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Flexible(child: Text("Booking Scheduled!")),
            ],
          ),
          content: const Text(
            "Your booking has been successfully scheduled. One of our representatives will contact you within 15 minutes.",
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              },
              child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processBooking() async {
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a Pickup Date & Time.")),
      );
      return;
    }

    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    if (bookingProvider.currentPickupLatLng == null || bookingProvider.dropLatLngs[0] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both Pickup and Drop locations.")),
      );
      return;
    }

    String memberId = profileProvider.memberNo;
    String memberName = profileProvider.memberFullName;

    if (memberId == 'N/A' || memberId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Member ID not found! Please log in again.")),
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      final selectedVehicle = vehicleProvider.vehicles[vehicleProvider.selectedVehicleIndex];
      final estimateFare = vehicleProvider.calculateEstimateFare(
          bookingProvider.totalDistanceKm,
          vehicleProvider.selectedVehicleIndex
      );

      await bookingProvider.scheduleBooking(
        memberId: memberId,
        memberName: memberName,
        pickupTime: _selectedDateTime!,
        selectedVehicle: selectedVehicle,
        estimateFare: estimateFare,
        paymentMethod: _selectedPaymentMethod,
      );

      if (mounted) {
        _showSuccessDialog();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String formattedDateTime = _selectedDateTime != null
        ? DateFormat('MMM dd, yyyy - hh:mm a').format(_selectedDateTime!)
        : "Select Time";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Use Expanded to prevent text overflow on small screens
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.access_time_filled, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Scheduled Time",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _pickDateTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.primary.withValues(alpha: 0.15) : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? theme.colorScheme.primary : Colors.blue.shade200),
                  ),
                  child: Text(
                    formattedDateTime,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.transparent,
              border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Payment
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () { /* Change payment */ },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(4)),
                          child: const Text("CASH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Pay with Cash", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text("Default", style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(height: 30, width: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                // Add Note
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () {},
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_outlined, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800, size: 20),
                        const SizedBox(width: 4),
                        Text("Add note", style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),

        // Confirm Button (Fixed at bottom)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isBooking ? null : _processBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // Changed to blue per user request
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            child: _isBooking
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text("Book Now", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}