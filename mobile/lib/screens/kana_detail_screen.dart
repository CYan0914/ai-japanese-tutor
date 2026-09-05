/// Single kana detail — large display, listen to pronunciation, practice, mark progress.
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../config/tokens.dart';
import '../models/kana.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/kana_state.dart';
import 'writing_screen.dart';

class KanaDetailScreen extends StatefulWidget {
  final Kana kana;
  final MasteryLevel level;

  const KanaDetailScreen({
    super.key,
    required this.kana,
    required this.level,
  });

  @override
  State<KanaDetailScreen> createState() => _KanaDetailScreenState();
}

class _KanaDetailScreenState extends State<KanaDetailScreen> {
  bool _isPlaying = false;
  final _player = AudioPlayer();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playPronunciation() async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);

    try {
      final audioUrl = await ApiService.tts(widget.kana.character);
      final filePath = await AudioService.dataUriToFile(audioUrl);
      await _player.setFilePath(filePath);
      await _player.play();
      await _player.playerStateStream
          .firstWhere((s) => s.processingState == ProcessingState.completed);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play audio: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  Color get _levelColor {
    switch (widget.level) {
      case MasteryLevel.unseen: return SakuraColors.stone;
      case MasteryLevel.learning: return SakuraColors.momiji;
      case MasteryLevel.familiar: return SakuraColors.kinari;
      case MasteryLevel.mastered: return SakuraColors.matcha;
    }
  }

  String _levelLabel() => widget.level.displayLabel;

  IconData _levelIcon() {
    switch (widget.level) {
      case MasteryLevel.unseen: return Icons.circle_outlined;
      case MasteryLevel.learning: return Icons.school_outlined;
      case MasteryLevel.familiar: return Icons.star_half_rounded;
      case MasteryLevel.mastered: return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kana = widget.kana;
    final level = widget.level;
    final levelColor = _levelColor;
    return Scaffold(
      appBar: AppBar(
        title: Text(kana.character, style: SakuraType.kana(size: 22)),
      ),
      body: Stack(
        children: [
          // Kanji watermark — the kana character itself, oversized
          Positioned(
            right: -40,
            top: 40,
            child: IgnorePointer(
              child: Text(
                kana.character,
                style: TextStyle(
                  fontSize: 320,
                  fontWeight: FontWeight.w300,
                  color: SakuraColors.bamboo.withOpacity(0.45),
                  height: 1,
                  fontFamily: 'ShipporiMincho', // Japanese serif fallback
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              SakuraSpace.l, SakuraSpace.l, SakuraSpace.l, SakuraSpace.l,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Large kana display card
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: SakuraColors.white,
                    borderRadius: const BorderRadius.all(SakuraRadius.l),
                    border: Border.all(
                      color: levelColor.withOpacity(0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          kana.character,
                          style: SakuraType.kana(
                            color: SakuraColors.sumi,
                            size: 88,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Semantics(
                          label: _isPlaying
                              ? 'Loading pronunciation'
                              : 'Play pronunciation',
                          button: true,
                          child: Material(
                            color: levelColor.withOpacity(0.12),
                            borderRadius: const BorderRadius.all(SakuraRadius.m),
                            child: InkWell(
                              borderRadius: const BorderRadius.all(SakuraRadius.m),
                              onTap: _isPlaying ? null : _playPronunciation,
                              child: Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                child: _isPlaying
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: levelColor,
                                        ),
                                      )
                                    : Icon(
                                        Icons.volume_up_rounded,
                                        color: levelColor,
                                        size: 22,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SakuraSpace.l),

                // Romaji (display style)
                Text(
                  kana.romaji,
                  style: SakuraType.display(size: 32, color: SakuraColors.mist),
                ),
                const SizedBox(height: SakuraSpace.s),

                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SakuraSpace.m, vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.all(SakuraRadius.pill),
                    border: Border.all(color: levelColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_levelIcon(), size: 16, color: levelColor),
                      const SizedBox(width: 6),
                      Text(
                        _levelLabel(),
                        style: SakuraType.label(color: levelColor, size: 13)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SakuraSpace.xl),

                // Practice writing button (primary CTA)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => WritingScreen(kana: kana),
                      ));
                    },
                    icon: const Icon(Icons.draw_rounded, size: 18),
                    label: Text(
                      'Practice writing',
                      style: SakuraType.label(size: 15, color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: SakuraSpace.s),

                // Mark as known toggle (secondary)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    onPressed: () {
                      final state = context.read<KanaState>();
                      if (level == MasteryLevel.mastered) {
                        state.mark(kana.romaji, MasteryLevel.familiar);
                      } else {
                        state.mark(kana.romaji, MasteryLevel.mastered);
                      }
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      level == MasteryLevel.mastered
                          ? Icons.undo_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 18,
                    ),
                    label: Text(
                      level == MasteryLevel.mastered
                          ? 'Mark as not mastered'
                          : 'I know this kana',
                      style: SakuraType.label(
                        size: 14,
                        color: level == MasteryLevel.mastered
                            ? SakuraColors.mist
                            : SakuraColors.matcha,
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
