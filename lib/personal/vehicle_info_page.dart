// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vehicle_provider.dart'; // 💡 🎯 කලින් හදපු අපේ අලුත් Provider එක ඉම්පෝර්ට් කරා මචං
import 'vehicle_overview_section.dart';
import 'compliance_docs_section.dart';
import 'vehicle_photos_section.dart';
import 'change_vehicle_section.dart';

class VehicleInfoPage extends StatefulWidget {
  final String membershipNo;

  const VehicleInfoPage({
    super.key,
    required this.membershipNo,
  });

  @override
  State<VehicleInfoPage> createState() => _VehicleInfoPageState();
}

class _VehicleInfoPageState extends State<VehicleInfoPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VehicleProvider>(
        context,
        listen: false,
      ).fetchVehicleData(widget.membershipNo);
    });
  }

  void _showAddVehicleDialog(VehicleProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Request New Vehicle"),
        content: ChangeVehicleSection(
          onSubmit: (data) {
            provider.requestAddVehicle(
              widget.membershipNo,
              data,
            );

            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Request sent for approval. Refreshing..."),
                backgroundColor: Colors.blue,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Vehicle Profile"),
        centerTitle: true,
        actions: [
          Consumer<VehicleProvider>(
            builder: (context, provider, _) {
              return TextButton.icon(
                onPressed: () => _showAddVehicleDialog(provider),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text("Add New"),
              );
            },
          ),
        ],
      ),
      body: Consumer<VehicleProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data = provider.vehicleData;

          if (data == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("No vehicle registered yet. Please click 'Add New'."),
              ),
            );
          }

          // 🧠 Vehicle Details (Fallback එකක් ලෙස - මෙතන Firestore එකේ 'Make' කැපිටල්)
          final Map<String, dynamic> vehicleDetails = {};
          if (data['details'] != null) {
            data['details'].forEach((key, value) {
              vehicleDetails[key.toString()] = value;
            });
          }

          // =========================================================================
          // 🧠 SMART REG BOOK DETECTOR ENGINE (Type Safe Copying)
          // =========================================================================
          final List<dynamic> documents = data['documents'] != null ? List.from(data['documents']) : [];
          Map<String, dynamic> regBookData = {};

          for (var doc in documents) {
            if (doc is Map && doc['reviewData'] != null) {
              final Map<String, dynamic> reviewMap = {};
              doc['reviewData'].forEach((k, v) {
                reviewMap[k.toString()] = v;
              });

              // Reg Book එක අඳුරගන්න සුවිශේෂී Key එකක් චෙක් කරනවා මචං
              if (reviewMap.containsKey('Plate Number') || reviewMap.containsKey('Chassis Number')) {
                regBookData = reviewMap;
                break;
              }
            }
          }

          // =========================================================================
          // 🎯 MERGE DATA: පිටතට දෙන Keys හැමවිටම සිම්පල් විය යුතුයි (make, model)
          // =========================================================================
          final Map<String, dynamic> mergedData = {
            // 💡 Firestore එකේ 'Make' හෝ 'details' එකේ 'Make' කැපිටල් නිසා ඒවා එහෙමම අරන් අපේ 'make' (සිම්පල්) එකට දානවා
            'make': regBookData['Make'] ??
                vehicleDetails['Make'] ??
                vehicleDetails['brand'] ?? // පැරණි fallback එකක් තිබුණොත්
                "N/A",

            // 💡 Firestore එකේ 'Model' කැපිටල් නිසා ඒක අරන් අපේ 'model' (සිම්පල්) එකට දානවා
            'model': regBookData['Model'] ??
                vehicleDetails['Model'] ??
                vehicleDetails['model'] ??
                "N/A",

            // 💡 'Plate Number' එක අරන් අපේ 'vehicleNumber' එකට මැප් කරනවා
            'vehicleNumber': regBookData['Plate Number'] ??
                vehicleDetails['Plate Number'] ??
                vehicleDetails['vehicleNumber'] ??
                "N/A",

            'vehicle_category': data['vehicle_category'] ?? data['selectedCategory'] ?? "N/A",
            'frontImage': data['vehiclePhotos']?['Front']?['url'] ?? '',
          };

          final bool canEdit = data['canEdit'] ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                VehicleOverviewSection(
                  data: mergedData,
                ),
                const SizedBox(height: 20),
                ComplianceDocsSection(
                  data: data,
                  canEdit: canEdit,
                  membershipNo: widget.membershipNo,
                ),
                const SizedBox(height: 20),
                VehiclePhotosSection(
                  data: data,
                  canEdit: canEdit,
                  membershipNo: widget.membershipNo,
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}