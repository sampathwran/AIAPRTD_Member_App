import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../utils/app_icons_library.dart';

class MemberBenefitsPage extends StatelessWidget {
  const MemberBenefitsPage({super.key});

  IconData _getIconData(String iconName) {
    return AppIconsLibrary.getIcon(iconName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileProvider = Provider.of<ProfileProvider>(context);
    final grantedBenefits = profileProvider.grantedBenefits;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Member Benefits", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('member_benefits').orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No benefits available at the moment.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final benefitId = doc.id;
              final title = data['title'] ?? 'Benefit';
              final desc = data['description'] ?? '';
              final iconName = data['icon'] ?? 'star';
              final iconUrl = data['iconUrl'];
              final isGlobal = data['isGlobal'] == true;
              
              final bool isUnlocked = isGlobal || grantedBenefits.contains(benefitId);
              final IconData iconData = _getIconData(iconName);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isUnlocked 
                      ? (isDark ? theme.cardColor : Colors.white) 
                      : (isDark ? theme.cardColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(12),
                  border: isUnlocked
                      ? Border.all(color: isDark ? Colors.blue.shade700 : Colors.blue.shade200, width: 1.5)
                      : Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300, width: 1),
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      iconColor: isUnlocked ? Colors.blue : Colors.grey,
                      collapsedIconColor: isUnlocked ? Colors.blue.shade300 : Colors.grey,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isUnlocked 
                              ? (isDark && iconUrl != null && iconUrl.toString().isNotEmpty 
                                  ? Colors.white.withValues(alpha: 0.8) 
                                  : Colors.blue.withValues(alpha: 0.1)) 
                              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: !isUnlocked
                            ? Icon(Icons.lock_outline, color: Colors.grey, size: 24)
                            : iconUrl != null && iconUrl.toString().isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: iconUrl,
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                                    errorWidget: (context, url, error) => Icon(iconData, color: Colors.blue, size: 24),
                                  )
                                : Icon(iconData, color: Colors.blue, size: 24),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isUnlocked 
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          if (isUnlocked) 
                            const Icon(Icons.check_circle, color: Colors.green, size: 20)
                          else 
                            const Icon(Icons.lock, color: Colors.grey, size: 16),
                        ],
                      ),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 0),
                          child: Text(
                            desc,
                            style: TextStyle(
                              color: isUnlocked ? (isDark ? Colors.white70 : Colors.black87) : Colors.grey,
                              height: 1.5,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}