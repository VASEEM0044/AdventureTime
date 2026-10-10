import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../components/collectibles.dart';
import '../components/enemies.dart';
import '../components/knight.dart';
import '../components/platforms.dart';
import '../components/tileset_decor.dart';
import '../controllers/game_controller.dart';
import 'sprite_atlas.dart';

class BackgroundComponent extends PositionComponent {
  BackgroundComponent({required super.size}) : super(priority: -10);

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();

    // Atmospheric fantasy sky gradient
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF0D1B2A), // Midnight navy
        Color(0xFF1B263B), // Indigo dusk
        Color(0xFF2C3E50), // Slate mist
        Color(0xFF1E3A2F), // Forest canopy horizon
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = skyGradient.createShader(rect));

    // Distant mountain silhouettes
    final mountainPaint = Paint()..color = const Color(0x33102422);
    final mountainPath = Path();
    mountainPath.moveTo(0, size.y - 180);
    for (double x = 0; x <= size.x; x += 120) {
      final peakY = size.y - 260 - (math.sin(x * 0.005) * 60) - (math.cos(x * 0.015) * 35);
      mountainPath.lineTo(x, peakY);
    }
    mountainPath.lineTo(size.x, size.y);
    mountainPath.lineTo(0, size.y);
    mountainPath.close();
    canvas.drawPath(mountainPath, mountainPaint);

    // Midground treeline silhouettes
    final treelinePaint = Paint()..color = const Color(0x4D0C2219);
    final treelinePath = Path();
    treelinePath.moveTo(0, size.y - 120);
    for (double x = 0; x <= size.x; x += 50) {
      final treeTop = size.y - 170 - (math.sin(x * 0.02) * 25);
      treelinePath.lineTo(x, treeTop);
    }
    treelinePath.lineTo(size.x, size.y);
    treelinePath.lineTo(0, size.y);
    treelinePath.close();
    canvas.drawPath(treelinePath, treelinePaint);

    // Floating fantasy clouds
    final cloudPaint = Paint()
      ..color = const Color(0x1AFFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    for (double cx = 100; cx < size.x; cx += 520) {
      final cy = 120.0 + (math.sin(cx) * 50);
      canvas.drawOval(Rect.fromLTWH(cx, cy, 220, 50), cloudPaint);
    }
  }
}

class AntigravityGame extends FlameGame with HasCollisionDetection {
  AntigravityGame({
    required this.gameController,
    required this.levelId,
  });

  final GameController gameController;
  final int levelId;

  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<int> coinCount = ValueNotifier<int>(0);
  final ValueNotifier<int> health = ValueNotifier<int>(5);
  final ValueNotifier<bool> immunity = ValueNotifier<bool>(false);
  final ValueNotifier<double> immunityTimer = ValueNotifier<double>(0);
  final ValueNotifier<bool> isPaused = ValueNotifier<bool>(false);
  final ValueNotifier<bool> levelComplete = ValueNotifier<bool>(false);

  late KnightComponent _player;
  late List<CoinComponent> _coins;
  late List<EnemyComponent> _enemies;
  late List<FruitComponent> _fruits;
  late List<PlatformComponent> _platforms;
  late World _gameWorld;

  final double _worldWidth = 5400;
  final double _worldHeight = 900;
  final double _groundHeight = 96;

  bool _leftPressed = false;
  bool _rightPressed = false;
  bool _jumpPressed = false;
  bool _rollPressed = false;
  bool _gameOverShown = false;
  double _defeatElapsed = 0;

  @override
  Color backgroundColor() => const Color(0xFF0D1B2A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Configure Flame asset path directly to assets/ folder
    images.prefix = 'assets/';

    // Preload all game sprite assets once; components reuse the image
    // cache (no repeated texture loads during gameplay).
    await images.loadAll(SpriteFiles.all);

    _buildLevel();
  }

