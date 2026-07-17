// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aiaprtd_member/core/providers/profile_provider.dart';

import 'package:aiaprtd_member/features/profile/profile_menu_widget.dart';
import 'package:aiaprtd_member/features/profile/achievement_badge_widget.dart';
import 'package:aiaprtd_member/features/profile/member_status/status_badge_widget.dart';
import 'package:aiaprtd_member/features/profile/rank_page.dart';
import 'package:aiaprtd_member/features/profile/image_upload_page.dart';
import 'package:aiaprtd_member/features/profile/widgets/rating_widget.dart';
import 'package:aiaprtd_member/features/profile/widgets/trip_count_widget.dart';
import 'package:aiaprtd_member/features/profile/widgets/tenure_widget.dart';

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
      if (mounted) {
        Provider.of<ProfileProvider>(context, listen: false).fetchAndStoreMemberData();
      }
    });
  }

  // Logic to calculate 5-level Rank based on criteria
  String determineRank(Map<String, dynamic> data) {
    final String joinDateStr = data['joinDate'] ?? DateTime.now().toString().split(' ')[0];
    final double rating = (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0;
    final int trips = int.tryParse(data['tripCount']?.toString() ?? '0') ?? 0;

    int monthsJoined = 0;
    try {
      DateTime joinDate = DateTime.parse(joinDateStr);
      DateTime now = DateTime.now();
      monthsJoined = now.difference(joinDate).inDays ~/ 30;
    } catch (e) {
      monthsJoined = 0;
    }

    if (monthsJoined >= 24 && rating >= 4.8) return "Diamond";
    if (monthsJoined >= 12 && rating >= 4.7) return "Platinum";
    if (monthsJoined >= 6 && rating >= 4.5 && trips >= 200) return "Gold";
    if (monthsJoined >= 3 && rating >= 4.0 && trips >= 50) return "Silver";

    return "Bronze"; // Default Rank
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = profileProvider.memberData;
          if (data == null) {
            return const Center(child: Text("Data not found!"));
          }

          return Stack(
            children: [
              ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildCoverAndProfile(context, data, profileProvider),
                  _buildStatsRow(data),
                  _buildAchievementBadge(context, data),
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

  Widget _buildCoverAndProfile(BuildContext context, Map<String, dynamic> data, ProfileProvider provider) {
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
          child: Column(
            children: [
              GestureDetector(
                onTap: () async {
                  final String memNo = data['membershipNo'] ?? 'N/A';
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => ImageUploadPage(membershipNo: memNo)));

                  if (!context.mounted) return;

                  Provider.of<ProfileProvider>(context, listen: false).fetchAndStoreMemberData();
                },
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: provider.profileImageUrl.isNotEmpty ? NetworkImage(provider.profileImageUrl) : null,
                    child: provider.profileImageUrl.isEmpty ? const Icon(Icons.person, size: 45, color: Colors.blue) : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                data['fullName'] ?? "No Name",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                "Membership ID: ${data['membershipNo'] ?? 'N/A'}",
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              StatusBadgeWidget(
                memberData: data,
                isProfileView: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> data) {
    return Builder(
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RatingWidget(memberData: data),
              TripCountWidget(memberData: data),
              TenureWidget(memberData: data),
            ],
          ),
        );
      }
    );
  }

  Widget _buildAchievementBadge(BuildContext context, Map<String, dynamic> data) {
    final String currentRank = determineRank(data);

    // Added 'Widget' suffix
    return AchievementBadgeWidget(
      rank: currentRank,
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => RankPage(memberData: data)));
      },
    );
  }
}