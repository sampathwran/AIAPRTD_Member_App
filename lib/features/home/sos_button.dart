import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SosPage extends StatelessWidget {
  const SosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text('home.sos_alert'.tr()), backgroundColor: Colors.red),
      body: const Center(
        child: Text("SOS Page - SOS Logic should be implemented here"),
      ),
    );
  }
}


