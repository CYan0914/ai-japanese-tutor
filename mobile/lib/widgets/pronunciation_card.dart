/// Pronunciation score card — colored score display.
import 'package:flutter/material.dart';
import '../models/tutor_response.dart';

class PronunciationCard extends StatelessWidget {
  final PronunciationScore score;

  const PronunciationCard({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score.overall >= 85
        ? Colors.green
        : score.overall >= 70
            ? Colors.lightGreen
            : score.overall >= 50
                ? Colors.orange
                : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            // Score circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
              ),
              child: Center(
                child: Text(
                  '${score.overall}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _gradeLabel(score.overall),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    score.feedback.isNotEmpty
                        ? score.feedback
                        : _defaultFeedback(score.overall),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _gradeLabel(int s) {
    if (s >= 85) return 'Excellent!';
    if (s >= 70) return 'Good!';
    if (s >= 50) return 'Fair';
    return 'Needs Work';
  }

  String _defaultFeedback(int s) {
    if (s >= 85) return 'Keep up the great work!';
    if (s >= 70) return 'A few small improvements needed.';
    if (s >= 50) return 'Focus on the highlighted sounds.';
    return 'Practice makes perfect — keep trying!';
  }
}
