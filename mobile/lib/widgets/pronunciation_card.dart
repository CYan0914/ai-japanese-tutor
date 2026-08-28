/// Pronunciation score card — refined with sakura palette.
import 'package:flutter/material.dart';
import '../config/tokens.dart';
import '../models/tutor_response.dart';

class PronunciationCard extends StatelessWidget {
  final PronunciationScore score;

  const PronunciationCard({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(score.overall);

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: SakuraSpace.s, top: 4),
      child: Container(
        padding: const EdgeInsets.all(SakuraSpace.m),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: const BorderRadius.all(SakuraRadius.s),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            // Score ring
            SizedBox(
              width: 56, height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 56, height: 56,
                    child: CircularProgressIndicator(
                      value: score.overall / 100,
                      strokeWidth: 3,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                  Text(
                    '${score.overall}',
                    style: SakuraType.label(color: color, size: 16).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: SakuraSpace.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _gradeLabel(score.overall),
                    style: SakuraType.title(color: color, size: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    score.feedback.isNotEmpty
                        ? score.feedback
                        : _defaultFeedback(score.overall),
                    style: SakuraType.caption(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(int s) {
    if (s >= 85) return SakuraColors.matcha;
    if (s >= 70) return SakuraColors.kinari;
    if (s >= 50) return SakuraColors.momiji;
    return SakuraColors.sakura;
  }

  String _gradeLabel(int s) {
    if (s >= 85) return 'Excellent';
    if (s >= 70) return 'Good';
    if (s >= 50) return 'Fair';
    return 'Needs work';
  }

  String _defaultFeedback(int s) {
    if (s >= 85) return 'Keep up the great work.';
    if (s >= 70) return 'A few small improvements needed.';
    if (s >= 50) return 'Focus on the highlighted sounds.';
    return 'Practice makes perfect — keep trying.';
  }
}
