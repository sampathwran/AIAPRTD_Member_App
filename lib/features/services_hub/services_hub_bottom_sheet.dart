import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aiaprtd_member/features/marketplace/ads_page.dart';
import 'package:aiaprtd_member/features/flight_tracking/flight_tracking_page.dart';
import 'package:aiaprtd_member/features/mobile_reload/mobile_reload_page.dart';
import 'package:aiaprtd_member/features/ev_charging/ev_charging_page.dart';
import 'package:aiaprtd_member/features/services_hub/report_traffic_page.dart';
import 'package:aiaprtd_member/core/utils/icon_mapper.dart';

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
    final isDark = theme.brightness == Brightness.dark;

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
          const SizedBox(height: 16),
          const Text(
            'Driver Services Hub',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Access all your essential tools in one place',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('driver_services_hub')
                .orderBy('order')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ));
              }

              if (snapshot.hasError) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Error loading services', style: TextStyle(color: Colors.red)),
                ));
              }

              final allDocs = snapshot.data?.docs ?? [];
              // Filter active services locally to avoid Firestore composite index requirement
              final docs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['isActive'] == true;
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No services available at the moment.'),
                ));
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final label = data['label'] ?? 'Unknown';
                  final imageUrl = data['imageUrl'] as String?;
                  final iconName = data['icon'] ?? 'apps';
                  final colorHex = data['colorHex'] ?? '#2196F3';
                  final actionType = data['actionType'] ?? 'coming_soon';
                  final actionTarget = data['actionTarget'] ?? '';

                  return _ServiceItem(
                    imageUrl: imageUrl,
                    fallbackIcon: IconMapper.getIcon(iconName),
                    label: label,
                    color: IconMapper.getColor(colorHex),
                    onTap: () => _handleServiceTap(context, actionType, actionTarget, label, IconMapper.getColor(colorHex)),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _handleServiceTap(BuildContext context, String actionType, String actionTarget, String label, Color color) {
    if (actionType == 'internal_route') {
      Navigator.pop(context);
      
      Widget? targetPage;
      if (actionTarget == '/mobile_reload' || actionTarget == 'MobileReloadPage' || actionTarget == 'mobile_reload') {
        targetPage = const MobileReloadPage();
      } else if (actionTarget == '/marketplace' || actionTarget == 'AdsPage' || actionTarget == 'marketplace') {
        targetPage = const AdsPage();
      } else if (actionTarget == '/flight_tracking' || actionTarget == 'FlightTrackingPage' || actionTarget == 'flight_tracking') {
        targetPage = const FlightTrackingPage();
      } else if (actionTarget == '/ev_charging' || actionTarget == 'EvChargingPage' || actionTarget == 'ev_charging') {
        targetPage = const EvChargingPage();
      } else if (actionTarget == '/report_traffic' || actionTarget == 'ReportTrafficPage' || actionTarget == 'report_traffic') {
        targetPage = const ReportTrafficPage();
      }

      if (targetPage != null) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => targetPage!));
      } else {
        _showComingSoon(context, label, color);
      }
    } else if (actionType == 'webview') {
      Navigator.pop(context);
      // In a real implementation, navigate to a WebView page
      // Navigator.push(context, MaterialPageRoute(builder: (context) => WebViewPage(url: actionTarget, title: label)));
      _showComingSoon(context, 'Web: $label', color);
    } else {
      _showComingSoon(context, label, color);
    }
  }

  void _showComingSoon(BuildContext context, String label, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "$label - Coming Soon! 🚀",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: color,
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ServiceItem({
    this.imageUrl,
    required this.fallbackIcon,
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.3 : 0.2),
                width: 1.5,
              ),
            ),
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.network(
                      imageUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Icon(
                        fallbackIcon,
                        color: isDark ? color.withOpacity(0.9) : color,
                        size: 64,
                      ),
                    ),
                  )
                : Icon(
                    fallbackIcon,
                    color: isDark ? color.withOpacity(0.9) : color,
                    size: 64,
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
