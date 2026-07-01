import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/booking_provider.dart'; // ඔයාගේ path එක දාගන්න
import 'route_preview_page.dart'; // 💡 Auto Next Page යන්න මේකත් ඕනේ

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

  // 💡 Location තේරුවට පස්සේ දෙකම තියෙනවද බලලා Next page යවන function එක
  void _checkAndNavigate(BuildContext context, BookingProvider provider) {
    if (provider.currentPickupLatLng != null && provider.dropLatLngs.isNotEmpty && provider.dropLatLngs[0] != null) {
      provider.calculateRoute(); // දුර සහ පාර (Route) ගණනය කරනවා
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RoutePreviewPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context, listen: false);

    // 💡 මෙතන Material එකක් දැම්මා Error එක නැති වෙන්න
    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // 💡 Handle Bar (Top Dash)
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 40,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),

            // 💡 Title
            Text(
              widget.isPickup ? "Set Pickup Location" : "Set Drop Location",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 💡 Search Bar
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
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(),

            // 💡 Options / Results List
            Expanded(
              child: _searchController.text.isEmpty
                  ? _buildDefaultOptions(provider)
                  : _buildSearchResults(provider),
            ),
          ],
        ), // 👈 💡 ඔන්න Column එක වැහුවා
      ), // 👈 💡 ඔන්න Container එක වැහුවා
    ); // 👈 💡 ඔන්න Material එක වැහුවා
  }

  // 💡 Default Options (When Search is empty)
  Widget _buildDefaultOptions(BookingProvider provider) {
    return ListView(
      children: [
        // 📍 Choose on Map
        ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.map, color: Colors.white, size: 20)),
          title: const Text("Choose on Map", style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text("Pin a location on the map"),
          onTap: () {
            Navigator.pop(context);
            // මෙතනින් map එකේ pin කරන තැනට යන්න පුළුවන්
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
              _checkAndNavigate(context, provider); // 💡 Auto Navigate
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
              _checkAndNavigate(context, provider); // 💡 Auto Navigate
            },
          )),
        ]
      ],
    );
  }

  // 💡 Search Results from Places API
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
          leading: const Icon(Icons.location_on, color: Colors.black54),
          title: Text(option['name']),
          onTap: () async {
            await provider.fetchPlaceDetailsAndSetLocation(
              option['place_id'],
              option['name'],
              isPickup: widget.isPickup,
              dropIndex: widget.dropIndex,
            );

            // 💡 මේ පේලිය දැම්මම අර Warning එක සම්පූර්ණයෙන්ම නැතිවෙලා යනවා
            if (!context.mounted) return;

            Navigator.pop(context);
            _checkAndNavigate(context, provider); // 💡 Auto Navigate
          },
        );
      },
    );
  }
} // 👈 💡 ඔන්න ෆයිල් එක ඉවර වෙන තැන අන්තිම Bracket එක මම දැම්මා