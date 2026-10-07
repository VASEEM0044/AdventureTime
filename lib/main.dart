import 'dart:async';

import 'package:flutter/material.dart';

import 'controllers/game_controller.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final gameController = GameController();
  runApp(AntigravityApp(gameController: gameController));
}

class AntigravityApp extends StatefulWidget {
  const AntigravityApp({super.key, GameController? gameController})
      : _gameController = gameController;

  final GameController? _gameController;

  @override
  State<AntigravityApp> createState() => _AntigravityAppState();
}

class _AntigravityAppState extends State<AntigravityApp> {
  late final GameController _gameController;

  @override
  void initState() {
    super.initState();
    _gameController = widget._gameController ?? GameController();
    unawaited(_gameController.initializeAudio());
  }

  @override
  void dispose() {
    _gameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Antigravity Platformer',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF6C453),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF101B3C),
      ),
      home: const SplashScreen(),
    );
  }
}
