import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileWidget extends StatelessWidget {
  final User? user;
  const ProfileWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 25,
      backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
      child: user?.photoURL == null ? const Icon(Icons.person, size: 30) : null,
    );
  }
}