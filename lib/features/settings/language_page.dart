import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  // Currently selected language (If coming from Backend, it should be set here)
  String selectedLanguage = "English";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.locale.languageCode == 'si') {
      selectedLanguage = "සිංහල";
    } else if (context.locale.languageCode == 'ta') {
      selectedLanguage = "தமிழ்";
    } else {
      selectedLanguage = "English";
    }
  }

  final List<String> languages = ["English", "සිංහල", "தமிழ்"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Select Language",
            style: TextStyle(fontWeight: FontWeight.bold)),
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
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: languages.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  bool isEnglish = lang == "English";
                  bool isSelected = selectedLanguage == lang;

                  return ListTile(
                    title: Row(
                      children: [
                        Text(lang,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: Colors.black87,
                            )),
                      ],
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.blue)
                        : null,
                    onTap: () {
                            setState(() {
                              selectedLanguage = lang;
                            });
                            
                            if (lang == "English") {
                              context.setLocale(const Locale('en', 'US'));
                            } else if (lang == "සිංහල") {
                              context.setLocale(const Locale('si', 'LK'));
                            } else if (lang == "தமிழ்") {
                              context.setLocale(const Locale('ta', 'LK'));
                            }
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
