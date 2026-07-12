/// Chat message model for the conversation UI.
import 'tutor_response.dart';

enum MessageRole { user, assistant, system }

class ChatMessage {
  final MessageRole role;
  final String text;
  final String? japanesePhrase;
  final String? romaji;
  final String? pronunciationTips;
  final Evaluation? evaluation;
  final List<Correction> corrections;
  final String? encouragement;
  final PronunciationScore? pronunciationScore;
  final String? audioUrl;
  final String? localAudioPath; // path to user's own recording for playback
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.text,
    this.japanesePhrase,
    this.romaji,
    this.pronunciationTips,
    this.evaluation,
    this.corrections = const [],
    this.encouragement,
    this.pronunciationScore,
    this.audioUrl,
    this.localAudioPath,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == MessageRole.user;
  bool get hasLocalAudio => localAudioPath != null && localAudioPath!.isNotEmpty;

  static ChatMessage user(String text, {String? audioPath}) {
    return ChatMessage(
      role: MessageRole.user,
      text: text,
      localAudioPath: audioPath,
    );
  }

  factory ChatMessage.fromResponse(TutorResponse resp, String? audioUrl) {
    return ChatMessage(
      role: MessageRole.assistant,
      text: resp.yourMessage,
      japanesePhrase: resp.japanesePhrase.isNotEmpty ? resp.japanesePhrase : null,
      romaji: resp.romaji.isNotEmpty ? resp.romaji : null,
      pronunciationTips: resp.pronunciationTips.isNotEmpty ? resp.pronunciationTips : null,
      evaluation: resp.evaluation,
      corrections: resp.corrections,
      encouragement: resp.encouragement.isNotEmpty ? resp.encouragement : null,
      audioUrl: audioUrl,
    );
  }
}