  void _buildLevel() {
    _gameWorld = World();
    add(_gameWorld);

    // Background
    _gameWorld.add(BackgroundComponent(size: Vector2(_worldWidth, _worldHeight)));

    // Ground platform
    final ground = PlatformComponent(
      id: 'ground',
      position: Vector2(0, _worldHeight - _groundHeight),
      size: Vector2(_worldWidth, _groundHeight),
      type: PlatformType.ground,
    );
    _gameWorld.add(ground);

    // Floating platforms (stored for one-way landing resolution).
    _platforms = <PlatformComponent>[
      PlatformComponent(id: 'p1', position: Vector2(520, 650), size: Vector2(180, 24), type: PlatformType.grass),
      PlatformComponent(id: 'p2', position: Vector2(820, 580), size: Vector2(180, 24), type: PlatformType.sand),
      PlatformComponent(id: 'p3', position: Vector2(1150, 510), size: Vector2(230, 24), type: PlatformType.ice),
      PlatformComponent(id: 'p4', position: Vector2(1550, 620), size: Vector2(180, 24), type: PlatformType.gold),
      PlatformComponent(id: 'p5', position: Vector2(1910, 540), size: Vector2(210, 24), type: PlatformType.grass),
      PlatformComponent(id: 'p6', position: Vector2(2320, 470), size: Vector2(170, 24), type: PlatformType.sand),
      PlatformComponent(id: 'p7', position: Vector2(2860, 610), size: Vector2(240, 24), type: PlatformType.ice),
      PlatformComponent(id: 'p8', position: Vector2(3340, 500), size: Vector2(220, 24), type: PlatformType.gold),
      PlatformComponent(id: 'p9', position: Vector2(3820, 430), size: Vector2(260, 24), type: PlatformType.grass),
      PlatformComponent(id: 'p10', position: Vector2(4280, 520), size: Vector2(190, 24), type: PlatformType.sand),
      PlatformComponent(id: 'p11', position: Vector2(4680, 620), size: Vector2(240, 24), type: PlatformType.gold),
    ];
    for (final platform in _platforms) {
      _gameWorld.add(platform);
    }

    _buildDecorations(_gameWorld);
    _buildTilesetDecor(_gameWorld);
    // Tileset grass edge sits on top of the procedural ground strip.
    _gameWorld.add(
      GroundTilesComponent(
        worldWidth: _worldWidth,
        groundY: _worldHeight - _groundHeight,
      ),
    );
    _coins = _buildCoins();
    _enemies = _buildEnemies();
    _fruits = _buildFruits();

    _player = KnightComponent(
        position: Vector2(90, _worldHeight - _groundHeight - 68));
    _gameWorld.add(_player);

    for (final coin in _coins) { _gameWorld.add(coin); }
    for (final enemy in _enemies) { _gameWorld.add(enemy); }
    for (final fruit in _fruits) { _gameWorld.add(fruit); }

    _player.onDamage = _handlePlayerDamage;
    _player.onDefeat = _handlePlayerDefeat;
    _player.onCollectedFruit = _handleFruitPickup;

    _configureCamera();
  }

  void _configureCamera() {
    camera.world = _gameWorld;
    camera.viewfinder.anchor = const Anchor(0.35, 0.65);
    camera.viewfinder.position = Vector2(
      _player.position.x,
      _player.position.y,
    );
    camera.follow(
      _player,
      horizontalOnly: true,
      maxSpeed: 600,
    );
  }

  void _buildDecorations(World world) {
    final decorations = <DecorationComponent>[
      DecorationComponent(position: Vector2(220, 674), size: Vector2(130, 130), variant: DecorationType.tree),
      DecorationComponent(position: Vector2(620, 714), size: Vector2(120, 90), variant: DecorationType.bush),
      DecorationComponent(position: Vector2(1090, 664), size: Vector2(130, 140), variant: DecorationType.tree),
      DecorationComponent(position: Vector2(1500, 724), size: Vector2(100, 80), variant: DecorationType.mushroom),
      DecorationComponent(position: Vector2(2030, 674), size: Vector2(130, 130), variant: DecorationType.tree),
      DecorationComponent(position: Vector2(2450, 714), size: Vector2(120, 90), variant: DecorationType.bush),
      DecorationComponent(position: Vector2(2980, 664), size: Vector2(140, 140), variant: DecorationType.tree),
      DecorationComponent(position: Vector2(3550, 724), size: Vector2(110, 80), variant: DecorationType.mushroom),
      DecorationComponent(position: Vector2(4140, 664), size: Vector2(120, 140), variant: DecorationType.tree),
      DecorationComponent(position: Vector2(4680, 714), size: Vector2(140, 90), variant: DecorationType.bush),
      DecorationComponent(position: Vector2(4880, 664), size: Vector2(130, 140), variant: DecorationType.tree),
    ];
    for (final decoration in decorations) {
      world.add(decoration);
    }
  }

