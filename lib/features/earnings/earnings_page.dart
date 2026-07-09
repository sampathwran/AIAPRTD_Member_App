import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/theme_provider.dart';
import 'package:aiaprtd_member/core/providers/earnings_provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/features/earnings/widgets/earning_summary_card.dart';
import 'package:aiaprtd_member/features/earnings/widgets/earning_trip_tile.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final earningsProvider = Provider.of<EarningsProvider>(context, listen: false);
      if (profileProvider.memberNo != 'N/A') {
        earningsProvider.fetchEarnings(profileProvider.memberNo);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "My Earnings",
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          // Added Refresh Button again
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
              if (profileProvider.memberNo != 'N/A') {
                Provider.of<EarningsProvider>(context, listen: false).fetchEarnings(profileProvider.memberNo);
              }
            },
          )
        ],
      ),
      body: Consumer<EarningsProvider>(
        builder: (context, provider, child) {
          // Filtering logic
          final trips = provider.trips.where((trip) {
            if (_selectedFilter == 'All') return true;
            if (_selectedFilter == 'Bookings') return trip.type == 'booking' && trip.status != 'cancelled';
            if (_selectedFilter == 'Pickups') return trip.type == 'road_pickup' && trip.status != 'cancelled';
            if (_selectedFilter == 'Cancelled') return trip.status == 'cancelled';
            return true;
          }).toList();

          return Column(
            children: [
              if (provider.isLoading)
                const LinearProgressIndicator(),
              Expanded(
                child: RefreshIndicator(
                  // Fixed Pull to refresh to work again
                  onRefresh: () async {
                    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
                    if (profileProvider.memberNo != 'N/A') {
                      await provider.fetchEarnings(profileProvider.memberNo);
                    }
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time Period Filters
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildTimePeriodChip("Daily", provider, isDark),
                                const SizedBox(width: 8),
                                _buildTimePeriodChip("Weekly", provider, isDark),
                                const SizedBox(width: 8),
                                _buildTimePeriodChip("Monthly", provider, isDark),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Top Summary Card
                          EarningSummaryCard(
                            totalEarnings: provider.totalEarnings,
                            bookingsEarnings: provider.totalBookingsEarnings,
                            roadPickupEarnings: provider.totalRoadPickupEarnings,
                            isDark: isDark,
                          ),

                          const SizedBox(height: 24),

                          // Filters Row
                          Text(
                            "Trip History",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip("All", isDark),
                                const SizedBox(width: 8),
                                _buildFilterChip("Bookings", isDark),
                                const SizedBox(width: 8),
                                _buildFilterChip("Pickups", isDark),
                                const SizedBox(width: 8),
                                _buildFilterChip("Cancelled", isDark),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Trips List
                          if (trips.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(32),
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No trips found",
                                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: trips.length,
                              itemBuilder: (context, index) {
                                return EarningTripTile(
                                  trip: trips[index],
                                  isDark: isDark,
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isDark) {
    final bool isSelected = _selectedFilter == label;

    final isCancelledTab = label == 'Cancelled';
    final selectedColor = isCancelledTab
        ? Colors.red.shade400
        : Theme.of(context).colorScheme.primary;

    final unselectedColor = Theme.of(context).cardTheme.color;
    const selectedTextColor = Colors.white;
    final unselectedTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? selectedTextColor : unselectedTextColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTimePeriodChip(String label, EarningsProvider provider, bool isDark) {
    final bool isSelected = provider.timePeriod == label;

    final selectedColor = isDark ? Colors.teal.shade500 : Colors.teal.shade600;
    final unselectedColor = Theme.of(context).cardTheme.color;
    const selectedTextColor = Colors.white;
    final unselectedTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;

    return GestureDetector(
      onTap: () {
        provider.setTimePeriod(label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? selectedTextColor : unselectedTextColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}