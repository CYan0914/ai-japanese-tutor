/// Sakura AI Tutor — Entry Point.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/lesson_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => LessonState(),
      child: const SakuraApp(),
    ),
  );
}
