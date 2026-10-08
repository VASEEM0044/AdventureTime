import 'dart:ui' as ui;
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

  ui.Image? _platformSheet;
  Sprite? _leftSprite;
  Sprite? _midSprite;
  Sprite? _rightSprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _hitbox = RectangleHitbox(
      position: Vector2(0, 0),
      size: size,
      isSolid: true,
    );
    add(_hitbox);

    try {
      _platformSheet = await game.images.load('platforms.png');
      final rowIndex = switch (type) {
        PlatformType.grass => 0,
        PlatformType.sand => 1,
        PlatformType.gold => 2,
        PlatformType.ice => 3,
        PlatformType.ground => 0,
      };

      final yOffset = rowIndex * 16.0;
      _leftSprite = Sprite(
        _platformSheet!,
        srcPosition: Vector2(0, yOffset),
        srcSize: Vector2(16, 9),
      );
      _midSprite = Sprite(
        _platformSheet!,
        srcPosition: Vector2(16, yOffset),
        srcSize: Vector2(16, 9),
      );
      _rightSprite = Sprite(
        _platformSheet!,
        srcPosition: Vector2(32, yOffset),
        srcSize: Vector2(16, 9),
      );
    } catch (_) {
      // Fallback rendering handles if sheet is unavailable
    }
  }

  @override
  void render(Canvas canvas) {
    if (type == PlatformType.ground) {
      _renderGround(canvas);
      return;
    }

    if (_leftSprite != null && _midSprite != null && _rightSprite != null) {
      _renderSpritePlatform(canvas);
    } else {
      _renderFallbackPlatform(canvas);
    }
  }

  void _renderGround(Canvas canvas) {
    final rect = size.toRect();

    // Deep underground gradient
    final dirtGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF4A2E1B),
        Color(0xFF2C190E),
        Color(0xFF190E08),
      ],
    );
    final dirtPaint = Paint()..shader = dirtGradient.createShader(rect);
    canvas.drawRect(rect, dirtPaint);

    // Underground bedrock line
    final bedRockPaint = Paint()..color = const Color(0x33000000);
    for (double y = 28; y < size.y; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), bedRockPaint);
    }

    // Top lush grass strip
    final grassTopPaint = Paint()..color = const Color(0xFF43A047);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, 14), grassTopPaint);

    final grassHighlight = Paint()..color = const Color(0xFF76D275);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, 4), grassHighlight);

    // Grass edge fringe details
    final fringePaint = Paint()..color = const Color(0xFF2E7D32);
    for (double x = 0; x < size.x; x += 24) {
      canvas.drawRect(Rect.fromLTWH(x, 14, 12, 4), fringePaint);
    }

    // Surface highlight line
    final surfaceLine = Paint()..color = const Color(0xFFB9F5D8)..strokeWidth = 1.5;
    canvas.drawLine(const Offset(0, 1), Offset(size.x, 1), surfaceLine);
  }

  void _renderSpritePlatform(Canvas canvas) {
    final capWidth = (size.y * (16 / 9)).clamp(16.0, 32.0);
    final h = size.y;

    // Platform drop shadow
    final shadowPaint = Paint()..color = const Color(0x55000000);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.x - 8, size.y),
        const Radius.circular(4),
      ),
      shadowPaint,
    );

    // Draw left cap
    _leftSprite!.render(
      canvas,
      position: Vector2(0, 0),
      size: Vector2(capWidth, h),
    );

    // Draw repeating center segments
    double currentX = capWidth;
    final maxX = size.x - capWidth;
    while (currentX < maxX) {
      final drawWidth = (maxX - currentX).clamp(0.0, capWidth);
      _midSprite!.render(
        canvas,
        position: Vector2(currentX, 0),
        size: Vector2(drawWidth, h),
      );
      currentX += capWidth;
    }

    // Draw right cap
    _rightSprite!.render(
      canvas,
      position: Vector2(size.x - capWidth, 0),
      size: Vector2(capWidth, h),
    );
  }

  void _renderFallbackPlatform(Canvas canvas) {
    final rect = size.toRect();
    final colors = {
      PlatformType.grass: const [Color(0xFF43A047), Color(0xFF2E7D32)],
      PlatformType.sand: const [Color(0xFFE0C068), Color(0xFFC7A65B)],
      PlatformType.gold: const [Color(0xFFFFD54F), Color(0xFFFFA000)],
      PlatformType.ice: const [Color(0xFF80DEEA), Color(0xFF00ACC1)],
      PlatformType.ground: const [Color(0xFF5D4037), Color(0xFF3E2723)],
    };

    final gradientColors = colors[type] ?? const [Colors.grey, Colors.blueGrey];
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradientColors,
      ).createShader(rect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      paint,
    );
  }
}

