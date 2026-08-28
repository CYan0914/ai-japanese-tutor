/// Quiz mode — shown kana, pick correct romaji.
import 'dart:math';
import 'package:flutter/material.dart';
import '../config/tokens.dart';
import '../models/kana.dart';

class QuizScreen extends StatefulWidget {
  final KanaType type;
  const QuizScreen({super.key, required this.type});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Kana> _deck;
  int _current = 0;
  int _correct = 0;
  int _wrong = 0;
  String? _selectedAnswer;
  bool _showingResult = false;
  bool _isCorrect = false;

  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _deck = List.from(KanaData.all(widget.type))..shuffle(_rng);
  }

  Kana get _currentKana => _deck[_current];

  List<String> get _options {
    final correct = _currentKana.romaji;
    // Pick 3 random wrong answers
    final allRomaji = KanaData.all(widget.type).map((k) => k.romaji).toList();
    allRomaji.remove(correct);
    allRomaji.shuffle(_rng);
    final opts = [correct, allRomaji[0], allRomaji[1], allRomaji[2]];
    opts.shuffle(_rng);
    return opts;
  }

  void _answer(String romaji) {
    setState(() {
      _selectedAnswer = romaji;
      _showingResult = true;
      _isCorrect = romaji == _currentKana.romaji;
      if (_isCorrect) {
        _correct++;
      } else {
        _wrong++;
      }
    });
  }

  void _next() {
    if (_current >= _deck.length - 1) {
      // Quiz complete
      _restart();
      return;
    }
    setState(() {
      _current++;
      _selectedAnswer = null;
      _showingResult = false;
    });
  }

  void _restart() {
    setState(() {
      _deck.shuffle(_rng);
      _current = 0;
      _correct = 0;
      _wrong = 0;
      _selectedAnswer = null;
      _showingResult = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final kana = _currentKana;
    final options = _options;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kana Quiz'),
      ),
      body: Stack(
        children: [
          // Kanji watermark — the current character
          Positioned(
            right: -60,
            bottom: 40,
            child: IgnorePointer(
              child: Text(
                kana.character,
                style: TextStyle(
                  fontSize: 380,
                  fontWeight: FontWeight.w300,
                  color: SakuraColors.bamboo.withOpacity(0.4),
                  height: 1,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              SakuraSpace.l, SakuraSpace.l, SakuraSpace.l, SakuraSpace.l,
            ),
            child: Column(
              children: [
                // Score row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ScoreChip(
                      icon: Icons.check_rounded,
                      count: _correct,
                      color: SakuraColors.matcha,
                    ),
                    const SizedBox(width: SakuraSpace.s),
                    _ScoreChip(
                      icon: Icons.remove_rounded,
                      count: _current + 1,
                      label: 'of ${_deck.length}',
                      color: SakuraColors.mist,
                    ),
                    const SizedBox(width: SakuraSpace.s),
                    _ScoreChip(
                      icon: Icons.close_rounded,
                      count: _wrong,
                      color: SakuraColors.sakura,
                    ),
                  ],
                ),
                const SizedBox(height: SakuraSpace.xl),

                // The kana question
                Text(
                  'What is the romaji for',
                  style: SakuraType.body(color: SakuraColors.mist, size: 15),
                ),
                const SizedBox(height: SakuraSpace.m),
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: SakuraColors.white,
                    borderRadius: const BorderRadius.all(SakuraRadius.l),
                    border: Border.all(color: SakuraColors.bamboo),
                  ),
                  child: Center(
                    child: Text(
                      kana.character,
                      style: SakuraType.kana(size: 80, color: SakuraColors.sumi),
                    ),
                  ),
                ),
                const SizedBox(height: SakuraSpace.xl),

                // Options
                ...options.map((opt) {
                  Color? bg;
                  Color? borderColor;
                  Color? fg;
                  if (_showingResult && opt == _selectedAnswer) {
                    bg = _isCorrect
                        ? SakuraColors.matcha.withOpacity(0.12)
                        : SakuraColors.sakura.withOpacity(0.10);
                    borderColor = _isCorrect
                        ? SakuraColors.matcha
                        : SakuraColors.sakura;
                    fg = _isCorrect
                        ? SakuraColors.matcha
                        : SakuraColors.sakura;
                  } else if (_showingResult && opt == kana.romaji) {
                    bg = SakuraColors.matcha.withOpacity(0.08);
                    borderColor = SakuraColors.matcha.withOpacity(0.5);
                  } else {
                    bg = SakuraColors.white;
                    borderColor = SakuraColors.bamboo;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: SakuraSpace.s),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Material(
                        color: bg,
                        borderRadius: const BorderRadius.all(SakuraRadius.m),
                        child: InkWell(
                          borderRadius: const BorderRadius.all(SakuraRadius.m),
                          onTap: _showingResult ? null : () => _answer(opt),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(SakuraRadius.m),
                              border: Border.all(color: borderColor, width: 1.2),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              opt,
                              style: SakuraType.title(
                                size: 17,
                                color: fg ?? SakuraColors.sumi,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),

                // Result / Next
                if (_showingResult)
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isCorrect
                                ? Icons.check_circle_rounded
                                : Icons.info_outline_rounded,
                            color: _isCorrect
                                ? SakuraColors.matcha
                                : SakuraColors.sakura,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isCorrect
                                ? 'Correct'
                                : 'The answer is ${kana.romaji}',
                            style: SakuraType.title(
                              size: 15,
                              color: _isCorrect
                                  ? SakuraColors.matcha
                                  : SakuraColors.sakura,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: SakuraSpace.m),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SakuraColors.sumi,
                            foregroundColor: SakuraColors.washi,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(SakuraRadius.m),
                            ),
                          ),
                          child: Text(
                            _current >= _deck.length - 1 ? 'Restart' : 'Next',
                            style: SakuraType.label(
                              size: 14, color: SakuraColors.washi,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final String? label;
  final Color color;

  const _ScoreChip({
    required this.icon,
    required this.count,
    required this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SakuraSpace.s + 4, vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: const BorderRadius.all(SakuraRadius.pill),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label == null ? '$count' : '$count $label',
            style: SakuraType.label(color: color, size: 12)
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
