import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Central sprite-atlas definitions for Antigravity Knight.
///
/// Every rectangle below was measured against the actual PNG bytes
/// (see audit: per-cell alpha occupancy + zoomed row strips).
/// Do not edit frame coordinates without re-measuring the sheet.
///
/// Sheets (exact on-disk case — required for iOS case-sensitive bundles):
/// - knight.png 256x256, 8x8 grid of 32x32. Rows 0,2,5,6,7 hold sprites;
///   rows 1 ("RUN") and 4 ("ROLL") are label-only rows; row 0 cols 4-5
///   ("IDLE"), row 6 cols 4-5 ("HIT"), row 7 cols 4-6 ("DEATH") are baked-in
///   labels. Row 3 is a spare 8-frame run-with-dust variant.
/// - Enemy_slime_green/purple.png 96x72, 4x3 grid of 24x24 (palettes differ,
///   layouts identical). Row 0 = spawn/idle morph, row 1 = hop/walk,
///   row 2 = defeat (frame 2 is the red flash frame).
/// - coin.png 192x16, 12 frames of 16x16 spin cycle.
/// - fruit_immunity.png 64x64, 12 fruit variants of 16x16
///   (cols 0-2 x rows 0-3; col 3 is empty). Rows: green, orange, pink, red.
/// - platforms.png 64x64. Four rows of 16px pitch; each row holds
///   left/mid/right tiles of 16x9 at the TOP of its 16px band
///   (rows y0-8 opaque, y9-15 transparent; col x48-63 empty).
/// - world_tileset.png 256x256, 16x16 grid. Dirt/stone rows 0-2,
///   vegetation rows 3-8, gradients/bones rows 9-15.
class SpriteFiles {
  static const String knight = 'knight.png';
  static const String platforms = 'platforms.png';
  static const String worldTileset = 'world_tileset.png';
  static const String coin = 'coin.png';
  static const String fruit = 'fruit_immunity.png';
  static const String slimeGreen = 'Enemy_slime_green.png';
  static const String slimePurple = 'Enemy_slime_purple.png';

  static const List<String> all = [
    knight,
    platforms,
    worldTileset,
    coin,
    fruit,
    slimeGreen,
    slimePurple,
  ];
}

/// Crisp pixel-art paint: nearest-neighbour, no antialiasing.
/// Prevents blurry upscaling of 16/24/32px source art.
Paint pixelPaint() => Paint()
  ..filterQuality = FilterQuality.none
  ..isAntiAlias = false;

/// Blits the current frame of [sprite] into [size] at the origin.
/// The caller is responsible for transforms (flip) and save/restore.
void blitSprite(Canvas canvas, Sprite sprite, Vector2 size, Paint paint) {
  if (sprite.image.debugDisposed) return;
  final src = Rect.fromLTWH(
    sprite.srcPosition.x,
    sprite.srcPosition.y,
    sprite.srcSize.x,
    sprite.srcSize.y,
  );
  canvas.drawImageRect(sprite.image, src, size.toRect(), paint);
}

/// Frame rectangles for bounds-check tests.
List<Rect> frameRects({
  required double sheetSize,
  required double cell,
  required int row,
  required int amount,
  int startCol = 0,
}) {
  return List<Rect>.generate(amount, (i) {
    final r = Rect.fromLTWH((startCol + i) * cell, row * cell, cell, cell);
    assert(r.right <= sheetSize && r.bottom <= sheetSize);
    return r;
  });
}

class KnightAtlas {
  static const double cell = 32;
  static const double sheet = 256;

  static SpriteAnimationData idle() => SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.16,
        textureSize: Vector2.all(cell),
        texturePosition: Vector2(0, 0),
      );

  /// Row 2: clean 8-frame run cycle.
  static SpriteAnimationData run() => SpriteAnimationData.sequenced(
        amount: 8,
        stepTime: 0.09,
        textureSize: Vector2.all(cell),
        texturePosition: Vector2(0, 64),
      );

  /// Row 3: spare run variant with foot-dust puffs (verified, unused).
  static SpriteAnimationData runDust() => SpriteAnimationData.sequenced(
        amount: 8,
        stepTime: 0.09,
        textureSize: Vector2.all(cell),
        texturePosition: Vector2(0, 96),
      );

  /// Row 5: full tumble.
  static SpriteAnimationData roll() => SpriteAnimationData.sequenced(
        amount: 8,
        stepTime: 0.07,
        textureSize: Vector2.all(cell),
        texturePosition: Vector2(0, 160),
      );

  /// Row 6: 4 frames, frame 2 flashes red in the sheet itself.
  static SpriteAnimationData hit() => SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.12,
        textureSize: Vector2.all(cell),
        texturePosition: Vector2(0, 192),
      );

  /// Row 7: knight keels over; does not loop.
  static SpriteAnimationData death() => SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.15,
        textureSize: Vector2.all(cell),
        texturePosition: Vector2(0, 224),
        loop: false,
      );

  // NOTE: the sheet contains NO jump or fall frames. Airborne states reuse
  // the run cycle (see KnightComponent) — a documented fallback, not an
  // invented animation.
}

class SlimeAtlas {
  static const double cell = 24;

  /// Row 0: puddle-to-slime spawn morph.
  static SpriteAnimationData idle() => SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.18,
        textureSize: Vector2.all(cell),
        texturePosition: Vector2(0, 0),
      );

  /// Row 1: squash-and-stretch hop cycle.
  static SpriteAnimationData walk() => SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.16,
        textureSize: Vector2.all(cell),
        texturePosition: Vector2(0, 24),
      );

  /// Row 2: squash frames with red flash on frame 2; does not loop.
  static SpriteAnimationData defeat() => SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.08,
        textureSize: Vector2.all(cell),
        texturePosition: Vector2(0, 48),
        loop: false,
      );
}

class CoinAtlas {
  static SpriteAnimationData spin() => SpriteAnimationData.sequenced(
        amount: 12,
        stepTime: 0.08,
        textureSize: Vector2.all(16),
      );
}

class FruitAtlas {
  static const double cell = 16;

  /// 12 variants: variant = row * 3 + col (cols 0-2, rows 0-3).
  /// Row 0 green, 1 orange, 2 pink, 3 red; col 0 round, 1 pear, 2 grapes.
  static Vector2 cellTopLeft(int variant) {
    assert(variant >= 0 && variant < 12);
    return Vector2((variant % 3) * cell, (variant ~/ 3) * cell);
  }
}

class PlatformAtlas {
  static const double tileW = 16;
  static const double tileH = 9;
  static const double pitch = 16;

  /// Sheet row per platform type (matches PlatformType order).
  static int rowFor(String type) => switch (type) {
        'grass' => 0,
        'sand' => 1,
        'gold' => 2,
        'ice' => 3,
        _ => 0,
      };
}

/// Named 16px tiles in world_tileset.png (col, row), all verified full-bleed.
class WorldTiles {
  static final Vector2 grassTop = Vector2(0, 0);
  static final Vector2 dirt = Vector2(16, 16);
  static final Vector2 treeTop = Vector2(0, 48);
  static final Vector2 treeTrunk = Vector2(0, 64);
  static final Vector2 bush = Vector2(16, 48);
  static final Vector2 pillarTop = Vector2(80, 48);
  static final Vector2 pillar = Vector2(80, 64);
}
