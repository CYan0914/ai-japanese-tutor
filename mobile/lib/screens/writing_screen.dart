/// Writing practice screen — canvas with ghost guide.
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    ..color = Colors.black87
    ..strokeWidth = 6
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  final _guidePaint = Paint()
    ..color = Colors.grey.shade300
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
        content: Text('Progress saved for ${widget.kana.romaji}! 🎉'),
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
        backgroundColor: Colors.pink.shade50,
        foregroundColor: Colors.pink.shade800,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Top hint
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.orange.shade50,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '👆 Trace the character: ${widget.kana.romaji}',
                  style: TextStyle(color: Colors.orange.shade800, fontSize: 15),
                ),
              ],
            ),
          ),

          // Drawing canvas
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  painter: _WritingPainter(
                    strokes: _strokes,
                    currentStroke: _currentStroke,
                    brush: _paint,
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ToolBtn(Icons.undo, 'Undo', _undo),
                _ToolBtn(Icons.delete_outline, 'Clear', _clear),
                SizedBox(
                  width: 160,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _markDone,
                    icon: const Icon(Icons.check),
                    label: const Text('Done'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey.shade600),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

// ── Custom Painter ──

class _WritingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset>? currentStroke;
  final Paint brush;
  final String guideChar;
  final Paint guidePaint;

  _WritingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.brush,
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
        color: Colors.grey.shade300,
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
      ..color = Colors.grey.shade200
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
      canvas.drawPath(path, brush);
    }

    // Draw current in-progress stroke
    if (currentStroke != null && currentStroke!.isNotEmpty) {
      final path = Path()..moveTo(currentStroke!.first.dx, currentStroke!.first.dy);
      for (var i = 1; i < currentStroke!.length; i++) {
        path.lineTo(currentStroke![i].dx, currentStroke![i].dy);
      }
      canvas.drawPath(path, brush);
    }
  }

  @override
  bool shouldRepaint(covariant _WritingPainter old) => true;
}
