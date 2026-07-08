import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/ads_provider.dart';
import 'ad_chat_page.dart';

class AdDetailsPage extends StatefulWidget {
  final Map<String, dynamic> adData;
  final String adId;

  const AdDetailsPage({super.key, required this.adData, required this.adId});

  @override
  State<AdDetailsPage> createState() => _AdDetailsPageState();
}

class _AdDetailsPageState extends State<AdDetailsPage> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  bool get isOwner => currentUserId == widget.adData['ownerId'];

  @override
  void initState() {
    super.initState();
    // Increment views only if it's not the owner viewing their own ad
    if (!isOwner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AdsProvider>().incrementAdViews(widget.adId);
      });
    }
  }

  void _showBidDialog(BuildContext context) {
    final bidController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Place Your Bid"),
        content: TextField(
          controller: bidController,
          keyboardType: TextInputType.number, 
          decoration: const InputDecoration(hintText: "Enter your bid amount")
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (bidController.text.isNotEmpty) {
                // Fetch user data for name
                final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
                final userName = userDoc.data()?['name'] ?? 'Unknown User';

                await FirebaseFirestore.instance.collection('marketplace_ads').doc(widget.adId).collection('bids').add({
                  'amount': bidController.text,
                  'bidderId': currentUserId,
                  'bidderName': userName,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bid placed successfully!")));
                }
              }
            }, 
            child: const Text("Submit")
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String scheme, String path) async {
    final Uri url = Uri(scheme: scheme, path: path);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.adData;
    final title = ad['title'] ?? 'No Title';
    final priceStr = ad['price']?.toString() ?? '0';
    String formattedPrice = priceStr;
    try {
      formattedPrice = NumberFormat.decimalPattern().format(double.parse(priceStr));
    } catch (_) {}
    final description = ad['description'] ?? 'No Description';
    final category = ad['category'] ?? 'Category';
    final imageUrl = ad['imageUrl'] ?? 'https://via.placeholder.com/150';
    final lat = ad['lat'] != null ? (ad['lat'] as num).toDouble() : 0.0;
    final lng = ad['lng'] != null ? (ad['lng'] as num).toDouble() : 0.0;
    final address = ad['address'] ?? 'Location not available';
    final ownerId = ad['ownerId'] ?? '';
    final allowBidding = ad['allowBidding'] == true;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            Builder(
              builder: (context) {
                List<String> images = [];
                if (ad['imageUrls'] != null && ad['imageUrls'] is List) {
                  images = List<String>.from(ad['imageUrls']);
                } else if (ad['imageUrl'] != null) {
                  images = [ad['imageUrl']];
                } else {
                  images = ['https://via.placeholder.com/150'];
                }

                return SizedBox(
                  height: 250,
                  child: PageView.builder(
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: DecorationImage(
                                image: NetworkImage(images[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          if (images.length > 1)
                            Positioned(
                              bottom: 10,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(images.length, (dotIndex) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: dotIndex == index ? 10 : 6,
                                    height: dotIndex == index ? 10 : 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: dotIndex == index ? Colors.blueAccent : Colors.white70,
                                      border: Border.all(color: Colors.black12, width: 1),
                                    ),
                                  );
                                }),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                );
              }
            ),
            const SizedBox(height: 20),

            // Title & Category
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
                  child: Text(category, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    "Rs. $formattedPrice",
                    style: const TextStyle(fontSize: 22, color: Colors.green, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            if (isOwner) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1), 
                  borderRadius: BorderRadius.circular(15), 
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3))
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.visibility, color: Colors.blue, size: 30),
                        const SizedBox(height: 5),
                        Text("${ad['views'] ?? 0} Views", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                    if (allowBidding) ...[
                      Container(width: 1, height: 40, color: Colors.blue.withValues(alpha: 0.3)),
                      Column(
                        children: [
                          const Icon(Icons.gavel, color: Colors.blue, size: 30),
                          const SizedBox(height: 5),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('marketplace_ads').doc(widget.adId).collection('bids').snapshots(),
                            builder: (context, snapshot) {
                              final bidCount = snapshot.data?.docs.length ?? 0;
                              return Text("$bidCount Bids", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue));
                            }
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 25),
            ],

            // Description
            const Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 5),
            Text(description, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87, height: 1.4)),
            const SizedBox(height: 25),

            // Contact Buttons
            if (!isOwner) ...[
              const Text("Contact Owner", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildContactBtn(Icons.chat, "Chat", Colors.blue, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AdChatPage(adId: widget.adId, ownerId: ownerId, adTitle: title)));
                  }),
                  _buildContactBtn(Icons.phone, "Call", Colors.green, () {
                    // Fetch owner phone from 'users' collection (assuming ownerId maps to a user document)
                    FirebaseFirestore.instance.collection('users').doc(ownerId).get().then((doc) {
                      if (doc.exists && doc.data()?['mobile'] != null) {
                        _launchUrl('tel', doc.data()?['mobile']);
                      }
                    });
                  }),
                  _buildContactBtn(Icons.message, "SMS", Colors.orange, () {
                    FirebaseFirestore.instance.collection('users').doc(ownerId).get().then((doc) {
                      if (doc.exists && doc.data()?['mobile'] != null) {
                        _launchUrl('sms', doc.data()?['mobile']);
                      }
                    });
                  }),
                  // WhatsApp (Uses url_launcher to wa.me)
                  _buildContactBtn(Icons.wechat, "WhatsApp", Colors.teal, () {
                     FirebaseFirestore.instance.collection('users').doc(ownerId).get().then((doc) {
                      if (doc.exists && doc.data()?['whatsapp'] != null) {
                        String phone = doc.data()?['whatsapp'].toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                        if (phone.startsWith('0')) phone = '94' + phone.substring(1);
                        launchUrl(Uri.parse("https://wa.me/$phone?text=Hi, I am interested in your ad: $title"));
                      }
                    });
                  }),
                ],
              ),
              const SizedBox(height: 25),
            ],

            // Bidding Section
            if (allowBidding) ...[
              if (isOwner) ...[
                _buildSectionTitle("Live Bidding"),
                Container(
                  decoration: BoxDecoration(color: isDarkMode ? Colors.grey.shade800 : Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200)),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('marketplace_ads').doc(widget.adId).collection('bids').orderBy('createdAt', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No bids yet.", style: TextStyle(color: Colors.grey))));

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var bid = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                          return ListTile(
                            leading: CircleAvatar(backgroundColor: Colors.orange.shade100, child: const Icon(Icons.person, color: Colors.orange)),
                            title: Text(bid['bidderName'] ?? 'Member', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("LKR ${bid['amount']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          );
                        },
                      );
                    },
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _showBidDialog(context),
                    icon: const Icon(Icons.gavel),
                    label: const Text("Place a Bid", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  ),
                ),
              ],
              const SizedBox(height: 25),
            ],

            // Map Location
            if (lat != 0.0 && lng != 0.0) ...[
              _buildSectionTitle("Location: $address"),
              Container(
                height: 200,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: LatLng(lat, lng), zoom: 15),
                    zoomGesturesEnabled: false,
                    scrollGesturesEnabled: false,
                    markers: {
                      Marker(markerId: const MarkerId('adLocation'), position: LatLng(lat, lng)),
                    },
                  ),
                ),
              ),
              const SizedBox(height: 25),
            ],

            // Warning Message
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: isDarkMode ? Colors.red.withOpacity(0.1) : Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: isDarkMode ? Colors.red.withOpacity(0.3) : Colors.red.shade200)),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "WARNING: We are not responsible for the ads. We do not recommend paying advances or any payments upfront.",
                      style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildContactBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(radius: 25, backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 28)),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
