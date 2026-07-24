import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:aiaprtd_member/core/providers/booking_provider.dart';
import 'package:aiaprtd_member/core/providers/vehicle_provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:flutter/cupertino.dart';

class BookingSummaryWidget extends StatefulWidget {
  const BookingSummaryWidget({super.key});

  @override
  State<BookingSummaryWidget> createState() => _BookingSummaryWidgetState();
}

class _BookingSummaryWidgetState extends State<BookingSummaryWidget> {
  String _selectedPaymentMethod = "Pay by passenger";
  DateTime? _selectedDateTime;
  bool _isBooking = false;
  String? _bookingNote;

  Future<void> _pickDateTime() async {
    DateTime now = DateTime.now();
    DateTime minAllowedTime = now.add(const Duration(minutes: 30));
    DateTime initialDateTime = _selectedDateTime ?? minAllowedTime;

    // Ensure initialDateTime is not before minAllowedTime
    if (initialDateTime.isBefore(minAllowedTime)) {
      initialDateTime = minAllowedTime;
    }

    DateTime? tempPickedDate;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext builder) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return Container(
          height: 320,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Header with Done button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                    const Text('Select Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedDateTime = tempPickedDate ?? initialDateTime;
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text('Done', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
              // Cupertino Date Picker
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: isDark ? Brightness.dark : Brightness.light,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.dateAndTime,
                    initialDateTime: initialDateTime,
                    minimumDate: now,
                    maximumDate: now.add(const Duration(days: 30)),
                    onDateTimeChanged: (DateTime newDateTime) {
                      tempPickedDate = newDateTime;
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    // After bottom sheet closes, check if selected time is valid
    if (_selectedDateTime != null && _selectedDateTime!.isBefore(minAllowedTime)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bookings must be scheduled at least 30 minutes in advance!"),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _selectedDateTime = null; // Reset if invalid
      });
    }
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

  void _showPaymentMethodSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select Payment Method", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: const Text("Pay by passenger"),
                trailing: _selectedPaymentMethod == "Pay by passenger" ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  setState(() => _selectedPaymentMethod = "Pay by passenger");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.group, color: Colors.blue),
                title: const Text("Pay by member"),
                trailing: _selectedPaymentMethod == "Pay by member" ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  setState(() => _selectedPaymentMethod = "Pay by member");
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    );
  }

  void _showAddNoteDialog() {
    TextEditingController _noteController = TextEditingController(text: _bookingNote);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Note"),
          content: TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Type note here...",
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
                setState(() => _bookingNote = _noteController.text.trim());
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      }
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
        note: _bookingNote,
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
                    onTap: _showPaymentMethodSheet,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            _selectedPaymentMethod == "Pay by passenger" ? "PASSENGER" : "MEMBER", 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedPaymentMethod, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                    onTap: _showAddNoteDialog,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _bookingNote != null && _bookingNote!.isNotEmpty ? Icons.notes : Icons.edit_outlined, 
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade800, 
                          size: 20
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _bookingNote != null && _bookingNote!.isNotEmpty ? _bookingNote! : "Add note", 
                            style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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