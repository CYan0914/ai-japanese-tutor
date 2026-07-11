/// Quiz mode — shown kana, pick correct romaji.
import 'dart:math';
import 'package:flutter/material.dart';
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
    final total = _correct + _wrong;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kana Quiz'),
        backgroundColor: Colors.pink.shade50,
        foregroundColor: Colors.pink.shade800,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Score
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(label: Text('✅ $_correct'), backgroundColor: Colors.green.shade50),
                const SizedBox(width: 12),
                Chip(label: Text('${_current + 1}/${_deck.length}')),
                const SizedBox(width: 12),
                Chip(label: Text('❌ $_wrong'), backgroundColor: Colors.red.shade50),
              ],
            ),
            const SizedBox(height: 32),

            // The kana question
            Text(
              'What is the romaji for:',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  kana.character,
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Options
            ...options.map((opt) {
              Color? bg;
              if (_showingResult && opt == _selectedAnswer) {
                bg = _isCorrect ? Colors.green.shade100 : Colors.red.shade100;
              } else if (_showingResult && opt == kana.romaji) {
                bg = Colors.green.shade50;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _showingResult ? null : () => _answer(opt),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bg ?? Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                    ),
                    child: Text(opt, style: const TextStyle(fontSize: 18)),
                  ),
                ),
              );
            }),
            const Spacer(),

            // Result / Next
            if (_showingResult)
              Column(
                children: [
                  Text(
                    _isCorrect ? 'Correct! 🎉' : 'The answer is ${kana.romaji}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade400,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _current >= _deck.length - 1 ? 'Restart' : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
