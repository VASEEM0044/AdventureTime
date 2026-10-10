import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:antigravity_platformer/components/collectibles.dart';
import 'package:antigravity_platformer/components/enemies.dart';
import 'package:antigravity_platformer/controllers/game_controller.dart';
import 'package:antigravity_platformer/game/antigravity_game.dart';
import 'package:antigravity_platformer/screens/game_play_screen.dart';
import 'package:antigravity_platformer/screens/level_select_screen.dart';

/// Matches any GameWidget regardless of its game type parameter
/// (byType(GameWidget) never matches the instantiated generic).
Finder get _gameWidget => find.byWidgetPredicate((w) => w is GameWidget);

/// Final acceptance flows at widget level (no game-code changes).
/// Image decoding needs real async (see sprite_atlas_test.dart), so all
/// loading/pumping runs inside runAsync; taps and widget assertions run
/// in the normal test zone.
void main() {
  testWidgets('gameplay HUD, controls, pause and resume via real taps',
      (tester) async {
    final controller = GameController();
    await tester.pumpWidget(
      MaterialApp(home: GamePlayScreen(gameController: controller, levelId: 1)),
    );
    expect(_gameWidget, findsOneWidget);
    late AntigravityGame game;
    await tester.runAsync(() async {
      game =
          (tester.widget<GameWidget>(_gameWidget).game
              as AntigravityGame);
      await game.toBeLoaded();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    });

    // HUD + touch controls are on screen with the game.
    expect(_gameWidget, findsOneWidget);
    for (final label in ['LEFT', 'RIGHT', 'JUMP', 'ROLL']) {
      expect(find.text(label), findsOneWidget);
    }
    // 5 full hearts at start.
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(5));

    // Pause button freezes and shows the pause dialog; Resume dismisses it.
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    expect(find.text('GAME PAUSED'), findsOneWidget);
    expect(game.isPaused.value, isTrue);
    await tester.tap(find.text('Resume'));
    await tester.pump();
    expect(find.text('GAME PAUSED'), findsNothing);
    expect(game.isPaused.value, isFalse);
    game.dispose();
  });

  testWidgets('quit to menu and replay reloads a clean level', (tester) async {
    final controller = GameController();
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        home: LevelSelectScreen(gameController: controller),
      ),
    );
    await tester.pumpAndSettle();

    Future<AntigravityGame> pushGame() async {
      nav.currentState!.push(
        MaterialPageRoute(
          builder: (_) =>
              GamePlayScreen(gameController: controller, levelId: 1),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (_gameWidget.evaluate().isNotEmpty) break;
      }
      expect(_gameWidget, findsOneWidget);
      late AntigravityGame game;
      await tester.runAsync(() async {
        game =
            (tester.widget<GameWidget>(_gameWidget).game
                as AntigravityGame);
        await game.toBeLoaded();
        final probe1 = await game.images.load('world_tileset.png');
        // ignore: avoid_print
        print('diag probe1 id=${identityHashCode(probe1)} '
            'disposed=${probe1.debugDisposed}');
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final probe2 = await game.images.load('world_tileset.png');
        // ignore: avoid_print
        print('diag probe2 id=${identityHashCode(probe2)} '
            'disposed=${probe2.debugDisposed}');
      });
      return game;
    }

    var game = await pushGame();
    expect(find.text('LEFT'), findsOneWidget);

    // Quit back to level select through the real pause dialog.
    // NOTE: popping disposes game1 (State.dispose -> game.dispose() ->
    // global image cache clear); replay must reload cleanly after that.
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    await tester.tap(find.text('Quit to Levels'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Choose Your Quest'), findsOneWidget);

    // Play again: a brand-new game object loads cleanly.
    game = await pushGame();
    expect(find.text('LEFT'), findsOneWidget);
    expect(game.player.debugHasSprites, isTrue);
    expect(game.health.value, 5);
    expect(game.coinCount.value, 0);
    expect(game.score.value, 0);

    // Double restart leaves exactly one set of actors behind.
    game.restartLevel();
    game.restartLevel();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      game.levelWorld.children.whereType<CoinComponent>().length,
      14,
    );
    expect(
      game.levelWorld.children.whereType<EnemyComponent>().length,
      4,
    );
    expect(
      game.levelWorld.children.whereType<FruitComponent>().length,
      3,
    );
    game.dispose();
  });
}
