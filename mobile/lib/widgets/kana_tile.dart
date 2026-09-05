/// A single kana cell in the gojuuon grid.
import 'package:flutter/material.dart';
import '../config/tokens.dart';
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
    if (kana.isGap) {
      return const SizedBox.shrink();
    }

    final (bg, fg, accent, borderColor) = _styleFor(level);

    return Semantics(
      label: '${kana.character}, ${kana.romaji}, ${level.displayLabel}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.all(SakuraRadius.s),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                kana.character,
                style: SakuraType.kana(color: fg, size: 28),
              ),
              const SizedBox(height: 2),
              // Mastery dot
              Container(
                width: 4, height: 4,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                kana.romaji,
                style: SakuraType.caption(size: 10, color: SakuraColors.mist),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color, Color, Color) _styleFor(MasteryLevel l) {
    switch (l) {
      case MasteryLevel.unseen:
        return (SakuraColors.washi, SakuraColors.stone, SakuraColors.bamboo, SakuraColors.bamboo);
      case MasteryLevel.learning:
        return (SakuraColors.washi, SakuraColors.sumi, SakuraColors.momiji, SakuraColors.momiji.withOpacity(0.3));
      case MasteryLevel.familiar:
        return (SakuraColors.washi, SakuraColors.sumi, SakuraColors.kinari, SakuraColors.kinari.withOpacity(0.5));
      case MasteryLevel.mastered:
        return (SakuraColors.washi, SakuraColors.sumi, SakuraColors.matcha, SakuraColors.matcha.withOpacity(0.4));
    }
  }
}
