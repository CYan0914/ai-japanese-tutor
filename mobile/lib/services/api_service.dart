/// HTTP client for the Sakura backend API.
///
/// Token resolution: AuthState.token → /auth/token (anonymous).
/// Once the user signs in via the Account tab, AuthState.token is set and
/// all subsequent calls use that token. The anonymous bootstrap token is
/// replaced the first time the user signs in (the backend issues a fresh
/// bearer for each identity).
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/tutor_response.dart';
import 'auth_state.dart';

/// P1: which failures are worth retrying with backoff.
/// 429/5xx + network blips yes; 401 no (token flow handles it); 400 no.
bool _isRetryable(Object e, {int? statusCode}) {
  if (statusCode != null) {
    return statusCode == 429 || statusCode >= 500;
  }
  final s = e.toString();
  return s.contains('SocketException') ||
      s.contains('HandshakeException') ||
      s.contains('ClientException') ||
      s.contains('TimeoutException') ||
      s.contains('ai_service_error') ||
      s.contains('internal_error') ||
      s.contains('TTS failed');
}

/// P1: exponential backoff with jitter: 1s, 2s, 4s (+0-500ms jitter).
Future<T> _withRetry<T>(
  Future<T> Function() fn, {
  int maxAttempts = 3,
  Future<void> Function(int attempt)? onRetry,
}) async {
  Object? lastError;
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (e) {
      lastError = e;
      // Never retry quota errors — waiting won't refill the daily limit,
      // and hammering just burns the per-IP cap for no reason.
      final s = e.toString();
      if (s.contains('daily_limit_reached') ||
          s.contains('ip_daily_limit_reached') ||
          s.contains('too_many_tokens')) {
        rethrow;
      }
      if (attempt >= maxAttempts || !_isRetryable(e)) rethrow;
      if (onRetry != null) await onRetry(attempt);
      final delayMs = (1000 << (attempt - 1)) +
          (DateTime.now().millisecond % 500);
      await Future.delayed(Duration(milliseconds: delayMs));
    }
  }
  throw lastError ?? Exception('Request failed');
}

class ApiService {
  static const String _tokenKey = 'auth.token';

  // ── Token Management ──

  static Future<String?> getToken() async {
    final auth = AuthState.instance;
    if (auth != null && auth.token != null && auth.token!.isNotEmpty) {
      return auth.token;
    }
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
    final auth = AuthState.instance;
    if (auth != null && auth.token != null && auth.token!.isNotEmpty) {
      return auth.token!;
    }
    final existing = await getToken();
    if (existing != null && existing.isNotEmpty) {
      // Mirror into AuthState so the UI can see the user is "signed in"
      // (we may not have provider info; that's fine — AccountScreen
      // shows "signed in" only when isSignedIn is true).
      if (auth != null && auth.token == null) {
        auth.setAnonymousToken(existing);
      }
      return existing;
    }

    final resp = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/auth/token'),
      headers: {'Content-Type': 'application/json'},
      body: '{}',
    );
    if (resp.statusCode == 429) {
      throw Exception('too_many_tokens');
    }
    if (resp.statusCode != 200) {
      throw Exception('Failed to get auth token: ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final token = data['token'] as String;
    await saveToken(token);
    if (auth != null) auth.setAnonymousToken(token);
    return token;
  }

  // ── Chat ──

  /// Send a chat message to the AI tutor.
  /// P1: transient failures (502/503/network blips) retry with backoff
  /// (1s/2s/4s + jitter, 3 attempts). Quota errors never retry.
  static Future<ChatResponse> chat({
    required String message,
    String level = 'N5',
    String? audioBase64,
  }) async {
    return _withRetry(() => _postWithAuth(
          path: '/chat',
          body: {
            'message': message,
            'level': level,
            if (audioBase64 != null) 'audio': audioBase64,
          },
          fromJson: ChatResponse.fromJson,
        ));
  }

  // ── TTS (for kana pronunciation etc.) ──

  /// Synthesize Japanese text to speech. Returns a cacheable https audio URL
  /// (P0: backend stopped inlining base64 data URIs). Retries transient
  /// failures the same way chat does.
  static Future<String> tts(String text) async {
    return _withRetry(() async {
      final token = await ensureToken();
      final resp = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/tts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'text': text}),
      ).timeout(const Duration(seconds: 30));
      if (resp.statusCode == 429 || resp.statusCode >= 500) {
        throw Exception('TTS failed: ${resp.statusCode}');
      }
      if (resp.statusCode != 200) throw Exception('TTS failed: ${resp.statusCode}');
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['audio_url'] as String;
    });
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
      // P0: distinguish per-user daily limit vs per-IP abuse cap so the
      // UI can show the right message (upgrade vs try-tomorrow).
      String code = 'daily_limit_reached';
      try {
        final errBody = jsonDecode(resp.body) as Map<String, dynamic>;
        final detail = errBody['detail'];
        final err = detail is Map ? detail['error']?.toString() : null;
        if (err == 'ip_daily_limit_reached') code = 'ip_daily_limit_reached';
      } catch (_) {}
      throw Exception(code);
    }
    if (resp.statusCode == 500) {
      // P0: server no longer sends debug internals — generic error only.
      throw Exception('internal_error');
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
