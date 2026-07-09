// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: spell_check_on_word
import 'package:cached_network_image/cached_network_image.dart';

// FIXED: Removed old MemberProvider and added new ProfileProvider.
// (Path depends on your file location)
import 'package:aiaprtd_member/core/providers/profile_provider.dart';

class ProfileImageWidget extends StatelessWidget {
  final double radius;

  const ProfileImageWidget({
    super.key,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    // Security Check: Get logged-in member data directly from ProfileProvider.
    final profileProvider = Provider.of<ProfileProvider>(context);

    // FIXED: Directly use profileImageUrl getter from the new Provider
    final String loggedInUserImageUrl = profileProvider.profileImageUrl;

    // FIXED: Check if imageRequestStatus is Pending in the new ProfileProvider
    final bool isUpdatePending = profileProvider.memberData?['imageRequestStatus'] == 'pending';

    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Main image (old photo or empty icon)
        CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey.shade200,
          child: loggedInUserImageUrl.isNotEmpty
              ? ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: CachedNetworkImage(
              imageUrl: loggedInUserImageUrl,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,

              // Loading indicator shown while image loads
              placeholder: (context, url) => Center(
                child: SizedBox(
                  width: radius * 0.7,
                  height: radius * 0.7,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                  ),
                ),
              ),

              // Icon shown on Network Error
              errorWidget: (context, url, error) => Icon(
                  Icons.person_rounded,
                  size: radius * 1.2,
                  color: Colors.grey.shade400
              ),
            ),
          )
              : Icon(Icons.person_rounded, size: radius * 1.2, color: Colors.grey.shade400),
        ),

        // 2️⃣ ⏳ 🎯 Pending Indicator Overlay
        if (isUpdatePending)
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.55),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                    Icons.hourglass_top_rounded,
                    color: Colors.orangeAccent,
                    size: radius * 0.8 // Match circle size
                ),
              ],
            ),
          ),
      ],
    );
  }
}