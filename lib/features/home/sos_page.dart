import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/community_assistance_provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';

class SosPage extends StatefulWidget {
  const SosPage({super.key});

  @override
  State<SosPage> createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  final List<Map<String, dynamic>> _issueTypes = [
    {'title': 'Flat Tire', 'icon': Icons.tire_repair, 'color': Colors.orange},
    {'title': 'Dead Battery', 'icon': Icons.battery_alert, 'color': Colors.red},
    {'title': 'No Fuel', 'icon': Icons.local_gas_station, 'color': Colors.amber},
    {'title': 'Mechanical', 'icon': Icons.build, 'color': Colors.blueGrey},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assistanceProvider = Provider.of<CommunityAssistanceProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Community Assistance", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.handshake, color: Colors.blueAccent, size: 80),
              const SizedBox(height: 16),
              const Text(
                "Need Roadside Help?",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                "Select your issue and hold the button below to record a short voice note. We will alert drivers within 5km.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 30),

              // Issue Selection Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.5,
                ),
                itemCount: _issueTypes.length,
                itemBuilder: (context, index) {
                  final issue = _issueTypes[index];
                  final isSelected = assistanceProvider.selectedIssue == issue['title'];

                  return GestureDetector(
                    onTap: () => assistanceProvider.selectIssue(issue['title']),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? issue['color'].withOpacity(0.1) : Colors.grey.shade100,
                        border: Border.all(color: isSelected ? issue['color'] : Colors.transparent, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(issue['icon'], color: isSelected ? issue['color'] : Colors.grey, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            issue['title'],
                            style: TextStyle(
                              color: isSelected ? issue['color'] : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 50),

              // Record Button
              if (assistanceProvider.isSubmitting)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Sending request to nearby drivers...", style: TextStyle(color: Colors.grey)),
                  ],
                )
              else
                GestureDetector(
                  onLongPressStart: (_) {
                    assistanceProvider.startRecording();
                  },
                  onLongPressEnd: (_) async {
                    bool success = await assistanceProvider.stopRecordingAndSubmit(profileProvider);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Help request sent! Waiting for a nearby driver to accept."),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 4),
                        )
                      );
                      Navigator.pop(context); // Go back to home
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to send request. Try again."), backgroundColor: Colors.red)
                      );
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      bool isRec = assistanceProvider.isRecording;
                      return Container(
                        height: 180,
                        width: 180,
                        decoration: BoxDecoration(
                          color: isRec ? Colors.red : Colors.blueAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isRec ? Colors.red : Colors.blueAccent).withOpacity(isRec ? _animationController.value * 0.5 : 0.3),
                              blurRadius: isRec ? 50 * _animationController.value : 30,
                              spreadRadius: isRec ? 20 * _animationController.value : 10,
                            )
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(isRec ? Icons.mic : Icons.mic_none, color: Colors.white, size: 40),
                              const SizedBox(height: 8),
                              Text(
                                isRec ? "RECORDING...\nRelease to Send" : "HOLD TO\nRECORD",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}