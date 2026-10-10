import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/sprite_atlas.dart';

/// Single 16x16 tile from world_tileset.png, rendered crisp at 2x (32px).
/// See [WorldTiles] for verified full-bleed tile coordinates.
class TilesetTileComponent extends PositionComponent with HasGameReference {
  TilesetTileComponent({
    required super.position,
    required this.tileTopLeft,
    this.tileSize = 16,
    this.pixelScale = 2.0,
  }) : super(
          size: Vector2.all(16 * 2.0),
          anchor: Anchor.topLeft,
          priority: 1,
        );

  final Vector2 tileTopLeft;
  final double tileSize;
  final double pixelScale;

  ui.Image? _sheet;
  late final Paint _pixelPaint;

  bool get debugHasSprite => _sheet != null && !_sheet!.debugDisposed;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _pixelPaint = pixelPaint();
    size = Vector2.all(tileSize * pixelScale);
    // Preloaded by AntigravityGame; load() hits the image cache.
    _sheet = await game.images.load(SpriteFiles.worldTileset);
  }

  @override
  void render(Canvas canvas) {
    var sheet = _sheet;
    if (sheet == null || sheet.debugDisposed) {
      if (game.images.containsKey(SpriteFiles.worldTileset)) {
        final cached = game.images.fromCache(SpriteFiles.worldTileset);
        if (!cached.debugDisposed) {
          sheet = _sheet = cached;
        }
      }
    }
    if (sheet == null || sheet.debugDisposed) return;

    final src = Rect.fromLTWH(
      tileTopLeft.x,
      tileTopLeft.y,
      tileSize,
      tileSize,
    );
    canvas.drawImageRect(sheet, src, size.toRect(), _pixelPaint);
  }
}

/// Grass-topped dirt edge along the ground, tiled from world_tileset.png
/// tile (0,0) at 2x. Full-bleed 16x16 tiles butt seamlessly; the strip is
/// clipped to [size] so the final partial tile never overhangs.
class GroundTilesComponent extends PositionComponent with HasGameReference {
  GroundTilesComponent({
    required double worldWidth,
    required double groundY,
  }) : super(
          position: Vector2(0, groundY - 32),
          size: Vector2(worldWidth, 32),
          anchor: Anchor.topLeft,
          priority: 3,
        );

  static const double tilePx = 32;

  ui.Image? _sheet;
  late final Paint _pixelPaint;

  bool get debugHasSprite => _sheet != null && !_sheet!.debugDisposed;

  int get debugTileCount => (size.x / tilePx).ceil();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _pixelPaint = pixelPaint();
    // Preloaded by AntigravityGame; load() hits the image cache.
    _sheet = await game.images.load(SpriteFiles.worldTileset);
  }

  @override
  void render(Canvas canvas) {
    var sheet = _sheet;
    if (sheet == null || sheet.debugDisposed) {
      if (game.images.containsKey(SpriteFiles.worldTileset)) {
        final cached = game.images.fromCache(SpriteFiles.worldTileset);
        if (!cached.debugDisposed) {
          sheet = _sheet = cached;
        }
      }
    }
    if (sheet == null || sheet.debugDisposed) return;

    const src = Rect.fromLTWH(0, 0, 16, 16); // WorldTiles.grassTop
    canvas.save();
    canvas.clipRect(size.toRect());
    for (double x = 0; x < size.x; x += tilePx) {
      canvas.drawImageRect(
        sheet,
        src,
        Rect.fromLTWH(x, 0, tilePx, tilePx),
        _pixelPaint,
      );
    }
    canvas.restore();
  }
}
