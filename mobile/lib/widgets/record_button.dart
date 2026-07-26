/// Record button — hold to record, release to send.
import 'package:flutter/material.dart';

class RecordButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const RecordButton({
    super.key,
    required this.isRecording,
    required this.onStart,
    required this.onStop,
  });

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(RecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _animController.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _animController.stop();
      _animController.reset();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => widget.onStart(),
      onTapUp: (_) => widget.onStop(),
      onTapCancel: () {
        if (widget.isRecording) widget.onStop();
      },
      child: AnimatedBuilder(
        animation: _animController,
        builder: (_, child) {
          return SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Expanding outer ring (recording only) ──
                if (widget.isRecording)
                  Transform.scale(
                    scale: 1.0 + _animController.value * 0.35,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(
                          0.20 * (1.0 - _animController.value * 0.6),
                        ),
                      ),
                    ),
                  ),

                // ── Main button ──
                Transform.scale(
                  scale: widget.isRecording ? _pulseAnim.value : 1.0,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isRecording ? Colors.red : Colors.pink.shade400,
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isRecording ? Colors.red : Colors.pink)
                              .withOpacity(0.4),
                          blurRadius: widget.isRecording ? 24 : 12,
                          spreadRadius: widget.isRecording ? 6 : 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isRecording ? Icons.stop_rounded : Icons.mic,
                      color: Colors.white,
                      size: widget.isRecording ? 26 : 30,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
