import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileWidget extends StatelessWidget {
  final User? user;
  const ProfileWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 25,
      backgroundImage:
          user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
      child: user?.photoURL == null
          ? ClipOval(
              child: Opacity(
                opacity: 0.4,
                child: Image.asset(
                  'assets/images/profile_sample_image.png',
                  fit: BoxFit.cover,
                  width: 50,
                  height: 50,
                ),
              ),
            )
          : null,
    );
  }
}
