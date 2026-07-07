import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/booking_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/profile_provider.dart';

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
            content: Text("Booking එකක් දැමිය හැක්කේ අවම වශයෙන් විනාඩි 30කට පෙරයි!"),
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
              Text("Booking Scheduled!"),
            ],
          ),
          content: const Text(
            "ඔබගේ Booking එක සාර්ථකව ඇතුලත් කර ඇත. අපගේ නියෝජිතයෙකු විනාඩි 15ක් ඇතුලත ඔබව සම්බන්ධ කරගනු ඇත.",
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
        const SnackBar(content: Text("කරුණාකර Pickup Date & Time තෝරන්න.")),
      );
      return;
    }

    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    if (bookingProvider.currentPickupLatLng == null || bookingProvider.dropLatLngs[0] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("කරුණාකර Pickup සහ Drop locations දෙකම තෝරන්න.")),
      );
      return;
    }

    String memberId = profileProvider.memberNo;
    String memberName = profileProvider.memberFullName;

    if (memberId == 'N/A' || memberId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Member ID එක සොයාගත නොහැක! කරුණාකර නැවත Log වන්න.")),
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
    String formattedDateTime = _selectedDateTime != null
        ? DateFormat('MMM dd, yyyy - hh:mm a').format(_selectedDateTime!)
        : "Select Time";

    // 💡 අලුත් විදිහ: SingleChildScrollView එකක් ඇතුළට දැම්මා
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min, // 💡 ඉඩ තියෙන ගානට විතරක් Size වෙන්න හැදුවා
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 💡 Expanded දැම්මා පොඩි Screen වල වචන එළියට පනින එක නවත්තන්න
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.access_time_filled, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Scheduled Time",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
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
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    formattedDateTime,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Payment Method",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownButton<String>(
                value: _selectedPaymentMethod,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blue),
                underline: const SizedBox(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                items: [
                  const DropdownMenuItem(
                    value: "Cash",
                    child: Row(
                      children: [
                        Icon(Icons.money, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text("Cash", style: TextStyle(color: Colors.black)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: "Card",
                    enabled: false,
                    child: Row(
                      children: [
                        const Icon(Icons.credit_card, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text("Card (Soon)", style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: "Corporate",
                    enabled: false,
                    child: Row(
                      children: [
                        const Icon(Icons.business, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text("Corp (Soon)", style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedPaymentMethod = newValue;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _isBooking ? null : _processBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: _isBooking
                ? const SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
            )
                : const Text(
              "Schedule Booking",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}