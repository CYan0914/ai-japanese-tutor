/// Kana learning progress — persisted via SharedPreferences.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kana.dart';

enum MasteryLevel { unseen, learning, familiar, mastered }

class KanaState extends ChangeNotifier {
  final Map<String, MasteryLevel> _progress = {};
  KanaType _currentType = KanaType.hiragana;

  KanaType get currentType => _currentType;
  int get totalCount => 46;
  int get masteredCount => _progress.values.where((l) => l == MasteryLevel.mastered).length;
  int get unseenCount => _progress.values.where((l) => l == MasteryLevel.unseen).length;

  /// Get level for a specific kana (by romaji key).
  MasteryLevel levelFor(String romaji) =>
      _progress[romaji] ?? MasteryLevel.unseen;

  /// Call when user marks a kana as known or writes it successfully.
  void mark(String romaji, MasteryLevel level) {
    _progress[romaji] = level;
    _save();
    notifyListeners();
  }

  /// Toggle view between hiragana and katakana.
  void setType(KanaType type) {
    _currentType = type;
    notifyListeners();
  }

  /// Reset all progress (e.g., for katakana after hiragana).
  void resetAll() {
    _progress.clear();
    _save();
    notifyListeners();
  }

  // ── Persistence ──

  static const _key = 'kana_progress';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _progress.clear();
    for (final e in map.entries) {
      _progress[e.key] = MasteryLevel.values[e.value as int];
    }
    notifyListeners();
  }

  void _save() {
    final map = _progress.map((k, v) => MapEntry(k, v.index));
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_key, jsonEncode(map));
    });
  }
}
