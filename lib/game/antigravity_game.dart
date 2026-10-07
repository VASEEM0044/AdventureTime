import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../components/collectibles.dart';
import '../components/enemies.dart';
import '../components/knight.dart';
import '../components/platforms.dart';
import '../controllers/game_controller.dart';

class AntigravityGame extends FlameGame with HasCollisionDetection {
  AntigravityGame({
    required this.gameController,
    required this.levelId,
  });

  final GameController gameController;
  final int levelId;

  final ValueNotifier<int> coinCount = ValueNotifier<int>(0);
  final ValueNotifier<int> health = ValueNotifier<int>(5);
  final ValueNotifier<bool> immunity = ValueNotifier<bool>(false);
  final ValueNotifier<double> immunityTimer = ValueNotifier<double>(0);
  final ValueNotifier<bool> isPaused = ValueNotifier<bool>(false);
  final ValueNotifier<bool> levelComplete = ValueNotifier<bool>(false);

  late final KnightComponent _player;
  late final List<CoinComponent> _coins;
  late final List<EnemyComponent> _enemies;
  late final List<FruitComponent> _fruits;

  final double _worldWidth = 5400;
  final double _worldHeight = 900;
  final double _groundHeight = 96;

  bool _leftPressed = false;
  bool _rightPressed = false;
  bool _jumpPressed = false;
  bool _rollPressed = false;
  bool _gameOverShown = false;
  double _screenWidth = 800;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _buildLevel();
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewport.size = Vector2(_screenWidth, 800);
    overlays.add('pause');
  }

  void _configureCamera() {
    camera.viewfinder.visibleGameSize = Vector2(800, 450);
    camera.viewfinder.position = Vector2(300, 0);
    camera.follow(
      _player,
      horizontalOnly: true,
      maxSpeed: 400,
    );
  }

  void _buildLevel() {
    final world = World();
    add(world);

    final ground = PlatformComponent(
      id: 'ground',
      position: Vector2(0, _worldHeight - _groundHeight),
      size: Vector2(_worldWidth, _groundHeight),
      type: PlatformType.ground,
    );
    world.add(ground);

    final platforms = <PlatformComponent>[
      PlatformComponent(id: 'p1', position: Vector2(520, 650), size: Vector2(180, 22), type: PlatformType.grass),
      PlatformComponent(id: 'p2', position: Vector2(820, 580), size: Vector2(180, 22), type: PlatformType.sand),
      PlatformComponent(id: 'p3', position: Vector2(1150, 510), size: Vector2(230, 22), type: PlatformType.ice),
      PlatformComponent(id: 'p4', position: Vector2(1550, 620), size: Vector2(180, 22), type: PlatformType.gold),
      PlatformComponent(id: 'p5', position: Vector2(1910, 540), size: Vector2(210, 22), type: PlatformType.grass),
      PlatformComponent(id: 'p6', position: Vector2(2320, 470), size: Vector2(170, 22), type: PlatformType.sand),
      PlatformComponent(id: 'p7', position: Vector2(2860, 610), size: Vector2(240, 22), type: PlatformType.ice),
      PlatformComponent(id: 'p8', position: Vector2(3340, 500), size: Vector2(220, 22), type: PlatformType.gold),
      PlatformComponent(id: 'p9', position: Vector2(3820, 430), size: Vector2(260, 22), type: PlatformType.grass),
      PlatformComponent(id: 'p10', position: Vector2(4280, 520), size: Vector2(190, 22), type: PlatformType.sand),
      PlatformComponent(id: 'p11', position: Vector2(4680, 620), size: Vector2(240, 22), type: PlatformType.gold),
    ];
    for (final platform in platforms) {
      world.add(platform);
    }

    _buildDecorations(world);
    _coins = _buildCoins();
    _enemies = _buildEnemies();
    _fruits = _buildFruits();

    _player = KnightComponent(position: Vector2(90, _worldHeight - _groundHeight - 74));
    add(_player);
    for (final coin in _coins) { add(coin); }
    for (final enemy in _enemies) { add(enemy); }
    for (final fruit in _fruits) { add(fruit); }

    _player.onDamage = _handlePlayerDamage;
    _player.onDefeat = _handlePlayerDefeat;
    _player.onCollectedFruit = _handleFruitPickup;

    _configureCamera();
  }

  void _buildDecorations(World world) {
    final decorations = <DecorationComponent>[
      DecorationComponent(position: Vector2(220, 690), size: Vector2(130, 140), variant: DecorationType.tree),
      DecorationComponent(position: Vector2(620, 680), size: Vector2(120, 120), variant: DecorationType.bush),
      DecorationComponent(position: Vector2(1090, 694), size: Vector2(130, 150), variant: DecorationType.tree),
      DecorationComponent(position: Vector2(1500, 680), size: Vector2(140, 130), variant: DecorationType.mushroom),
      DecorationComponent(position: Vector2(2030, 686), size: Vector2(130, 130), variant: DecorationType.tree),
      DecorationComponent(position: Vector2(2450, 680), size: Vector2(120, 120), variant: DecorationType.bush),
      DecorationComponent(position: Vector2(2980, 690), size: Vector2(140, 150), variant: DecorationType.tree),
      DecorationComponent(position: Vector2(3550, 680), size: Vector2(110, 120), variant: DecorationType.mushroom),
      DecorationComponent(position: Vector2(4140, 682), size: Vector2(120, 140), variant: DecorationType.tree),
      DecorationComponent(position: Vector2(4680, 682), size: Vector2(140, 130), variant: DecorationType.bush),
      DecorationComponent(position: Vector2(4880, 694), size: Vector2(130, 150), variant: DecorationType.tree),
    ];
    for (final decoration in decorations) {
      world.add(decoration);
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
    final enemies = <EnemyComponent>[
      EnemyComponent(position: Vector2(930, 680), size: Vector2(46, 34), color: const Color(0xFF99EB77), direction: 1),
      EnemyComponent(position: Vector2(1760, 590), size: Vector2(46, 34), color: const Color(0xFFB29BFF), direction: 1),
      EnemyComponent(position: Vector2(2600, 680), size: Vector2(46, 34), color: const Color(0xFF99EB77), direction: -1),
      EnemyComponent(position: Vector2(4520, 500), size: Vector2(46, 34), color: const Color(0xFFB29BFF), direction: -1),
    ];
    return enemies;
  }

  List<FruitComponent> _buildFruits() {
    return [
      FruitComponent(position: Vector2(1420, 430)),
      FruitComponent(position: Vector2(3060, 552)),
      FruitComponent(position: Vector2(4980, 540)),
    ];
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isPaused.value || levelComplete.value || _player.isDefeated) {
      return;
    }

    _updateInput(dt);
    _updateImmunity(dt);
    _checkCoinPickup();
    _checkEnemyCollisions();
    _checkFruitPickup();
    _checkLevelComplete();
    _updateCamera();
  }

  void _updateInput(double dt) {
    final moveAxis = ((_rightPressed ? 1 : 0) - (_leftPressed ? 1 : 0)).toDouble();
    _player.setInput(moveAxis, _jumpPressed, _rollPressed, dt);
  }

  void _checkCoinPickup() {
    for (final coin in _coins) {
      if (!coin.collected && coin.isVisible && _player.bounds.overlaps(coin.bounds)) {
        coin.collect();
        coinCount.value = coinCount.value + 1;
        unawaited(gameController.playSfx('audio/coin.wav'));
      }
    }
  }

  void _checkEnemyCollisions() {
    for (final enemy in _enemies) {
      if (!enemy.isAlive) continue;
      if (!_player.bounds.overlaps(enemy.bounds)) continue;

      final playerCenter = _player.position + _player.size / 2;
      final enemyCenter = enemy.position + enemy.size / 2;
      final stomped = playerCenter.y > enemyCenter.y && _player.velocity.y > 0;

      if (stomped) {
        enemy.defeat();
        _player.velocity.y = -260;
        unawaited(gameController.playSfx('audio/shoot.wav'));
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
        unawaited(gameController.playSfx('audio/coin.wav'));
      }
    }
  }

  void _checkLevelComplete() {
    if (_player.position.x >= _worldWidth - 220 && coinCount.value >= 8) {
      levelComplete.value = true;
      overlays.add('levelComplete');
      unawaited(gameController.playSfx('audio/game_over.wav'));
    }
  }

  void _handlePlayerDamage() {
    if (immunity.value || _player.isInvulnerable) return;
    _player.takeDamage();
    health.value = math.max(0, health.value - 1);
    unawaited(gameController.playSfx('audio/hit.wav'));
    if (health.value <= 0) {
      _handlePlayerDefeat();
    }
  }

  void _handlePlayerDefeat() {
    if (_gameOverShown) return;
    _gameOverShown = true;
    _player.defeat();
    unawaited(gameController.playSfx('audio/game_over.wav'));
    isPaused.value = true;
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

  void _updateCamera() {
    final maxX = math.max(0.0, _worldWidth - 800.0);
    final targetX = _player.position.x.clamp(0.0, maxX);
    camera.viewfinder.position = Vector2(targetX, 0);
  }

  void setInput({bool left = false, bool right = false, bool jump = false, bool roll = false}) {
    _leftPressed = left;
    _rightPressed = right;
    _jumpPressed = jump;
    _rollPressed = roll;
  }

  void togglePause() {
    if (levelComplete.value || _player.isDefeated) return;
    isPaused.value = !isPaused.value;
    if (isPaused.value) {
      overlays.add('pause');
    } else {
      overlays.remove('pause');
    }
  }

  @override
  void onGameResize(Vector2 size) {
    _screenWidth = size.x;
    camera.viewfinder.visibleGameSize = Vector2(size.x, size.y);
    super.onGameResize(size);
  }

}
