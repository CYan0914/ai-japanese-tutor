/// Chat bubble widget — user and AI messages.
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? japanesePhrase;
  final String? romaji;
  final String? pronunciationTips;
  final String? audioUrl;
  final VoidCallback? onPlayAudio;
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
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final color = isUser ? Colors.pink : Colors.grey.shade100;
    final textColor = isUser ? Colors.white : Colors.black87;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Japanese phrase (if AI)
                if (japanesePhrase != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      japanesePhrase!,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (romaji != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      romaji!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isUser ? Colors.white70 : Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                // Main text
                Text(
                  text,
                  style: TextStyle(fontSize: 15, color: textColor),
                ),

                // Pronunciation tips
                if (pronunciationTips != null && pronunciationTips!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.white.withOpacity(0.15)
                            : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('💡', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              pronunciationTips!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isUser ? Colors.white : Colors.brown.shade700,
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

          // Play audio button
          if (onPlayAudio != null && audioUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: GestureDetector(
                onTap: onPlayAudio,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_up, size: 14, color: Colors.pink.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Listen',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.pink.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
