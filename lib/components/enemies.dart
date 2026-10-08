import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

class EnemyComponent extends PositionComponent with HasGameReference {
  EnemyComponent({
    required super.position,
    required super.size,
    required this.color,
    required this.direction,
  }) : super(priority: 4);

  final Color color;
  int direction;
  bool isAlive = true;

  SpriteAnimationTicker? _walkTicker;
  SpriteAnimationTicker? _defeatTicker;
  bool _isDefeating = false;
  double _defeatTimer = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      final isGreen = color.toARGB32() == const Color(0xFF99EB77).toARGB32() ||
          color.g > color.b;
      final assetName = isGreen ? 'Enemy_slime_green.png' : 'Enemy_slime_purple.png';
      final image = await game.images.load(assetName);

      final walkAnim = SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.16,
          textureSize: Vector2(24, 24),
          texturePosition: Vector2(0, 24),
        ),
      );
      _walkTicker = walkAnim.createTicker();

      final defeatAnim = SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.08,
          textureSize: Vector2(24, 24),
          texturePosition: Vector2(0, 48),
          loop: false,
        ),
      );
      _defeatTicker = defeatAnim.createTicker();
    } catch (_) {
      // Fallback
    }
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

    _walkTicker?.update(dt);
    position.x += direction * 90 * dt;
    if (position.x < 300 || position.x > 5100) {
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

    final ticker = _isDefeating ? (_defeatTicker ?? _walkTicker) : _walkTicker;

    canvas.save();
    // Slime shadow
    final shadowPaint = Paint()..color = const Color(0x44000000);
    canvas.drawOval(
      Rect.fromLTWH(4, size.y - 8, size.x - 8, 8),
      shadowPaint,
    );

    if (ticker != null) {
      if (direction < 0) {
        canvas.translate(size.x, 0);
        canvas.scale(-1, 1);
      }
      ticker.getSprite().render(
        canvas,
        position: Vector2.zero(),
        size: size,
      );
    } else {
      // Stylized fallback slime
      final paint = Paint()..color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(14)),
        paint,
      );
      // Eye
      final eyeX = direction > 0 ? size.x * 0.65 : size.x * 0.35;
      canvas.drawCircle(Offset(eyeX, size.y * 0.4), 5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(eyeX + (direction > 0 ? 1 : -1), size.y * 0.4), 2.5, Paint()..color = Colors.black87);
    }
    canvas.restore();
  }
}

