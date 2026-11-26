/// Offline outbox: queues chat messages when the network or backend is
/// down, then replays them in order when connectivity returns.
///
/// P1 traffic work: during an outage spike, failed sends used to vanish
/// (error text only). Now text messages persist to SharedPreferences and
/// auto-retry with exponential backoff, so a traffic surge degrades to
/// "delayed" instead of "lost".
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class QueuedMessage {
  final String message;
  final String level;
  final String? audioBase64;
  final int queuedAt;

  QueuedMessage({
    required this.message,
    required this.level,
    this.audioBase64,
    required this.queuedAt,
  });

  Map<String, dynamic> toJson() => {
        'message': message,
        'level': level,
        if (audioBase64 != null) 'audio': audioBase64,
        'queuedAt': queuedAt,
      };

  factory QueuedMessage.fromJson(Map<String, dynamic> json) => QueuedMessage(
        message: json['message'] as String? ?? '',
        level: json['level'] as String? ?? 'N5',
        audioBase64: json['audio'] as String?,
        queuedAt: json['queuedAt'] as int? ?? 0,
      );
}

class OfflineOutbox {
  static const String _key = 'sakura.offline_outbox';
  static const int maxItems = 20;

  /// Add a failed send to the queue. Returns false when the queue is full
  /// (oldest is kept, newest dropped — user sees a "queue full" hint).
  static Future<bool> enqueue({
    required String message,
    required String level,
    String? audioBase64,
  }) async {
    final items = await pending();
    if (items.length >= maxItems) return false;
    // Audio blobs are large — cap stored audio to keep prefs small.
    String? audio = audioBase64;
    if (audio != null && audio.length > 500 * 1024) audio = null;
    items.add(QueuedMessage(
      message: message,
      level: level,
      audioBase64: audio,
      queuedAt: DateTime.now().millisecondsSinceEpoch,
    ));
    await _save(items);
    return true;
  }

  static Future<List<QueuedMessage>> pending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => QueuedMessage.fromJson(e as Map<String, dynamic>))
          .where((m) => m.message.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> removeAt(int index) async {
    final items = await pending();
    if (index < 0 || index >= items.length) return;
    items.removeAt(index);
    await _save(items);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<void> _save(List<QueuedMessage> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((m) => m.toJson()).toList()),
    );
  }
}
