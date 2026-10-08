import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';
import '../models/level_data.dart';
import 'game_play_screen.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key, required this.gameController});

  final GameController gameController;

  void _launchLevel(BuildContext context, LevelData level) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) => GamePlayScreen(
          gameController: gameController,
          levelId: level.id,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B2A), Color(0xFF162544), Color(0xFF0E1E38)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        tooltip: 'Back to Menu',
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SELECT REALM',
                          style: TextStyle(
                            color: Color(0xFFF6C453),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'Choose Your Quest',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Level Cards Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(bottom: 12),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      childAspectRatio: 0.78,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                    ),
                    itemCount: levels.length,
                    itemBuilder: (context, index) {
                      final level = levels[index];
                      final enabled = level.unlocked;

                      return _LevelCard(
                        level: level,
                        enabled: enabled,
                        onTap: enabled ? () => _launchLevel(context, level) : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.enabled,
    required this.onTap,
  });

  final LevelData level;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141F36),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: enabled ? level.themeColors.first.withValues(alpha: 0.8) : Colors.white12,
          width: enabled ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: enabled ? level.themeColors.first.withValues(alpha: 0.3) : const Color(0x33000000),
            blurRadius: enabled ? 16 : 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Banner Thumbnail
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: enabled
                            ? level.themeColors
                            : const [Color(0xFF2C3440), Color(0xFF1C222C)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Watermark background icon
                        Positioned(
                          right: -10,
                          bottom: -10,
                          child: Icon(
                            level.icon,
                            size: 88,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        // Badges top row
                        Positioned(
                          top: 10,
                          left: 10,
                          right: 10,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Difficulty badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  level.difficulty.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              // Unlocked / Locked badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: enabled ? const Color(0xFF2ECC71) : Colors.black45,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      enabled ? Icons.check_circle_rounded : Icons.lock_rounded,
                                      size: 11,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      enabled ? 'ACTIVE' : 'LOCKED',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Center Theme Emblem
                        Center(
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black26,
                              border: Border.all(
                                color: enabled ? Colors.white70 : Colors.white24,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              level.icon,
                              color: enabled ? const Color(0xFFF6C453) : Colors.white38,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom Content
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LEVEL ${level.id}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: enabled ? const Color(0xFFF6C453) : Colors.white38,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          level.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: enabled ? Colors.white : Colors.white38,
                          ),
                        ),
                        Text(
                          level.themeName,
                          style: TextStyle(
                            fontSize: 11,
                            color: enabled ? Colors.white60 : Colors.white24,
                          ),
                        ),
                        const Spacer(),
                        // Target coins / Action strip
                        Row(
                          children: [
                            const Icon(
                              Icons.monetization_on_rounded,
                              size: 15,
                              color: Color(0xFFFFD700),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Target: ${level.coinTarget}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: enabled ? const Color(0xFFFFEAA7) : Colors.white30,
                              ),
                            ),
                            const Spacer(),
                            if (enabled)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2ECC71),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  children: [
                                    Text(
                                      'PLAY',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                                    ),
                                    SizedBox(width: 2),
                                    Icon(Icons.play_arrow_rounded, size: 14, color: Colors.white),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

