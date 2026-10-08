import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

abstract class Collectible extends PositionComponent {
  Collectible({required super.position, required super.size}) : super(priority: 5);

  bool collected = false;
  bool get isVisible => !collected;

  void collect() {
    collected = true;
    removeFromParent();
  }

  Rect get bounds => position & size;
}

class CoinComponent extends Collectible with HasGameReference {
  CoinComponent({required super.position})
      : super(size: Vector2.all(28));

  SpriteAnimation? _animation;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      final image = await game.images.load('coin.png');
      _animation = SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: 12,
          stepTime: 0.08,
          textureSize: Vector2(16, 16),
        ),
      );
    } catch (_) {
      // Fallback used if asset load fails
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!collected && _animation != null) {
      _animation!.update(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    if (collected) return;

    // Glowing aura behind coin
    final glowPaint = Paint()
      ..color = const Color(0x66FFD700)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 12, glowPaint);

    if (_animation != null) {
      _animation!.getSprite().render(
        canvas,
        position: Vector2.zero(),
        size: size,
      );
    } else {
      // Fallback vector coin
      final paint = Paint()..color = const Color(0xFFFFD052);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), 12, paint);
      final inner = Paint()..color = const Color(0xFFFFA000);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), 9, inner);
    }
  }
}

class FruitComponent extends Collectible with HasGameReference {
  FruitComponent({required super.position})
      : super(size: Vector2.all(32));

  double _time = 0;
  Sprite? _sprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      final image = await game.images.load('fruit_immunity.png');
      _sprite = Sprite(image);
    } catch (_) {
      // Fallback
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (collected) return;

    final floatOffset = math.sin(_time * 3.5) * 4.0;
    canvas.save();
    canvas.translate(0, floatOffset);

    // Cyan magical pulsing aura
    final pulseScale = 1.0 + math.sin(_time * 4) * 0.15;
    final auraPaint = Paint()
      ..color = const Color(0x8800E5FF)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0 * pulseScale);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 14 * pulseScale, auraPaint);

    if (_sprite != null) {
      _sprite!.render(
        canvas,
        position: Vector2.zero(),
        size: size,
      );
    } else {
      final paint = Paint()..color = const Color(0xFF00E5FF);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), 12, paint);
    }
    canvas.restore();
  }
}

class DecorationComponent extends PositionComponent {
  DecorationComponent({
    required super.position,
    required super.size,
    required this.variant,
  }) : super(priority: 1);

  final DecorationType variant;

  @override
  void render(Canvas canvas) {
    switch (variant) {
      case DecorationType.tree:
        _renderTree(canvas);
      case DecorationType.bush:
        _renderBush(canvas);
      case DecorationType.mushroom:
        _renderMushroom(canvas);
    }
  }

  void _renderTree(Canvas canvas) {
    // Trunk
    final trunkPaint = Paint()..color = const Color(0xFF4E342E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.4, size.y * 0.45, size.x * 0.2, size.y * 0.55),
        const Radius.circular(4),
      ),
      trunkPaint,
    );

    // Layered foliage canopy
    final darkCanopy = Paint()..color = const Color(0xFF1B5E20);
    canvas.drawOval(
      Rect.fromLTWH(size.x * 0.05, size.y * 0.1, size.x * 0.9, size.y * 0.55),
      darkCanopy,
    );

    final midCanopy = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawOval(
      Rect.fromLTWH(size.x * 0.12, 0, size.x * 0.76, size.y * 0.48),
      midCanopy,
    );

    final highlightCanopy = Paint()..color = const Color(0xFF43A047);
    canvas.drawOval(
      Rect.fromLTWH(size.x * 0.25, size.y * 0.04, size.x * 0.5, size.y * 0.3),
      highlightCanopy,
    );
  }

  void _renderBush(Canvas canvas) {
    final darkBush = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawOval(
      Rect.fromLTWH(0, size.y * 0.2, size.x, size.y * 0.8),
      darkBush,
    );

    final midBush = Paint()..color = const Color(0xFF43A047);
    canvas.drawOval(
      Rect.fromLTWH(size.x * 0.15, size.y * 0.05, size.x * 0.7, size.y * 0.7),
      midBush,
    );

    // Flowers / berries on the bush
    final flowerPaint = Paint()..color = const Color(0xFFFF4081);
    canvas.drawCircle(Offset(size.x * 0.3, size.y * 0.4), 4, flowerPaint);
    canvas.drawCircle(Offset(size.x * 0.7, size.y * 0.45), 4, flowerPaint);
    canvas.drawCircle(Offset(size.x * 0.5, size.y * 0.25), 4, flowerPaint);
  }

  void _renderMushroom(Canvas canvas) {
    // Stem
    final stemPaint = Paint()..color = const Color(0xFFFFF8E1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.38, size.y * 0.4, size.x * 0.24, size.y * 0.6),
        const Radius.circular(6),
      ),
      stemPaint,
    );

    // Mushroom Cap
    final capPaint = Paint()..color = const Color(0xFFE53935);
    canvas.drawArc(
      Rect.fromLTWH(size.x * 0.1, 0, size.x * 0.8, size.y * 0.65),
      math.pi,
      math.pi,
      true,
      capPaint,
    );

    // White polka dots
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.x * 0.32, size.y * 0.22), 4, dotPaint);
    canvas.drawCircle(Offset(size.x * 0.68, size.y * 0.22), 4, dotPaint);
    canvas.drawCircle(Offset(size.x * 0.5, size.y * 0.12), 5, dotPaint);
  }
}

enum DecorationType { tree, bush, mushroom }

