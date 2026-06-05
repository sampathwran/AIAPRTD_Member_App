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
    return CircleAvatar(
      radius: radius + 5, // වටේ සුදු පාට බෝඩරේ සඳහා
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade300,
        // Image URL එකක් තියෙනවා නම් NetworkImage එකෙන් පෙන්වනවා
        backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
            ? NetworkImage(imageUrl!)
            : null,
        // Image එකක් නැත්නම් පර්සන් අයිකන් එක පෙන්වනවා
        child: (imageUrl == null || imageUrl!.isEmpty)
            ? Icon(Icons.person, size: radius, color: Colors.grey.shade600)
            : null,
      ),
    );
  }
}