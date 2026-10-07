import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum PlatformType { ground, grass, sand, gold, ice }

class PlatformComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference {
  PlatformComponent({
    required this.id,
    required super.position,
    required super.size,
    required this.type,
  }) : super(priority: 2);

  final String id;
  final PlatformType type;
  late final RectangleHitbox _hitbox;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _hitbox = RectangleHitbox(
      position: Vector2(0, 0),
      size: size,
      isSolid: true,
    );
    add(_hitbox);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..style = PaintingStyle.fill;
    final colors = {
      PlatformType.ground: const Color(0xFF7C4E2A),
      PlatformType.grass: const Color(0xFF5AA66E),
      PlatformType.sand: const Color(0xFFC7A65B),
      PlatformType.gold: const Color(0xFFD7B63E),
      PlatformType.ice: const Color(0xFF8DE7FF),
    };
    paint.color = colors[type] ?? Colors.white;
    canvas.drawRect(size.toRect(), paint);
  }
}
