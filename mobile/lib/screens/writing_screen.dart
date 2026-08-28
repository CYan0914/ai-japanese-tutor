/// Writing practice screen — canvas with ghost guide.
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/tokens.dart';
import '../models/kana.dart';
import '../services/kana_state.dart';

class WritingScreen extends StatefulWidget {
  final Kana kana;
  const WritingScreen({super.key, required this.kana});

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;
  final _paint = Paint()
    ..color = SakuraColors.sumi
    ..strokeWidth = 6
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  final _guidePaint = Paint()
    ..color = SakuraColors.bamboo
    ..strokeWidth = 3
    ..style = PaintingStyle.stroke;

  Offset? _lastPoint;

  void _onPanStart(DragStartDetails d) {
    _currentStroke = [d.localPosition];
    _lastPoint = d.localPosition;
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_currentStroke == null) return;
    _currentStroke!.add(d.localPosition);
    _lastPoint = d.localPosition;
    setState(() {});
  }

  void _onPanEnd(DragEndDetails _) {
    if (_currentStroke != null && _currentStroke!.isNotEmpty) {
      _strokes.add(List.from(_currentStroke!));
    }
    _currentStroke = null;
    _lastPoint = null;
    setState(() {});
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      _strokes.removeLast();
    }
    _currentStroke = null;
    setState(() {});
  }

  void _clear() {
    _strokes.clear();
    _currentStroke = null;
    setState(() {});
  }

  void _markDone() {
    final state = context.read<KanaState>();
    final currentLevel = state.levelFor(widget.kana.romaji);
    if (currentLevel == MasteryLevel.unseen) {
      state.mark(widget.kana.romaji, MasteryLevel.learning);
    } else if (currentLevel == MasteryLevel.learning) {
      state.mark(widget.kana.romaji, MasteryLevel.familiar);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Progress saved for ${widget.kana.romaji}.',
          style: SakuraType.body(color: Colors.white, size: 14),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Write ${widget.kana.character}'),
      ),
      body: Column(
        children: [
          // Top hint
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SakuraSpace.m, vertical: 10,
            ),
            color: SakuraColors.kinari.withOpacity(0.15),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 16, color: SakuraColors.momiji,
                ),
                const SizedBox(width: 8),
                Text(
                  'Trace the character: ${widget.kana.romaji}',
                  style: SakuraType.label(
                    color: SakuraColors.momiji,
                    size: 13,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Drawing canvas
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(SakuraSpace.l),
              decoration: BoxDecoration(
                color: SakuraColors.white,
                borderRadius: const BorderRadius.all(SakuraRadius.l),
                border: Border.all(color: SakuraColors.bamboo),
              ),
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  painter: _WritingPainter(
                    strokes: _strokes,
                    currentStroke: _currentStroke,
                    strokePaint: _paint,
                    guideChar: widget.kana.character,
                    guidePaint: _guidePaint,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),

          // Toolbar
          Container(
            padding: const EdgeInsets.all(SakuraSpace.m),
            decoration: const BoxDecoration(
              color: SakuraColors.white,
              border: Border(
                top: BorderSide(color: SakuraColors.bamboo, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ToolBtn(Icons.undo_rounded, 'Undo', _undo),
                _ToolBtn(Icons.cleaning_services_outlined, 'Clear', _clear),
                SizedBox(
                  width: 160,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _markDone,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      'Done',
                      style: SakuraType.label(size: 14, color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolBtn(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SakuraSpace.s, vertical: 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: SakuraColors.mist, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: SakuraType.caption(size: 11, color: SakuraColors.mist),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom Painter ──

class _WritingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset>? currentStroke;
  final Paint strokePaint;
  final String guideChar;
  final Paint guidePaint;

  _WritingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.strokePaint,
    required this.guideChar,
    required this.guidePaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw ghost guide character in center
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 160,
      maxLines: 1,
    ))
      ..pushStyle(ui.TextStyle(
        color: SakuraColors.bamboo,
        fontWeight: FontWeight.bold,
      ))
      ..addText(guideChar);

    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: size.width));

    final textHeight = paragraph.height;
    final yOffset = (size.height - textHeight) / 2;
    canvas.drawParagraph(paragraph, Offset(0, yOffset));

    // Draw crosshair center lines
    final guideLine = Paint()
      ..color = SakuraColors.bamboo.withOpacity(0.6)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(size.width / 2 - 60, size.height / 2),
      Offset(size.width / 2 + 60, size.height / 2),
      guideLine,
    );
    canvas.drawLine(
      Offset(size.width / 2, size.height / 2 - 80),
      Offset(size.width / 2, size.height / 2 + 80),
      guideLine,
    );

    // Draw completed strokes
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, strokePaint);
    }

    // Draw current in-progress stroke
    if (currentStroke != null && currentStroke!.isNotEmpty) {
      final path = Path()..moveTo(currentStroke!.first.dx, currentStroke!.first.dy);
      for (var i = 1; i < currentStroke!.length; i++) {
        path.lineTo(currentStroke![i].dx, currentStroke![i].dy);
      }
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WritingPainter old) => true;
}
