/// Learn screen — hiragana/katakana grid + progress.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/kana.dart';
import '../services/kana_state.dart';
import '../widgets/kana_tile.dart';
import 'kana_detail_screen.dart';
import 'quiz_screen.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Load persistence on first access
    final state = context.watch<KanaState>();

    if (state.totalCount == 46) {
      // trigger async load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.load();
      });
    }

    final grid = KanaData.buildGrid(state.currentType);
    final mn = state.currentType == KanaType.hiragana ? 'Hiragana' : 'Katakana';

    return Scaffold(
      appBar: AppBar(
        title: Text('Learn — $mn'),
        backgroundColor: Colors.pink.shade50,
        foregroundColor: Colors.pink.shade800,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress bar
          _buildProgress(state),
          // Toggle
          _buildToggle(state),
          // Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  // Column headers: a i u e o
                  _buildColumnHeaders(),
                  // Rows
                  Expanded(
                    child: _buildGrid(context, grid, state),
                  ),
                  // ん row
                  _buildNRow(state),
                ],
              ),
            ),
          ),
          // Quiz button
          _buildQuizButton(context, state),
        ],
      ),
    );
  }

  Widget _buildProgress(KanaState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.masteredCount} / ${state.totalCount}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${state.unseenCount} remaining',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.masteredCount / state.totalCount,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(KanaState state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _toggleChip('Hiragana', KanaType.hiragana, state),
          const SizedBox(width: 8),
          _toggleChip('Katakana', KanaType.katakana, state),
        ],
      ),
    );
  }

  Widget _toggleChip(String label, KanaType type, KanaState state) {
    final selected = state.currentType == type;
    return GestureDetector(
      onTap: () => state.setType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.pink.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.pink.shade800 : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildColumnHeaders() {
    const labels = ['a', 'i', 'u', 'e', 'o'];
    return Padding(
      padding: const EdgeInsets.only(left: 36, top: 8),
      child: Row(
        children: labels.map((l) {
          return Expanded(
            child: Center(
              child: Text(l, style: TextStyle(
                color: Colors.grey.shade500, fontSize: 12,
              )),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<List<Kana>> grid, KanaState state) {
    return ListView.builder(
      itemCount: grid.length,
      itemBuilder: (_, rowIdx) {
        // Row label
        const romajiLabels = ['a', 'ka', 'sa', 'ta', 'na', 'ha', 'ma', 'ya', 'ra', 'wa'];
        final row = grid[rowIdx];
        return Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                romajiLabels[rowIdx],
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 4),
            ...row.map((kana) {
              return Expanded(
                child: AspectRatio(
                  aspectRatio: 0.85,
                  child: KanaTile(
                    kana: kana,
                    level: kana.isGap ? MasteryLevel.unseen : state.levelFor(kana.romaji),
                    onTap: () {
                      if (!kana.isGap) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => KanaDetailScreen(
                            kana: kana,
                            level: state.levelFor(kana.romaji),
                          ),
                        ));
                      }
                    },
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildNRow(KanaState state) {
    final n = KanaData.n(state.currentType);
    return Padding(
      padding: const EdgeInsets.only(left: 36 + 4, right: 4, bottom: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'n',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: AspectRatio(
              aspectRatio: 1.7,
              child: KanaTile(
                kana: n,
                level: state.levelFor(n.romaji),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => KanaDetailScreen(
                      kana: n,
                      level: state.levelFor(n.romaji),
                    ),
                  ));
                },
              ),
            ),
          ),
          const Spacer(flex: 7),
        ],
      ),
    );
  }

  Widget _buildQuizButton(BuildContext context, KanaState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2),
        )],
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => QuizScreen(type: state.currentType),
          ));
        },
        icon: const Icon(Icons.quiz),
        label: const Text('Quiz Yourself'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink.shade400,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
