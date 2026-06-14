import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../member_provider.dart';
import 'profile_menu_widget.dart';
import 'achievement_badge_widget.dart';
import 'status_badge_widget.dart';
import 'rank_page.dart';
import 'image_upload_page.dart';
import 'widgets/rating_widget.dart';
import 'widgets/trip_count_widget.dart';
import 'widgets/tenure_widget.dart';
import 'profile_header_info_widget.dart'; // අලුත් Widget එක import කරන්න

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MemberProvider>(context, listen: false).fetchAndStoreMemberData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.grey.shade50,
      body: Consumer<MemberProvider>(
        builder: (context, memberProvider, child) {
          if (memberProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = memberProvider.memberData;
          if (data == null) {
            return const Center(child: Text("Data not found!"));
          }

          return Stack(
            children: [
              ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildCoverAndProfile(data, memberProvider),
                  _buildStatsRow(data),
                  _buildAchievementBadge(data),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: ProfileMenuWidget(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 5,
                left: 10,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCoverAndProfile(Map<String, dynamic> data, MemberProvider provider) {
    return Column(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage("https://images.unsplash.com/photo-1557683316-973673baf926?q=80&w=2070&auto=format&fit=cover"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    final String memNo = data['membershipNo'] ?? 'N/A';
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => ImageUploadPage(membershipNo: memNo)));
                    if (!mounted) return;
                    Provider.of<MemberProvider>(context, listen: false).fetchAndStoreMemberData();
                  },
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: provider.profileImageUrl.isNotEmpty ? NetworkImage(provider.profileImageUrl) : null,
                      child: provider.profileImageUrl.isEmpty ? const Icon(Icons.person, size: 45, color: Colors.blue) : null,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileHeaderInfoWidget(
                          fullName: data['fullName'] ?? "No Name",
                          membershipNo: data['membershipNo'] ?? 'N/A',
                        ),
                        const SizedBox(height: 5),
                        StatusBadgeWidget(
                          status: data['status'] ?? 'inactive',
                          reason: data['inactive_reason'],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          RatingWidget(rating: data['rating']?.toString() ?? "0"),
          TripCountWidget(trips: data['payment_history']?.length.toString() ?? "0"),
          const TenureWidget(years: "2 Years"),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(Map<String, dynamic> data) {
    return AchievementBadgeWidget(
      rank: data['rank'] ?? "Member",
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const RankPage()));
      },
    );
  }
}