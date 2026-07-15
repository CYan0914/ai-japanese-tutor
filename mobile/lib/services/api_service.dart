/// HTTP client for the Sakura backend API.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/tutor_response.dart';

class ApiService {
  static const String _tokenKey = 'auth_token';

  // ── Token Management ──

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Get or create an auth token from the backend.
  static Future<String> ensureToken() async {
    final existing = await getToken();
    if (existing != null && existing.isNotEmpty) return existing;

    final resp = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/auth/token'),
      headers: {'Content-Type': 'application/json'},
      body: '{}',
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to get auth token: ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final token = data['token'] as String;
    await saveToken(token);
    return token;
  }

  // ── Chat ──

  /// Send a chat message to the AI tutor.
  static Future<ChatResponse> chat({
    required String message,
    String level = 'N5',
    String? audioBase64,
  }) async {
    return _postWithAuth(
      path: '/chat',
      body: {
        'message': message,
        'level': level,
        if (audioBase64 != null) 'audio': audioBase64,
      },
      fromJson: ChatResponse.fromJson,
    );
  }

  // ── TTS (for kana pronunciation etc.) ──

  /// Synthesize Japanese text to speech. Returns a data URI audio URL.
  static Future<String> tts(String text) async {
    final token = await ensureToken();
    final resp = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/tts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'text': text}),
    ).timeout(const Duration(seconds: 30));
    if (resp.statusCode != 200) throw Exception('TTS failed: ${resp.statusCode}');
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['audio_url'] as String;
  }

  // ── Core HTTP helper with auto-retry on 401 ──

  static Future<T> _postWithAuth<T>({
    required String path,
    required Map<String, dynamic> body,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final token = await ensureToken();

    Future<http.Response> doPost(String t) {
      return http.post(
        Uri.parse('${AppConstants.apiBaseUrl}$path'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $t',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 60));
    }

    var resp = await doPost(token);

    // Token expired (e.g. server restarted) — clear and retry once
    if (resp.statusCode == 401) {
      await clearToken();
      final newToken = await ensureToken();
      resp = await doPost(newToken);
    }

    if (resp.statusCode == 429) {
      throw Exception('daily_limit_reached');
    }
    if (resp.statusCode == 500) {
      // Try to extract debug info from response
      String debug = '';
      try {
        final errBody = jsonDecode(resp.body) as Map<String, dynamic>;
        debug = errBody['detail']?['debug'] ?? '';
      } catch (_) {}
      throw Exception('internal_error: $debug');
    }
    if (resp.statusCode == 502 || resp.statusCode == 503) {
      throw Exception('ai_service_error');
    }
    if (resp.statusCode != 200) {
      throw Exception('Chat API error: ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return fromJson(data);
  }

  // ── Subscription Sync ──

  /// Tell the backend the user's current subscription status.
  /// Called after every purchase or restore.
  static Future<void> syncSubscription({
    required String productId,
    required bool isPro,
  }) async {
    await _postWithAuth<void>(
      path: '/user/subscription',
      body: {'product_id': productId, 'is_pro': isPro},
      fromJson: (_) {},
    );
  }

  // ── Phoneme Profile ──

  static Future<PhonemeProfile> getPhonemeProfile() async {
    return _getWithAuth(
      path: '/user/phonemes',
      fromJson: PhonemeProfile.fromJson,
    );
  }

  static Future<T> _getWithAuth<T>({
    required String path,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final token = await ensureToken();

    Future<http.Response> doGet(String t) {
      return http.get(
        Uri.parse('${AppConstants.apiBaseUrl}$path'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $t',
        },
      ).timeout(const Duration(seconds: 30));
    }

    var resp = await doGet(token);

    if (resp.statusCode == 401) {
      await clearToken();
      final newToken = await ensureToken();
      resp = await doGet(newToken);
    }

    if (resp.statusCode != 200) {
      throw Exception('API error: ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return fromJson(data);
  }
}
