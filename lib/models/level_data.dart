class LevelData {
  const LevelData({
    required this.id,
    required this.name,
    required this.unlocked,
    required this.coinTarget,
    required this.worldWidth,
    required this.groundHeight,
  });

  final int id;
  final String name;
  final bool unlocked;
  final int coinTarget;
  final double worldWidth;
  final double groundHeight;
}

const List<LevelData> levels = [
  LevelData(
    id: 1,
    name: 'Forest Run',
    unlocked: true,
    coinTarget: 15,
    worldWidth: 5400,
    groundHeight: 96,
  ),
  LevelData(id: 2, name: 'Crystal Cliffs', unlocked: false, coinTarget: 18, worldWidth: 5800, groundHeight: 96),
  LevelData(id: 3, name: 'Sunken Ruins', unlocked: false, coinTarget: 22, worldWidth: 6600, groundHeight: 96),
  LevelData(id: 4, name: 'Gold Caves', unlocked: false, coinTarget: 25, worldWidth: 7000, groundHeight: 96),
  LevelData(id: 5, name: 'Sky Bastion', unlocked: false, coinTarget: 30, worldWidth: 7600, groundHeight: 96),
];
