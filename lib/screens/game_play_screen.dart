import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';
import '../game/antigravity_game.dart';

class GamePlayScreen extends StatefulWidget {
  const GamePlayScreen({super.key, required this.gameController, required this.levelId});

  final GameController gameController;
  final int levelId;

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  late final AntigravityGame _game;

  @override
  void initState() {
    super.initState();
    _game = AntigravityGame(gameController: widget.gameController, levelId: widget.levelId);
  }

  @override
  void dispose() {
    _game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          top: true,
          bottom: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final hudHeight = constraints.maxHeight * 0.18;
              return Stack(
                children: [
                  GameWidget(
                    game: _game,
                    overlayBuilderMap: {
                      'pause': (context, game) => const _PauseOverlay(),
                      'levelComplete': (context, game) => const _LevelCompleteOverlay(),
                    },
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: hudHeight,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xCC101B3C), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    bottom: 18,
                    child: _MovementControls(game: _game),
                  ),
                  Positioned(
                    right: 18,
                    bottom: 18,
                    child: _ActionControls(game: _game),
                  ),
                  Positioned(
                    right: 18,
                    top: 18,
                    child: IconButton(
                      onPressed: _game.togglePause,
                      icon: const Icon(Icons.pause_rounded),
                      style: IconButton.styleFrom(backgroundColor: Colors.black54),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MovementControls extends StatelessWidget {
  const _MovementControls({required this.game});

  final AntigravityGame game;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TouchButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onPressed: () => game.setInput(left: true),
          onReleased: () => game.setInput(left: false),
        ),
        const SizedBox(width: 12),
        _TouchButton(
          icon: Icons.arrow_forward_ios_rounded,
          onPressed: () => game.setInput(right: true),
          onReleased: () => game.setInput(right: false),
        ),
      ],
    );
  }
}

class _ActionControls extends StatelessWidget {
  const _ActionControls({required this.game});

  final AntigravityGame game;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TouchButton(
          icon: Icons.keyboard_double_arrow_up_rounded,
          onPressed: () => game.setInput(jump: true),
          onReleased: () => game.setInput(jump: false),
          size: 72,
        ),
        const SizedBox(width: 12),
        _TouchButton(
          icon: Icons.rotate_right_rounded,
          onPressed: () => game.setInput(roll: true),
          onReleased: () => game.setInput(roll: false),
          size: 64,
        ),
      ],
    );
  }
}

class _TouchButton extends StatelessWidget {
  const _TouchButton({
    required this.icon,
    required this.onPressed,
    required this.onReleased,
    this.size = 64,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final VoidCallback onReleased;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onPressed(),
      onPointerUp: (_) => onReleased(),
      onPointerCancel: (_) => onReleased(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xB31B1F2E),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30, width: 2),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.46),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xCC101B3C),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paused', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Resume'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCompleteOverlay extends StatelessWidget {
  const _LevelCompleteOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xCC101B3C),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Color(0xFFF6C453)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Level Complete!', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('The realm is safe again.', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Main Menu'),
            ),
          ],
        ),
      ),
    );
  }
}
