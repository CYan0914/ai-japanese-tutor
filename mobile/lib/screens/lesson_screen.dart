/// Lesson Screen — the core chat UI.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../config/tokens.dart';
import '../models/chat_message.dart';
import '../services/lesson_state.dart';
import '../services/subscription_service.dart';
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
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _checkPro();
  }

  Future<void> _checkPro() async {
    try {
      final pro = await SubscriptionService.isPro();
      if (mounted) setState(() => _isPro = pro);
    } catch (_) {}
  }

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('桜', style: TextStyle(color: SakuraColors.sakura, fontSize: 18)),
            const SizedBox(width: 8),
            Text('Sakura Tutor', style: SakuraType.title(size: 17)),
          ],
        ),
        actions: [
          Consumer<LessonState>(
            builder: (_, state, __) {
              final remaining = state.usage?.lessonsRemaining;
              final tier = state.usage?.tier;
              final isPro = tier == 'pro' || _isPro;
              return Padding(
                padding: const EdgeInsets.only(right: SakuraSpace.m),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPro ? SakuraColors.matcha : SakuraColors.washiDeep,
                      borderRadius: const BorderRadius.all(SakuraRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPro ? Icons.stars_rounded : Icons.menu_book_rounded,
                          size: 13,
                          color: isPro ? SakuraColors.washi : SakuraColors.sumi,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPro ? 'Pro' : '${remaining ?? AppConstants.freeDailyLimit}',
                          style: SakuraType.label(
                            color: isPro ? SakuraColors.washi : SakuraColors.sumi,
                            size: 11,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<LessonState>(
              builder: (_, state, __) {
                if (state.error != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.error!),
                        action: SnackBarAction(
                          label: 'OK',
                          onPressed: () => state.clearError(),
                          textColor: SakuraColors.sakura,
                        ),
                      ),
                    );
                  });
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(SakuraSpace.l),
                  itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == state.messages.length && state.isLoading) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: SakuraSpace.l),
                        child: Row(
                          children: [
                            Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                color: SakuraColors.sakuraSoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 12, height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: SakuraColors.sakura,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: SakuraSpace.s),
                            Text(
                              'Sakura is thinking...',
                              style: SakuraType.caption(),
                            ),
                          ],
                        ),
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
            decoration: const BoxDecoration(
              color: SakuraColors.white,
              border: Border(
                top: BorderSide(color: SakuraColors.bamboo, width: 1),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              SakuraSpace.m, SakuraSpace.s, SakuraSpace.m,
              MediaQuery.of(context).padding.bottom + SakuraSpace.s,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Mode toggle
                InkWell(
                  onTap: () => setState(() => _isTextMode = !_isTextMode),
                  borderRadius: const BorderRadius.all(SakuraRadius.pill),
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: _isTextMode ? SakuraColors.washiDeep : SakuraColors.sakura,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isTextMode ? Icons.mic_none_rounded : Icons.keyboard_alt_outlined,
                      color: _isTextMode ? SakuraColors.sumi : SakuraColors.washi,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: SakuraSpace.s),
                Expanded(
                  child: _isTextMode ? _buildTextField() : _buildRecordButton(),
                ),
                if (_isTextMode)
                  Padding(
                    padding: const EdgeInsets.only(left: SakuraSpace.s),
                    child: InkWell(
                      onTap: _sendText,
                      borderRadius: const BorderRadius.all(SakuraRadius.pill),
                      child: Container(
                        width: 42, height: 42,
                        decoration: const BoxDecoration(
                          color: SakuraColors.sumi,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          color: SakuraColors.washi,
                          size: 20,
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

  Widget _buildTextField() {
    return TextField(
      controller: _textController,
      style: SakuraType.body(size: 15),
      decoration: const InputDecoration(
        hintText: 'Ask Sakura anything...',
      ),
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => _sendText(),
      maxLines: 4,
      minLines: 1,
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
            padding: const EdgeInsets.only(left: 4, bottom: SakuraSpace.s, top: 2),
            child: Row(
              children: [
                const Text('✦', style: TextStyle(color: SakuraColors.sakura, fontSize: 12)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    msg.encouragement!,
                    style: SakuraType.caption(color: SakuraColors.sumi, size: 12)
                        .copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
