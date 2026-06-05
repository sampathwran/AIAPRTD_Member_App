import 'package:flutter/material.dart';
import 'scheduled_button.dart';
import 'create_job_button.dart';
import 'road_pickup_button.dart';

class HomeFooter extends StatelessWidget {
  final bool isSharingLocation;
  final VoidCallback onToggleLocation;

  const HomeFooter({
    super.key,
    required this.isSharingLocation,
    required this.onToggleLocation,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.22,
      minChildSize: 0.22,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                const SizedBox(height: 15),
                // Drag Handle
                Center(
                  child: Container(
                    width: 40, height: 5,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 15),

                // Status Bar
                Text(
                  isSharingLocation ? "You're online" : "You're offline",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Statistics Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat("95.0%", "Acceptance"),
                    _buildStat("4.75", "Rating"),
                    _buildStat("2.0%", "Cancellation"),
                  ],
                ),
                const Divider(height: 40, thickness: 1),

                // Shortcuts
                const Padding(
                  padding: EdgeInsets.only(left: 20, bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Shortcuts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                ScheduledButton(onTap: () => Navigator.pushNamed(context, '/scheduled')),
                const Divider(indent: 20, endIndent: 20),
                CreateJobButton(onTap: () => Navigator.pushNamed(context, '/create-job')),
                const Divider(indent: 20, endIndent: 20),
                RoadPickupButton(onTap: () => Navigator.pushNamed(context, '/road-pickup')),

                // Online වෙලාවේ විතරක් පේන OFF බොත්තම (80x80, Gradient)
                if (isSharingLocation) ...[
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: onToggleLocation,
                    child: Container(
                      width: 80, height: 80,
                      margin: const EdgeInsets.only(bottom: 30),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.red.shade300, Colors.red.shade600]),
                        shape: BoxShape.circle,
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                      ),
                      child: const Center(
                        child: Text(
                          "OFF",
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}