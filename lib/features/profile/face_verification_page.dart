import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';

import 'package:aiaprtd_member/core/providers/kyc_provider.dart';

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

class _FaceVerificationPageState extends State<FaceVerificationPage> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isScanning = false;
  bool _isSubmitting = false;

  // AI Terminal Logs
  int _logIndex = 0;
  final List<String> _aiLogs = [
    "SYSTEM: AWAITING FACE POSITON",
    "AI: INITIALIZING NEURAL ENGINE...",
    "AI: DETECTING 3D FACE MESH...",
    "AI: ANALYZING DEPTH & LIVENESS...",
    "AI: CROSS-CHECKING BIOMETRICS...",
    "AI: BIOMETRIC SCAN SUCCESSFUL ✅",
    "SYSTEM: UPLOADING ENCRYPTED DATA..."
  ];

  late AnimationController _scannerController;

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    // Laser scanner line animation
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

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
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  Future<void> _startAIScan() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() {
      _isScanning = true;
      _logIndex = 1;
    });

    // Start laser animation (up and down)
    _scannerController.repeat(reverse: true);

    // Switch AI logs sequentially for effect
    for (int i = 1; i < 6; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() => _logIndex = i);
    }

    try {
      final XFile selfieFile = await _cameraController!.takePicture();
      _scannerController.stop();

      if (!mounted) return;
      setState(() {
        _logIndex = 6;
        _isSubmitting = true;
      });

      await _uploadSelfie(File(selfieFile.path));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _isSubmitting = false;
        _logIndex = 0;
      });
    }
  }

  Future<void> _uploadSelfie(File file) async {
    try {
      final kycProvider = Provider.of<KYCProvider>(context, listen: false);
      final success = await kycProvider.saveFaceVerification(
        widget.membershipNo,
        widget.documentId,
        file,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Face biometrics securely saved! ✅"), backgroundColor: Colors.green),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        throw Exception("Upload failed");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _isSubmitting = false;
        _logIndex = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cloud sync failed. Please try again."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020611), // Dark blue/black (Hacker look)
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // ==========================================
                      // 🛡️ HEADER / LIVE BADGE
                      // ==========================================
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("AI SECURITY", style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                Text("BIOMETRIC SCAN", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.redAccent),
                              ),
                              child: Row(
                                children: [
                                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  const Text("LIVE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ==========================================
                      // 📷 AI SCANNER CAMERA VIEW
                      // ==========================================
                      Expanded(
                        child: Center(
                          child: _isCameraInitialized && _cameraController != null
                              ? Stack(
                            alignment: Alignment.center,
                            children: [
                              // Camera Circle
                              Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: _isScanning ? Colors.greenAccent : Colors.cyanAccent,
                                      width: 4
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                        color: (_isScanning ? Colors.greenAccent : Colors.cyanAccent).withValues(alpha: 0.3),
                                        blurRadius: 30,
                                        spreadRadius: 10
                                    )
                                  ],
                                ),
                                child: ClipOval(
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: CameraPreview(_cameraController!),
                                  ),
                                ),
                              ),

                              // Laser scanner line (Visible only during scan)
                              if (_isScanning)
                                AnimatedBuilder(
                                  animation: _scannerController,
                                  builder: (context, child) {
                                    return Positioned(
                                      top: 280 * _scannerController.value,
                                      child: Container(
                                        width: 280,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.greenAccent,
                                          boxShadow: [
                                            BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.8), blurRadius: 15, spreadRadius: 5)
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                              // 🎯 Target Brackets
                              if (!_isScanning)
                                const Icon(Icons.crop_free, size: 100, color: Colors.white54),
                            ],
                          )
                              : const CircularProgressIndicator(color: Colors.cyanAccent),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ==========================================
                      // 💻 AI TERMINAL BOX
                      // ==========================================
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.memory, color: _isScanning ? Colors.greenAccent : Colors.cyanAccent, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _aiLogs[_logIndex],
                                    style: TextStyle(
                                      color: _isScanning ? Colors.greenAccent : Colors.cyanAccent,
                                      fontFamily: 'Courier', // Hacker Terminal font
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: _logIndex / (_aiLogs.length - 1),
                              backgroundColor: Colors.white12,
                              color: Colors.greenAccent,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ==========================================
                      // 🟢 SCAN BUTTON
                      // ==========================================
                      Padding(
                        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isScanning || _isSubmitting ? null : _startAIScan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan.shade800,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: _isSubmitting
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.face),
                            label: Text(
                              _isScanning || _isSubmitting ? "PROCESSING BIOMETRICS..." : "INITIALIZE SCAN",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}