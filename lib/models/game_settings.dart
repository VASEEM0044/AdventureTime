class GameSettings {
  GameSettings({this.musicEnabled = true, this.soundsEnabled = true});

  final bool musicEnabled;
  final bool soundsEnabled;

  GameSettings copyWith({bool? musicEnabled, bool? soundsEnabled}) {
    return GameSettings(
      musicEnabled: musicEnabled ?? this.musicEnabled,
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
    );
  }
}
