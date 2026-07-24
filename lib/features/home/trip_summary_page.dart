import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aiaprtd_member/core/providers/meter_provider.dart';
import 'package:aiaprtd_member/core/providers/finance_provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/features/general/widgets/rating_dialog_widget.dart';

class TripSummaryPage extends StatefulWidget {
  final String? bookingId;
  final Map<String, dynamic>? bookingData;
  
  const TripSummaryPage({super.key, this.bookingId, this.bookingData});

  @override
  State<TripSummaryPage> createState() => _TripSummaryPageState();
}

class _TripSummaryPageState extends State<TripSummaryPage> {
  final TextEditingController _whatsappController = TextEditingController();
  GoogleMapController? _mapController;
  static const platform = MethodChannel('com.aiaprtd.whatsapp_share');

  Future<void> _sendWhatsAppBill(MeterProvider meter) async {
    String phone = _whatsappController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a phone number')));
      return;
    }
    
    try {
      // 1. Capture Map Snapshot
      Uint8List? mapSnapshot;
      if (_mapController != null) {
        mapSnapshot = await _mapController!.takeSnapshot();
      }

      // 2. Load Assets and Info
      final ByteData imageByteData = await rootBundle.load('assets/images/logo.png');
      final Uint8List logoBytes = imageByteData.buffer.asUint8List();
      final pw.MemoryImage logoImage = pw.MemoryImage(logoBytes);
      
      final profile = Provider.of<ProfileProvider>(context, listen: false);
      final memberNo = profile.memberData?['membershipNo'] ?? 'Unknown';

      // 3. Generate PDF
      final pdf = pw.Document();
      
      final startDateStr = meter.startTime != null ? DateFormat('yyyy-MM-dd').format(meter.startTime!) : 'Unknown';
      final startTimeStr = meter.startTime != null ? DateFormat('hh:mm a').format(meter.startTime!) : 'Unknown';
      final endTimeStr = meter.endTime != null ? DateFormat('hh:mm a').format(meter.endTime!) : 'Unknown';

      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Stack(
              alignment: pw.Alignment.center,
              children: [
                // Watermark Tiled
                pw.Opacity(
                  opacity: 0.06,
                  child: pw.Transform.rotateBox(
                    angle: 0.6,
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: List.generate(7, (index) => 
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 40),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text("AIAPRTD", style: pw.TextStyle(fontSize: 50, fontWeight: pw.FontWeight.bold, color: PdfColors.grey)),
                              pw.SizedBox(width: 60),
                              pw.Text("AIAPRTD", style: pw.TextStyle(fontSize: 50, fontWeight: pw.FontWeight.bold, color: PdfColors.grey)),
                              pw.SizedBox(width: 60),
                              pw.Text("AIAPRTD", style: pw.TextStyle(fontSize: 50, fontWeight: pw.FontWeight.bold, color: PdfColors.grey)),
                            ]
                          )
                        )
                      ),
                    ),
                  ),
                ),
                
                // Content
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header
                    pw.Center(
                      child: pw.Column(
                        children: [
                          pw.Image(logoImage, height: 60),
                          pw.SizedBox(height: 10),
                          pw.Text("AIAPRTD TAXI RECEIPT", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                          pw.SizedBox(height: 5),
                          pw.Text("Email: info@aiaprtd.lk | Contact: 0705001002 / 0775018681", style: const pw.TextStyle(fontSize: 10)),
                          pw.Text("Address: Head Office, Colombo, Sri Lanka | Reg No: Pending", style: const pw.TextStyle(fontSize: 10)),
                        ]
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    
                    // Trip Details
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Trip ID: ${meter.tripId}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Text("Driver ID: $memberNo", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      ]
                    ),
                    pw.Text("Date: $startDateStr", style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 10),
                    pw.Divider(color: PdfColors.grey400),
                    pw.SizedBox(height: 10),
                    
                    // Times and Locations
                    pw.Text("Start Time: $startTimeStr", style: const pw.TextStyle(fontSize: 12)),
                    pw.Text("End Time: $endTimeStr", style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 10),
                    pw.Text("From: ${meter.startAddress}", style: const pw.TextStyle(fontSize: 12)),
                    pw.Text("To: ${meter.endAddress}", style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 10),
                    pw.Divider(color: PdfColors.grey400),
                    pw.SizedBox(height: 10),
                    
                    // Fare Breakdown
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Distance:", style: const pw.TextStyle(fontSize: 12)),
                        pw.Text("${meter.totalDistanceKm.toStringAsFixed(2)} km", style: const pw.TextStyle(fontSize: 12)),
                      ]
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Wait Time:", style: const pw.TextStyle(fontSize: 12)),
                        pw.Text("${(meter.waitingTimeSeconds / 60).floor()}m ${(meter.waitingTimeSeconds % 60)}s", style: const pw.TextStyle(fontSize: 12)),
                      ]
                    ),
                    pw.SizedBox(height: 10),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      color: PdfColors.grey200,
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("TOTAL FARE:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          pw.Text("LKR ${meter.totalFare.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        ]
                      )
                    ),
                    pw.SizedBox(height: 20),
                    
                    // Map Snapshot
                    if (mapSnapshot != null)
                      pw.Expanded(
                        child: pw.Center(
                          child: pw.ClipRRect(
                            horizontalRadius: 10,
                            verticalRadius: 10,
                            child: pw.Image(pw.MemoryImage(mapSnapshot)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // 3. Save PDF to temp file
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/receipt_${meter.tripId}.pdf");
      await file.writeAsBytes(await pdf.save());

      // 4. Send via MethodChannel
      await platform.invokeMethod('sharePdf', {
        'phone': phone,
        'filePath': file.path,
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate or send receipt: $e')),
        );
      }
    }
  }

  Future<void> _collectCashAndRate(MeterProvider meter, String driverMembershipNo) async {
    // 1. Mark as collected in meter provider
    await meter.collectCash(driverMembershipNo);
    
    // 2. Save bill to passenger's booking history
    String passengerId = widget.bookingData?['memberId']?.toString() ?? '';
    if (passengerId.isNotEmpty && widget.bookingId != null) {
      final billDetails = {
        'tripId': meter.tripId,
        'distanceKm': meter.totalDistanceKm,
        'waitingTimeSec': meter.waitingTimeSeconds,
        'totalFare': meter.totalFare,
        'pickupTime': meter.startTime?.toIso8601String(),
        'endTime': meter.endTime?.toIso8601String(),
        'paymentStatus': 'Collected',
        'billSavedAt': FieldValue.serverTimestamp(),
      };
      
      try {
        DocumentReference? passRef;
        final passQ = await FirebaseFirestore.instance.collection('member').where('membershipNo', isEqualTo: passengerId).limit(1).get();
        if (passQ.docs.isNotEmpty) {
          passRef = passQ.docs.first.reference;
        } else {
          final webQ = await FirebaseFirestore.instance.collection('web_sync_member').where('membershipNo', isEqualTo: passengerId).limit(1).get();
          if (webQ.docs.isNotEmpty) passRef = webQ.docs.first.reference;
        }
        if (passRef != null) {
          await passRef.collection('my_bookings').doc(widget.bookingId!).set(billDetails, SetOptions(merge: true));
        } else {
          await FirebaseFirestore.instance.collection('member').doc(passengerId).collection('my_bookings').doc(widget.bookingId!).set(billDetails, SetOptions(merge: true));
        }
        await FirebaseFirestore.instance.collection('all_bookings').doc(widget.bookingId!).set(billDetails, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error saving bill to passenger: $e");
      }
    }

    // Process Trip Commission (10% Split for App Booking, 3% for Road Pickup)
    try {
      final financeProv = Provider.of<FinanceProvider>(context, listen: false);
      await financeProv.processTripCommission(
        tripId: meter.tripId,
        totalFare: meter.totalFare,
        driverId: driverMembershipNo,
        passengerId: passengerId,
      );
    } catch (e) {
      debugPrint("Error processing finance commission: $e");
    }

    if (passengerId.isNotEmpty && widget.bookingId != null) {
      // Show Rating Dialog for App Bookings
      if (!mounted) return;
      _showRatingDialog(passengerId, meter);
    } else {
      // For Road Pickups, just reset and close
      meter.resetMeter();
      if (mounted) Navigator.pop(context);
    }
  }

  void _showRatingDialog(String passengerId, MeterProvider meter) {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            bool isSubmitting = false;
            return RatingDialogWidget(
              title: "Rate Passenger",
              isRatingDriver: false, // Driver is rating the passenger
              onSubmit: (rating, selectedChips, customReason) async {
                setStateDialog(() => isSubmitting = true);
                try {
                  await FirebaseFirestore.instance.collection('all_bookings').doc(widget.bookingId!).set({
                    'passengerRating': rating,
                    'passengerRatingReasons': selectedChips,
                    'passengerRatingCustomReason': customReason,
                  }, SetOptions(merge: true));
                  
                  if (passengerId.isNotEmpty) {
                    DocumentReference? passRef;
                    final passQ = await FirebaseFirestore.instance.collection('member').where('membershipNo', isEqualTo: passengerId).limit(1).get();
                    if (passQ.docs.isNotEmpty) passRef = passQ.docs.first.reference;
                    else {
                      final webQ = await FirebaseFirestore.instance.collection('web_sync_member').where('membershipNo', isEqualTo: passengerId).limit(1).get();
                      if (webQ.docs.isNotEmpty) passRef = webQ.docs.first.reference;
                    }
                    if (passRef != null) {
                      await passRef.collection('my_bookings').doc(widget.bookingId!).set({
                        'passengerRating': rating,
                        'passengerRatingReasons': selectedChips,
                        'passengerRatingCustomReason': customReason,
                      }, SetOptions(merge: true));
                    } else {
                      await FirebaseFirestore.instance.collection('member').doc(passengerId).collection('my_bookings').doc(widget.bookingId!).set({
                        'passengerRating': rating,
                        'passengerRatingReasons': selectedChips,
                        'passengerRatingCustomReason': customReason,
                      }, SetOptions(merge: true));
                    }
                    
                    final memberRef = passRef ?? FirebaseFirestore.instance.collection('member').doc(passengerId);
                    await FirebaseFirestore.instance.runTransaction((transaction) async {
                      final snapshot = await transaction.get(memberRef);
                      if (snapshot.exists) {
                        final data = snapshot.data() as Map<String, dynamic>;
                        double currentSum = (data['ratingSum'] ?? 0.0).toDouble();
                        int currentCount = (data['ratingCount'] ?? 0).toInt();
                        
                        currentSum += rating;
                        currentCount += 1;
                        double newRating = currentSum / currentCount;
                        
                        transaction.update(memberRef, {
                          'ratingSum': currentSum,
                          'ratingCount': currentCount,
                          'rating': double.parse(newRating.toStringAsFixed(1)),
                        });
                      }
                    });
                  }
                } catch (e) {
                  debugPrint("Error updating passenger rating: $e");
                }
                
                meter.resetMeter();
                navigator.pop(); // Close dialog
                navigator.pop(); // Go back to Home
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please collect cash to finish the trip."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text("Trip Summary", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
      body: Consumer<MeterProvider>(
        builder: (context, meter, child) {
          final profile = Provider.of<ProfileProvider>(context, listen: false);
          String membershipNo = 'Unknown';
          if (profile.memberData != null) {
            membershipNo = profile.memberData!['membershipNo'] ?? 'Unknown';
          }
          
          List<LatLng> polylineCoordinates = meter.routePoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
          
          LatLng center = const LatLng(6.9271, 79.8612); // Default Colombo
          if (polylineCoordinates.isNotEmpty) {
            center = polylineCoordinates.first;
          }

          Set<Marker> markers = {};
          if (polylineCoordinates.isNotEmpty) {
            markers.add(Marker(markerId: const MarkerId('start'), position: polylineCoordinates.first, infoWindow: const InfoWindow(title: "Start")));
            markers.add(Marker(markerId: const MarkerId('end'), position: polylineCoordinates.last, infoWindow: const InfoWindow(title: "End")));
          }

          Set<Polyline> polylines = {};
          if (polylineCoordinates.isNotEmpty) {
            polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                color: Colors.blue,
                width: 5,
                points: polylineCoordinates,
              )
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Map View
                SizedBox(
                  height: 250,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: center, zoom: 14),
                    onMapCreated: (controller) => _mapController = controller,
                    markers: markers,
                    polylines: polylines,
                    myLocationEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Addresses
                      _buildInfoRow(Icons.my_location, "From", meter.startAddress),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.location_on, "To", meter.endAddress),
                      
                      const Divider(height: 30, thickness: 1),
                      Center(child: Text("Trip ID: ${meter.tripId}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo))),
                      const Divider(height: 30, thickness: 1),
                      
                      // Metrics
                      Row(
                        children: [
                          Expanded(child: _buildSmallMetric("Distance", "${meter.totalDistanceKm.toStringAsFixed(2)} km")),
                          Expanded(child: _buildSmallMetric("Wait Time", "${(meter.waitingTimeSeconds / 60).floor()}m")),
                          Expanded(child: _buildSmallMetric("Fare", "LKR ${meter.totalFare.toStringAsFixed(2)}", isBold: true)),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // WhatsApp Sharing
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Share Bill via WhatsApp", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _whatsappController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      hintText: "Passenger Phone No",
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  onPressed: () => _sendWhatsAppBill(meter),
                                  icon: const Icon(Icons.send),
                                  color: Colors.white,
                                  style: IconButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Collect Cash Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => _collectCashAndRate(meter, membershipNo),
                        child: const Text("COLLECT CASH", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    ));
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        )
      ],
    );
  }
  
  Widget _buildSmallMetric(String title, String value, {bool isBold = false}) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isBold ? 20 : 16, color: isBold ? Colors.blue : Colors.black)),
      ],
    );
  }
}