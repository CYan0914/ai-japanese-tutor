/// Sakura AI Tutor — Entry Point.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/lesson_state.dart';
import 'services/kana_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
