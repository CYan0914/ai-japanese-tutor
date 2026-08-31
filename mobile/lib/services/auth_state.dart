/// Auth state — wraps backend /auth/apple, /auth/google, /auth/email/*.
///
/// Persists token + user info via shared_preferences so the user stays
/// signed in across app restarts. Exposed as a ChangeNotifier so the UI
/// can react to sign-in / sign-out.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/constants.dart';

enum AuthProvider { apple, google, email, anonymous }

class AuthUser {
  final String userId;
  final String email;
  final AuthProvider provider;
  final bool isNewUser;

  const AuthUser({
    required this.userId,
    required this.email,
    required this.provider,
    this.isNewUser = false,
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'email': email,
        'provider': provider.name,
        'is_new_user': isNewUser,
      };

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        userId: (j['user_id'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        provider: AuthProvider.values.firstWhere(
          (p) => p.name == (j['provider'] ?? 'anonymous'),
          orElse: () => AuthProvider.anonymous,
        ),
        isNewUser: (j['is_new_user'] ?? false) as bool,
      );
}

class AuthState extends ChangeNotifier {
  static const String _kToken = 'auth.token';
  static const String _kUser = 'auth.user';

  /// Globally-accessible instance. api_service uses this when it needs to
  /// read the current token (because it lives outside the widget tree).
  static AuthState? _instance;
  static AuthState? get instance => _instance;

  String? _token;
  AuthUser? _user;
  bool _ready = false;
  bool _busy = false;
  String? _lastError;

  AuthState() {
    _instance = this;
  }

  String? get token => _token;
  AuthUser? get user => _user;
  bool get isReady => _ready;
  bool get isBusy => _busy;
  bool get isSignedIn => _token != null && _user != null;
  String? get lastError => _lastError;

  /// Load persisted auth on app start. Safe to call multiple times.
  Future<void> bootstrap() async {
    if (_ready) return;
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_kToken);
    final u = prefs.getString(_kUser);
    if (t != null && t.isNotEmpty) {
      _token = t;
    }
    if (u != null && u.isNotEmpty) {
      try {
        _user = AuthUser.fromJson(jsonDecode(u) as Map<String, dynamic>);
      } catch (_) {
        _user = null;
      }
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString(_kToken, _token!);
    } else {
      await prefs.remove(_kToken);
    }
    if (_user != null) {
      await prefs.setString(_kUser, jsonEncode(_user!.toJson()));
    } else {
      await prefs.remove(_kUser);
    }
  }

  /// Set the in-memory user (used by the anonymous-token bootstrap path so
  /// ApiService can still call the backend). Does NOT mark the user as
  /// "signed in" for the UI.
  void setAnonymousToken(String token) {
    _token = token;
    _user = const AuthUser(
      userId: 'anonymous',
      email: '',
      provider: AuthProvider.anonymous,
    );
    notifyListeners();
  }

  // ── Sign-in flows ──

  Future<bool> signInWithApple() async {
    _setBusy(true, null);
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email],
      );
      final resp = await _post(
        '/auth/apple',
        {'id_token': credential.identityToken ?? ''},
      );
      return _onAuthResponse(resp);
    } catch (e) {
      _setBusy(false, 'Apple sign-in failed: $e');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setBusy(true, null);
    try {
      final google = GoogleSignIn(
        scopes: const ['email'],
        // clientId omitted — google_sign_in will read it from
        // GoogleService-Info.plist on iOS.
      );
      final account = await google.signIn();
      if (account == null) {
        _setBusy(false, 'Google sign-in cancelled');
        return false;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        _setBusy(false, 'Google returned no ID token');
        return false;
      }
      final resp = await _post('/auth/google', {'id_token': idToken});
      return _onAuthResponse(resp);
    } catch (e) {
      _setBusy(false, 'Google sign-in failed: $e');
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setBusy(true, null);
    try {
      final resp = await _post('/auth/email/signup', {
        'email': email,
        'password': password,
        if (displayName != null && displayName.isNotEmpty)
          'display_name': displayName,
      });
      return _onAuthResponse(resp);
    } catch (e) {
      _setBusy(false, 'Sign-up failed: $e');
      return false;
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setBusy(true, null);
    try {
      final resp = await _post('/auth/email/login', {
        'email': email,
        'password': password,
      });
      return _onAuthResponse(resp);
    } catch (e) {
      _setBusy(false, 'Sign-in failed: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    _token = null;
    _user = null;
    await _persist();
    notifyListeners();
  }

  // ── internals ──

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final resp = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 20));
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode != 200) {
      final detail = (data['detail'] ?? 'HTTP ${resp.statusCode}').toString();
      throw Exception(detail);
    }
    return data;
  }

  bool _onAuthResponse(Map<String, dynamic> data) {
    final token = (data['token'] ?? '') as String;
    if (token.isEmpty) {
      _setBusy(false, 'Server returned no token');
      return false;
    }
    _token = token;
    _user = AuthUser.fromJson({
      'user_id': data['user_id'] ?? '',
      'email': data['email'] ?? '',
      'provider': data['provider'] ?? 'anonymous',
      'is_new_user': data['is_new_user'] ?? false,
    });
    _lastError = null;
    _busy = false;
    _persist();
    notifyListeners();
    return true;
  }

  void _setBusy(bool busy, String? err) {
    _busy = busy;
    _lastError = err;
    notifyListeners();
  }
}
