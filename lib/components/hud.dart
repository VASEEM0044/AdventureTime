import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HudComponent extends PositionComponent {
  HudComponent({required this.coinCount, required this.health, required this.immunity})
      : super(position: Vector2.zero(), size: Vector2(800, 110), priority: 50);

  final ValueNotifier<int> coinCount;
  final ValueNotifier<int> health;
  final ValueNotifier<bool> immunity;

  @override
  void render(Canvas canvas) {
    final bg = Paint()..color = const Color(0xCC101B3C);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, width, 80), const Radius.circular(18)), bg);

    final coinPaint = Paint()..color = const Color(0xFFF6C453);
    canvas.drawCircle(const Offset(52, 40), 15, coinPaint);
    final text = TextPainter(
      text: TextSpan(text: 'x${coinCount.value}', style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, const Offset(80, 22));

    final heartPaint = Paint()..color = const Color(0xFFFF6B6B);
    for (var i = 0; i < health.value; i++) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(230 + i * 34.0, 24, 24, 24), const Radius.circular(6)), heartPaint);
    }

    if (immunity.value) {
      final timer = TextPainter(
        text: const TextSpan(text: 'IMMUNE', style: TextStyle(fontSize: 18, color: Color(0xFF7AF0FF), fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout();
      timer.paint(canvas, const Offset(420, 26));
    }
  }
}
