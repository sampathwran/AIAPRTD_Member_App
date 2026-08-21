import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class BirthdayWishesOverlay extends StatefulWidget {
  final String firstName;
  final String lastName;
  final VoidCallback onClose;

  const BirthdayWishesOverlay({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.onClose,
  });

  @override
  State<BirthdayWishesOverlay> createState() => _BirthdayWishesOverlayState();
}

class _BirthdayWishesOverlayState extends State<BirthdayWishesOverlay>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 10));

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();
    _confettiController.play();
    
    // Auto close after 12 seconds
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted) {
        _closeOverlay();
      }
    });
  }

  void _closeOverlay() {
    _fadeController.reverse().then((value) {
      widget.onClose();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Path drawStar(Size size) {
    // Method to convert degree to radians
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.black.withOpacity(0.85),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Confetti Emitter
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: pi / 2, // fall down
                  maxBlastForce: 5,
                  minBlastForce: 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  gravity: 0.1,
                  shouldLoop: true,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.purple
                  ],
                  createParticlePath: drawStar,
                ),
              ),

              // Content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "🎂",
                    style: TextStyle(fontSize: 100),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "HAPPY BIRTHDAY",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${widget.firstName} ${widget.lastName}".toUpperCase(),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _closeOverlay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text("Thank You!"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
