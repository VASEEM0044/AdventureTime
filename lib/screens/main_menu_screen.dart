import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';
import 'level_select_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key, this.gameController});

  final GameController? gameController;

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  late GameController _gameController;
  bool _musicEnabled = true;

  @override
  void initState() {
    super.initState();
    _gameController = widget.gameController ?? GameController();
    _musicEnabled = _gameController.currentSettings.musicEnabled;
  }

  Future<void> _openHelp() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Play'),
        content: const SingleChildScrollView(
          child: Text(
            'Movement: Use A/D or the left/right buttons.\n\n'
            'Jump: Tap the jump button or press Space/W.\n\n'
            'Roll: Use the action button to roll through hazards.\n\n'
            'Collectibles: Coins increase your score. Fruits grant temporary immunity.\n\n'
            'Enemies: Jump on a slime to defeat it. Side contact reduces health.\n\n'
            'Goal: Reach the finish and collect as many coins as possible.',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmExit() async {
    final navigator = Navigator.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Game?'),
        content: const Text('Return to the home screen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Exit')),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;
      navigator.pop();
    }
  }

  void _toggleMusic() {
    setState(() {
      _musicEnabled = !_musicEnabled;
    });
    _gameController.updateSettings(
      _gameController.currentSettings.copyWith(musicEnabled: _musicEnabled),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF101B3C), Color(0xFF183A30)],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          tooltip: _musicEnabled ? 'Mute music' : 'Enable music',
                          onPressed: _toggleMusic,
                          icon: Icon(_musicEnabled ? Icons.volume_up : Icons.volume_off),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'ANTIGRAVITY',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Knight of the Floating Realm',
                        style: TextStyle(color: Color(0xFFBDE7D1), fontSize: 16),
                      ),
                      const SizedBox(height: 26),
                      _MenuButton(
                        icon: Icons.play_arrow_rounded,
                        label: 'Play',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LevelSelectScreen(gameController: _gameController),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _MenuButton(
                        icon: Icons.help_outline_rounded,
                        label: 'Help',
                        onPressed: _openHelp,
                      ),
                      const SizedBox(height: 14),
                      _MenuButton(
                        icon: Icons.exit_to_app_rounded,
                        label: 'Exit',
                        color: Colors.redAccent,
                        onPressed: _confirmExit,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white24, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Color(0x66000000), blurRadius: 32, offset: Offset(0, 12)),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.image_not_supported_outlined, size: 120, color: Colors.white38),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = const Color(0xFFF6C453),
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
