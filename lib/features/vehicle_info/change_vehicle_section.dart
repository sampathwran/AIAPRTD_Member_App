import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class ChangeVehicleSection extends StatefulWidget {
  final Function(Map<String, String>) onSubmit;
  const ChangeVehicleSection({super.key, required this.onSubmit});

  @override
  State<ChangeVehicleSection> createState() => _ChangeVehicleSectionState();
}

class _ChangeVehicleSectionState extends State<ChangeVehicleSection> {
  Map<String, List<String>> vehicleData = {};
  bool isLoading = true;

  String? selectedBrand;
  String? selectedModel;
  final TextEditingController _yearController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadVehiclesFromFirestore();
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  Future<void> loadVehiclesFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('vehicle_brands').get();
      Map<String, List<String>> fetchedData = {};
      
      for (var doc in snapshot.docs) {
        String brandName = doc.id;
        List<dynamic> modelsRaw = doc.data()['models'] ?? [];
        fetchedData[brandName] = modelsRaw.map((e) => e.toString()).toList();
      }
      
      // Sort brands alphabetically
      var sortedKeys = fetchedData.keys.toList()..sort();
      Map<String, List<String>> sortedData = {};
      for (var key in sortedKeys) {
        fetchedData[key]!.sort(); // Sort models alphabetically
        sortedData[key] = fetchedData[key]!;
      }
      
      setState(() {
        vehicleData = sortedData;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading vehicles from Firestore: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSelectionSheet(BuildContext context, String title, List<String> items, Function(String) onSelected) {
    if (items.isEmpty) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Controller for search
    TextEditingController searchController = TextEditingController();
    List<String> filteredItems = List.from(items);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle indicator
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      height: 5,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        )
                      ],
                    ),
                  ),
                  
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Search $title...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (value) {
                        setSheetState(() {
                          if (value.isEmpty) {
                            filteredItems = List.from(items);
                          } else {
                            filteredItems = items
                                .where((item) => item.toLowerCase().contains(value.toLowerCase()))
                                .toList();
                          }
                        });
                      },
                    ),
                  ),
                  
                  const Divider(),
                  
                  // List
                  Expanded(
                    child: filteredItems.isEmpty
                      ? const Center(child: Text("No results found"))
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                              title: Text(filteredItems[index], style: const TextStyle(fontSize: 16)),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                              onTap: () {
                                onSelected(filteredItems[index]);
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildSelectionBox({
    required String label, 
    required String? value, 
    required IconData icon, 
    required VoidCallback onTap,
    required bool isEnabled,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isEnabled 
              ? (isDark ? Colors.grey.shade900 : Colors.white)
              : (isDark ? Colors.grey.shade900.withValues(alpha: 0.5) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value != null 
                ? theme.colorScheme.primary 
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            width: value != null ? 1.5 : 1.0,
          ),
          boxShadow: isEnabled && value == null && !isDark ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: value != null 
                    ? theme.colorScheme.primary.withValues(alpha: 0.1) 
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon, 
                color: value != null ? theme.colorScheme.primary : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? "Tap to select",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: value != null ? FontWeight.bold : FontWeight.normal,
                      color: value != null 
                          ? (isDark ? Colors.white : Colors.black87)
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.expand_more,
              color: isEnabled ? Colors.grey : Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 200, 
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Loading vehicle list...", style: TextStyle(color: Colors.grey)),
            ],
          )
        )
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool canSubmit = selectedBrand != null && selectedModel != null && _yearController.text.isNotEmpty;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Illustration / Icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.car_detailed,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Center(
            child: Text(
              "Add New Vehicle Request",
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 20,
                color: isDark ? Colors.white : Colors.black87,
              )
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              "Select your vehicle details from the list below",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 32),

          // 1. Brand Selection
          _buildSelectionBox(
            label: "Vehicle Brand",
            value: selectedBrand,
            icon: Icons.directions_car_outlined,
            isEnabled: vehicleData.isNotEmpty,
            onTap: () {
              _showSelectionSheet(
                context, 
                "Select Brand", 
                vehicleData.keys.toList(), 
                (brand) {
                  setState(() {
                    selectedBrand = brand;
                    selectedModel = null; // Reset model when brand changes
                  });
                }
              );
            },
          ),
          
          const SizedBox(height: 16),

          // 2. Model Selection
          _buildSelectionBox(
            label: "Vehicle Model",
            value: selectedModel,
            icon: Icons.settings_suggest_outlined,
            isEnabled: selectedBrand != null && vehicleData[selectedBrand!]!.isNotEmpty,
            onTap: () {
              _showSelectionSheet(
                context, 
                "Select Model", 
                vehicleData[selectedBrand!] ?? [], 
                (model) {
                  setState(() {
                    selectedModel = model;
                  });
                }
              );
            },
          ),
          
          const SizedBox(height: 16),

          // 3. Register Year Field
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            ),
            child: TextField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                onChanged: (v) => setState(() {}), // Trigger rebuild to update submit button
                decoration: InputDecoration(
                    labelText: "Register Year (e.g. 2018)",
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    border: InputBorder.none,
                    counterText: "",
                    prefixIcon: Icon(Icons.calendar_month_outlined, color: Colors.grey.shade500),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                )
            ),
          ),

          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canSubmit ? theme.colorScheme.primary : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                foregroundColor: canSubmit ? Colors.white : Colors.grey.shade500,
                elevation: canSubmit ? 4 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: canSubmit
                  ? () {
                      FocusScope.of(context).unfocus();
                      widget.onSubmit({
                        "brand": selectedBrand!,
                        "model": selectedModel!,
                        "year": _yearController.text,
                      });
                    }
                  : null,
              child: const Text(
                "Send Request to Admin",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}