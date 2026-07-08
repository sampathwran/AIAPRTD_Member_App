import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../providers/ads_provider.dart';
import 'post_ad_page.dart';
import 'ad_details_page.dart';
import 'my_ads_page.dart';
import 'sponsor_ad_widget.dart';

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
  List<dynamic> _currentSubcategories = [];

  String _sortBy = "Newest First";
  double? _userLat;
  double? _userLng;

  List<Map<String, dynamic>> _sponsorAds = [];
  StreamSubscription? _sponsorSub;

  @override
  void initState() {
    super.initState();
    // Fetch Sponsor Ads
    final provider = Provider.of<AdsProvider>(context, listen: false);
    _sponsorSub = provider.getSponsorAdsStream().listen((snapshot) {
      if (mounted) {
        setState(() {
          _sponsorAds = snapshot.docs.map((d) {
            var data = d.data() as Map<String, dynamic>;
            data['id'] = d.id;
            return data;
          }).toList();
        });
      }
    });
  }

  @override
  void dispose() {
    _sponsorSub?.cancel();
    super.dispose();
  }

  void _showFilterSheet() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    String tempLocation = _locationQuery;
    double tempMin = _minPrice;
    double tempMax = _maxPrice;
    String tempSortBy = _sortBy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
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
                          final provider = Provider.of<AdsProvider>(context, listen: false);
                          final res = await provider.getCurrentLocation();
                          if (res['success'] == true && mounted) {
                            setState(() {
                              _userLat = res['lat'];
                              _userLng = res['lng'];
                            });
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not get location. ${res['error']}")));
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
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAdsPage()));
            },
            tooltip: "My Ads",
          )
        ],
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

          // 2. Categories (Horizontal Scroll)
          SizedBox(
            height: 120,
            child: StreamBuilder<QuerySnapshot>(
              stream: context.read<AdsProvider>().getCategoriesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                List<Map<String, dynamic>> catList = [];
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  catList = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
                  catList.sort((a, b) => (a['order'] ?? 999).compareTo(b['order'] ?? 999));
                }

                if (catList.isEmpty) {
                  return const Center(child: Text("No categories found", style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: catList.length,
                  itemBuilder: (context, index) {
                    final catData = catList[index];
                    final catName = catData['name'] ?? 'Unknown';
                    final catImage = catData['imageUrl'] ?? 'https://via.placeholder.com/100';
                    final subCats = catData['subcategories'] as List<dynamic>? ?? [];
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
                      child: Padding(
                        padding: const EdgeInsets.only(right: 15),
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
                                backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                              ),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              width: 70,
                              child: Text(
                                catName,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.purpleAccent : theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            )
                          ],
                        ),
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
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _currentSubcategories.length,
                itemBuilder: (context, index) {
                  final sub = _currentSubcategories[index];
                  String name = '';
                  String iconUrl = '';
                  
                  if (sub is String) {
                    name = sub;
                  } else if (sub is Map) {
                    name = sub['name'] ?? '';
                    iconUrl = sub['iconUrl'] ?? '';
                  }

                  final isSelected = _selectedSubCategory == name;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      avatar: iconUrl.isNotEmpty ? Image.network(iconUrl, width: 24, height: 24) : null,
                      label: Text(name),
                      selected: isSelected,
                      selectedColor: Colors.purpleAccent.withValues(alpha: 0.2),
                      checkmarkColor: Colors.purple,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.purpleAccent : (isDarkMode ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedSubCategory = selected ? name : null;
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
                
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    data['id'] = doc.id;
                    
                    // Filter out ads that were sold > 12 hours ago
                    if (data['status'] == 'sold' && data['soldAt'] != null) {
                      final soldAt = (data['soldAt'] as Timestamp).toDate();
                      if (DateTime.now().difference(soldAt).inHours > 12) {
                        continue; // Skip this ad
                      }
                    }
                    
                    adList.add(data);
                  }

                  // Sort locally since we removed orderBy from Firestore to avoid composite index error
                  adList.sort((a, b) {
                    final aTime = a['createdAt'] as Timestamp?;
                    final bTime = b['createdAt'] as Timestamp?;
                    if (aTime == null && bTime == null) return 0;
                    if (aTime == null) return 1;
                    if (bTime == null) return -1;
                    return bTime.compareTo(aTime);
                  });
                }

                // Apply Local Filters
                adList = adList.where((data) {
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final address = (data['address'] ?? '').toString().toLowerCase();
                  final priceStr = data['price']?.toString() ?? '0';
                  String formattedPrice = priceStr;
                  try {
                    formattedPrice = NumberFormat.decimalPattern().format(double.parse(priceStr));
                  } catch (_) {}
                  final price = double.tryParse(priceStr) ?? 0;
                  final category = data['category'] ?? '';
                  final subcategory = data['subcategory'] ?? '';

                  // Subcategory Match
                  if (_selectedSubCategory != null && subcategory != _selectedSubCategory) return false;
                  // Search Query
                  if (_searchQuery.isNotEmpty && !title.contains(_searchQuery)) return false;
                  // Location Query
                  if (_locationQuery.isNotEmpty && !address.contains(_locationQuery)) return false;
                  // Price Range
                  if (price < _minPrice || price > _maxPrice) return false;
                    
                  data['formattedPrice'] = formattedPrice;

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
                    child: Text("No ads matching your criteria.", style: TextStyle(color: Colors.grey)),
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
                  itemCount: adList.length + (adList.length ~/ 4), // Add space for Sponsor Ads (1 every 4)
                  itemBuilder: (context, index) {
                    // Determine if this index should be a sponsor ad
                    if ((index + 1) % 5 == 0 && _sponsorAds.isNotEmpty) {
                      // It's a sponsor ad! We cycle through the available sponsor ads.
                      int sponsorIndex = ((index + 1) ~/ 5 - 1) % _sponsorAds.length;
                      return SponsorAdWidget(sponsorAd: _sponsorAds[sponsorIndex]);
                    }

                    // Otherwise, calculate the actual ad index
                    int adIndex = index - (index ~/ 5);
                    if (adIndex >= adList.length) return const SizedBox.shrink();

                    final ad = adList[adIndex];
                    final docId = ad['id'] as String;
                    final isSold = ad['status'] == 'sold';
                    
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
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                      image: DecorationImage(
                                        image: NetworkImage(thumbUrl),
                                        fit: BoxFit.cover,
                                        colorFilter: isSold ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) : null,
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
                                        style: TextStyle(fontWeight: FontWeight.bold, decoration: isSold ? TextDecoration.lineThrough : null),
                                      ),
                                      const SizedBox(height: 5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          "Rs. ${ad['formattedPrice'] ?? ad['price']}",
                                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
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
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.visibility, size: 12, color: Colors.blueAccent),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${ad['views'] ?? 0}",
                                                style: const TextStyle(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (isSold)
                              Container(
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(15)),
                                child: const Center(
                                  child: Text("SOLD", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
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