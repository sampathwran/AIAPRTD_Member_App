import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:aiaprtd_member/core/providers/booking_provider.dart'; // Import booking provider

class LocationSearchSheet extends StatefulWidget {
  final bool isPickup;
  final int dropIndex;

  const LocationSearchSheet({
    super.key,
    required this.isPickup,
    this.dropIndex = 0,
  });

  @override
  State<LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<LocationSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  void _onSearchChanged(String query, BookingProvider provider) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await provider.searchLocations(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context, listen: false);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Add Material widget to fix error
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 40, // Space from top screen edge
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          // Removed fixed height so it adapts to the padding and fills remaining space
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
        child: Column(
          children: [
            // Handle Bar (Top Dash)
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 40,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),

            // Title
            Text(
              widget.isPickup ? "Set Pickup Location" : "Set Drop Location",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) => _onSearchChanged(val, provider),
                decoration: InputDecoration(
                  hintText: "Search for a location...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged("", provider);
                    },
                  )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(),

            // Options / Results List
            Expanded(
              child: _searchController.text.isEmpty
                  ? _buildDefaultOptions(provider)
                  : _buildSearchResults(provider),
            ),
          ],
        ), // Close Column
      ), // Close Container
     ), // Close Material
    ); // Close Padding
  }

  // Default Options (When Search is empty)
  Widget _buildDefaultOptions(BookingProvider provider) {
    return ListView(
      children: [
        // 📍 Choose on Map
        ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.map, color: Colors.white, size: 20)),
          title: const Text("Choose on Map", style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text("Pin a location on the map"),
          onTap: () {
            provider.enableChooseOnMap(isPickup: widget.isPickup, dropIndex: widget.dropIndex);
            Navigator.pop(context);
          },
        ),
        const Divider(),

        // ⭐ Saved Locations
        if (provider.savedLocations.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text("Saved Places", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ...provider.savedLocations.map((loc) => ListTile(
            leading: const Icon(Icons.star_rounded, color: Colors.amber),
            title: Text(loc['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(loc['address']),
            onTap: () {
              LatLng latLng = LatLng(loc['lat'], loc['lng']);
              if (widget.isPickup) {
                provider.setPickupLocation(latLng, loc['address']);
              } else {
                provider.setDropLocation(widget.dropIndex, latLng, loc['address']);
              }
              Navigator.pop(context);
              
            },
          )),
          const Divider(),
        ],

        // 🕒 Recent Locations
        if (provider.recentLocations.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text("Recent Places", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ...provider.recentLocations.map((loc) => ListTile(
            leading: const Icon(Icons.history, color: Colors.grey),
            title: Text(loc['address']),
            onTap: () {
              LatLng latLng = LatLng(loc['lat'], loc['lng']);
              if (widget.isPickup) {
                provider.setPickupLocation(latLng, loc['address']);
              } else {
                provider.setDropLocation(widget.dropIndex, latLng, loc['address']);
              }
              Navigator.pop(context);
              
            },
          )),
        ]
      ],
    );
  }

  // Search Results from Places API
  Widget _buildSearchResults(BookingProvider provider) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return const Center(child: Text("No results found."));
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final option = _searchResults[index];
        return ListTile(
          leading: Icon(Icons.location_on, color: Theme.of(context).iconTheme.color ?? Colors.black54),
          title: Text(option['name']),
          onTap: () async {
            await provider.fetchPlaceDetailsAndSetLocation(
              option['place_id'],
              option['name'],
              isPickup: widget.isPickup,
              dropIndex: widget.dropIndex,
            );

            // Check if context is mounted to fix warning
            if (!context.mounted) return;

            Navigator.pop(context);
          },
        );
      },
    );
  }
} // End of file