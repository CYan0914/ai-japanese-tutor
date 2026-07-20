/// Sakura AI Tutor — Entry Point.
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LessonState()),
        ChangeNotifierProvider.value(value: kanaState),
      ],
      child: const SakuraApp(),
    ),
  );
}
