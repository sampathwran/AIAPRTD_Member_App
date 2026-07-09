import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/community_assistance_provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:aiaprtd_member/features/home/assistance_tracking_page.dart';

class HelpAlertOverlay extends StatefulWidget {
  const HelpAlertOverlay({super.key});

  @override
  State<HelpAlertOverlay> createState() => _HelpAlertOverlayState();
}

class _HelpAlertOverlayState extends State<HelpAlertOverlay> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentlyPlayingUrl;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playAudio(String url) async {
    if (_isPlaying && _currentlyPlayingUrl == url) {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _currentlyPlayingUrl = null;
      });
    } else {
      await _audioPlayer.play(UrlSource(url));
      setState(() {
        _isPlaying = true;
        _currentlyPlayingUrl = url;
      });
      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _currentlyPlayingUrl = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final assistanceProvider = Provider.of<CommunityAssistanceProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    if (assistanceProvider.nearbyRequests.isEmpty) {
      return const SizedBox.shrink(); // Hide if no requests
    }

    // Only show the closest one for now, or use a PageView/ListView if multiple
    final request = assistanceProvider.nearbyRequests.first;
    double distanceKm = (request['distanceMeters'] as double) / 1000;

    return Positioned(
      top: kToolbarHeight + 40,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade600,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 5)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "SOS: Member Needs Help!",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Text(
                    "${distanceKm.toStringAsFixed(1)} km away",
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Issue: ${request['issueType']}",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                "Member: ${request['requesterName']}",
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (request['voiceNoteUrl'] != null)
                    ElevatedButton.icon(
                      onPressed: () => _playAudio(request['voiceNoteUrl']),
                      icon: Icon(
                        _isPlaying && _currentlyPlayingUrl == request['voiceNoteUrl'] 
                          ? Icons.stop 
                          : Icons.play_arrow,
                        color: Colors.red.shade700
                      ),
                      label: Text(_isPlaying ? "STOP" : "LISTEN"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red.shade700,
                      ),
                    ),
                  ElevatedButton(
                    onPressed: () async {
                      bool accepted = await assistanceProvider.acceptRequest(request['requestId'], profileProvider);
                      if (accepted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Request Accepted! Navigating to tracking..."))
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AssistanceTrackingPage(
                              requestId: request['requestId'],
                              isHelper: true,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("I CAN HELP", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
