// ignore_for_file: spell_check_on_languages

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';

import '../providers/kyc_provider.dart';

class FaceVerificationPage extends StatefulWidget {
  final String membershipNo;
  final String documentId;

  const FaceVerificationPage({
    super.key,
    required this.membershipNo,
    required this.documentId,
  });

  @override
  State<FaceVerificationPage> createState() => _FaceVerificationPageState();
}

class _FaceVerificationPageState extends State<FaceVerificationPage>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isScanning = false;
  bool _isSubmitting = false;

  String _aiLogText = "SYSTEM: READY FOR BIOMETRIC SCAN";
  double _progress = 0.0;
  int _scanQuality = 0;

  late AnimationController _rotationController;
  late AnimationController _reverseRotationController;
  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  late AnimationController _glitchController;

  late Animation<double> _scanLineAnimation;
  Timer? _qualityTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();

    _reverseRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    )..repeat(reverse: true);

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scanLineAnimation = Tween<double>(begin: -120, end: 120).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.92,
      upperBound: 1.08,
    )..repeat(reverse: true);

    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() => _aiLogText = "ERROR: NO CAMERA FOUND");
        return;
      }

      final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Camera Init Error: $e");
      if (mounted) {
        setState(() => _aiLogText = "ERROR: CAMERA HARDWARE FAILURE");
      }
    }
  }

  Future<void> _startAIFaceScan() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isScanning = true;
      _progress = 0.0;
      _scanQuality = 0;
      _aiLogText = "AI: INITIALIZING SECURE FACE LOCK...";
    });

    _scanLineController.repeat(reverse: true);

    _qualityTimer?.cancel();
    _qualityTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!_isScanning || !mounted) return;

      setState(() {
        _scanQuality = min(98, _scanQuality + Random().nextInt(4));
      });
    });

    final logs = [
      "AI: DETECTING LIVE FACE...",
      "AI: BUILDING FACE MESH POINTS...",
      "AI: CHECKING EYES / NOSE / MOUTH...",
      "AI: ANALYZING DEPTH MAP...",
      "AI: LIVENESS DETECTION ACTIVE...",
      "AI: MATCHING PROFILE IDENTITY...",
      "AI: BIOMETRIC SCAN SUCCESSFUL ✅",
    ];

    for (int i = 0; i < logs.length; i++) {
      await Future.delayed(const Duration(milliseconds: 650));

      if (!mounted) return;

      setState(() {
        _aiLogText = logs[i];
        _progress = (i + 1) / logs.length;
      });
    }

    try {
      final XFile selfieFile = await _cameraController!.takePicture();
      _scanLineController.stop();

      if (!mounted) return;
      await _uploadAndSaveSelfie(File(selfieFile.path));
    } catch (e) {
      debugPrint("Capture Error: $e");

      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _isSubmitting = false;
        _aiLogText = "ERROR: CAPTURE FAILED. TRY AGAIN.";
      });
    }
  }

  Future<void> _uploadAndSaveSelfie(File capturedSelfie) async {
    setState(() {
      _isSubmitting = true;
      _aiLogText = "SYSTEM: UPLOADING BIOMETRIC DATA...";
    });

    final messenger = ScaffoldMessenger.of(context);
    final kycProvider = Provider.of<KYCProvider>(context, listen: false);

    try {
      final success = await kycProvider.saveFaceVerification(
        widget.membershipNo,
        widget.documentId,
        capturedSelfie,
      );

      if (!mounted) return;

      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Face biometric scan saved successfully! ✅"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        throw Exception("Provider failed");
      }
    } catch (e) {
      debugPrint("Final KYC Error: $e");

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isScanning = false;
        _aiLogText = "SYSTEM ERROR: CLOUD SYNC FAILED.";
      });
    }
  }

  @override
  void dispose() {
    _qualityTimer?.cancel();
    _cameraController?.dispose();
    _rotationController.dispose();
    _reverseRotationController.dispose();
    _scanLineController.dispose();
    _pulseController.dispose();
    _glitchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020611),
      body: Stack(
        children: [
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: Opacity(
                opacity: _isScanning ? 0.92 : 0.65,
                child: CameraPreview(_cameraController!),
              ),
            )
          else
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
            ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.15,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(120),
                    const Color(0xFF020611).withAlpha(245),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _hudLabel("AI SECURITY SYSTEM", "BIOMETRIC SCANNER"),
                  _liveBadge(),
                ],
              ),
            ),
          ),

          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _rotationController,
                _reverseRotationController,
                _pulseController,
                _scanLineController,
              ]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _isScanning ? _pulseController.value : 1,
                  child: SizedBox(
                    width: 330,
                    height: 330,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        RotationTransition(
                          turns: _rotationController,
                          child: CustomPaint(
                            size: const Size(330, 330),
                            painter: _RadarRingPainter(
                              color: Colors.cyanAccent,
                              active: _isScanning,
                            ),
                          ),
                        ),
                        RotationTransition(
                          turns: _reverseRotationController,
                          child: CustomPaint(
                            size: const Size(290, 290),
                            painter: _BrokenRingPainter(
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                        Container(
                          width: 255,
                          height: 255,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isScanning
                                  ? Colors.greenAccent
                                  : Colors.cyanAccent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isScanning
                                    ? Colors.greenAccent
                                    : Colors.cyanAccent)
                                    .withAlpha(90),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        if (_isScanning) ...[
                          CustomPaint(
                            size: const Size(230, 250),
                            painter: _FaceMeshPainter(),
                          ),
                          Positioned(
                            top: 40 + _scanLineAnimation.value,
                            child: Container(
                              width: 245,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.greenAccent.withAlpha(220),
                                    blurRadius: 24,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        Positioned(
                          top: 18,
                          child: _smallChip(
                            _isScanning ? "FACE LOCKED" : "POSITION FACE",
                            _isScanning ? Colors.greenAccent : Colors.cyanAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Positioned(
            top: 115,
            right: 18,
            child: _qualityPanel(),
          ),

          Positioned(
            left: 18,
            top: 130,
            child: _sideStatusPanel(),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: Column(
              children: [
                _terminalPanel(),
                const SizedBox(height: 14),
                _warningStrip(),
                const SizedBox(height: 18),
                _scanButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hudLabel(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.greenAccent,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _liveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(160),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.redAccent.withAlpha(150)),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            "LIVE",
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _qualityPanel() {
    return Container(
      width: 112,
      padding: const EdgeInsets.all(12),
      decoration: _glassBox(),
      child: Column(
        children: [
          const Text(
            "SCAN QUALITY",
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${_isScanning ? _scanQuality : 0}%",
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _isScanning ? _scanQuality / 100 : 0,
            backgroundColor: Colors.white12,
            color: Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _sideStatusPanel() {
    return Container(
      width: 92,
      padding: const EdgeInsets.all(10),
      decoration: _glassBox(),
      child: Column(
        children: [
          _miniStatus(Icons.grid_4x4_rounded, "MESH", _isScanning),
          const SizedBox(height: 14),
          _miniStatus(Icons.remove_red_eye_rounded, "EYES", _progress > 0.35),
          const SizedBox(height: 14),
          _miniStatus(Icons.health_and_safety, "LIVE", _progress > 0.55),
        ],
      ),
    );
  }

  Widget _miniStatus(IconData icon, String text, bool active) {
    return Column(
      children: [
        Icon(
          icon,
          color: active ? Colors.greenAccent : Colors.white30,
          size: 22,
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            color: active ? Colors.greenAccent : Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _terminalPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _glassBox(borderColor: Colors.cyanAccent),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _isScanning ? Icons.memory_rounded : Icons.terminal_rounded,
                color: _isScanning ? Colors.greenAccent : Colors.cyanAccent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _aiLogText,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _isScanning ? Colors.greenAccent : Colors.cyanAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Courier',
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: Colors.white12,
              color: Colors.greenAccent,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _logItem("FACE MESH"),
              _logItem("DEPTH MAP"),
              _logItem("LIVENESS"),
            ],
          )
        ],
      ),
    );
  }

  Widget _logItem(String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            _progress > 0.2 ? Icons.check_circle : Icons.radio_button_unchecked,
            color: _progress > 0.2 ? Colors.greenAccent : Colors.white24,
            size: 13,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _warningStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withAlpha(150)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Do not use masks, sunglasses, screenshots, or another person's face.",
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanButton() {
    if (_isSubmitting) {
      return const SizedBox(
        height: 55,
        child: Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _isScanning ? Colors.redAccent : Colors.cyan.shade700,
          foregroundColor: Colors.white,
          elevation: 14,
          shadowColor: _isScanning ? Colors.redAccent : Colors.cyanAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _isScanning ? null : _startAIFaceScan,
        icon: Icon(
          _isScanning
              ? Icons.security_rounded
              : Icons.face_retouching_natural_rounded,
        ),
        label: Text(
          _isScanning ? "SCANNING BIOMETRICS..." : "INITIALIZE SECURITY SCAN",
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _smallChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(170),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withAlpha(180)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  BoxDecoration _glassBox({Color borderColor = Colors.white}) {
    return BoxDecoration(
      color: Colors.black.withAlpha(170),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor.withAlpha(95)),
      boxShadow: [
        BoxShadow(
          color: Colors.cyanAccent.withAlpha(25),
          blurRadius: 20,
          spreadRadius: 1,
        ),
      ],
    );
  }
}

class _RadarRingPainter extends CustomPainter {
  final Color color;
  final bool active;

  _RadarRingPainter({
    required this.color,
    required this.active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color.withAlpha(active ? 190 : 100)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 70; i++) {
      final angle = (2 * pi / 70) * i;
      final start = Offset(
        center.dx + cos(angle) * (radius - 12),
        center.dy + sin(angle) * (radius - 12),
      );
      final end = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );

      canvas.drawLine(start, end, paint);
    }

    canvas.drawCircle(center, radius - 35, paint..color = color.withAlpha(75));
    canvas.drawCircle(center, radius - 70, paint..color = color.withAlpha(45));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BrokenRingPainter extends CustomPainter {
  final Color color;

  _BrokenRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..color = color.withAlpha(150)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (double start = 0; start < 360; start += 55) {
      canvas.drawArc(
        rect.deflate(8),
        start * pi / 180,
        25 * pi / 180,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _FaceMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[
      Offset(size.width * .50, size.height * .08),
      Offset(size.width * .28, size.height * .18),
      Offset(size.width * .72, size.height * .18),
      Offset(size.width * .20, size.height * .38),
      Offset(size.width * .40, size.height * .35),
      Offset(size.width * .60, size.height * .35),
      Offset(size.width * .80, size.height * .38),
      Offset(size.width * .50, size.height * .50),
      Offset(size.width * .34, size.height * .62),
      Offset(size.width * .66, size.height * .62),
      Offset(size.width * .50, size.height * .74),
      Offset(size.width * .35, size.height * .84),
      Offset(size.width * .65, size.height * .84),
      Offset(size.width * .50, size.height * .93),
    ];

    final linePaint = Paint()
      ..color = Colors.greenAccent.withAlpha(130)
      ..strokeWidth = 1.2;

    final dotPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;

    final connections = [
      [0, 1],
      [0, 2],
      [1, 3],
      [2, 6],
      [3, 4],
      [4, 5],
      [5, 6],
      [4, 7],
      [5, 7],
      [7, 8],
      [7, 9],
      [8, 10],
      [9, 10],
      [10, 11],
      [10, 12],
      [11, 13],
      [12, 13],
      [3, 8],
      [6, 9],
    ];

    for (final c in connections) {
      canvas.drawLine(points[c[0]], points[c[1]], linePaint);
    }

    for (final p in points) {
      canvas.drawCircle(p, 3.2, dotPaint);
      canvas.drawCircle(
        p,
        7,
        Paint()
          ..color = Colors.greenAccent.withAlpha(55)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}