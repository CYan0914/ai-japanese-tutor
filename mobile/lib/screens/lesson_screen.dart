/// Lesson Screen — the core chat UI.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../services/lesson_state.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/record_button.dart';
import '../widgets/pronunciation_card.dart';
import '../widgets/correction_tile.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTextMode = true;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    final state = context.read<LessonState>();
    await state.sendText(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sakura Sensei'),
        centerTitle: true,
        backgroundColor: Colors.pink.shade50,
        foregroundColor: Colors.pink.shade800,
        actions: [
          Consumer<LessonState>(
            builder: (_, state, __) {
              final remaining = state.usage?.lessonsRemaining;
              final tier = state.usage?.tier;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Chip(
                  label: Text(
                    tier == 'pro'
                        ? 'Unlimited'
                        : '${remaining ?? 5} left',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: tier == 'pro'
                      ? Colors.amber.shade100
                      : Colors.grey.shade100,
                  visualDensity: VisualDensity.compact,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: Consumer<LessonState>(
              builder: (_, state, __) {
                if (state.error != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.error!),
                        backgroundColor: Colors.orange,
                        action: SnackBarAction(
                          label: 'OK',
                          onPressed: () => state.clearError(),
                        ),
                      ),
                    );
                  });
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == state.messages.length && state.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final msg = state.messages[i];
                    return _buildMessage(msg);
                  },
                );
              },
            ),
          ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            child: Row(
              children: [
                // Mode toggle
                IconButton(
                  icon: Icon(
                    _isTextMode ? Icons.mic : Icons.keyboard,
                    color: Colors.pink.shade300,
                  ),
                  onPressed: () => setState(() => _isTextMode = !_isTextMode),
                  tooltip: _isTextMode ? 'Switch to voice' : 'Switch to text',
                ),

                // Text input or record button
                Expanded(
                  child: _isTextMode ? _buildTextField() : _buildRecordButton(),
                ),

                if (_isTextMode)
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.pink),
                    onPressed: _sendText,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _textController,
      decoration: const InputDecoration(
        hintText: 'Ask Sakura a question...',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => _sendText(),
      maxLines: 1,
    );
  }

  Widget _buildRecordButton() {
    return Consumer<LessonState>(
      builder: (_, state, __) => RecordButton(
        isRecording: state.isRecording,
        onStart: () => state.startRecording(),
        onStop: () {
          state.stopAndSend();
          _scrollToBottom();
        },
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: ChatBubble(
          text: msg.text,
          isUser: true,
          localAudioPath: msg.localAudioPath,
          onPlayLocalAudio: msg.hasLocalAudio
              ? () async {
                  final state = context.read<LessonState>();
                  await state.audio.playFile(msg.localAudioPath!);
                }
              : null,
          timestamp: msg.timestamp,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChatBubble(
          text: msg.text,
          isUser: false,
          japanesePhrase: msg.japanesePhrase,
          romaji: msg.romaji,
          pronunciationTips: msg.pronunciationTips,
          audioUrl: msg.audioUrl,
          onPlayAudio: msg.audioUrl != null
              ? () async {
                  final state = context.read<LessonState>();
                  await state.audio.playUrl(msg.audioUrl!);
                }
              : null,
          timestamp: msg.timestamp,
        ),
        if (msg.pronunciationScore != null)
          PronunciationCard(score: msg.pronunciationScore!),
        if (msg.corrections.isNotEmpty)
          ...msg.corrections.map((c) => CorrectionTile(correction: c)),
        if (msg.encouragement != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Row(
              children: [
                const Text('🌟', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    msg.encouragement!,
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
