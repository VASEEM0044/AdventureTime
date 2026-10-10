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
        backgroundColor: const Color(0xFF0D1B2A),
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          top: true,
          bottom: true,
          child: Stack(
            children: [
              GameWidget(
                game: _game,
                loadingBuilder: (context) => const _GameLoadingScreen(),
                overlayBuilderMap: {
                  'pause': (context, game) => _PauseOverlay(game: _game),
                  'levelComplete': (context, game) => _LevelCompleteOverlay(game: _game),
                  'gameOver': (context, game) => _GameOverOverlay(game: _game),
                },
              ),

              // Top Heads-Up Display (HUD)
              Positioned(
                left: 16,
                right: 16,
                top: 10,
                child: _GameHud(game: _game),
              ),

              // Bottom Left: Movement Controls (Left / Right)
              Positioned(
                left: 20,
                bottom: 20,
                child: _MovementControls(game: _game),
              ),

              // Bottom Right: Action Controls (Jump / Roll)
              Positioned(
                right: 20,
                bottom: 20,
                child: _ActionControls(game: _game),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Seamless loading screen displayed while assets load to prevent black flashes
class _GameLoadingScreen extends StatelessWidget {
  const _GameLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF6C453)),
            ),
            SizedBox(height: 16),
            Text(
              'Entering Realm...',
              style: TextStyle(
                color: Color(0xFFBDE7D1),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Comprehensive Top HUD displaying Score, Coins collected, Lives/Hearts, and Immunity
class _GameHud extends StatelessWidget {
  const _GameHud({required this.game});

  final AntigravityGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xEE16223D), Color(0xDD0D1B2A)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x66F6C453), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Hearts / Lives
          ValueListenableBuilder<int>(
            valueListenable: game.health,
            builder: (context, health, _) {
              return Row(
                children: List.generate(5, (index) {
                  final isAlive = index < health;
                  return Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Icon(
                      isAlive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isAlive ? const Color(0xFFFF4757) : Colors.white30,
                      size: 24,
                    ),
                  );
                }),
              );
            },
          ),

          const SizedBox(width: 14),

          // Coins collected
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0x33F6C453),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x88F6C453)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD700), size: 20),
                const SizedBox(width: 5),
                ValueListenableBuilder<int>(
                  valueListenable: game.coinCount,
                  builder: (context, coins, _) {
                    return Text(
                      '$coins',
                      style: const TextStyle(
                        color: Color(0xFFFFEAA7),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Score badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0x334834D4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x88686DE0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.military_tech_rounded, color: Color(0xFFF9CA24), size: 20),
                const SizedBox(width: 4),
                ValueListenableBuilder<int>(
                  valueListenable: game.score,
                  builder: (context, score, _) {
                    return Text(
                      'SCORE: $score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.1,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Immunity active timer badge
          ValueListenableBuilder<bool>(
            valueListenable: game.immunity,
            builder: (context, isImmune, _) {
              if (!isImmune) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0x4400E5FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF00E5FF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_rounded, color: Color(0xFF00E5FF), size: 16),
                      const SizedBox(width: 4),
                      ValueListenableBuilder<double>(
                        valueListenable: game.immunityTimer,
                        builder: (context, timer, _) {
                          return Text(
                            'IMMUNE ${timer.toInt()}s',
                            style: const TextStyle(
                              color: Color(0xFF7AF0FF),
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const Spacer(),

          // Restart level button
          _TopBarIconButton(
            icon: Icons.replay_rounded,
            tooltip: 'Restart Level',
            color: const Color(0xFFE67E22),
            onPressed: game.restartLevel,
          ),

          const SizedBox(width: 8),

          // Pause button
          _TopBarIconButton(
            icon: Icons.pause_rounded,
            tooltip: 'Pause',
            color: const Color(0xFFF1C40F),
            onPressed: game.togglePause,
          ),
        ],
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 1.2),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

/// Themed Movement Controls (Left / Right)
class _MovementControls extends StatelessWidget {
  const _MovementControls({required this.game});

  final AntigravityGame game;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FantasyControlButton(
          icon: Icons.arrow_back_rounded,
          label: 'LEFT',
          color: const Color(0xFF3498DB),
          onPressed: () => game.setLeft(true),
          onReleased: () => game.setLeft(false),
        ),
        const SizedBox(width: 16),
        _FantasyControlButton(
          icon: Icons.arrow_forward_rounded,
          label: 'RIGHT',
          color: const Color(0xFF3498DB),
          onPressed: () => game.setRight(true),
          onReleased: () => game.setRight(false),
        ),
      ],
    );
  }
}

/// Themed Action Controls (Jump / Roll)
class _ActionControls extends StatelessWidget {
  const _ActionControls({required this.game});

  final AntigravityGame game;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Roll / Down action button
        _FantasyControlButton(
          icon: Icons.cyclone_rounded,
          label: 'ROLL',
          color: const Color(0xFFE67E22),
          size: 64,
          onPressed: () => game.setRoll(true),
          onReleased: () => game.setRoll(false),
        ),
        const SizedBox(width: 16),
        // Jump / Up button
        _FantasyControlButton(
          icon: Icons.arrow_upward_rounded,
          label: 'JUMP',
          color: const Color(0xFF2ECC71),
          size: 72,
          onPressed: () => game.setJump(true),
          onReleased: () => game.setJump(false),
        ),
      ],
    );
  }
}

/// Themed Touch Button with fantasy borders, gradient styling, and haptic feel
class _FantasyControlButton extends StatefulWidget {
  const _FantasyControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    required this.onReleased,
    this.size = 64,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final VoidCallback onReleased;
  final double size;

  @override
  State<_FantasyControlButton> createState() => _FantasyControlButtonState();
}

class _FantasyControlButtonState extends State<_FantasyControlButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color;

    return Listener(
      onPointerDown: (_) {
        setState(() => _isPressed = true);
        widget.onPressed();
      },
      onPointerUp: (_) {
        setState(() => _isPressed = false);
        widget.onReleased();
      },
      onPointerCancel: (_) {
        setState(() => _isPressed = false);
        widget.onReleased();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _isPressed ? effectiveColor.withValues(alpha: 0.8) : const Color(0xEE1A253F),
                _isPressed ? effectiveColor.withValues(alpha: 0.5) : const Color(0xDD0D1629),
              ],
            ),
            border: Border.all(
              color: _isPressed ? Colors.white : effectiveColor.withValues(alpha: 0.8),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: effectiveColor.withValues(alpha: _isPressed ? 0.7 : 0.35),
                blurRadius: _isPressed ? 18 : 10,
                spreadRadius: _isPressed ? 2 : 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: _isPressed ? Colors.white : effectiveColor,
                size: widget.size * 0.42,
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: TextStyle(
                  color: _isPressed ? Colors.white : Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stylized Pause Overlay
class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.game});

  final AntigravityGame game;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF0162544), Color(0xF00D1B2A)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF6C453), width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x99000000), blurRadius: 28, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pause_circle_filled_rounded, size: 54, color: Color(0xFFF6C453)),
            const SizedBox(height: 10),
            const Text(
              'GAME PAUSED',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
            ),
            const SizedBox(height: 24),
            // Resume
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: game.togglePause,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Resume', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            // Restart
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF6C453),
                  side: const BorderSide(color: Color(0xFFF6C453)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: game.restartLevel,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Restart Level', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            // Quit
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white60,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.exit_to_app_rounded),
                label: const Text('Quit to Levels'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stylized Game Over Overlay (same pattern as pause/victory; restart or quit)
class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({required this.game});

  final AntigravityGame game;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF0441A2B), Color(0xF00D1B2A)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFF4757), width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x99000000), blurRadius: 28, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.heart_broken_rounded, size: 54, color: Color(0xFFFF4757)),
            const SizedBox(height: 10),
            const Text(
              'GAME OVER',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              'Score: ${game.score.value}  •  Coins: ${game.coinCount.value}',
              style: const TextStyle(color: Color(0xFFBDE7D1), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // Retry
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: game.restartLevel,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            // Quit
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white60,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.exit_to_app_rounded),
                label: const Text('Quit to Levels'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stylized Level Complete Overlay
class _LevelCompleteOverlay extends StatelessWidget {
  const _LevelCompleteOverlay({required this.game});

  final AntigravityGame game;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF0183A30), Color(0xF00D1B2A)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF2ECC71), width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x99000000), blurRadius: 28, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, size: 64, color: Color(0xFFFFD700)),
            const SizedBox(height: 10),
            const Text(
              'VICTORY!',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              'Final Score: ${game.score.value}  •  Coins: ${game.coinCount.value}',
              style: const TextStyle(color: Color(0xFFBDE7D1), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

