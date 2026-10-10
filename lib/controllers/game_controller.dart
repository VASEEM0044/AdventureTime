import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

import '../models/game_settings.dart';

class GameController {
  GameController() {
    _subscription = _settingsController.stream.listen(_handleSettingsChange);
  }

  final StreamController<GameSettings> _settingsController =
      StreamController<GameSettings>.broadcast();

  late final StreamSubscription<GameSettings> _subscription;

  GameSettings _settings = GameSettings();
  bool _musicStarted = false;

  Stream<GameSettings> get settings => _settingsController.stream;
  GameSettings get currentSettings => _settings;

  void updateSettings(GameSettings settings) {
    _settings = settings;
    _settingsController.add(settings);
  }

  Future<void> initializeAudio() async {
    await FlameAudio.bgm.initialize();
    if (_settings.musicEnabled && !_musicStarted) {
      await playMusic();
    }
  }

  Future<void> playMusic() async {
    if (!_settings.musicEnabled) return;
    if (_musicStarted) return;

    await FlameAudio.bgm.play('bgm.mp3', volume: 0.45);
    _musicStarted = true;
  }

  Future<void> stopMusic() async {
    await FlameAudio.bgm.stop();
    _musicStarted = false;
  }

  Future<void> playSfx(String asset) async {
    if (!_settings.soundsEnabled) return;
    await FlameAudio.play(asset, volume: 0.9);
  }

  void _handleSettingsChange(GameSettings settings) {
    if (!settings.musicEnabled) {
      unawaited(stopMusic());
      return;
    }

    if (!_musicStarted) {
      unawaited(playMusic());
    }
  }

  void dispose() {
    _subscription.cancel();
    _settingsController.close();
    FlameAudio.bgm.stop();
  }
}
