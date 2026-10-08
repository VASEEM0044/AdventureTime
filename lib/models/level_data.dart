import 'package:flutter/material.dart';

class LevelData {
  const LevelData({
    required this.id,
    required this.name,
    required this.unlocked,
    required this.coinTarget,
    required this.worldWidth,
    required this.groundHeight,
    required this.themeName,
    required this.themeColors,
    required this.icon,
    this.difficulty = 'Normal',
  });

  final int id;
  final String name;
  final bool unlocked;
  final int coinTarget;
  final double worldWidth;
  final double groundHeight;
  final String themeName;
  final List<Color> themeColors;
  final IconData icon;
  final String difficulty;
}

const List<LevelData> levels = [
  LevelData(
    id: 1,
    name: 'Forest Run',
    unlocked: true,
    coinTarget: 15,
    worldWidth: 5400,
    groundHeight: 96,
    themeName: 'Emerald Woods',
    themeColors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
    icon: Icons.forest_rounded,
    difficulty: 'Easy',
  ),
  LevelData(
    id: 2,
    name: 'Crystal Cliffs',
    unlocked: false,
    coinTarget: 18,
    worldWidth: 5800,
    groundHeight: 96,
    themeName: 'Glacial Ridge',
    themeColors: [Color(0xFF0277BD), Color(0xFF0097A7), Color(0xFF26C6DA)],
    icon: Icons.diamond_rounded,
    difficulty: 'Medium',
  ),
  LevelData(
    id: 3,
    name: 'Sunken Ruins',
    unlocked: false,
    coinTarget: 22,
    worldWidth: 6600,
    groundHeight: 96,
    themeName: 'Ancient Depths',
    themeColors: [Color(0xFF004D40), Color(0xFF00796B), Color(0xFF009688)],
    icon: Icons.temple_buddhist_rounded,
    difficulty: 'Hard',
  ),
  LevelData(
    id: 4,
    name: 'Gold Caves',
    unlocked: false,
    coinTarget: 25,
    worldWidth: 7000,
    groundHeight: 96,
    themeName: 'Molten Caverns',
    themeColors: [Color(0xFFBF360C), Color(0xFFD84315), Color(0xFFF57C00)],
    icon: Icons.monetization_on_rounded,
    difficulty: 'Expert',
  ),
  LevelData(
    id: 5,
    name: 'Sky Bastion',
    unlocked: false,
    coinTarget: 30,
    worldWidth: 7600,
    groundHeight: 96,
    themeName: 'Astral Citadel',
    themeColors: [Color(0xFF311B92), Color(0xFF512DA8), Color(0xFF7E57C2)],
    icon: Icons.castle_rounded,
    difficulty: 'Master',
  ),
];

