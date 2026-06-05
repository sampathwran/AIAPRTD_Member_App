import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../member_provider.dart';
import 'profile_menu_widget.dart';
import 'profile_image_widget.dart';
import 'achievement_badge_widget.dart';
import 'status_badge_widget.dart';

// මචං, මේ අලුත් පේජ් දෙක දැනට හිස්ව හදලා තියෙන්නේ, පස්සේ උඹ ඒ ටික edit කරපන්
import 'rank_page.dart';
import 'image_upload_page.dart';

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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text("Profile"), centerTitle: true, elevation: 0),
      body: Consumer<MemberProvider>(
        builder: (context, memberProvider, child) {
          if (memberProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = memberProvider.memberData;
          if (data == null) return const Center(child: Text("Data not found!"));

          return ListView(
            children: [
              _buildCoverAndProfile(data),
              _buildStatsRow(data),
              _buildAchievementBadge(data),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ProfileMenuWidget(),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCoverAndProfile(Map<String, dynamic> data) {
    return Column(
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.blue.shade400,
            image: const DecorationImage(
              image: NetworkImage("https://images.unsplash.com/photo-1557683316-973673baf926?q=80&w=2070&auto=format&fit=crop"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Profile Image එක Click කළාම ImageUploadPage එකට යනවා
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ImageUploadPage()));
                  },
                  child: ProfileImageWidget(imageUrl: data['profile_url'], radius: 40),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['fullName'] ?? "No Name",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text("#${data['membershipNo'] ?? 'N/A'}",
                            style: TextStyle(color: Colors.grey.shade600)),
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
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, spreadRadius: 2)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatColumn("Rating", data['rating']?.toString() ?? "0"),
          _buildStatColumn("Trips", data['payment_history']?.length.toString() ?? "0"),
          _buildStatColumn("Tenure", "2 Years"),
        ],
      ),
    );
  }

  // Achievement Badge එක Click කළාම RankPage එකට යනවා
  Widget _buildAchievementBadge(Map<String, dynamic> data) {
    return AchievementBadgeWidget(
      rank: data['rank'] ?? "Member",
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const RankPage()));
      },
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}