  /// Tileset-sourced scenery from world_tileset.png (verified full-bleed
  /// 16px tiles). Placed on the ground clear of the procedural decor.
  void _buildTilesetDecor(World world) {
    final groundY = _worldHeight - _groundHeight;
    final tiles = <TilesetTileComponent>[
      // Tree: foliage over trunk (32x64).
      TilesetTileComponent(
          position: Vector2(870, groundY - 64), tileTopLeft: WorldTiles.treeTop),
      TilesetTileComponent(
          position: Vector2(870, groundY - 32),
          tileTopLeft: WorldTiles.treeTrunk),
      // Bush.
      TilesetTileComponent(
          position: Vector2(1420, groundY - 32), tileTopLeft: WorldTiles.bush),
      // Pillar: cap over shaft (32x64).
      TilesetTileComponent(
          position: Vector2(2600, groundY - 64),
          tileTopLeft: WorldTiles.pillarTop),
      TilesetTileComponent(
          position: Vector2(2600, groundY - 32), tileTopLeft: WorldTiles.pillar),
      // Bush + tree pair far right.
      TilesetTileComponent(
          position: Vector2(3700, groundY - 32), tileTopLeft: WorldTiles.bush),
      TilesetTileComponent(
          position: Vector2(4950, groundY - 64), tileTopLeft: WorldTiles.treeTop),
      TilesetTileComponent(
          position: Vector2(4950, groundY - 32),
          tileTopLeft: WorldTiles.treeTrunk),
    ];
    for (final tile in tiles) {
      world.add(tile);
    }
  }
  List<CoinComponent> _buildCoins() {
    final coins = <CoinComponent>[];
    final positions = [
      Vector2(300, 610), Vector2(420, 600), Vector2(620, 600), Vector2(870, 520), Vector2(1290, 455),
      Vector2(1660, 560), Vector2(1960, 480), Vector2(2400, 410), Vector2(2920, 540), Vector2(3400, 440),
      Vector2(3900, 365), Vector2(4370, 460), Vector2(4770, 560), Vector2(5050, 560),
    ];
    for (var i = 0; i < positions.length; i++) {
      coins.add(CoinComponent(position: positions[i]));
    }
    return coins;
  }

  List<EnemyComponent> _buildEnemies() {
    // Slimes render 48x48 (exact 2x of the 24px art). Ground foes sit on
    // the ground top (y=804); platform foes sit on their platform tops.
    // Each foe patrols a corridor inside its own area and turns at the
    // corridor ends, so it can never leave its platform.
    return [
      EnemyComponent(position: Vector2(930, 756), size: Vector2.all(48), color: const Color(0xFF99EB77), direction: 1, minX: 600, maxX: 1400),
      EnemyComponent(position: Vector2(1600, 572), size: Vector2.all(48), color: const Color(0xFFB29BFF), direction: 1, minX: 1560, maxX: 1680),
      EnemyComponent(position: Vector2(2600, 756), size: Vector2.all(48), color: const Color(0xFF99EB77), direction: -1, minX: 2300, maxX: 3000),
      EnemyComponent(position: Vector2(4350, 472), size: Vector2.all(48), color: const Color(0xFFB29BFF), direction: -1, minX: 4290, maxX: 4420),
    ];
  }

