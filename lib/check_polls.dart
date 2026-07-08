import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  print("Checking polls in Firestore...");
  final snapshot = await FirebaseFirestore.instance.collection('polls').get();
  
  if (snapshot.docs.isEmpty) {
    print("No polls found in Firestore.");
  } else {
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final expiresAt = data['expiresAt'] as Timestamp?;
      final now = DateTime.now();
      bool isFuture = expiresAt != null ? expiresAt.toDate().isAfter(now) : false;
      print("Poll: ${data['title']} | Expires: ${expiresAt?.toDate()} | Is Active: $isFuture");
    }
  }
}
