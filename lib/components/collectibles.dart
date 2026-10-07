import 'dart:math' as math;
import 'dart:ui';

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

class CoinComponent extends Collectible {
  CoinComponent({required super.position})
      : super(size: Vector2.all(28));

  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    angle = math.sin(_time * 6) * 0.35;
  }

  @override
  void render(Canvas canvas) {
    if (collected) return;
    final rect = const Rect.fromLTWH(0, 0, 16, 16);
    final paint = Paint()..color = const Color(0xFFFFD052);
    canvas.save();
    canvas.translate(position.x, position.y);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), paint);
    canvas.drawCircle(Offset(12, 8), 6, Paint()..color = const Color(0xFFFFC94D));
    canvas.restore();
  }
}

class FruitComponent extends Collectible {
  FruitComponent({required super.position})
      : super(size: Vector2.all(26));

  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    position.y += math.sin(_time * 3) * 0.6;
  }

  @override
  void render(Canvas canvas) {
    if (collected) return;
    final paint = Paint()..color = const Color(0xFFB2FF70);
    canvas.drawCircle(Offset(position.x + 13, position.y + 13), 10, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(position.x + 7, position.y + 10, 12, 12),
        const Radius.circular(4),
      ),
      paint,
    );
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
    final paint = Paint()..color = switch (variant) {
      DecorationType.tree => const Color(0xFF2D7E4B),
      DecorationType.bush => const Color(0xFF4CAF50),
      DecorationType.mushroom => const Color(0xFFEB8A5D),
    };
    canvas.drawOval(size.toRect(), paint);
  }
}

enum DecorationType { tree, bush, mushroom }
