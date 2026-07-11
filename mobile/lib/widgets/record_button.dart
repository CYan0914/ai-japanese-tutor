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

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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
          final scale = widget.isRecording ? 1.0 + _animController.value * 0.15 : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isRecording ? Colors.red : Colors.pink.shade400,
                boxShadow: [
                  BoxShadow(
                    color: (widget.isRecording ? Colors.red : Colors.pink).withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                widget.isRecording ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }
}
