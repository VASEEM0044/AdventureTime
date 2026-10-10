import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import '../game/sprite_atlas.dart';

/// Slime enemy. Source art is 24x24 per frame, rendered at 48x48
/// (exact 2x) with nearest-neighbour sampling.
///
/// Verified map (96x72 sheet, 4x3 grid of 24px; green and purple sheets
/// share the layout byte-for-byte, palettes differ):
/// row 0 = spawn/idle morph (puddle rises into slime),
/// row 1 = hop/walk squash-and-stretch, row 2 = defeat squash with a
/// red flash on frame 2 (does not loop).
class EnemyComponent extends PositionComponent with HasGameReference {
  EnemyComponent({
    required super.position,
    required super.size,
    required this.color,
    required this.direction,
    this.minX,
    this.maxX,
  }) : super(priority: 4);

  final Color color;
  int direction;

  /// Patrol corridor for [position.x] (left edge). When null, the legacy
  /// world-wide clamp (300..5100) applies. Platforms pass their own span
  /// so foes never wander off their platform.
  final double? minX;
  final double? maxX;
  bool isAlive = true;
  bool get isDefeating => _isDefeating;

  SpriteAnimationTicker? _idleTicker;
  SpriteAnimationTicker? _walkTicker;
  SpriteAnimationTicker? _defeatTicker;
  bool _isDefeating = false;
  double _defeatTimer = 0;
  double _age = 0;
  late final Paint _pixelPaint;

  /// First 0.6s plays the spawn-morph (row 0), then the walk cycle.
  static const double spawnDuration = 0.6;

  bool get debugHasSprites =>
      _idleTicker != null && _walkTicker != null && _defeatTicker != null;

  String get debugAnimName {
    if (_isDefeating || !isAlive) return 'defeat';
    if (_age < spawnDuration) return 'idle';
    return 'walk';
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _pixelPaint = pixelPaint();
    final isGreen = color.toARGB32() == const Color(0xFF99EB77).toARGB32() ||
        color.g > color.b;
    final assetName =
        isGreen ? SpriteFiles.slimeGreen : SpriteFiles.slimePurple;
    // Preloaded by AntigravityGame; load() hits the image cache.
    final image = await game.images.load(assetName);

    _idleTicker =
        SpriteAnimation.fromFrameData(image, SlimeAtlas.idle()).createTicker();
    _walkTicker =
        SpriteAnimation.fromFrameData(image, SlimeAtlas.walk()).createTicker();
    _defeatTicker = SpriteAnimation.fromFrameData(image, SlimeAtlas.defeat())
        .createTicker();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isAlive) return;

    if (_isDefeating) {
      _defeatTimer += dt;
      _defeatTicker?.update(dt);
      if (_defeatTimer >= 0.35) {
        isAlive = false;
        removeFromParent();
      }
      return;
    }

    _age += dt;
    if (_age < spawnDuration) {
      _idleTicker?.update(dt);
    } else {
      _walkTicker?.update(dt);
    }
    position.x += direction * 90 * dt;
    if (minX != null && maxX != null) {
      if (position.x < minX!) {
        position.x = minX!;
        direction = 1;
      } else if (position.x > maxX!) {
        position.x = maxX!;
        direction = -1;
      }
    } else if (position.x < 300 || position.x > 5100) {
      direction *= -1;
    }
  }

  void defeat() {
    if (_isDefeating) return;
    _isDefeating = true;
    _defeatTimer = 0;
  }

  Rect get bounds => position & size;

  @override
  void render(Canvas canvas) {
    if (!isAlive) return;

    final SpriteAnimationTicker? ticker =
        _isDefeating ? (_defeatTicker ?? _walkTicker) : (_walkTicker);
    final SpriteAnimationTicker? idleOrWalk =
        _age < spawnDuration ? (_idleTicker ?? ticker) : ticker;

    canvas.save();
    // Slime shadow
    final shadowPaint = Paint()..color = const Color(0x44000000);
    canvas.drawOval(
      Rect.fromLTWH(4, size.y - 8, size.x - 8, 8),
      shadowPaint,
    );

    if (idleOrWalk != null) {
      if (direction < 0) {
        canvas.translate(size.x, 0);
        canvas.scale(-1, 1);
      }
      blitSprite(canvas, idleOrWalk.getSprite(), size, _pixelPaint);
    } else {
      // Stylized fallback slime (only if the sheet failed to load)
      final paint = Paint()..color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(14)),
        paint,
      );
      // Eye
      final eyeX = direction > 0 ? size.x * 0.65 : size.x * 0.35;
      canvas.drawCircle(
          Offset(eyeX, size.y * 0.4), 5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(eyeX + (direction > 0 ? 1 : -1), size.y * 0.4),
          2.5, Paint()..color = Colors.black87);
    }
    canvas.restore();
  }
}
