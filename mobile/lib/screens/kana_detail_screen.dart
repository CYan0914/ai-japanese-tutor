/// Single kana detail — large display, listen to pronunciation, practice, mark progress.
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final kana = widget.kana;
    final level = widget.level;
    return Scaffold(
      appBar: AppBar(
        title: Text(kana.character),
        backgroundColor: Colors.pink.shade50,
        foregroundColor: Colors.pink.shade800,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large kana display with speaker icon overlay
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: _levelColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _levelColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      kana.character,
                      style: const TextStyle(
                        fontSize: 88,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Speaker icon button at bottom-right of the kana card
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Material(
                    color: Colors.pink.shade100.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _isPlaying ? null : _playPronunciation,
                      child: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        child: _isPlaying
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.pink.shade800,
                                ),
                              )
                            : Icon(
                                Icons.volume_up,
                                color: Colors.pink.shade800,
                                size: 24,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Romaji
            Text(
              kana.romaji,
              style: TextStyle(
                fontSize: 32,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 8),

            // Status chip
            _buildStatusChip(),
            const SizedBox(height: 32),

            // Practice writing button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => WritingScreen(kana: kana),
                  ));
                },
                icon: const Icon(Icons.draw),
                label: const Text('Practice Writing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Mark as known button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  final state = context.read<KanaState>();
                  if (level == MasteryLevel.mastered) {
                    state.mark(kana.romaji, MasteryLevel.familiar);
                  } else {
                    state.mark(kana.romaji, MasteryLevel.mastered);
                  }
                  Navigator.of(context).pop();
                },
                icon: Icon(level == MasteryLevel.mastered
                    ? Icons.undo : Icons.check_circle),
                label: Text(level == MasteryLevel.mastered
                    ? 'Mark as Not Mastered' : 'I Know This Kana'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: level == MasteryLevel.mastered
                      ? Colors.grey : Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    String label;
    IconData icon;
    Color color;
    switch (widget.level) {
      case MasteryLevel.unseen:
        label = 'New';
        icon = Icons.circle_outlined;
        color = Colors.grey;
      case MasteryLevel.learning:
        label = 'Learning';
        icon = Icons.school;
        color = Colors.orange;
      case MasteryLevel.familiar:
        label = 'Familiar';
        icon = Icons.star_half;
        color = Colors.amber;
      case MasteryLevel.mastered:
        label = 'Mastered';
        icon = Icons.star;
        color = Colors.green;
    }
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  Color get _levelColor {
    switch (widget.level) {
      case MasteryLevel.unseen: return Colors.grey;
      case MasteryLevel.learning: return Colors.orange;
      case MasteryLevel.familiar: return Colors.amber;
      case MasteryLevel.mastered: return Colors.green;
    }
  }
}
