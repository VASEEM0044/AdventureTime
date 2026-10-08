import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class KnightComponent extends PositionComponent with CollisionCallbacks, HasGameReference {
  KnightComponent({required super.position})
      : super(size: Vector2(56, 68), anchor: Anchor.topLeft, priority: 10);

  static const double _moveSpeed = 210;
  static const double _jumpForce = 460;
  static const double _gravity = 830;

  bool isGrounded = false;
  bool isDefeated = false;
  bool isInvulnerable = false;
  int facing = 1;
  double _moveInput = 0;
  bool _jumpRequested = false;
  bool _rollRequested = false;
  double _invulnerabilityTimer = 0;
  late final RectangleHitbox _hitbox;

  SpriteAnimation? _idleAnimation;
  SpriteAnimation? _runAnimation;
  SpriteAnimation? _rollAnimation;
  SpriteAnimation? _hurtAnimation;
  SpriteAnimation? _defeatAnimation;

  Vector2 velocity = Vector2.zero();
  void Function()? onDamage;
  void Function()? onDefeat;
  void Function()? onCollectedFruit;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _hitbox = RectangleHitbox(
      position: Vector2(10, 8),
      size: Vector2(width - 20, height - 12),
      collisionType: CollisionType.active,
    );
    add(_hitbox);

    try {
      final image = await game.images.load('knight.png');

      // Row 0: Idle (4 frames of 32x32)
      _idleAnimation = SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.16,
          textureSize: Vector2(32, 32),
          texturePosition: Vector2(0, 0),
        ),
      );

      // Row 2: Run (8 frames of 32x32)
      _runAnimation = SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: 8,
          stepTime: 0.09,
          textureSize: Vector2(32, 32),
          texturePosition: Vector2(0, 64),
        ),
      );

      // Row 5: Roll (8 frames of 32x32)
      _rollAnimation = SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: 8,
          stepTime: 0.07,
          textureSize: Vector2(32, 32),
          texturePosition: Vector2(0, 160),
        ),
      );

      // Row 6: Hurt (4 frames of 32x32)
      _hurtAnimation = SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.12,
          textureSize: Vector2(32, 32),
          texturePosition: Vector2(0, 192),
        ),
      );

      // Row 7: Defeat (4 frames of 32x32)
      _defeatAnimation = SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.15,
          textureSize: Vector2(32, 32),
          texturePosition: Vector2(0, 224),
          loop: false,
        ),
      );
    } catch (_) {
      // Fallback
    }
  }

  void setInput(double moveInput, bool jump, bool roll, double dt) {
    _moveInput = moveInput;
    _jumpRequested = jump;
    _rollRequested = roll;
    velocity.x = _moveInput * _moveSpeed;
    if (_moveInput != 0) {
      facing = _moveInput > 0 ? 1 : -1;
    }
    if (_jumpRequested && isGrounded) {
      velocity.y = -_jumpForce;
      isGrounded = false;
    }
    if (_rollRequested) {
      size = Vector2(58, 54);
    } else {
      size = Vector2(56, 68);
    }
  }

  void activateImmunity() {
    isInvulnerable = true;
    _invulnerabilityTimer = 8;
    onCollectedFruit?.call();
  }

  void defeat() {
    isDefeated = true;
    velocity.setZero();
  }

  void takeDamage() {
    isInvulnerable = true;
    _invulnerabilityTimer = 1.2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDefeated) {
      _defeatAnimation?.update(dt);
      return;
    }

    if (isInvulnerable) {
      _invulnerabilityTimer -= dt;
      if (_invulnerabilityTimer <= 0) {
        isInvulnerable = false;
      }
    }

    // Update current active animation
    if (_rollRequested) {
      _rollAnimation?.update(dt);
    } else if (isInvulnerable && _invulnerabilityTimer > 0.8) {
      _hurtAnimation?.update(dt);
    } else if (velocity.x.abs() > 10) {
      _runAnimation?.update(dt);
    } else {
      _idleAnimation?.update(dt);
    }

    velocity.y += _gravity * dt;
    position += velocity * dt;

    if (position.y > 900) {
      position.y = 60;
      velocity.y = 0;
      onDamage?.call();
    }

    final groundY = 900 - 96;
    if (position.y + height >= groundY && velocity.y >= 0) {
      position.y = groundY - height;
      velocity.y = 0;
      isGrounded = true;
    } else {
      isGrounded = false;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();

    // Subtle contact shadow
    final shadowPaint = Paint()..color = const Color(0x55000000);
    canvas.drawOval(
      Rect.fromLTWH(8, size.y - 6, size.x - 16, 8),
      shadowPaint,
    );

    // Invulnerability flashing or shield aura
    if (isInvulnerable) {
      if (_invulnerabilityTimer > 1.5) {
        // Star fruit immunity aura
        final auraPaint = Paint()
          ..color = const Color(0x6600E5FF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(Offset(size.x / 2, size.y / 2), 34, auraPaint);
      } else {
        // Damage flicker
        final shouldFlicker = (_invulnerabilityTimer * 12).toInt().isOdd;
        if (shouldFlicker) {
          canvas.restore();
          return;
        }
      }
    }

    // Flip horizontally when facing left
    if (facing < 0) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }

    SpriteAnimation? currentAnim;
    if (isDefeated) {
      currentAnim = _defeatAnimation;
    } else if (_rollRequested) {
      currentAnim = _rollAnimation;
    } else if (isInvulnerable && _invulnerabilityTimer > 0.8) {
      currentAnim = _hurtAnimation;
    } else if (velocity.x.abs() > 10) {
      currentAnim = _runAnimation;
    } else {
      currentAnim = _idleAnimation;
    }

    if (currentAnim != null) {
      currentAnim.getSprite().render(
        canvas,
        position: Vector2.zero(),
        size: size,
      );
    } else {
      // Stylized fallback knight
      final paint = Paint()..color = isInvulnerable ? const Color(0xFF9EF5FF) : const Color(0xFF5EA0FF);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(10)), paint);
      canvas.drawRect(Rect.fromLTWH(facing > 0 ? size.x - 18 : 6, 16, 12, 12), Paint()..color = Colors.white);
    }

    canvas.restore();
  }

  Rect get bounds => position & size;
}

