import 'package:flutter/material.dart';

class ProfileImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const ProfileImageWidget({
    super.key,
    this.imageUrl,
    this.radius = 45.0,
  });

  @override
  Widget build(BuildContext context) {
    // URL එක වලංගු දැයි සහ http වලින් ආරම්භ වේදැයි පරීක්ෂා කිරීම
    final bool hasImage = imageUrl != null &&
        imageUrl!.isNotEmpty &&
        imageUrl!.startsWith('http');

    return CircleAvatar(
      radius: radius + 5,
      backgroundColor: Colors.blue.shade100, // බාහිර Border වර්ණය
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200, // පින්තූරය පූරණය වන විට පෙනෙන පසුබිම් වර්ණය

        // foregroundImage භාවිතා කිරීමෙන් පින්තූරය නොමැති විට child එක පෙන්වීම පහසු වේ
        foregroundImage: hasImage ? NetworkImage(imageUrl!) : null,

        // පින්තූරයක් නොමැති විට හෝ URL එක invalid විට icon එක පෙන්වීම
        child: !hasImage
            ? Icon(Icons.person, size: radius, color: Colors.grey.shade500)
            : null,
      ),
    );
  }
}