  List<FruitComponent> _buildFruits() {
    // One 16px sheet cell per fruit: green grapes, orange pear, red grapes.
    return [
      FruitComponent(position: Vector2(1420, 430), variant: 2),
      FruitComponent(position: Vector2(3060, 552), variant: 4),
      FruitComponent(position: Vector2(4980, 540), variant: 11),
    ];
  }

  @override
  void update(double dt) {
    // Pause and victory freeze the whole simulation: nothing below runs,
    // so enemies, physics, pickups, and the camera all stop together.
    if (isPaused.value || levelComplete.value) {
      return;
    }
    // Death freezes the world too, but the knight's defeat animation
    // keeps ticking; the game-over overlay follows after a beat.
    if (_player.isDefeated) {
      _player.updateDefeat(dt);
      _defeatElapsed += dt;
      if (_defeatElapsed >= 0.9 && !_gameOverShown) {
        _gameOverShown = true;
        overlays.add('gameOver');
      }
      return;
    }
    super.update(dt);

    _updateInput(dt);
    _resolvePlatformCollisions(dt);
    _updateImmunity(dt);
    _checkCoinPickup();
    _checkEnemyCollisions();
    _checkFruitPickup();
    _checkLevelComplete();
  }

  void _updateInput(double dt) {
    final moveAxis = ((_rightPressed ? 1 : 0) - (_leftPressed ? 1 : 0)).toDouble();
    _player.setInput(moveAxis, _jumpPressed, _rollPressed, dt);
  }

  /// One-way landing on floating platforms: when falling, if the player's
  /// feet crossed a platform top this frame with horizontal overlap, snap
  /// onto it. Rising/jumping passes through from below, and sides never
  /// resolve, so the player can neither fall through nor get stuck.
  void _resolvePlatformCollisions(double dt) {
    if (_player.isDefeated || _player.velocity.y < 0) return;
    final pos = _player.position;
    final size = _player.size;
    final bottom = pos.y + size.y;
    final prevBottom = bottom - _player.velocity.y * dt;
    for (final platform in _platforms) {
      final top = platform.position.y;
      if (prevBottom > top + 1 || bottom < top) continue;
      const inset = 10.0;
      final overlapX = pos.x + inset < platform.position.x + platform.size.x &&
          pos.x + size.x - inset > platform.position.x;
      if (!overlapX) continue;
      pos.y = top - size.y;
      _player.velocity.y = 0;
      _player.isGrounded = true;
      break;
    }
  }

  void _checkCoinPickup() {
    for (final coin in _coins) {
      if (!coin.collected && coin.isVisible && _player.bounds.overlaps(coin.bounds)) {
        coin.collect();
        coinCount.value = coinCount.value + 1;
        score.value = score.value + 100;
        unawaited(gameController.playSfx('coin.wav'));
      }
    }
  }

  void _checkEnemyCollisions() {
    for (final enemy in _enemies) {
      if (!enemy.isAlive || enemy.isDefeating) continue;
      if (!_player.bounds.overlaps(enemy.bounds)) continue;

      final playerCenter = _player.position + _player.size / 2;
      final enemyCenter = enemy.position + enemy.size / 2;
      final stomped = playerCenter.y < enemyCenter.y && _player.velocity.y > 0;

      if (stomped) {
        enemy.defeat();
        score.value = score.value + 250;
        _player.velocity.y = -320;
        unawaited(gameController.playSfx('shoot.wav'));
      } else if (_player.isRolling) {
        // Dodge: rolling through a slime avoids damage (the foe lives on).
      } else if (health.value > 0) {
        _handlePlayerDamage();
      }
    }
  }

  void _checkFruitPickup() {
    for (final fruit in _fruits) {
      if (!fruit.collected && fruit.isVisible && _player.bounds.overlaps(fruit.bounds)) {
        fruit.collect();
        _player.activateImmunity();
        immunity.value = true;
        immunityTimer.value = 8;
        score.value = score.value + 500;
        unawaited(gameController.playSfx('coin.wav'));
      }
    }
  }

  void _checkLevelComplete() {
    if (_player.position.x >= _worldWidth - 220 && coinCount.value >= 8) {
      levelComplete.value = true;
      overlays.add('levelComplete');
      unawaited(gameController.playSfx('game_over.wav'));
    }
  }

