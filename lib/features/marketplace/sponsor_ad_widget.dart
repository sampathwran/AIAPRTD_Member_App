import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SponsorAdWidget extends StatefulWidget {
  final Map<String, dynamic> sponsorAd;

  const SponsorAdWidget({super.key, required this.sponsorAd});

  @override
  State<SponsorAdWidget> createState() => _SponsorAdWidgetState();
}

class _SponsorAdWidgetState extends State<SponsorAdWidget> {
  VideoPlayerController? _controller;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _isVideo = widget.sponsorAd['type'] == 'video';
    if (_isVideo) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.sponsorAd['mediaUrl']))
        ..initialize().then((_) {
          _controller!.setVolume(0); // Muted
          _controller!.setLooping(true);
          _controller!.play();
          if (mounted) setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _isVideo
              ? (_controller != null && _controller!.value.isInitialized
                  ? SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller!.value.size.width,
                          height: _controller!.value.size.height,
                          child: VideoPlayer(_controller!),
                        ),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()))
              : Image.network(
                  widget.sponsorAd['mediaUrl'] ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                ),
          Positioned(
            top: 5, right: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(5)),
              child: const Text("SPONSORED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          )
        ],
      ),
    );
  }
}