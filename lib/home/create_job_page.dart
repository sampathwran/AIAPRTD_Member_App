import 'package:flutter/material.dart';

class CreateJobPage extends StatelessWidget { // Class නම මෙහෙම විය යුතුයි
  const CreateJobPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Job")),
      body: const Center(child: Text("Create Job Page")),
    );
  }
}