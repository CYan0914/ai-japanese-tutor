/// Learn screen — gojuuon grid + progress.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/tokens.dart';
import '../models/kana.dart';
import '../services/kana_state.dart';
import '../widgets/kana_tile.dart';
import 'kana_detail_screen.dart';
import 'quiz_screen.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<KanaState>();

    if (state.totalCount == 46) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.load();
      });
    }

    final grid = KanaData.buildGrid(state.currentType);
    final mn = state.currentType == KanaType.hiragana ? 'Hiragana' : 'Katakana';
    final script = state.currentType == KanaType.hiragana ? 'ひらがな' : 'カタカナ';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SakuraSpace.l, SakuraSpace.l, SakuraSpace.l, SakuraSpace.s,
              ),
              child: Row(
                children: [
                  Text('Learn', style: SakuraType.title(size: 18)),
                  const Spacer(),
                  Text(
                    '${state.masteredCount} / ${state.totalCount}',
                    style: SakuraType.label(size: 12, color: SakuraColors.mist),
                  ),
                ],
              ),
            ),

            // Hero section: script name + progress
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SakuraSpace.l, SakuraSpace.s, SakuraSpace.l, SakuraSpace.m,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(script, style: SakuraType.japanese(
                    color: SakuraColors.sakura, size: 14,
                  )),
                  const SizedBox(height: 4),
                  Text(mn, style: SakuraType.display(size: 28)),
                  const SizedBox(height: SakuraSpace.m),
                  // Slim progress bar
                  ClipRRect(
                    borderRadius: const BorderRadius.all(SakuraRadius.pill),
                    child: LinearProgressIndicator(
                      value: state.masteredCount / state.totalCount,
                      minHeight: 4,
                      backgroundColor: SakuraColors.bamboo,
                      color: SakuraColors.sakura,
                    ),
                  ),
                ],
              ),
            ),

            // Toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SakuraSpace.l, SakuraSpace.m, SakuraSpace.l, SakuraSpace.s,
              ),
              child: Row(
                children: [
                  _toggleChip('Hiragana', KanaType.hiragana, state),
                  const SizedBox(width: SakuraSpace.s),
                  _toggleChip('Katakana', KanaType.katakana, state),
                ],
              ),
            ),

            // Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    _buildColumnHeaders(),
                    Expanded(child: _buildGrid(context, grid, state)),
                    _buildNRow(state, context),
                  ],
                ),
              ),
            ),

            // Quiz button
            Container(
              decoration: const BoxDecoration(
                color: SakuraColors.white,
                border: Border(
                  top: BorderSide(color: SakuraColors.bamboo, width: 1),
                ),
              ),
              padding: const EdgeInsets.all(SakuraSpace.m),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => QuizScreen(type: state.currentType),
                    ));
                  },
                  icon: const Icon(Icons.quiz_outlined, size: 18),
                  label: Text('Quiz yourself',
                    style: SakuraType.label(size: 15, color: Colors.white).copyWith(
                      fontWeight: FontWeight.w600, letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleChip(String label, KanaType type, KanaState state) {
    final selected = state.currentType == type;
    return GestureDetector(
      onTap: () => state.setType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: SakuraSpace.m, vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected ? SakuraColors.sumi : SakuraColors.white,
          borderRadius: const BorderRadius.all(SakuraRadius.pill),
          border: Border.all(
            color: selected ? SakuraColors.sumi : SakuraColors.bamboo,
          ),
        ),
        child: Text(
          label,
          style: SakuraType.label(
            color: selected ? SakuraColors.washi : SakuraColors.mist,
            size: 13,
          ).copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildColumnHeaders() {
    const labels = ['a', 'i', 'u', 'e', 'o'];
    return Padding(
      padding: const EdgeInsets.only(left: 36, top: 4, bottom: 4),
      child: Row(
        children: labels.map((l) {
          return Expanded(
            child: Center(
              child: Text(
                l,
                style: SakuraType.caption(size: 11, color: SakuraColors.stone),
              ),
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
        const romajiLabels = ['a', 'ka', 'sa', 'ta', 'na', 'ha', 'ma', 'ya', 'ra', 'wa'];
        final row = grid[rowIdx];
        return Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                romajiLabels[rowIdx],
                style: SakuraType.caption(size: 11, color: SakuraColors.stone),
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

  Widget _buildNRow(KanaState state, BuildContext context) {
    final n = KanaData.n(state.currentType);
    return Padding(
      padding: const EdgeInsets.only(left: 40, right: 4, bottom: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'n',
              style: SakuraType.caption(size: 11, color: SakuraColors.stone),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: AspectRatio(
              aspectRatio: 1.7,
              child: Builder(
                builder: (ctx) => KanaTile(
                  kana: n,
                  level: state.levelFor(n.romaji),
                  onTap: () {
                    Navigator.of(ctx).push(MaterialPageRoute(
                      builder: (_) => KanaDetailScreen(
                        kana: n,
                        level: state.levelFor(n.romaji),
                      ),
                    ));
                  },
                ),
              ),
            ),
          ),
          const Spacer(flex: 7),
        ],
      ),
    );
  }
}
