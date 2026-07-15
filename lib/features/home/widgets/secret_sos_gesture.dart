import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/core/providers/sos_provider.dart';

class SecretSosGesture extends StatefulWidget {
  final Widget child;
  const SecretSosGesture({super.key, required this.child});

  @override
  State<SecretSosGesture> createState() => _SecretSosGestureState();
}

class _SecretSosGestureState extends State<SecretSosGesture> {
  Timer? _sosTimer;

  void _startSosTimer(BuildContext context) {
    _sosTimer?.cancel();
    _sosTimer = Timer(const Duration(seconds: 2), () {
      _triggerSos(context);
    });
  }

  void _cancelSosTimer() {
    _sosTimer?.cancel();
  }

  void _triggerSos(BuildContext context) {
    HapticFeedback.vibrate();
    Future.delayed(const Duration(milliseconds: 300), () => HapticFeedback.vibrate());
    Future.delayed(const Duration(milliseconds: 600), () => HapticFeedback.heavyImpact());

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final sosProvider = Provider.of<SosProvider>(context, listen: false);
    
    if (!sosProvider.isSosActive) {
      sosProvider.startSos(profileProvider);
    }
  }

  @override
  void dispose() {
    _cancelSosTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => _startSosTimer(context),
      onTapUp: (_) => _cancelSosTimer(),
      onTapCancel: () => _cancelSosTimer(),
      onPanDown: (_) => _startSosTimer(context),
      onPanCancel: () => _cancelSosTimer(),
      child: widget.child,
    );
  }
}
