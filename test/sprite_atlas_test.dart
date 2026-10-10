import 'dart:io';
import 'dart:typed_data';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:antigravity_platformer/components/collectibles.dart';
import 'package:antigravity_platformer/components/enemies.dart';
import 'package:antigravity_platformer/components/tileset_decor.dart';
import 'package:antigravity_platformer/controllers/game_controller.dart';
import 'package:antigravity_platformer/game/antigravity_game.dart';
import 'package:antigravity_platformer/game/sprite_atlas.dart';

/// Reads PNG IHDR width/height without decoding pixels.
List<int> pngSize(String path) {
  final bytes = File(path).readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  assert(String.fromCharCodes(bytes.sublist(1, 4)) == 'PNG');
  final width = data.getUint32(16);
  final height = data.getUint32(20);
  return [width, height];
}

void main() {
  group('sprite sheet dimensions (measured, not assumed)', () {
    const cases = {
      'assets/knight.png': [256, 256],
      'assets/platforms.png': [64, 64],
      'assets/world_tileset.png': [256, 256],
      'assets/coin.png': [192, 16],
      'assets/fruit_immunity.png': [64, 64],
      'assets/Enemy_slime_green.png': [96, 72],
      'assets/Enemy_slime_purple.png': [96, 72],
    };
    for (final entry in cases.entries) {
      test('${entry.key} is ${entry.value}', () {
        expect(pngSize(entry.key), entry.value);
      });
    }
  });

  group('atlas frame rects stay inside their sheets', () {
    test('knight rows (idle/run/roll/hit/death)', () {
      expect(
          frameRects(sheetSize: 256, cell: 32, row: 0, amount: 4), hasLength(4));
      expect(
          frameRects(sheetSize: 256, cell: 32, row: 2, amount: 8), hasLength(8));
      expect(
          frameRects(sheetSize: 256, cell: 32, row: 5, amount: 8), hasLength(8));
      expect(
          frameRects(sheetSize: 256, cell: 32, row: 6, amount: 4), hasLength(4));
      expect(
          frameRects(sheetSize: 256, cell: 32, row: 7, amount: 4), hasLength(4));
      for (final r in [
        ...frameRects(sheetSize: 256, cell: 32, row: 0, amount: 4),
        ...frameRects(sheetSize: 256, cell: 32, row: 2, amount: 8),
        ...frameRects(sheetSize: 256, cell: 32, row: 5, amount: 8),
        ...frameRects(sheetSize: 256, cell: 32, row: 6, amount: 4),
        ...frameRects(sheetSize: 256, cell: 32, row: 7, amount: 4),
      ]) {
        expect(r.right, lessThanOrEqualTo(256));
        expect(r.bottom, lessThanOrEqualTo(256));
      }
    });

    test('slime rows (idle/walk/defeat) in 96x72', () {
      for (var row = 0; row < 3; row++) {
        final frames =
            frameRects(sheetSize: 96, cell: 24, row: row, amount: 4);
        expect(frames, hasLength(4));
        for (final r in frames) {
          expect(r.right, lessThanOrEqualTo(96));
          expect(r.bottom, lessThanOrEqualTo(72));
        }
      }
    });

    test('coin 12 frames fill the 192x16 strip exactly', () {
      final frames = frameRects(sheetSize: 192, cell: 16, row: 0, amount: 12);
      expect(frames, hasLength(12));
      expect(frames.last.right, 192);
    });

    test('fruit 12 variants are 16px cells, col 3 never used', () {
      for (var v = 0; v < 12; v++) {
        final topLeft = FruitAtlas.cellTopLeft(v);
        expect(topLeft.x + 16, lessThanOrEqualTo(48)); // cols 0-2 only
        expect(topLeft.y + 16, lessThanOrEqualTo(64));
      }
    });

    test('platform 16x9 tiles sit inside 64x64', () {
      for (var row = 0; row < 4; row++) {
        for (var col = 0; col < 3; col++) {
          final r = Rect.fromLTWH(
              col * 16.0, row * 16.0, PlatformAtlas.tileW, PlatformAtlas.tileH);
          expect(r.right, lessThanOrEqualTo(64));
          expect(r.bottom, lessThanOrEqualTo(64));
        }
      }
    });

    test('world tiles used are inside 256x256', () {
      for (final t in [
        WorldTiles.grassTop,
        WorldTiles.dirt,
        WorldTiles.treeTop,
        WorldTiles.treeTrunk,
        WorldTiles.bush,
        WorldTiles.pillarTop,
        WorldTiles.pillar,
      ]) {
        expect(t.x + 16, lessThanOrEqualTo(256));
        expect(t.y + 16, lessThanOrEqualTo(256));
      }
    });
  });

  group('gameplay sprites load and animate', () {
    testWidgets('player, enemies, coins, fruits, tiles use sheet art',
        (tester) async {
      final game = AntigravityGame(
        gameController: GameController(),
        levelId: 1,
      );
      // NOTE: image decoding uses engine codecs that stall under the
      // fake-async test clock. Loading therefore happens inside runAsync:
      // pump the widget, really await the game's load future, then pump
      // frames so world children mount and bind their cached sprites.
      // (Verified by bisection: identical loads hang without runAsync.)
      await tester.runAsync(() async {
        await tester.pumpWidget(GameWidget(game: game));
        await game.toBeLoaded();
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      });

      // Player: real sprites, settled on the ground, idle.
      expect(game.player.debugHasSprites, isTrue);
      expect(game.player.size.x, 64);
      expect(game.player.size.y, 64);
      expect(game.player.isGrounded, isTrue);
      expect(game.player.debugAnimName, 'idle');

      // Run state follows input.
      game.setInput(right: true);
      await tester.pump(const Duration(milliseconds: 300));
      expect(game.player.debugAnimName, 'run');
      expect(game.player.velocity.x, greaterThan(0));

      // Roll state.
      game.setInput(roll: true);
      await tester.pump(const Duration(milliseconds: 200));
      expect(game.player.debugAnimName, 'roll');
      game.setInput(roll: false);

      // Multi-touch latch: LEFT+RIGHT cancel out; releasing LEFT keeps
      // RIGHT held (buttons no longer wipe each other's state).
      game.setLeft(true);
      game.setRight(true);
      await tester.pump(const Duration(milliseconds: 200));
      expect(game.player.velocity.x, 0);
      game.setLeft(false);
      await tester.pump(const Duration(milliseconds: 200));
      expect(game.player.velocity.x, greaterThan(0));
      game.setRight(false);
      await tester.pump(const Duration(milliseconds: 200));
      expect(game.player.velocity.x, 0);

      // Jump needs grounded state and fires once per press: holding
      // JUMP through landing must not auto-bunny-hop.
      expect(game.player.isGrounded, isTrue);
      game.setJump(true);
      await tester.pump(const Duration(milliseconds: 100));
      expect(game.player.isGrounded, isFalse);
      expect(game.player.velocity.y, lessThan(0));
      expect(game.player.debugAnimName, 'air');
      // Integrate landing in small steps: one giant dt would tunnel past
      // the ground clamp in a single frame (unlike the real game loop).
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(game.player.isGrounded, isTrue);
      final restY = game.player.position.y;
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(game.player.position.y, restY);
      expect(game.player.isGrounded, isTrue);
      game.setJump(false);

      // One-way platform landing: dropped above p1 (top y=650), the
      // 64px player must settle exactly on top, never fall through.
      game.player.position = Vector2(560, 500);
      game.player.velocity = Vector2.zero();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(game.player.isGrounded, isTrue);
      expect(game.player.position.y, 650 - 64);

      // Approaching from below/side never sticks: dropped with feet
      // already under the platform top, the player falls past it to
      // the ground instead of snapping or getting stuck.
      game.player.position = Vector2(560, 660);
      game.player.velocity = Vector2.zero();
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(game.player.isGrounded, isTrue);
      expect(game.player.position.y, 804 - 64);

      // Enemies: sheet art, spawn morph then walk cycle.
      expect(game.enemies, hasLength(4));
      for (final enemy in game.enemies) {
        expect(enemy.debugHasSprites, isTrue);
        expect(enemy.size.x, 48);
        expect(enemy.size.y, 48);
      }
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      for (final enemy in game.enemies) {
        expect(enemy.debugAnimName, 'walk');
      }

      // Coins: 12-frame spin advances with time.
      expect(game.coins, hasLength(14));
      for (final coin in game.coins) {
        expect(coin.hasAnimation, isTrue);
        expect(coin.size.x, 32);
      }
      final frameBefore = game.coins.first.debugFrameLeft;
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final frameAfter = game.coins.first.debugFrameLeft;
      expect(frameBefore, greaterThanOrEqualTo(0));
      expect(frameAfter, greaterThanOrEqualTo(0));
      expect(frameAfter == frameBefore, isFalse,
          reason: 'coin spin must advance (stepTime 0.08s)');

      // Fruits: one 16px sheet cell each.
      expect(game.fruits, hasLength(3));
      expect(game.fruits.map((f) => f.variant).toList(), [2, 4, 11]);
      for (final fruit in game.fruits) {
        expect(fruit.hasSprite, isTrue);
      }

      // Tileset: grass strip + 8 decor tiles all bound to the sheet.
      final groundTiles =
          game.levelWorld.children.whereType<GroundTilesComponent>();
      expect(groundTiles, hasLength(1));
      expect(groundTiles.first.debugHasSprite, isTrue);
      expect(groundTiles.first.debugTileCount, 169);
      final decorTiles =
          game.levelWorld.children.whereType<TilesetTileComponent>();
      expect(decorTiles, hasLength(8));
      for (final tile in decorTiles) {
        expect(tile.debugHasSprite, isTrue);
      }

      game.dispose();
    });

    testWidgets('enemies patrol inside their platform corridors',
        (tester) async {
      final game = await loadGame(tester);

      // Green foes first/front, purple foes on platforms (sprite assignment).
      expect(game.enemies[0].color, const Color(0xFF99EB77));
      expect(game.enemies[1].color, const Color(0xFFB29BFF));
      expect(game.enemies[2].color, const Color(0xFF99EB77));
      expect(game.enemies[3].color, const Color(0xFFB29BFF));

      final starts = [for (final e in game.enemies) e.position.x];
      final mins = List<double>.from(starts);
      final maxs = List<double>.from(starts);
      for (var s = 0; s < 30; s++) {
        await tester.pump(const Duration(milliseconds: 100));
        for (var i = 0; i < game.enemies.length; i++) {
          final e = game.enemies[i];
          expect(e.minX, isNotNull);
          expect(e.maxX, isNotNull);
          expect(e.position.x, greaterThanOrEqualTo(e.minX! - 0.001));
          expect(e.position.x, lessThanOrEqualTo(e.maxX! + 0.001));
          if (e.position.x < mins[i]) mins[i] = e.position.x;
          if (e.position.x > maxs[i]) maxs[i] = e.position.x;
        }
      }
      for (var i = 0; i < game.enemies.length; i++) {
        expect(maxs[i] - mins[i], greaterThan(5),
            reason: 'foe $i must patrol, not stand still');
      }

      game.dispose();
    });

    testWidgets('stomp defeats, side hit damages once, roll dodges',
        (tester) async {
      final game = await loadGame(tester);
      expect(game.health.value, 5);

      // Stomp foe 0: drop onto it, leading its patrol drift so the landing
      // stays centered (90 px/s * ~0.4 s fall).
      final foe = game.enemies[0];
      game.player.position = Vector2(
        foe.position.x + 8 + foe.direction * 37,
        foe.position.y - 70,
      );
      game.player.velocity = Vector2.zero();
      await step(tester, 20);
      expect(foe.isAlive, isFalse);
      expect(game.score.value, greaterThanOrEqualTo(250));
      expect(game.health.value, 5);

      // Roll dodge through foe 2: sustained contact, no damage, foe lives.
      final dodger = game.enemies[2];
      game.setRoll(true);
      game.player.position = Vector2(dodger.position.x, 740);
      game.player.velocity = Vector2.zero();
      await step(tester, 5);
      expect(game.health.value, 5);
      expect(dodger.isAlive, isTrue);
      game.setRoll(false);

      // Side contact with foe 1 (platform): exactly one hit per window —
      // the 1.2 s post-hit invulnerability blocks per-frame repeats.
      final bumper = game.enemies[1];
      game.player.position = Vector2(bumper.position.x, 620 - 64);
      game.player.velocity = Vector2.zero();
      await step(tester, 5);
      expect(game.health.value, 4);

      game.dispose();
    });

    testWidgets('systems: coins, fruit, pause, death, restart, completion',
        (tester) async {
      final game = await loadGame(tester);

      // 1. Coin: +1 coin, +100 score, collected exactly once.
      final coin = game.coins.first;
      game.player.position = Vector2(coin.position.x, coin.position.y - 32);
      game.player.velocity = Vector2.zero();
      await step(tester, 10);
      expect(game.coinCount.value, 1);
      expect(game.score.value, 100);
      expect(coin.collected, isTrue);
      await step(tester, 5);
      expect(game.coinCount.value, 1);
      expect(game.score.value, 100);

      // 2. Fruit: immunity power-up, +500 score, single pickup.
      final fruit = game.fruits.firstWhere((f) => !f.collected);
      game.player.position = Vector2(fruit.position.x, fruit.position.y - 32);
      game.player.velocity = Vector2.zero();
      await step(tester, 10);
      expect(fruit.collected, isTrue);
      expect(game.immunity.value, isTrue);
      expect(game.immunityTimer.value, greaterThan(6.5));
      expect(game.score.value, greaterThanOrEqualTo(600));

      // 3. Pause freezes the whole simulation and resumes cleanly.
      final foeXBefore =
          game.enemies.map((e) => e.position.x).toList();
      final playerBefore = game.player.position.clone();
      game.togglePause();
      expect(game.overlays.isActive('pause'), isTrue);
      await step(tester, 5);
      for (var i = 0; i < game.enemies.length; i++) {
        expect(game.enemies[i].position.x, foeXBefore[i]);
      }
      expect(game.player.position, playerBefore);
      game.togglePause();
      expect(game.overlays.isActive('pause'), isFalse);
      await step(tester, 5);
      var moved = false;
      for (var i = 0; i < game.enemies.length; i++) {
        if (game.enemies[i].position.x != foeXBefore[i]) moved = true;
      }
      expect(moved, isTrue);

      // 4. Death at zero health: defeat anim, frozen world, game-over UI.
      // (Fruit immunity from step 2 is cleared first so the hit lands.)
      game.immunity.value = false;
      game.immunityTimer.value = 0;
      game.player.isInvulnerable = false;
      game.health.value = 1;
      final killer = game.enemies.firstWhere(
        (e) => e.isAlive && e.position.y > 700,
      );
      game.player.position = Vector2(killer.position.x, killer.position.y);
      game.player.velocity = Vector2.zero();
      await step(tester, 5);
      expect(game.player.isDefeated, isTrue);
      expect(game.player.debugAnimName, 'death');
      await step(tester, 12);
      expect(game.overlays.isActive('gameOver'), isTrue);
      final frozenX = game.enemies.map((e) => e.position.x).toList();
      await step(tester, 3);
      for (var i = 0; i < game.enemies.length; i++) {
        expect(game.enemies[i].position.x, frozenX[i]);
      }

      // 5. Restart restores the full initial state with no stale objects.
      game.restartLevel();
      expect(game.health.value, 5);
      expect(game.coinCount.value, 0);
      expect(game.score.value, 0);
      expect(game.immunity.value, isFalse);
      expect(game.immunityTimer.value, 0);
      expect(game.overlays.isActive('pause'), isFalse);
      expect(game.overlays.isActive('levelComplete'), isFalse);
      expect(game.overlays.isActive('gameOver'), isFalse);
      expect(game.player.position, Vector2(90, 804 - 68));
      expect(game.player.velocity.length, 0);
      expect(game.player.isDefeated, isFalse);
      expect(
        game.camera.viewfinder.position.x,
        game.player.position.x,
      );
      // Let the add/remove queue settle so mounted counts are exact.
      await step(tester, 3);
      final freshCoins =
          game.levelWorld.children.whereType<CoinComponent>().toList();
      final freshEnemies =
          game.levelWorld.children.whereType<EnemyComponent>().toList();
      final freshFruits =
          game.levelWorld.children.whereType<FruitComponent>().toList();
      expect(freshCoins, hasLength(14));
      expect(freshEnemies, hasLength(4));
      expect(freshFruits, hasLength(3));
      for (final c in freshCoins) {
        expect(c.collected, isFalse);
      }
      for (final e in freshEnemies) {
        expect(e.isAlive, isTrue);
      }
      for (final f in freshFruits) {
        expect(f.collected, isFalse);
      }

      // 6. Reachable exit: crossing x=5180 with 8 coins completes the level.
      game.coinCount.value = 8;
      game.player.position = Vector2(5200, 740);
      game.player.velocity = Vector2.zero();
      await step(tester, 5);
      expect(game.levelComplete.value, isTrue);
      expect(game.overlays.isActive('levelComplete'), isTrue);

      game.dispose();
    });
  });
}

/// Loads a fresh level: pumps the widget inside runAsync (engine image
/// codecs stall under the fake-async clock), really awaits the load
/// future, then lets world children mount and bind cached sprites.
Future<AntigravityGame> loadGame(WidgetTester tester) async {
  final game = AntigravityGame(
    gameController: GameController(),
    levelId: 1,
  );
  await tester.runAsync(() async {
    // Overlay builders mirror GamePlayScreen's overlayBuilderMap; without
    // them overlays.add() asserts (production registers the real dialogs).
    await tester.pumpWidget(
      GameWidget(
        game: game,
        overlayBuilderMap: {
          'pause': (context, game) => const SizedBox(),
          'levelComplete': (context, game) => const SizedBox(),
          'gameOver': (context, game) => const SizedBox(),
        },
      ),
    );
    await game.toBeLoaded();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  });
  return game;
}

/// Advances game time in small physics-safe steps (<=100 ms).
Future<void> step(WidgetTester tester, int n) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
