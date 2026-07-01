// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: spell_check_on_word
import 'package:cached_network_image/cached_network_image.dart';

// 💡 FIXED: පරණ MemberProvider එක අයින් කරලා අලුත් ProfileProvider එක ඇඩ් කළා.
// (ඔයාගේ මේ ෆයිල් එක තියෙන තැන අනුව '../providers/profile_provider.dart' හෝ '../../providers/profile_provider.dart' වෙන්න පුළුවන්)
import '../providers/profile_provider.dart';

class ProfileImageWidget extends StatelessWidget {
  final double radius;

  const ProfileImageWidget({
    super.key,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    // 🛡️ සිකියුරිටි චෙක්: කෙලින්ම ලොග් වෙලා ඉන්න මෙම්බර්ගේ ඩේටා අලුත් ProfileProvider එකෙන් ගන්නවා.
    final profileProvider = Provider.of<ProfileProvider>(context);

    // 💡 FIXED: අලුත් Provider එකේ තියෙන profileImageUrl getter එක කෙලින්ම පාවිච්චි කළා
    final String loggedInUserImageUrl = profileProvider.profileImageUrl;

    // ⏳ 🎯 FIXED: අලුත් ProfileProvider එකේ imageRequestStatus එකෙන් Pending ද කියලා බලනවා
    final bool isUpdatePending = profileProvider.memberData?['imageRequestStatus'] == 'pending';

    return Stack(
      alignment: Alignment.center,
      children: [
        // 1️⃣ ප්‍රධාන පින්තූරය (පරණ ෆොටෝ එක හෝ හිස් අයිකන් එක)
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

              // 💡 පින්තූරය Load වෙනකන් පෙන්වන ලස්සන Loading Indicator එක
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

              // 💡 Network Error එකක් ආවොත් වැටෙන Icon එක
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
                    size: radius * 0.8 // රවුමේ සයිස් එකට ගැලපෙන්න
                ),
              ],
            ),
          ),
      ],
    );
  }
}