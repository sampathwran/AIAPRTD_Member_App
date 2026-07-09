import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:aiaprtd_member/core/providers/ads_provider.dart';
import 'package:aiaprtd_member/features/marketplace/ad_details_page.dart';

class MyAdsPage extends StatelessWidget {
  const MyAdsPage({super.key});

  void _showPriceDropDialog(BuildContext context, String adId, String currentPrice) {
    final priceController = TextEditingController(text: currentPrice);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Drop Price"),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "New Price (LKR)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (priceController.text.isNotEmpty) {
                final res = await context.read<AdsProvider>().updateAdPrice(adId, priceController.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  if (res['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Price updated successfully!")));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${res['error']}")));
                  }
                }
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String adId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Ad"),
        content: const Text("Are you sure you want to delete this ad? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final res = await context.read<AdsProvider>().deleteAd(adId);
              if (context.mounted) {
                Navigator.pop(context);
                if (res['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ad deleted successfully!")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${res['error']}")));
                }
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Ads"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: context.read<AdsProvider>().getMyAdsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.toList();
          
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });
          
          if (docs.isEmpty) return const Center(child: Text("You haven't posted any ads yet."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final imageUrls = data['imageUrls'] as List<dynamic>? ?? [];
              final title = data['title'] ?? 'No Title';
              final priceStr = data['price']?.toString() ?? '0';
              String formattedPrice = priceStr;
              try {
                formattedPrice = NumberFormat.decimalPattern().format(double.parse(priceStr));
              } catch (_) {}
              final status = data['status'] ?? 'pending';
              final createdAt = data['createdAt'] as Timestamp?;
              
              Color statusColor = Colors.orange;
              if (status == 'approved') statusColor = Colors.green;
              if (status == 'rejected') statusColor = Colors.red;
              if (status == 'sold') statusColor = Colors.grey;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      imageUrls.isNotEmpty 
                        ? Image.network(imageUrls[0], width: 80, height: 80, fit: BoxFit.cover)
                        : Container(width: 80, height: 80, color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300, child: const Icon(Icons.image)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, decoration: status == 'sold' ? TextDecoration.lineThrough : null)),
                            Container(
                              margin: const EdgeInsets.only(top: 4, bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                "Rs. $formattedPrice",
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 14),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                              child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 4),
                            Text("Posted: ${createdAt != null ? DateFormat.yMd().format(createdAt.toDate()) : 'Unknown'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) async {
                          if (value == 'view') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => AdDetailsPage(adData: data, adId: docs[index].id)));
                          } else if (value == 'drop_price') {
                            _showPriceDropDialog(context, docs[index].id, priceStr);
                          } else if (value == 'mark_sold') {
                            final res = await context.read<AdsProvider>().markAdAsSold(docs[index].id);
                            if (res['success'] == true && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ad marked as sold!")));
                            }
                          } else if (value == 'delete') {
                            _showDeleteDialog(context, docs[index].id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'view', child: Text("View Ad Details")),
                          const PopupMenuItem(value: 'drop_price', child: Text("Drop Price")),
                          if (status == 'approved') const PopupMenuItem(value: 'mark_sold', child: Text("Mark as Sold")),
                          const PopupMenuItem(value: 'delete', child: Text("Delete Ad", style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}