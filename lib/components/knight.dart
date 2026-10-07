import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class KnightComponent extends PositionComponent with CollisionCallbacks, HasGameReference {
  KnightComponent({required super.position})
      : super(size: Vector2(52, 68), anchor: Anchor.topLeft, priority: 10);

  static const double _moveSpeed = 190;
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

  Vector2 velocity = Vector2.zero();
  void Function()? onDamage;
  void Function()? onDefeat;
  void Function()? onCollectedFruit;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _hitbox = RectangleHitbox(
      position: Vector2(8, 8),
      size: Vector2(width - 16, height - 8),
      collisionType: CollisionType.active,
    );
    add(_hitbox);
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
      size = Vector2(58, 58);
    } else {
      size = Vector2(52, 68);
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
    if (isDefeated) return;

    if (isInvulnerable) {
      _invulnerabilityTimer -= dt;
      if (_invulnerabilityTimer <= 0) {
        isInvulnerable = false;
      }
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
    final paint = Paint()..color = isInvulnerable
        ? const Color(0xFF9EF5FF)
        : const Color(0xFF5EA0FF);
    final body = Rect.fromLTWH(position.x, position.y, size.x, size.y);
    canvas.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(10)), paint);
    final facingOffset = facing * 18;
    canvas.drawRect(
      Rect.fromLTWH(position.x + 8 + facingOffset, position.y + 20, 18, 18),
      Paint()..color = Colors.white,
    );
  }

  Rect get bounds => position & size;
}
