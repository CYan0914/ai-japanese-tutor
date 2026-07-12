/// Lesson state management with Provider.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/tutor_response.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';

class LessonState extends ChangeNotifier {
  final AudioService audio = AudioService();

  List<ChatMessage> messages = [];
  bool isLoading = false;
  bool isRecording = false;
  String? error;
  UsageInfo? usage;
  String currentLevel = 'N5';

  /// Send text message to the tutor.
  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;
    messages.add(ChatMessage.user(text));
    notifyListeners();

    await _callApi(message: text);
  }

  /// Record and send audio to the tutor.
  Future<void> startRecording() async {
    try {
      isRecording = true;
      notifyListeners();
      await audio.startRecording();
    } catch (e) {
      error = 'Failed to start recording: $e';
      isRecording = false;
      notifyListeners();
    }
  }

  Future<void> stopAndSend() async {
    if (!isRecording) return;
    isRecording = false;
    notifyListeners();

    try {
      final bytes = await audio.stopRecording();
      if (bytes == null || bytes.isEmpty) {
        error = 'No audio captured';
        notifyListeners();
        return;
      }

      // Save recording to temp file so user can play it back
      final dir = Directory.systemTemp;
      final localPath = '${dir.path}/sakura_myrec_${DateTime.now().millisecondsSinceEpoch}.wav';
      await File(localPath).writeAsBytes(bytes);

      // Show user message with local audio path
      final b64 = base64Encode(bytes);
      messages.add(ChatMessage.user('[Audio recording]', audioPath: localPath));
      notifyListeners();

      await _callApi(audioBase64: b64);
    } catch (e) {
      error = 'Recording failed: $e';
      notifyListeners();
    }
  }

  /// Core API call.
  Future<void> _callApi({String? message, String? audioBase64}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final resp = await ApiService.chat(
        message: message ?? '[audio]',
        level: currentLevel,
        audioBase64: audioBase64,
      );

      messages.add(ChatMessage.fromResponse(resp.response, resp.audioUrl));
      usage = resp.usage;
    } catch (e) {
      if (e.toString().contains('daily_limit_reached')) {
        error = 'You\'ve used all your free lessons for today. Upgrade to Pro!';
      } else if (e.toString().contains('ai_service_error')) {
        error = 'AI service is temporarily unavailable. Please try again in a moment.';
      } else {
        // Show actual error so we can debug. For production, replace with generic message.
        final msg = e.toString();
        if (msg.contains('SocketException') || msg.contains('HandshakeException')) {
          error = 'Cannot connect to server. Check your internet connection.';
        } else if (msg.contains('timeout') || msg.contains('TimeoutException')) {
          error = 'Request timed out. Please try again.';
        } else {
          error = 'Something went wrong: ${msg.length > 120 ? '${msg.substring(0, 120)}...' : msg}';
        }
      }
    }

    isLoading = false;
    notifyListeners();

    // Auto-play TTS audio if available
    final lastMsg = messages.isNotEmpty ? messages.last : null;
    if (lastMsg?.audioUrl != null) {
      try {
        await audio.playUrl(lastMsg!.audioUrl!);
      } catch (_) {}
    }
  }

  void setLevel(String level) {
    currentLevel = level;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    audio.dispose();
    super.dispose();
  }
}
