import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/ads_provider.dart';
import 'post_ad_page.dart';
import 'ad_details_page.dart';

class AdsPage extends StatefulWidget {
  const AdsPage({super.key});

  @override
  State<AdsPage> createState() => _AdsPageState();
}

class _AdsPageState extends State<AdsPage> {
  String _searchQuery = "";
  String _locationQuery = "";
  double _minPrice = 0;
  double _maxPrice = 10000000;
  
  String? _selectedCategory;
  String? _selectedSubCategory;
  List<String> _currentSubcategories = [];

  String _sortBy = "Newest First";
  double? _userLat;
  double? _userLng;

  void _showFilterSheet() {
    String tempLocation = _locationQuery;
    double tempMin = _minPrice;
    double tempMax = _maxPrice;
    String tempSortBy = _sortBy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Filter Ads", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  // Sort By Dropdown
                  DropdownButtonFormField<String>(
                    value: tempSortBy,
                    decoration: InputDecoration(
                      labelText: "Sort By",
                      prefixIcon: const Icon(Icons.sort, color: Colors.blueAccent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    items: ["Newest First", "Lowest Price", "Nearest First"]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setSheetState(() => tempSortBy = v);
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Location Filter
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Location (City/Town)",
                      prefixIcon: const Icon(Icons.location_on, color: Colors.blueAccent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    controller: TextEditingController(text: tempLocation)..selection = TextSelection.collapsed(offset: tempLocation.length),
                    onChanged: (v) => tempLocation = v,
                  ),
                  const SizedBox(height: 20),
                  
                  // Price Filter
                  Text("Price Range (LKR): ${tempMin.toInt()} - ${tempMax.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  RangeSlider(
                    values: RangeValues(tempMin, tempMax),
                    min: 0,
                    max: 10000000,
                    divisions: 100,
                    activeColor: Colors.purpleAccent,
                    labels: RangeLabels(tempMin.toInt().toString(), tempMax.toInt().toString()),
                    onChanged: (RangeValues values) {
                      setSheetState(() {
                        tempMin = values.start;
                        tempMax = values.end;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      onPressed: () async {
                        if (tempSortBy == "Nearest First" && _userLat == null) {
                          // Try getting location
                          final provider = Provider.of<AdsProvider>(context, listen: false);
                          final res = await provider.getCurrentLocation();
                          if (res['success'] == true && mounted) {
                            setState(() {
                              _userLat = res['lat'];
                              _userLng = res['lng'];
                            });
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not get location for Nearest First. ${res['error']}")));
                            tempSortBy = "Newest First";
                          }
                        }

                        if (mounted) {
                          setState(() {
                            _locationQuery = tempLocation.toLowerCase();
                            _minPrice = tempMin;
                            _maxPrice = tempMax;
                            _sortBy = tempSortBy;
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Apply Filters", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      },
    );
  }

  List<Map<String, dynamic>> _getDummyAds() {
    return List.generate(10, (index) {
      return {
        'id': 'dummy_$index',
        'title': 'Premium Item ${index + 1}',
        'price': '${(index + 1) * 15000}',
        'address': index % 2 == 0 ? 'Colombo, Sri Lanka' : 'Kandy, Sri Lanka',
        'imageUrls': [
          'https://images.unsplash.com/photo-1523275335684-37898b6baf30?q=80&w=200',
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=200'
        ],
        'category': 'Electronics',
        'subcategory': index % 2 == 0 ? 'Computers' : 'Mobile Phones',
        'lat': index % 2 == 0 ? 6.9271 : 7.2906, 
        'lng': index % 2 == 0 ? 79.8612 : 80.6337,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(days: index))),
      };
    });
  }

  List<Map<String, dynamic>> _getDummyCategories() {
    return [
      {
        'name': 'Electronics',
        'imageUrl': 'https://img.icons8.com/color/96/000000/electronics.png',
        'subcategories': ['Mobile Phones', 'Computers', 'TVs', 'Audio']
      },
      {
        'name': 'Vehicles',
        'imageUrl': 'https://img.icons8.com/color/96/000000/car--v1.png',
        'subcategories': ['Cars', 'Motorcycles', 'Three Wheelers', 'Vans']
      },
      {
        'name': 'Property',
        'imageUrl': 'https://img.icons8.com/color/96/000000/house.png',
        'subcategories': ['Land', 'Houses', 'Apartments', 'Commercial']
      },
      {
        'name': 'Services',
        'imageUrl': 'https://img.icons8.com/color/96/000000/service.png',
        'subcategories': ['Education', 'Repairs', 'Events', 'Health']
      },
      {
        'name': 'Fashion',
        'imageUrl': 'https://img.icons8.com/color/96/000000/t-shirt.png',
        'subcategories': ['Men', 'Women', 'Kids', 'Watches']
      },
      {
        'name': 'Sports',
        'imageUrl': 'https://img.icons8.com/color/96/000000/dumbbell.png',
        'subcategories': ['Fitness', 'Outdoor', 'Equipment', 'Bicycles']
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Marketplace", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. Search Bar & Filter Button
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              boxShadow: [BoxShadow(color: isDarkMode ? Colors.black38 : Colors.black12, blurRadius: 5, offset: const Offset(0, 3))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search ads...",
                      prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.purpleAccent),
                    onPressed: _showFilterSheet,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 2. Categories (2 Rows Horizontal Scroll)
          SizedBox(
            height: 220,
            child: StreamBuilder<QuerySnapshot>(
              stream: context.read<AdsProvider>().getCategoriesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                List<Map<String, dynamic>> catList = [];
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  catList = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
                } else {
                  // Fallback to dummy categories for UI testing
                  catList = _getDummyCategories();
                }

                return GridView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.1, 
                  ),
                  itemCount: catList.length,
                  itemBuilder: (context, index) {
                    final catData = catList[index];
                    final catName = catData['name'] ?? 'Unknown';
                    final catImage = catData['imageUrl'] ?? 'https://via.placeholder.com/100';
                    final subCats = (catData['subcategories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
                    final isSelected = _selectedCategory == catName;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedCategory = null;
                            _selectedSubCategory = null;
                            _currentSubcategories = [];
                          } else {
                            _selectedCategory = catName;
                            _selectedSubCategory = null;
                            _currentSubcategories = subCats;
                          }
                        });
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.purpleAccent : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: [
                                if (!isSelected) BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 5)
                              ]
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(catImage),
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            catName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.purpleAccent : theme.textTheme.bodyMedium?.color,
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // 3. Subcategories (Horizontal Scroll)
          if (_currentSubcategories.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _currentSubcategories.length,
                itemBuilder: (context, index) {
                  final sub = _currentSubcategories[index];
                  final isSelected = _selectedSubCategory == sub;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(sub),
                      selected: isSelected,
                      selectedColor: Colors.purpleAccent.withValues(alpha: 0.2),
                      checkmarkColor: Colors.purple,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.purple : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedSubCategory = selected ? sub : null;
                        });
                      },
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 10),

          // 4. Ads Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: context.read<AdsProvider>().getAdsStream(_selectedCategory),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                List<Map<String, dynamic>> adList = [];
                
                // Add Firebase Ads
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    data['id'] = doc.id;
                    adList.add(data);
                  }
                }

                // Append Dummy Ads for UI Visualization if needed
                if (adList.isEmpty) {
                  adList.addAll(_getDummyAds());
                }

                // Apply Local Filters
                adList = adList.where((data) {
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final address = (data['address'] ?? '').toString().toLowerCase();
                  final priceStr = data['price'] ?? '0';
                  final price = double.tryParse(priceStr.toString()) ?? 0;
                  final category = data['category'] ?? '';
                  final subcategory = data['subcategory'] ?? '';

                  // Subcategory Match
                  if (_selectedSubCategory != null && subcategory != _selectedSubCategory) return false;
                  // Selected Category Match (for dummy ads since stream already filters firebase ads)
                  if (_selectedCategory != null && category != _selectedCategory) return false;
                  // Search Query
                  if (_searchQuery.isNotEmpty && !title.contains(_searchQuery)) return false;
                  // Location Query
                  if (_locationQuery.isNotEmpty && !address.contains(_locationQuery)) return false;
                  // Price Range
                  if (price < _minPrice || price > _maxPrice) return false;

                  return true;
                }).toList();

                // Apply Sorting
                adList.sort((a, b) {
                  if (_sortBy == "Lowest Price") {
                    final priceA = double.tryParse(a['price'].toString()) ?? 0;
                    final priceB = double.tryParse(b['price'].toString()) ?? 0;
                    return priceA.compareTo(priceB);
                  } else if (_sortBy == "Nearest First" && _userLat != null && _userLng != null) {
                    final latA = (a['lat'] as num?)?.toDouble() ?? 0.0;
                    final lngA = (a['lng'] as num?)?.toDouble() ?? 0.0;
                    final latB = (b['lat'] as num?)?.toDouble() ?? 0.0;
                    final lngB = (b['lng'] as num?)?.toDouble() ?? 0.0;
                    
                    if (latA != 0.0 && latB != 0.0) {
                      final distA = Geolocator.distanceBetween(_userLat!, _userLng!, latA, lngA);
                      final distB = Geolocator.distanceBetween(_userLat!, _userLng!, latB, lngB);
                      return distA.compareTo(distB);
                    }
                    return 0; // fallback if lat/lng missing
                  } else {
                    // Default: Newest First
                    final tA = a['createdAt'] as Timestamp?;
                    final tB = b['createdAt'] as Timestamp?;
                    if (tA == null || tB == null) return 0;
                    return tB.compareTo(tA); // Descending (Newest first)
                  }
                });

                if (adList.isEmpty) {
                  return const Center(
                    child: Text("No ads matching your filters.", style: TextStyle(color: Colors.grey)),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75, 
                  ),
                  itemCount: adList.length,
                  itemBuilder: (context, index) {
                    final ad = adList[index];
                    final docId = ad['id'] as String;
                    
                    // Handle image fallback
                    String thumbUrl = 'https://via.placeholder.com/150';
                    if (ad['imageUrls'] != null && (ad['imageUrls'] as List).isNotEmpty) {
                      thumbUrl = ad['imageUrls'][0];
                    } else if (ad['imageUrl'] != null) {
                      thumbUrl = ad['imageUrl'];
                    }
                    
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => AdDetailsPage(adData: ad, adId: docId)
                        ));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 5))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                  image: DecorationImage(
                                    image: NetworkImage(thumbUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ad['title'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "Rs ${ad['price'] ?? ''}",
                                    style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          ad['address'] ?? 'No Location',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PostAdPage()));
        },
        backgroundColor: Colors.purpleAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}