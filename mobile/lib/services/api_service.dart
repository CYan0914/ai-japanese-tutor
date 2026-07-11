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
    final token = await ensureToken();

    final body = <String, dynamic>{
      'message': message,
      'level': level,
    };
    if (audioBase64 != null) {
      body['audio'] = audioBase64;
    }

    final resp = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (resp.statusCode == 429) {
      throw Exception('daily_limit_reached');
    }
    if (resp.statusCode != 200) {
      throw Exception('Chat API error: ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return ChatResponse.fromJson(data);
  }
}
