import 'package:flutter/material.dart';

class DarkModePage extends StatefulWidget {
  const DarkModePage({super.key});

  @override
  State<DarkModePage> createState() => _DarkModePageState();
}

class _DarkModePageState extends State<DarkModePage> {
  bool isDarkMode = false; // මේක ඇත්ත ඇප් එකේදි Global state එකකින් ගන්න ඕනේ

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Display Settings", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode, color: Colors.blue),
                ),
                title: const Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(isDarkMode ? "Current: Dark Theme" : "Current: Light Theme"),
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (value) {
                    setState(() {
                      isDarkMode = value;
                    });
                    // මෙතන තමයි Theme Provider එකට call කරන්න ඕනේ
                    // උදාහරණයක්: Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Enabling dark mode will save battery and reduce eye strain in low-light environments.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}