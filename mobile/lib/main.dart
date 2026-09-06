/// Sakura AI Tutor — Entry Point.
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'config/constants.dart';
import 'services/auth_state.dart';
import 'services/lesson_state.dart';
import 'services/kana_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch unhandled errors so the app doesn't crash on first launch
  FlutterError.onError = (details) {
    debugPrint('=== FLUTTER ERROR: ${details.exception} ===');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('=== PLATFORM ERROR: $error ===');
    return true; // Handled — don't crash
  };

  final kanaState = KanaState();
  kanaState.load(); // load persisted progress

  final auth = AuthState();
  // Restore persisted auth (token + user) so the user stays signed in.
  auth.bootstrap();

  // Warm GIDSignIn on iOS — the first call to signIn() after cold launch
  // can throw a native NSException inside the SDK before the Dart
  // signIn() future is even awaited, bypassing our try/catch and
  // crashing the app. signInSilently() forces GIDSignIn to do its
  // setup (keychain probe, GMS check) up front so the real sign-in
  // call later is on a warmed-up singleton.
  // Safe to ignore the result — we don't care if there's a signed-in
  // account or not, only that the SDK initialised without crashing.
  // Fire-and-forget; the splash screen shows while this runs.
  unawaited(
    GoogleSignIn(clientId: AppConstants.googleIosClientId).signInSilently(),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LessonState()),
        ChangeNotifierProvider.value(value: kanaState),
        ChangeNotifierProvider.value(value: auth),
      ],
      child: const SakuraApp(),
    ),
  );
}
