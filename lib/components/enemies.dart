import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class EnemyComponent extends PositionComponent {
  EnemyComponent({
    required super.position,
    required super.size,
    required this.color,
    required this.direction,
  }) : super(priority: 4);

  final Color color;
  int direction;
  bool isAlive = true;

  @override
  void update(double dt) {
    if (!isAlive) return;
    position.x += direction * 90 * dt;
    if (position.x < 300 || position.x > 5100) {
      direction *= -1;
    }
  }

  void defeat() {
    isAlive = false;
    removeFromParent();
  }

  Rect get bounds => position & size;

  @override
  void render(Canvas canvas) {
    if (!isAlive) return;
    final paint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(12)),
      paint,
    );
    canvas.drawCircle(Offset(position.x + size.x * 0.5, position.y + 8), 6, Paint()..color = Colors.white);
  }
}
