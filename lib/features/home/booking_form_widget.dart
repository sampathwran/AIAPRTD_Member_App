import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/booking_provider.dart';
import 'package:aiaprtd_member/features/home/route_preview_page.dart';

import 'package:aiaprtd_member/features/home/one_way_form_widget.dart';
import 'package:aiaprtd_member/features/home/round_form_widget.dart';
import 'package:aiaprtd_member/features/home/package_form_widget.dart';

class BookingFormWidget extends StatelessWidget {
  const BookingFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Adapt to available space
        children: [
          // Tabs Section
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                _buildTab(context, provider, 'One way', Icons.arrow_right_alt_rounded),
                _buildTab(context, provider, 'Round', Icons.sync_alt_rounded),
                _buildTab(context, provider, 'Package', Icons.inventory_2_outlined),
              ],
            ),
          ),

          // Selected Tab Content Section
          // Added Flexible and ScrollView to fix overflow issue
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(), // Bouncing scroll effect
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: _buildFormContent(provider.tripType),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (provider.currentPickupLatLng != null && provider.dropLatLngs.isNotEmpty && provider.dropLatLngs[0] != null) {
                    provider.calculateRoute();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RoutePreviewPage()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all required locations (Pickup and at least one Drop).")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Content Switcher (Form changes based on tab)
  Widget _buildFormContent(String tripType) {
    switch (tripType) {
      case 'One way':
        return const OneWayFormWidget();
      case 'Round':
        return const RoundFormWidget();
      case 'Package':
        return const PackageFormWidget();
      default:
        return const OneWayFormWidget();
    }
  }

  // Custom Tab Builder
  Widget _buildTab(BuildContext context, BookingProvider provider, String title, IconData icon) {
    bool isActive = provider.tripType == title;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setTripType(title),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? theme.cardTheme.color : Colors.transparent,
            borderRadius: isActive ? const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)) : null,
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? Icons.check_circle : Icons.circle_outlined,
                  color: isActive ? colorScheme.primary : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: isActive ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}