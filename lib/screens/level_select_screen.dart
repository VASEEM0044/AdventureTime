import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';
import '../models/level_data.dart';
import 'game_play_screen.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key, required this.gameController});

  final GameController gameController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF233267), Color(0xFF131F3D)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Select Level',
                      style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 240,
                      childAspectRatio: 0.82,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                    ),
                    itemCount: levels.length,
                    itemBuilder: (context, index) {
                      final level = levels[index];
                      final enabled = level.unlocked;

                      return Card(
                        color: enabled ? const Color(0xFF284A6D) : const Color(0xFF1F263E),
                        elevation: enabled ? 8 : 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: enabled
                              ? () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => GamePlayScreen(
                                        gameController: gameController,
                                        levelId: level.id,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (enabled)
                                      const Icon(Icons.check_circle_rounded, color: Color(0xFF89F0A0))
                                    else
                                      const Icon(Icons.lock_rounded, color: Colors.white54),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: enabled ? const Color(0xFF5BD590) : Colors.white12,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        enabled ? 'ACTIVE' : 'LOCKED',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  'Level ${level.id}',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  level.name,
                                  style: TextStyle(color: enabled ? Colors.white70 : Colors.white38),
                                ),
                                const SizedBox(height: 14),
                                const Row(
                                  children: [
                                    Icon(Icons.monetization_on_outlined, size: 16, color: Color(0xFFF6C453)),
                                    SizedBox(width: 4),
                                    Text('Target coins', style: TextStyle(color: Colors.white60)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
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
