// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';

class RankPage extends StatefulWidget {
  final Map<String, dynamic> memberData; // Member data passed from previous screen

  const RankPage({super.key, required this.memberData});

  @override
  State<RankPage> createState() => _RankPageState();
}

class _RankPageState extends State<RankPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Member's current statistics
  int currentMonths = 0;
  double currentRating = 0.0;
  int currentRides = 0;

  @override
  void initState() {
    super.initState();
    _calculateCurrentStats();
  }

  // Calculate current status of member
  void _calculateCurrentStats() {
    final data = widget.memberData;

    // Tenure in months
    final joinDateStr = data['joinDate'] ?? DateTime.now().toString().split(' ')[0];
    try {
      currentMonths = DateTime.now().difference(DateTime.parse(joinDateStr)).inDays ~/ 30;
    } catch (e) {
      currentMonths = 0;
    }

    // Rating
    currentRating = (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0;

    // Trip Count (Assumed 'tripCount' in DB)
    currentRides = int.tryParse(data['tripCount']?.toString() ?? '0') ?? 0;
  }

  // Calculate progress towards 100% for each criterion
  double _calculateProgress(String type, dynamic target) {
    if (target == 0) return 1.0; // If no target, then 100% completed

    switch (type) {
      case 'tenure':
        return (currentMonths / (target as int)).clamp(0.0, 1.0);
      case 'rating':
        return (currentRating / (target as double)).clamp(0.0, 1.0);
      case 'rides':
        return (currentRides / (target as int)).clamp(0.0, 1.0);
      case 'binary':
        return 1.0; // Currently considered as 100% (e.g. Fees Paid)
      default:
        return 0.0;
    }
  }

  final List<Map<String, dynamic>> _rankDetails = [
    {
      "name": "BRONZE MEMBER",
      "level": "Level 1 (New Member)",
      "icon": Icons.workspace_premium_rounded,
      "gradient": [const Color(0xFFCD7F32), const Color(0xFFB5732E)],
      "benefits": [
        {"icon": Icons.local_taxi_rounded, "title": "Standard Dispatch", "desc": "Equal Access", "details": "Fair and equal distribution of hires to all drivers through our system without any discrimination."},
        {"icon": Icons.health_and_safety_rounded, "title": "24/7 SOS Safety", "desc": "App Support", "details": "Access to our dedicated 24/7 emergency response team in case of an accident or safety concern."},
        {"icon": Icons.balance_rounded, "title": "Fair Hearing", "desc": "Unbiased Review", "details": "Guarantees your right to a fair and unbiased investigation by listening to your side of the story in the event of a passenger complaint."},
      ],
      "criteria": [
        {"icon": Icons.calendar_month_rounded, "title": "Tenure", "desc": "0-3 Months", "details": "Your active service period on the platform must be between 0 and 3 months.", "type": "tenure", "target": 0},
        {"icon": Icons.star_half_rounded, "title": "Rating", "desc": "Base Level", "details": "As a new member, maintaining the base star rating is sufficient.", "type": "rating", "target": 0},
        {"icon": Icons.payments_rounded, "title": "App Fees", "desc": "Up to Date", "details": "All platform fees must be fully paid with no outstanding balances.", "type": "binary", "target": 1},
      ]
    },
    {
      "name": "SILVER MEMBER",
      "level": "Level 2 (Active Cruiser)",
      "icon": Icons.stars_rounded,
      "gradient": [const Color(0xFFC0C0C0), const Color(0xFFA9A9A9)],
      "benefits": [
        {"icon": Icons.account_balance_wallet_rounded, "title": "Instant Payouts", "desc": "Fast Withdrawals", "details": "Ability to instantly withdraw your daily earnings to your bank account without any delays."},
        {"icon": Icons.verified_user_rounded, "title": "Verified Riders", "desc": "Enhanced Safety", "details": "For your safety, you will only be allocated rides from passengers with verified NICs or phone numbers."},
        {"icon": Icons.gavel_rounded, "title": "Priority Support", "desc": "Fast Resolution", "details": "Skip the regular queue and get priority assistance and faster resolutions for your issues."},
      ],
      "criteria": [
        {"icon": Icons.calendar_month_rounded, "title": "Tenure", "desc": "3+ Months", "details": "Must have actively served on the platform for a minimum of 3 months.", "type": "tenure", "target": 3},
        {"icon": Icons.star_rounded, "title": "Rating", "desc": "4.0 or Above", "details": "Must maintain a minimum customer star rating of 4.0 or above.", "type": "rating", "target": 4.0},
        {"icon": Icons.route_rounded, "title": "Total Rides", "desc": "50+ Rides", "details": "Must have successfully completed more than 50 total trips.", "type": "rides", "target": 50},
      ]
    },
    {
      "name": "GOLD MEMBER",
      "level": "Level 3 (Pro Navigator)",
      "icon": Icons.workspace_premium,
      "gradient": [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      "benefits": [
        {"icon": Icons.explore_rounded, "title": "Premium Hires", "desc": "Long Trips", "details": "Priority access to long-distance and high-value trips to maximize your daily income."},
        {"icon": Icons.policy_rounded, "title": "Legal Guidance", "desc": "Basic Aid", "details": "Basic legal guidance and support provided by the company in the event of traffic accidents or police matters."},
        {"icon": Icons.volunteer_activism_rounded, "title": "Welfare Fund", "desc": "Emergency Aid", "details": "Access to financial or medical assistance from the company's Driver Welfare Fund during emergencies."},
      ],
      "criteria": [
        {"icon": Icons.calendar_month_rounded, "title": "Tenure", "desc": "6+ Months", "details": "Must have actively served on the platform for a minimum of 6 months.", "type": "tenure", "target": 6},
        {"icon": Icons.star_rounded, "title": "Rating", "desc": "4.5 or Above", "details": "Must maintain a minimum customer star rating of 4.5 or above.", "type": "rating", "target": 4.5},
        {"icon": Icons.route_rounded, "title": "Total Rides", "desc": "200+ Rides", "details": "Must have successfully completed more than 200 total trips.", "type": "rides", "target": 200},
      ]
    },
    {
      "name": "PLATINUM MEMBER",
      "level": "Level 4 (Elite Captain)",
      "icon": Icons.diamond_outlined,
      "gradient": [const Color(0xFFE5E4E2), const Color(0xFFB0C4DE)],
      "benefits": [
        {"icon": Icons.business_center_rounded, "title": "Corporate Rides", "desc": "VIP Passengers", "details": "Exclusive access to highly profitable corporate and VIP passenger transportation services."},
        {"icon": Icons.request_quote_rounded, "title": "Bank Referrals", "desc": "Lease Letters", "details": "Official recommendation letters from the company verifying your income for bank loans or vehicle leasing."},
        {"icon": Icons.medical_services_rounded, "title": "Accident Aid", "desc": "Medical Support", "details": "Special company assistance for hospital bills or insurance claims in the event of an on-duty accident."},
      ],
      "criteria": [
        {"icon": Icons.calendar_month_rounded, "title": "Tenure", "desc": "12+ Months", "details": "Must have actively served on the platform for a minimum of 12 months.", "type": "tenure", "target": 12},
        {"icon": Icons.star_rounded, "title": "Rating", "desc": "4.7 or Above", "details": "Must maintain an excellent customer star rating of 4.7 or above.", "type": "rating", "target": 4.7},
        {"icon": Icons.cancel_presentation_rounded, "title": "Cancellations", "desc": "Below 5%", "details": "Your trip cancellation rate must remain strictly below 5%.", "type": "binary", "target": 1},
      ]
    },
    {
      "name": "DIAMOND MEMBER",
      "level": "Level 5 (Ultimate Legend)",
      "icon": Icons.diamond_rounded,
      "gradient": [const Color(0xFF00FFFF), const Color(0xFF1E90FF)],
      "benefits": [
        {"icon": Icons.flash_on_rounded, "title": "Top Dispatch", "desc": "Highest Priority", "details": "Enjoy the highest dispatch priority in your region, giving you the 'First Pick' on any incoming trip."},
        {"icon": Icons.diversity_3_rounded, "title": "Admin Access", "desc": "Direct Voice", "details": "Direct communication with the administration to represent driver opinions during company policy."},
        {"icon": Icons.family_restroom_rounded, "title": "Family Welfare", "desc": "Annual Grants", "details": "Annual company grants or scholarships supporting your family's health and children's education."},
      ],
      "criteria": [
        {"icon": Icons.calendar_month_rounded, "title": "Tenure", "desc": "24+ Months", "details": "Must have actively served on the platform for a minimum of 24 months.", "type": "tenure", "target": 24},
        {"icon": Icons.star_rounded, "title": "Rating", "desc": "4.8 or Above", "details": "Must maintain an outstanding customer star rating of 4.8 or above.", "type": "rating", "target": 4.8},
        {"icon": Icons.thumb_up_alt_rounded, "title": "Discipline", "desc": "Zero Complaints", "details": "Must maintain the highest level of professionalism and discipline with zero passenger complaints.", "type": "binary", "target": 1},
      ]
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showDetailsModal(BuildContext context, String title, String subtitle, String details, IconData icon, Color color) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 40),
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 16),
              Text(details, style: const TextStyle(fontSize: 15, color: Color(0xFF475569), height: 1.6, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Got it!", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Rank System Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swipe_left_rounded, size: 16, color: Colors.grey),
              SizedBox(width: 6),
              Text("Swipe Left or Right to browse all 5 Tiers", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
              SizedBox(width: 6),
              Icon(Icons.swipe_right_rounded, size: 16, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _rankDetails.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final rank = _rankDetails[index];
                final List<Color> gradColors = rank['gradient'];

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: gradColors[0].withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                        ),
                        child: Column(
                          children: [
                            Icon(rank['icon'], size: 72, color: Colors.white),
                            const SizedBox(height: 12),
                            Text(rank['name'], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                            const SizedBox(height: 4),
                            Text(rank['level'], style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildSection(
                          "Rank Benefits (${rank['name'].split(' ')[0]})",
                          (rank['benefits'] as List).map((b) => _buildTile(
                              b['icon'], b['title'], b['desc'], gradColors[0],
                                  () => _showDetailsModal(context, b['title'], b['desc'], b['details'], b['icon'], gradColors[0])
                          )).toList()
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                          "System Auto-Upgrade Criteria",
                          (rank['criteria'] as List).map((c) {
                            // Calculate progress for each criteria
                            double progress = _calculateProgress(c['type'], c['target']);
                            return _buildCriteriaTile(
                                c['icon'], c['title'], c['desc'], gradColors[0], progress,
                                    () => _showDetailsModal(context, c['title'], c['desc'], c['details'], c['icon'], gradColors[0])
                            );
                          }).toList()
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_rankDetails.length, (index) {
                final List<Color> grad = _rankDetails[index]['gradient'];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? grad[0] : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF64748B), letterSpacing: 1.1)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  // Normal tile for Benefits (Without progress bar)
  Widget _buildTile(IconData icon, String title, String subtitle, Color mainColor, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1))),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: mainColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: mainColor, size: 18),
            ),
            title: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(subtitle, style: TextStyle(fontSize: 11, color: mainColor, fontWeight: FontWeight.w700), maxLines: 1),
          ),
        ),
      ),
    );
  }

  // New Tile (To show progress bar for criteria)
  Widget _buildCriteriaTile(IconData icon, String title, String subtitle, Color mainColor, double progress, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1))),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: mainColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: mainColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        // Show 'Completed' if 100%, else percentage
                        Text(
                            progress >= 1.0 ? "Completed" : "${(progress * 100).toInt()}%",
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: progress >= 1.0 ? Colors.green : mainColor)
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? Colors.green : mainColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}