import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class ChangeVehicleSection extends StatefulWidget {
  final Function(Map<String, String>) onSubmit;
  const ChangeVehicleSection({super.key, required this.onSubmit});

  @override
  State<ChangeVehicleSection> createState() => _ChangeVehicleSectionState();
}

class _ChangeVehicleSectionState extends State<ChangeVehicleSection> {
  Map<String, dynamic> vehicleData = {};
  String? selectedBrand;
  String? selectedModel;
  final TextEditingController _yearController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadVehicles();
  }

  Future<void> loadVehicles() async {
    try {
      final String response = await rootBundle.loadString('assets/vehicles.json');
      setState(() {
        vehicleData = json.decode(response);
      });
    } catch (e) {
      debugPrint("Error loading vehicles: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (vehicleData.isEmpty) {
      return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // මාතෘකාව වෙනස් කළා
          const Text("Add New Vehicle Request",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 15),

          // Brand Dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Brand", border: OutlineInputBorder()),
            items: vehicleData.keys.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            onChanged: (val) => setState(() {
              selectedBrand = val;
              selectedModel = null;
            }),
          ),
          const SizedBox(height: 10),

          // Model Dropdown
          DropdownButtonFormField<String>(
            key: ValueKey(selectedBrand),
            decoration: const InputDecoration(labelText: "Model", border: OutlineInputBorder()),
            items: (selectedBrand == null)
                ? []
                : (vehicleData[selectedBrand] as List).map((m) =>
                DropdownMenuItem(value: m.toString(), child: Text(m.toString()))).toList(),
            onChanged: (val) => setState(() => selectedModel = val),
          ),
          const SizedBox(height: 10),

          // Register Year Field
          TextField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: "Register Year",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today)
              )
          ),

          const SizedBox(height: 20),

          // Submit Button - නම වෙනස් කළා
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: (selectedBrand != null && selectedModel != null) ? Colors.blue : Colors.grey,
                foregroundColor: Colors.white,
              ),
              onPressed: (selectedBrand != null && selectedModel != null)
                  ? () {
                widget.onSubmit({
                  "brand": selectedBrand!,
                  "model": selectedModel!,
                  "year": _yearController.text,
                });
              }
                  : null,
              child: const Text("Send Request to Admin"),
            ),
          ),
        ],
      ),
    );
  }
}