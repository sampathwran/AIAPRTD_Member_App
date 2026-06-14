import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'vehicle_info_provider.dart';
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
      Provider.of<VehicleInfoProvider>(
        context,
        listen: false,
      ).fetchVehicleData(widget.membershipNo);
    });
  }

  void _showAddVehicleDialog(
      VehicleInfoProvider provider,
      ) {
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
                content: Text(
                  "Request sent for approval. Refreshing...",
                ),
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
          // සෑම විටම 'Add New' බොත්තම පෙන්වයි
          Consumer<VehicleInfoProvider>(
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
      body: Consumer<VehicleInfoProvider>(
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
                child: Text(
                  "No vehicle registered yet. Please click 'Add New'.",
                ),
              ),
            );
          }

          // Vehicle Details
          final Map<String, dynamic> vehicleDetails =
          Map<String, dynamic>.from(
            data['details'] ?? {},
          );

          // Documents
          final List documents =
          List.from(data['documents'] ?? []);

          // Registration Book Data
          Map<String, dynamic> regBookData = {};

          if (documents.length > 2) {
            regBookData =
            Map<String, dynamic>.from(
              documents[2]['reviewData'] ?? {},
            );
          }

          // Merge Data
          final Map<String, dynamic> mergedData = {
            'make': regBookData['Make'] ??
                vehicleDetails['brand'] ??
                "N/A",
            'model': regBookData['Model'] ??
                vehicleDetails['model'] ??
                "N/A",
            'vehicleNumber': regBookData['Plate Number'] ??
                vehicleDetails['vehicleNumber'] ??
                "N/A",
            'selectedCategory': data['selectedCategory'] ??
                "N/A",
            'frontImage': data['vehiclePhotos']?['Front']?['url'] ??
                '',
          };

          final bool canEdit =
              data['canEdit'] ?? false;

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