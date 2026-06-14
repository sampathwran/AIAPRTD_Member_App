import 'package:flutter/material.dart';

class MemberBenefitsPage extends StatelessWidget {
  const MemberBenefitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // සාම්පල් දත්ත 20ක් (Admin විසින් දෙන දත්ත මෙතනට එන්න ඕනේ)
    final List<Map<String, dynamic>> allBenefits = List.generate(20, (index) => {
      "title": "Benefit ${index + 1}",
      "desc": "Description for exclusive benefit ${index + 1}",
      "isUnlocked": index < 8, // පළමු 8 දෙනාට විතරයි Unlocked
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Member Benefits", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allBenefits.length,
        itemBuilder: (context, index) {
          final benefit = allBenefits[index];
          final bool isUnlocked = benefit['isUnlocked'];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isUnlocked ? Colors.white : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: isUnlocked
                  ? Border.all(color: Colors.blue.shade200)
                  : Border.all(color: Colors.grey.shade300),
              boxShadow: isUnlocked
                  ? [BoxShadow(color: Colors.blue.shade50, blurRadius: 10, offset: const Offset(0, 5))]
                  : [],
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isUnlocked ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isUnlocked ? Icons.star_rounded : Icons.lock_outline,
                  color: isUnlocked ? Colors.blue : Colors.grey,
                ),
              ),
              title: Text(
                benefit['title'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? Colors.black : Colors.grey,
                ),
              ),
              subtitle: Text(benefit['desc']),
              trailing: isUnlocked
                  ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                  : const Icon(Icons.lock, color: Colors.grey, size: 16),
            ),
          );
        },
      ),
    );
  }
}