import 'dart:io';
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

  // Dummy Categories for UI Testing
  final List<Map<String, dynamic>> _dummyCategories = [
    {
      'name': 'Electronics',
      'subcategories': ['Mobile Phones', 'Computers', 'TVs', 'Audio']
    },
    {
      'name': 'Vehicles',
      'subcategories': ['Cars', 'Motorcycles', 'Three Wheelers', 'Vans']
    },
    {
      'name': 'Property',
      'subcategories': ['Land', 'Houses', 'Apartments', 'Commercial']
    },
  ];

  List<String> _currentSubCategories = [];

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
    final isLoading = context.watch<AdsProvider>().isLoading;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Post an Ad", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
                  // Multi Image Picker
                  const Text("Add up to 5 photos", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
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
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5), width: 2),
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
                  const SizedBox(height: 20),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: "Ad Title", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                    validator: (v) => v!.isEmpty ? "Enter a title" : null,
                  ),
                  const SizedBox(height: 15),

                  // Price
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "Price (LKR)", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                    validator: (v) => v!.isEmpty ? "Enter a price" : null,
                  ),
                  const SizedBox(height: 15),

                  // Category
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: "Category",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedCategory,
                        hint: const Text("Select Category"),
                        items: _dummyCategories.map((c) => DropdownMenuItem<String>(
                          value: c['name'], 
                          child: Text(c['name'])
                        )).toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedCategory = v;
                            _selectedSubCategory = null; 
                            _currentSubCategories = List<String>.from(
                              _dummyCategories.firstWhere((element) => element['name'] == v)['subcategories']
                            );
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Subcategory
                  if (_currentSubCategories.isNotEmpty) ...[
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: "Subcategory",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedSubCategory,
                          hint: const Text("Select Subcategory"),
                          items: _currentSubCategories.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setState(() => _selectedSubCategory = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],

                  // Description
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: InputDecoration(labelText: "Description", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                    validator: (v) => v!.isEmpty ? "Enter a description" : null,
                  ),
                  const SizedBox(height: 20),

                  // Interactive Location Map
                  const Text("Select Location", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade300)
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
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.blueAccent),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _address, 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Bidding Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
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
                  const SizedBox(height: 30),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _submitAd,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: const Text("Post Ad", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
    );
  }
}
