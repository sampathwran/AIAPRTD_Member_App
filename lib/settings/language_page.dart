import 'package:flutter/material.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  // දැනට තෝරාගෙන ඇති භාෂාව (Backend එකෙන් එනවා නම් මෙතනට ඒක එන්න ඕනේ)
  String selectedLanguage = "English";

  final List<String> languages = ["English", "සිංහල", "தமிழ்"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Select Language", style: TextStyle(fontWeight: FontWeight.bold)),
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
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: languages.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  bool isSelected = selectedLanguage == lang;

                  return ListTile(
                    title: Text(lang, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.blue)
                        : null,
                    onTap: () {
                      setState(() {
                        selectedLanguage = lang;
                      });
                      // මෙතන තමයි භාෂාව මාරු කරන logic එක ලියන්න ඕනේ (Provider හෝ Localisation)
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Changing the language will restart the current screen to apply changes.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}