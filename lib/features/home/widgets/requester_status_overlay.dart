import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/community_assistance_provider.dart';
import 'package:aiaprtd_member/features/home/assistance_tracking_page.dart';

class RequesterStatusOverlay extends StatelessWidget {
  const RequesterStatusOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final assistanceProvider = Provider.of<CommunityAssistanceProvider>(context);

    if (!assistanceProvider.isMyRequestAccepted || assistanceProvider.myActiveRequestId == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: kToolbarHeight + 40,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 5)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Helper is on the way!",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "A community member has accepted your request and is coming to help you.",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssistanceTrackingPage(
                          requestId: assistanceProvider.myActiveRequestId!,
                          isHelper: false,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map, color: Colors.green),
                  label: const Text("TRACK HELPER", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green.shade700,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
