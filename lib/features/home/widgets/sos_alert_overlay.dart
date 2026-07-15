import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/sos_provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class SosAlertOverlay extends StatefulWidget {
  const SosAlertOverlay({super.key});

  @override
  State<SosAlertOverlay> createState() => _SosAlertOverlayState();
}

class _SosAlertOverlayState extends State<SosAlertOverlay> {
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
    final sosProvider = Provider.of<SosProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    if (sosProvider.nearbySosAlerts.isEmpty) {
      return const SizedBox.shrink(); // Hide if no requests
    }

    // Only show the closest one for now
    final alert = sosProvider.nearbySosAlerts.first;
    double distanceKm = (alert['distance'] as double) / 1000;
    
    // Get the latest audio url if any
    List<dynamic> audioUrls = alert['voiceRecordingUrls'] ?? [];
    String? latestAudioUrl = audioUrls.isNotEmpty ? audioUrls.last : null;

    return Positioned(
      top: kToolbarHeight + 40,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 5)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.emergency_share_rounded, color: Colors.redAccent, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "SECRET SOS TRIGGERED!",
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          "${distanceKm.toStringAsFixed(1)} km away",
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () {
                      sosProvider.ignoreSosAlert(alert['sosId']);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Driver: ${alert['memberName']} needs emergency help!",
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Phone: ${alert['memberPhone']}",
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (latestAudioUrl != null)
                    ElevatedButton.icon(
                      onPressed: () => _playAudio(latestAudioUrl),
                      icon: Icon(
                        _isPlaying && _currentlyPlayingUrl == latestAudioUrl 
                          ? Icons.stop 
                          : Icons.play_arrow,
                        color: Colors.white
                      ),
                      label: Text(_isPlaying ? "STOP" : "PLAY AUDIO"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("No audio yet", style: TextStyle(color: Colors.white54)),
                    ),
                    
                  ElevatedButton(
                    onPressed: () async {
                      bool accepted = await sosProvider.acceptSosAlert(alert['sosId'], profileProvider);
                      if (accepted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("You marked yourself as a responder! Head to their location."))
                        );
                        // Hide this specific alert from the local view if needed, 
                        // but since the admin tracks it, the member just responds.
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("I AM GOING", style: TextStyle(fontWeight: FontWeight.bold)),
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
