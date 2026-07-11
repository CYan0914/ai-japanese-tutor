/// A single kana cell in the gojuuon grid.
import 'package:flutter/material.dart';
import '../models/kana.dart';
import '../services/kana_state.dart';

class KanaTile extends StatelessWidget {
  final Kana kana;
  final MasteryLevel level;
  final VoidCallback onTap;

  const KanaTile({
    super.key,
    required this.kana,
    required this.level,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Gap cells: empty space
    if (kana.isGap) {
      return const SizedBox.shrink();
    }

    final color = _bgColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: level == MasteryLevel.unseen
              ? Border.all(color: Colors.grey.shade300)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              kana.character,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: level == MasteryLevel.unseen
                    ? Colors.grey.shade700
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              kana.romaji,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _bgColor {
    switch (level) {
      case MasteryLevel.unseen:
        return Colors.white;
      case MasteryLevel.learning:
        return Colors.orange.shade50;
      case MasteryLevel.familiar:
        return Colors.yellow.shade50;
      case MasteryLevel.mastered:
        return Colors.green.shade50;
    }
  }
}
