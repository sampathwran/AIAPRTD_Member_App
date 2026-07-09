import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';

class VotesPage extends StatefulWidget {
  const VotesPage({super.key});

  @override
  State<VotesPage> createState() => _VotesPageState();
}

class _VotesPageState extends State<VotesPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh the UI every minute to keep the countdown timer accurate
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _submitComment(String pollId, String text, String memberName, String memberId) async {
    if (text.trim().isEmpty) return;
    try {
      final commentData = {
        'memberId': memberId,
        'name': memberName,
        'text': text.trim(),
        'timestamp': Timestamp.now(),
      };
      await FirebaseFirestore.instance.collection('polls').doc(pollId).update({
        'comments': FieldValue.arrayUnion([commentData]),
      });
    } catch (e) {
      debugPrint("Comment error: $e");
    }
  }

  void _showPollDetailsSheet(BuildContext context, Map<String, dynamic> data, String docId, String memberId, String memberName, String memberNo, String memberPhone, bool isDark, ThemeData theme) {
    int? selectedOption;
    bool isSubmitting = false;
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final Map<String, dynamic> votesMap = data['votes'] ?? {};
            final bool hasVoted = votesMap.containsKey(memberId);
            final List<dynamic> options = data['options'] ?? [];
            String myVoteText = "";
            if (hasVoted) {
              int optIdx = votesMap[memberId]['optionIndex'] ?? -1;
              if (optIdx >= 0 && optIdx < options.length) {
                myVoteText = options[optIdx].toString();
              }
            }

            final expiresAt = data['expiresAt'] as Timestamp?;
            final DateTime? expiryDate = expiresAt?.toDate();
            bool isExpired = false;
            if (expiryDate != null) {
              isExpired = expiryDate.difference(DateTime.now()).isNegative;
            }

            final bool allowComments = data['allowComments'] == true;
            final List<dynamic> comments = data['comments'] ?? [];
            bool hasCommented = comments.any((c) => c['memberId'] == memberId);

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (_, controller) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                      const SizedBox(height: 20),
                      
                      Expanded(
                        child: ListView(
                          controller: controller,
                          children: [
                            Text(data['title'] ?? 'No Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: isDark ? Colors.white : Colors.black87)),
                            const SizedBox(height: 8),
                            Text(data['description'] ?? '', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 15)),
                            const SizedBox(height: 24),
                            
                            // Voting Section
                            if (isExpired) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                                child: Column(
                                  children: [
                                    Icon(Icons.block, color: Colors.grey.shade500, size: 28),
                                    const SizedBox(height: 8),
                                    Text("This poll has ended", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                    if (hasVoted) ...[
                                      const SizedBox(height: 4),
                                      Text("Your choice: $myVoteText", style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, fontSize: 13)),
                                    ]
                                  ],
                                ),
                              )
                            ] else if (hasVoted) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.withValues(alpha: 0.3))),
                                child: Column(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 32),
                                    const SizedBox(height: 8),
                                    const Text("You have voted", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text("Your choice: $myVoteText", style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.black87, fontSize: 14)),
                                  ],
                                ),
                              )
                            ] else ...[
                              ...List.generate(options.length, (index) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(12),
                                    color: selectedOption == index ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                    title: Text(options[index].toString(), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: selectedOption == index ? FontWeight.bold : FontWeight.normal)),
                                    leading: Radio<int>(
                                      value: index,
                                      groupValue: selectedOption,
                                      onChanged: (val) => setState(() => selectedOption = val),
                                      activeColor: Colors.blue,
                                    ),
                                    onTap: () => setState(() => selectedOption = index),
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: (selectedOption == null || isSubmitting)
                                      ? null
                                      : () async {
                                          setState(() => isSubmitting = true);
                                          try {
                                            final voteData = {
                                              'optionIndex': selectedOption,
                                              'name': memberName,
                                              'memberNo': memberNo,
                                              'phone': memberPhone,
                                            };
                                            await FirebaseFirestore.instance.collection('polls').doc(docId).update({
                                              'votes.$memberId': voteData,
                                            });
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vote submitted successfully!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
                                            }
                                          } catch (e) {
                                            setState(() => isSubmitting = false);
                                            debugPrint("Vote error: $e");
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    disabledBackgroundColor: Colors.blue.withValues(alpha: 0.3),
                                  ),
                                  child: isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Submit Vote", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                            
                            // Comments Section
                            if (allowComments) ...[
                              const Padding(
                                padding: EdgeInsets.only(top: 24, bottom: 16),
                                child: Divider(),
                              ),
                              Text("Discussion", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
                              const SizedBox(height: 16),
                              
                              if (!hasCommented && !isExpired) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: commentCtrl,
                                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                        decoration: InputDecoration(
                                          hintText: "Add your opinion...",
                                          hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          filled: true,
                                          fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                                        ),
                                        onSubmitted: (text) {
                                          _submitComment(docId, text, memberName, memberId);
                                          commentCtrl.clear();
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                                      child: IconButton(
                                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
                                        onPressed: () {
                                          _submitComment(docId, commentCtrl.text, memberName, memberId);
                                          commentCtrl.clear();
                                          FocusScope.of(context).unfocus();
                                          Navigator.pop(context);
                                        },
                                      ),
                                    )
                                  ],
                                ),
                              ] else if (hasCommented) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, size: 20, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text("You have already shared your opinion.", style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              
                              if (comments.isNotEmpty) const SizedBox(height: 24),
                              ...comments.map((c) {
                                final bool isMyComment = c['memberId'] == memberId;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 18, 
                                        backgroundColor: isMyComment ? Colors.blue.shade100 : (isDark ? Colors.grey.shade700 : Colors.grey.shade200), 
                                        child: Text(c['name']?.substring(0, 1) ?? 'M', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isMyComment ? Colors.blue : (isDark ? Colors.white : Colors.grey.shade700)))
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: isMyComment ? Colors.blue.withValues(alpha: 0.05) : (isDark ? Colors.grey.shade800 : Colors.grey.shade50), 
                                            borderRadius: BorderRadius.circular(16),
                                            border: isMyComment ? Border.all(color: Colors.blue.withValues(alpha: 0.2)) : null,
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(child: Text(c['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                                  if (isMyComment) ...[
                                                    const SizedBox(width: 8),
                                                    const Text("You", style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
                                                  ]
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(c['text'] ?? '', style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade300 : Colors.black87)),
                                            ],
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 40),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProv = context.watch<ProfileProvider>();
    final memberData = profileProv.memberData;

    if (memberData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String memberId = profileProv.documentId;
    final String memberName = profileProv.memberFullName;
    final String memberNo = profileProv.memberNo;
    final String memberPhone = memberData['mobile_number'] ?? '';

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Voting & Polls", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? theme.appBarTheme.backgroundColor : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('polls').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: isDark ? Colors.white : Colors.black)));

          final now = DateTime.now();
          var docs = snapshot.data?.docs ?? [];
          
          // Filter to show active polls + polls expired within the last 1 hour
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final expiresAt = data['expiresAt'] as Timestamp?;
            if (expiresAt == null) return true;
            
            final hideAt = expiresAt.toDate().add(const Duration(hours: 1));
            return hideAt.isAfter(now); 
          }).toList();

          docs.sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.how_to_vote_outlined, size: 80, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("No Active Polls", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey)),
                  const SizedBox(height: 8),
                  Text("Check back later for new voting events.", style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final Map<String, dynamic> votesMap = data['votes'] ?? {};
              final bool hasVoted = votesMap.containsKey(memberId);

              // Time Logic
              final expiresAt = data['expiresAt'] as Timestamp?;
              final DateTime? expiryDate = expiresAt?.toDate();
              
              bool isExpired = false;
              bool showCountdown = false;
              String timeStatusText = "";
              Color timeStatusColor = Colors.grey.shade500;
              Color timeStatusBgColor = Colors.transparent;

              if (expiryDate != null) {
                final diff = expiryDate.difference(now);
                if (diff.isNegative) {
                  isExpired = true;
                  timeStatusText = "Expired";
                  timeStatusColor = Colors.red.shade600;
                  timeStatusBgColor = Colors.red.withValues(alpha: 0.1);
                } else if (diff.inHours < 6) {
                  showCountdown = true;
                  int hours = diff.inHours;
                  int minutes = diff.inMinutes % 60;
                  timeStatusText = "Ends in ${hours}h ${minutes}m";
                  timeStatusColor = Colors.orange.shade700;
                  timeStatusBgColor = Colors.orange.withValues(alpha: 0.1);
                } else {
                  timeStatusText = "Ends: ${DateFormat('MMM dd, hh:mm a').format(expiryDate)}";
                  timeStatusColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
                }
              }

              return GestureDetector(
                onTap: () => _showPollDetailsSheet(context, data, doc.id, memberId, memberName, memberNo, memberPhone, isDark, theme),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? theme.cardColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isExpired ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8)
                            ),
                            child: Text(isExpired ? "Closed" : "Active Poll", style: TextStyle(color: isExpired ? Colors.red : Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                          if (timeStatusText.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: timeStatusBgColor == Colors.transparent ? 0 : 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: timeStatusBgColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (showCountdown) ...[
                                    Icon(Icons.timer_outlined, color: timeStatusColor, size: 12),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(timeStatusText, style: TextStyle(color: timeStatusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['title'] ?? 'No Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(data['description'] ?? '', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (hasVoted && !isExpired)
                            const Icon(Icons.check_circle, color: Colors.green, size: 28)
                          else if (!isExpired)
                            Icon(Icons.chevron_right, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, size: 28)
                          else
                            Icon(Icons.block, color: Colors.grey.shade500, size: 24),
                        ],
                      ),
                    ],
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