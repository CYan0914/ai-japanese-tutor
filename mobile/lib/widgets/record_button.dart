/// Record button — tap to start, tap again to stop and send.
import 'package:flutter/material.dart';
import '../config/tokens.dart';

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
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
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
    return SizedBox(
      height: 44,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (widget.isRecording) {
              widget.onStop();
            } else {
              widget.onStart();
            }
          },
          borderRadius: const BorderRadius.all(SakuraRadius.m),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: SakuraSpace.m),
            decoration: BoxDecoration(
              color: widget.isRecording
                  ? SakuraColors.sakura
                  : SakuraColors.washiDeep,
              borderRadius: const BorderRadius.all(SakuraRadius.m),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _animController,
                  builder: (_, child) {
                    return Transform.scale(
                      scale: widget.isRecording ? _pulseAnim.value : 1.0,
                      child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: widget.isRecording
                              ? SakuraColors.washi
                              : SakuraColors.sakura,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: SakuraSpace.s),
                Text(
                  widget.isRecording ? 'Listening...  Tap to stop' : 'Tap to speak',
                  style: SakuraType.label(
                    color: widget.isRecording ? SakuraColors.washi : SakuraColors.sumi,
                    size: 14,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