  void _handlePlayerDamage() {
    if (immunity.value || _player.isInvulnerable) return;
    _player.takeDamage();
    health.value = math.max(0, health.value - 1);
    unawaited(gameController.playSfx('hit.wav'));
    if (health.value <= 0) {
      _handlePlayerDefeat();
    }
  }

  void _handlePlayerDefeat() {
    if (_player.isDefeated) return;
    _defeatElapsed = 0;
    _player.defeat();
    unawaited(gameController.playSfx('game_over.wav'));
  }

  void _handleFruitPickup() {
    immunity.value = true;
    immunityTimer.value = 8;
  }

  void _updateImmunity(double dt) {
    if (!immunity.value) return;
    immunityTimer.value = math.max(0, immunityTimer.value - dt);
    if (immunityTimer.value <= 0) {
      immunity.value = false;
      immunityTimer.value = 0;
    }
  }

  /// Full-state setter (kept for tests/compat). Touch buttons must use the
  /// per-flag setters below so holding one button never clears the others.
  void setInput({bool left = false, bool right = false, bool jump = false, bool roll = false}) {
    _leftPressed = left;
    _rightPressed = right;
    _jumpPressed = jump;
    _rollPressed = roll;
  }

  void setLeft(bool pressed) => _leftPressed = pressed;
  void setRight(bool pressed) => _rightPressed = pressed;
  void setJump(bool pressed) => _jumpPressed = pressed;
  void setRoll(bool pressed) => _rollPressed = pressed;

  void togglePause() {
    if (levelComplete.value || _player.isDefeated) return;
    isPaused.value = !isPaused.value;
    if (isPaused.value) {
      overlays.add('pause');
    } else {
      overlays.remove('pause');
    }
  }

  void restartLevel() {
    _gameOverShown = false;
    _defeatElapsed = 0;
    isPaused.value = false;
    levelComplete.value = false;
    overlays.remove('pause');
    overlays.remove('levelComplete');
    overlays.remove('gameOver');

    health.value = 5;
    coinCount.value = 0;
    score.value = 0;
    immunity.value = false;
    immunityTimer.value = 0;

    _player.position = Vector2(90, _worldHeight - _groundHeight - 68);
    _player.velocity = Vector2.zero();
    _player.isDefeated = false;
    _player.isInvulnerable = false;
    _player.resetAnimation();

    // Snap the camera back to the start (x follows the knight; y is
    // fixed by the horizontal-only follow, so it stays as-is). Note:
    // Viewfinder.position is a computed value — it must be assigned,
    // not mutated in place.
    camera.viewfinder.position = Vector2(
      _player.position.x,
      _player.position.y,
    );

    // Remove old collectibles and enemies, re-instantiate
    for (final coin in _coins) {
      coin.removeFromParent();
    }
    for (final enemy in _enemies) {
      enemy.removeFromParent();
    }
    for (final fruit in _fruits) {
      fruit.removeFromParent();
    }
    for (final coin in _gameWorld.children.whereType<CoinComponent>().toList()) {
      coin.removeFromParent();
    }
    for (final enemy in _gameWorld.children.whereType<EnemyComponent>().toList()) {
      enemy.removeFromParent();
    }
    for (final fruit in _gameWorld.children.whereType<FruitComponent>().toList()) {
      fruit.removeFromParent();
    }

    _coins = _buildCoins();
    _enemies = _buildEnemies();
    _fruits = _buildFruits();

    for (final coin in _coins) { _gameWorld.add(coin); }
    for (final enemy in _enemies) { _gameWorld.add(enemy); }
    for (final fruit in _fruits) { _gameWorld.add(fruit); }
  }

  // Test/debug accessors (read-only views over live level objects).
  KnightComponent get player => _player;
  World get levelWorld => _gameWorld;
  List<CoinComponent> get coins => List.unmodifiable(_coins);
  List<EnemyComponent> get enemies => List.unmodifiable(_enemies);
  List<FruitComponent> get fruits => List.unmodifiable(_fruits);
}

