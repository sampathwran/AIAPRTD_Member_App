import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart' as cloud_firestore;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../providers/ads_provider.dart';
import '../providers/profile_provider.dart';

class PostAdPage extends StatefulWidget {
  const PostAdPage({super.key});

  @override
  State<PostAdPage> createState() => _PostAdPageState();
}

class _PostAdPageState extends State<PostAdPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedSubCategory;
  
  final List<File> _imageFiles = [];
  
  double? _lat;
  double? _lng;
  String _address = "Tap on the map to select location";
  bool _allowBidding = false;

  List<dynamic> _currentSubCategories = [];
  List<Map<String, dynamic>> _firebaseCategories = [];

  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
  }

  Future<void> _initCurrentLocation() async {
    final provider = Provider.of<AdsProvider>(context, listen: false);
    final result = await provider.getCurrentLocation();
    if (mounted && result['success'] == true) {
      setState(() {
        _lat = result['lat'];
        _lng = result['lng'];
      });
      _updateAddress(_lat!, _lng!);
      _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(_lat!, _lng!)));
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        for (var picked in pickedFiles) {
          if (_imageFiles.length < 5) {
            _imageFiles.add(File(picked.path));
          }
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  Future<void> _updateAddress(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String locality = place.locality ?? place.subAdministrativeArea ?? 'Unknown City';
        String country = place.country ?? 'Unknown Country';
        
        setState(() {
          _address = "$locality, $country";
        });
      }
    } catch (e) {
      setState(() {
        _address = "Location Selected (Address not found)";
      });
    }
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _lat = position.latitude;
      _lng = position.longitude;
      _address = "Loading address...";
    });
    _updateAddress(position.latitude, position.longitude);
  }

  Future<void> _submitAd() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select at least one image")));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a category")));
      return;
    }
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a location on the map")));
      return;
    }

    final provider = Provider.of<AdsProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final String membershipNo = profileProvider.memberNo;

    final result = await provider.postAd(
      imageFiles: _imageFiles,
      title: _titleController.text.trim(),
      price: _priceController.text.trim(),
      category: _selectedCategory!,
      description: _descController.text.trim(),
      lat: _lat!,
      lng: _lng!,
      address: _address,
      allowBidding: _allowBidding,
      membershipNo: membershipNo,
    );

    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ad submitted for approval!")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${result['error']}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final fillColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    final isLoading = context.watch<AdsProvider>().isLoading;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Post an Ad", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      body: isLoading 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 15),
                Text("Uploading Ad...", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent))
              ],
            )
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  _buildSectionCard(
                    isDarkMode,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.photo_library, color: Colors.blueAccent.shade200),
                            const SizedBox(width: 8),
                            const Text("Photos (Up to 5)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _imageFiles.length < 5 ? _imageFiles.length + 1 : 5,
                            itemBuilder: (context, index) {
                              if (index == _imageFiles.length) {
                                return GestureDetector(
                                  onTap: _pickImages,
                                  child: Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? Colors.grey.shade800 : Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5), width: 2, style: BorderStyle.solid),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo, size: 40, color: Colors.blueAccent),
                                        SizedBox(height: 5),
                                        Text("Add Photo", style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      image: DecorationImage(image: FileImage(_imageFiles[index]), fit: BoxFit.cover),
                                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                                    ),
                                  ),
                                  Positioned(
                                    top: 5,
                                    right: 15,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  )
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Details Section
                  _buildSectionCard(
                    isDarkMode,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description, color: Colors.purpleAccent.shade200),
                            const SizedBox(width: 8),
                            const Text("Ad Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: "Ad Title",
                            prefixIcon: const Icon(Icons.title, color: Colors.blueGrey),
                            filled: true,
                            fillColor: fillColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300)),
                          ),
                          validator: (v) => v!.isEmpty ? "Enter a title" : null,
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Price (LKR)",
                            prefixIcon: const Icon(Icons.monetization_on, color: Colors.green),
                            filled: true,
                            fillColor: fillColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300)),
                          ),
                          validator: (v) => v!.isEmpty ? "Enter a price" : null,
                        ),
                        const SizedBox(height: 15),
                        StreamBuilder<cloud_firestore.QuerySnapshot>(
                          stream: context.read<AdsProvider>().getCategoriesStream(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            _firebaseCategories = snapshot.data!.docs
                                .map((doc) => doc.data() as Map<String, dynamic>)
                                .toList();
                            _firebaseCategories.sort((a, b) => (a['order'] ?? 999).compareTo(b['order'] ?? 999));

                            if (_selectedCategory != null &&
                                !_firebaseCategories.any((c) => c['name'] == _selectedCategory)) {
                              _selectedCategory = null;
                              _selectedSubCategory = null;
                              _currentSubCategories = [];
                            }

                            return InputDecorator(
                              decoration: InputDecoration(
                                labelText: "Category",
                                prefixIcon: const Icon(Icons.category, color: Colors.orange),
                                filled: true,
                                fillColor: fillColor,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedCategory,
                                  hint: const Text("Select Category"),
                                  items: _firebaseCategories.map((c) => DropdownMenuItem<String>(
                                    value: c['name'], 
                                    child: Text(c['name'] ?? 'Unknown')
                                  )).toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      _selectedCategory = v;
                                      _selectedSubCategory = null;
                                      final cat = _firebaseCategories.firstWhere((element) => element['name'] == v);
                                      _currentSubCategories = cat['subcategories'] ?? [];
                                    });
                                  },
                                ),
                              ),
                            );
                          }
                        ),
                        const SizedBox(height: 15),
                        if (_currentSubCategories.isNotEmpty) ...[
                          InputDecorator(
                            decoration: InputDecoration(
                              labelText: "Subcategory",
                              prefixIcon: const Icon(Icons.subdirectory_arrow_right, color: Colors.orangeAccent),
                              filled: true,
                              fillColor: fillColor,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedSubCategory,
                                hint: const Text("Select Subcategory"),
                                items: _currentSubCategories.map((c) {
                                  String name = c is Map ? (c['name'] ?? '') : c.toString();
                                  return DropdownMenuItem<String>(value: name, child: Text(name));
                                }).toList(),
                                onChanged: (v) => setState(() => _selectedSubCategory = v),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                        ],
                        TextFormField(
                          controller: _descController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: "Description",
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 50.0),
                              child: Icon(Icons.subject, color: Colors.blueGrey),
                            ),
                            filled: true,
                            fillColor: fillColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300)),
                          ),
                          validator: (v) => v!.isEmpty ? "Enter a description" : null,
                        ),
                      ],
                    ),
                  ),

                  // Location Section
                  _buildSectionCard(
                    isDarkMode,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            const Text("Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300)
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(_lat ?? 6.9271, _lng ?? 79.8612), // Default Colombo
                                zoom: 12
                              ),
                              onMapCreated: (controller) => _mapController = controller,
                              onTap: _onMapTapped,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              markers: _lat != null && _lng != null 
                                ? { Marker(markerId: const MarkerId('selected'), position: LatLng(_lat!, _lng!)) }
                                : {},
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.place, size: 16, color: Colors.blueAccent),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                _address, 
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Options Section
                  _buildSectionCard(
                    isDarkMode,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.settings, color: Colors.teal),
                            const SizedBox(width: 8),
                            const Text("Options", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: fillColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300)
                          ),
                          child: SwitchListTile(
                            title: const Text("Allow Bidding", style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text("Let buyers place bids on your item", style: TextStyle(fontSize: 12)),
                            activeThumbColor: Colors.blueAccent,
                            value: _allowBidding,
                            onChanged: (val) {
                              setState(() {
                                _allowBidding = val;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _submitAd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent, 
                        foregroundColor: Colors.white, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                        shadowColor: Colors.blueAccent.withValues(alpha: 0.5),
                      ),
                      child: const Text("Post Ad", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  )
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSectionCard(bool isDarkMode, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
