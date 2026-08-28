/// Chat bubble — user and AI messages, with refined typography.
import 'package:flutter/material.dart';
import '../config/tokens.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? japanesePhrase;
  final String? romaji;
  final String? pronunciationTips;
  final String? audioUrl;
  final VoidCallback? onPlayAudio;
  final String? localAudioPath;
  final VoidCallback? onPlayLocalAudio;
  final DateTime? timestamp;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.japanesePhrase,
    this.romaji,
    this.pronunciationTips,
    this.audioUrl,
    this.onPlayAudio,
    this.localAudioPath,
    this.onPlayLocalAudio,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SakuraSpace.m),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender label (only for AI)
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                'SAKURA',
                style: SakuraType.caption(size: 10).copyWith(
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
                  color: SakuraColors.sakura,
                ),
              ),
            ),

          // Bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            decoration: BoxDecoration(
              color: isUser ? SakuraColors.sumi : SakuraColors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              border: isUser
                  ? null
                  : Border.all(color: SakuraColors.bamboo),
            ),
            padding: const EdgeInsets.all(SakuraSpace.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (japanesePhrase != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      japanesePhrase!,
                      style: SakuraType.japanese(
                        color: isUser ? SakuraColors.washi : SakuraColors.sumi,
                        size: 22,
                      ),
                    ),
                  ),
                if (romaji != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      romaji!,
                      style: SakuraType.caption(
                        color: isUser
                            ? SakuraColors.washi.withOpacity(0.7)
                            : SakuraColors.mist,
                        size: 13,
                      ).copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                Text(
                  text,
                  style: SakuraType.body(
                    color: isUser ? SakuraColors.washi : SakuraColors.sumi,
                    size: 15,
                  ),
                ),
                if (pronunciationTips != null && pronunciationTips!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: SakuraSpace.s),
                    child: Container(
                      padding: const EdgeInsets.all(SakuraSpace.s + 2),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.white.withOpacity(0.08)
                            : SakuraColors.washiDeep,
                        borderRadius: const BorderRadius.all(SakuraRadius.s),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '◇',
                            style: SakuraType.label(
                              color: isUser ? SakuraColors.washi : SakuraColors.sakura,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              pronunciationTips!,
                              style: SakuraType.body(
                                color: isUser
                                    ? SakuraColors.washi.withOpacity(0.85)
                                    : SakuraColors.sumi,
                                size: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // TTS playback (AI)
          if (onPlayAudio != null && audioUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: _ListenChip(
                icon: Icons.volume_up_rounded,
                label: 'Listen',
                onTap: onPlayAudio!,
              ),
            ),

          // User's own voice playback
          if (onPlayLocalAudio != null && localAudioPath != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: _ListenChip(
                icon: Icons.play_arrow_rounded,
                label: 'My voice',
                onTap: onPlayLocalAudio!,
                isUserChip: true,
              ),
            ),
        ],
      ),
    );
  }
}

class _ListenChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isUserChip;
  const _ListenChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isUserChip = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(SakuraRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isUserChip
              ? SakuraColors.washiDeep
              : SakuraColors.sakuraSoft,
          borderRadius: const BorderRadius.all(SakuraRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: isUserChip ? SakuraColors.sumi : SakuraColors.sakura),
            const SizedBox(width: 4),
            Text(
              label,
              style: SakuraType.label(
                color: isUserChip ? SakuraColors.sumi : SakuraColors.sakura,
                size: 11,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
