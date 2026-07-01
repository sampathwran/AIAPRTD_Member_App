import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';

import 'one_way_form_widget.dart';
import 'round_form_widget.dart';
import 'package_form_widget.dart';

class BookingFormWidget extends StatelessWidget {
  const BookingFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 💡 තියෙන ඉඩට විතරක් හැඩ ගැහෙන්න
        children: [
          // 💡 Tabs Section
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
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

          // 💡 Selected Tab Content Section
          // මෙන්න මෙතන තමයි අවුල තිබ්බේ. දැන් Flexible සහ ScrollView එකක් දැම්මා!
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(), // 💡 ලස්සනට Bounce වෙලා Scroll වෙන්න
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: _buildFormContent(provider.tripType),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 💡 Content Switcher (Tab එක අනුව පෙන්වන Form එක වෙනස් වෙනවා)
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

  // 💡 Custom Tab Builder
  Widget _buildTab(BuildContext context, BookingProvider provider, String title, IconData icon) {
    bool isActive = provider.tripType == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setTripType(title),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: isActive ? const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)) : null,
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? Icons.check_circle : Icons.circle_outlined,
                  color: isActive ? Colors.black : Colors.grey.shade400,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: isActive ? Colors.black : Colors.grey.shade600,
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