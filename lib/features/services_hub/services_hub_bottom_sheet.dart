import 'package:flutter/material.dart';
import 'package:aiaprtd_member/features/marketplace/ads_page.dart';
import 'package:aiaprtd_member/features/flight_tracking/flight_tracking_page.dart';
import 'package:aiaprtd_member/features/mobile_reload/mobile_reload_page.dart';

class ServicesHubBottomSheet extends StatelessWidget {
  const ServicesHubBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ServicesHubBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final services = [
      {
        'icon': Icons.phone_android_rounded,
        'label': 'Mobile Reload',
        'color': Colors.blue,
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MobileReloadPage()),
          );
        },
      },
      {
        'icon': Icons.shopping_cart_rounded,
        'label': 'Marketplace',
        'color': Colors.orange,
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdsPage()),
          );
        },
      },
      {
        'icon': Icons.flight_takeoff_rounded,
        'label': 'Flight Tracking',
        'color': Colors.green,
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FlightTrackingPage()),
          );
        },
      },
      {
        'icon': Icons.receipt_long_rounded,
        'label': 'Pay Fines',
        'color': Colors.red,
        'onTap': () => _showComingSoon(context, 'Pay Fines', Colors.red),
      },
      {
        'icon': Icons.local_parking_rounded,
        'label': 'Parking',
        'color': Colors.purple,
        'onTap': () => _showComingSoon(context, 'Parking', Colors.purple),
      },
      {
        'icon': Icons.account_balance_wallet_rounded,
        'label': 'Finance & Loans',
        'color': Colors.teal,
        'onTap': () => _showComingSoon(context, 'Finance & Loans', Colors.teal),
      },
      {
        'icon': Icons.storefront_rounded,
        'label': 'Welfare Shops',
        'color': Colors.brown,
        'onTap': () => _showComingSoon(context, 'Welfare Shops', Colors.brown),
      },
      {
        'icon': Icons.local_car_wash_rounded,
        'label': 'Service Stations',
        'color': Colors.indigo,
        'onTap': () =>
            _showComingSoon(context, 'Service Stations', Colors.indigo),
      },
      {
        'icon': Icons.settings_suggest_rounded,
        'label': 'Vehicle Parts',
        'color': Colors.cyan,
        'onTap': () => _showComingSoon(context, 'Vehicle Parts', Colors.cyan),
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16), // Reduced from 24
          const Text(
            'Driver Services Hub',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4), // Reduced from 8
          Text(
            'Access all your essential tools in one place',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20), // Reduced from 32
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 24,
              crossAxisSpacing: 16,
              childAspectRatio: 0.8, // Adjust height
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return _ServiceItem(
                icon: service['icon'] as IconData,
                label: service['label'] as String,
                color: service['color'] as Color,
                onTap: service['onTap'] as VoidCallback,
              );
            },
          ),
          const SizedBox(height: 16), // safe area buffer
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String label, Color color) {
    Navigator.pop(context); // Close bottom sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "$label - Coming Soon! 🚀",
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: color,
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ServiceItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.3 : 0.2),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: isDark ? color.withOpacity(0.9) : color,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
