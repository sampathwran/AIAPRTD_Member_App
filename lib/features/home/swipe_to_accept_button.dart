import 'package:flutter/material.dart';

class SwipeToAcceptButton extends StatefulWidget {
  final Future<bool> Function() onAccept;
  final bool isActive;
  final bool isOnline;
  final VoidCallback? onInactiveAttempt;
  final VoidCallback? onOfflineAttempt;

  const SwipeToAcceptButton({
    super.key, 
    required this.onAccept, 
    this.isActive = true, 
    this.isOnline = true,
    this.onInactiveAttempt,
    this.onOfflineAttempt,
  });

  @override
  State<SwipeToAcceptButton> createState() => _SwipeToAcceptButtonState();
}

class _SwipeToAcceptButtonState extends State<SwipeToAcceptButton> {
  double _dragPosition = 0.0;
  bool _isLoading = false;
  bool _isAccepted = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          // Max drag distance (Button width - thumb width)
          double maxDrag = constraints.maxWidth - 60;

          return Container(
            height: 60,
            decoration: BoxDecoration(
              color: _isAccepted ? Colors.green : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _isAccepted ? Colors.green : Colors.blue, width: 2),
            ),
            child: Stack(
              children: [
                // 1. Text (Swipe to Accept >>>)
                Center(
                  child: Text(
                    _isAccepted
                        ? "ACCEPTED!"
                        : (_isLoading ? "Processing..." : "Swipe to Accept >>>"),
                    style: TextStyle(
                      color: _isAccepted ? Colors.white : Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                // 2. Draggable Thumb
                if (!_isAccepted && !_isLoading)
                  Positioned(
                    left: _dragPosition,
                    child: GestureDetector(
                      onHorizontalDragStart: (details) {
                        if (!widget.isOnline) {
                          widget.onOfflineAttempt?.call();
                        } else if (!widget.isActive) {
                          widget.onInactiveAttempt?.call();
                        }
                      },
                      onHorizontalDragUpdate: (details) {
                        if (!widget.isOnline || !widget.isActive) return;
                        setState(() {
                          _dragPosition += details.primaryDelta!;
                          // Prevent dragging out of bounds
                          if (_dragPosition < 0) {
                            _dragPosition = 0;
                          }
                          if (_dragPosition > maxDrag) {
                            _dragPosition = maxDrag;
                          }
                        });
                      },
                      onHorizontalDragEnd: (details) async {
                        // Accept if dragged more than 80%
                        if (_dragPosition > maxDrag * 0.8) {
                          setState(() {
                            _dragPosition = maxDrag;
                            _isLoading = true; // Show processing indicator
                          });

                          // Call Firebase Function
                          bool success = await widget.onAccept();

                          if (success) {
                            setState(() {
                              _isAccepted = true;
                              _isLoading = false;
                            });
                          } else {
                            setState(() {
                              _dragPosition = 0.0;
                              _isLoading = false;
                            });
                          }
                        } else {
                          // Snap back
                          setState(() {
                            _dragPosition = 0.0;
                          });
                        }
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                      ),
                    ),
                  ),

                // 3. Loading Indicator
                if (_isLoading && !_isAccepted)
                  const Positioned(
                    right: 20,
                    top: 15,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.blue, strokeWidth: 3),
                    ),
                  ),
              ],
            ),
          );
        }
    );
  }
}
