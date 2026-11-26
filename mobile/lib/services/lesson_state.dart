/// Lesson state management with Provider.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/tutor_response.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/offline_outbox.dart';
import '../services/tts_disk_cache.dart';

/// P1: how the last send failed, so the UI can offer the right action
/// (paywall for quota, retry for transient, queued-hint for offline).
enum LessonFailure { none, quota, ipCap, offline, transient }

class LessonState extends ChangeNotifier {
  final AudioService audio = AudioService();

  List<ChatMessage> messages = [];
  bool isLoading = false;
  bool isRecording = false;
  String? error;
  UsageInfo? usage;
  String currentLevel = 'N5';

  /// P1: set when the last failure was quota-related → lesson screen
  /// navigates to the Pro paywall instead of a dead-end error toast.
  LessonFailure lastFailure = LessonFailure.none;

  /// P1: queued-but-unsent count for the "N messages waiting" banner.
  int queuedCount = 0;

  LessonState() {
    _refreshQueuedCount();
  }

  Future<void> _refreshQueuedCount() async {
    try {
      queuedCount = (await OfflineOutbox.pending()).length;
      notifyListeners();
    } catch (_) {}
  }

  /// Send text message to the tutor.
  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;
    messages.add(ChatMessage.user(text));
    notifyListeners();

    await _callApi(message: text);
  }

  /// Record and send audio to the tutor.
  Future<void> startRecording() async {
    // First request permission — on first launch this shows the system dialog
    // without recording anything. Only starts recording after permission granted.
    final hasPerm = await audio.hasPermission();
    if (!hasPerm) {
      error = 'Microphone access is needed for voice input. Please allow in Settings.';
      notifyListeners();
      return;
    }
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
    lastFailure = LessonFailure.none;
    notifyListeners();

    try {
      final resp = await ApiService.chat(
        message: message ?? '[audio]',
        level: currentLevel,
        audioBase64: audioBase64,
      );

      messages.add(ChatMessage.fromResponse(resp.response, resp.audioUrl));
      usage = resp.usage;
      // Emission succeeded — try flushing anything queued during the outage.
      unawaitedFlush();
    } catch (e) {
      final s = e.toString();
      if (s.contains('daily_limit_reached')) {
        lastFailure = LessonFailure.quota;
        error = 'You\'ve used all your free lessons for today. Upgrade to Pro!';
      } else if (s.contains('ip_daily_limit_reached')) {
        lastFailure = LessonFailure.ipCap;
        error = 'Too many requests from this device today. Please try again tomorrow.';
      } else if (s.contains('too_many_tokens')) {
        lastFailure = LessonFailure.transient;
        error = 'Too many sign-ins from this device. Please try again later.';
      } else if (s.contains('internal_error')) {
        // P0: never surface server internals — generic message only.
        lastFailure = LessonFailure.transient;
        error = 'Server error. Please try again.';
      } else if (s.contains('ai_service_error')) {
        lastFailure = LessonFailure.transient;
        error = 'AI service is temporarily unavailable. Please try again in a moment.';
      } else if (s.contains('SocketException') ||
          s.contains('HandshakeException') ||
          s.contains('ClientException') ||
          s.contains('TimeoutException') ||
          s.contains('Failed host lookup')) {
        // P1: likely offline — queue text sends so nothing is lost.
        lastFailure = LessonFailure.offline;
        final queued = await OfflineOutbox.enqueue(
          message: message ?? '[audio]',
          level: currentLevel,
          audioBase64: message != null ? null : audioBase64,
        );
        await _refreshQueuedCount();
        error = queued
            ? 'You seem offline — message queued, will send when reconnected.'
            : 'You seem offline — queue is full, please retry when reconnected.';
      } else {
        lastFailure = LessonFailure.transient;
        final msg = s;
        error = 'Something went wrong: ${msg.length > 120 ? '${msg.substring(0, 120)}...' : msg}';
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

  /// P1: replay queued messages in order after connectivity returns.
  /// Fire-and-forget from success paths and app resume; never throws.
  Future<void> unawaitedFlush() async {
    try {
      // Drain the queue head-first: each iteration re-reads pending so
      // removeAt(0) index shifts can't desync us. Stop on first failure.
      for (;;) {
        final pending = await OfflineOutbox.pending();
        if (pending.isEmpty) break;
        final m = pending.first;
        try {
          final resp = await ApiService.chat(
            message: m.message,
            level: m.level,
            audioBase64: m.audioBase64,
          );
          messages.add(ChatMessage.fromResponse(resp.response, resp.audioUrl));
          usage = resp.usage;
          await OfflineOutbox.removeAt(0);
        } catch (_) {
          // Still offline or backend still down — stop, keep the rest.
          break;
        }
      }
      await _refreshQueuedCount();
      notifyListeners();
    } catch (_) {}
  }

  /// P1: warm the disk cache for the latest assistant audio so replay
  /// is instant even on flaky networks.
  Future<void> prefetchLatestAudio() async {
    try {
      for (final m in messages.reversed.take(3)) {
        final url = m.audioUrl;
        if (url != null && !url.startsWith('data:')) {
          await TtsDiskCache.resolve(url);
        }
      }
      await TtsDiskCache.prune();
    } catch (_) {}
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
