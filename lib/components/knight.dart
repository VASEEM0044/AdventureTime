import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import '../game/sprite_atlas.dart';

/// Player knight. Source art is 32x32 per frame, rendered at 64x64
/// (exact 2x) with nearest-neighbour sampling to keep pixels crisp.
///
/// Verified animation map (knight.png, 8x8 grid of 32px):
/// idle = row 0 cols 0-3 | run = row 2 (8f) | roll = row 5 (8f) |
/// hit = row 6 cols 0-3 | death = row 7 cols 0-3 (no loop).
/// The sheet has NO jump/fall frames: airborne states reuse the run
/// cycle. Row 3 (run-with-dust) is a verified spare, not wired.
class KnightComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference {
  KnightComponent({required super.position})
      : super(size: Vector2.all(64), anchor: Anchor.topLeft, priority: 10);

  static const double _moveSpeed = 210;
  static const double _jumpForce = 460;
  static const double _gravity = 830;

  bool isGrounded = false;
  bool isDefeated = false;
  bool isInvulnerable = false;
  int facing = 1;
  double _moveInput = 0;
  bool _jumpRequested = false;
  bool _prevJumpHeld = false;
  bool _rollRequested = false;
  double _invulnerabilityTimer = 0;
  late final RectangleHitbox _hitbox;
  late final Paint _pixelPaint;

  SpriteAnimationTicker? _idleTicker;
  SpriteAnimationTicker? _runTicker;
  SpriteAnimationTicker? _rollTicker;
  SpriteAnimationTicker? _hurtTicker;
  SpriteAnimationTicker? _defeatTicker;

  Vector2 velocity = Vector2.zero();
  void Function()? onDamage;
  void Function()? onDefeat;
  void Function()? onCollectedFruit;

  bool get debugHasSprites =>
      _idleTicker != null &&
      _runTicker != null &&
      _rollTicker != null &&
      _hurtTicker != null &&
      _defeatTicker != null;

  /// True while the ROLL button is held (and not defeated). Rolling is the
  /// dodge: it plays the roll cycle and lets the knight pass through
  /// slimes unharmed (see AntigravityGame collision handling).
  bool get isRolling => _rollRequested && !isDefeated;

  /// Animation state name for tests/debug. 'air' reuses the run cycle
  /// (no jump/fall frames exist in the sheet).
  String get debugAnimName {
    if (isDefeated) return 'death';
    if (_rollRequested) return 'roll';
    if (isInvulnerable && _invulnerabilityTimer > 0.8) return 'hit';
    if (!isGrounded) return 'air';
    if (velocity.x.abs() > 10) return 'run';
    return 'idle';
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _pixelPaint = pixelPaint();
    _hitbox = RectangleHitbox(
      position: Vector2(12, 8),
      size: Vector2(width - 24, height - 10),
      collisionType: CollisionType.active,
    );
    add(_hitbox);

    // game.images is preloaded by AntigravityGame; load() hits the cache.
    final image = await game.images.load(SpriteFiles.knight);
    _idleTicker =
        SpriteAnimation.fromFrameData(image, KnightAtlas.idle()).createTicker();
    _runTicker =
        SpriteAnimation.fromFrameData(image, KnightAtlas.run()).createTicker();
    _rollTicker =
        SpriteAnimation.fromFrameData(image, KnightAtlas.roll()).createTicker();
    _hurtTicker =
        SpriteAnimation.fromFrameData(image, KnightAtlas.hit()).createTicker();
    _defeatTicker = SpriteAnimation.fromFrameData(image, KnightAtlas.death())
        .createTicker();
  }

  void setInput(double moveInput, bool jump, bool roll, double dt) {
    _moveInput = moveInput;
    _jumpRequested = jump;
    _rollRequested = roll;
    velocity.x = _moveInput * _moveSpeed;
    if (_moveInput != 0) {
      facing = _moveInput > 0 ? 1 : -1;
    }
    // Rising-edge jump: a held button jumps once per press and never
    // auto-bunny-hops on landing. Requires grounded state.
    if (_jumpRequested && !_prevJumpHeld && isGrounded) {
      velocity.y = -_jumpForce;
      isGrounded = false;
    }
    _prevJumpHeld = _jumpRequested;
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

  /// Advances only the death animation. Used by the game when the world
  /// simulation is frozen after death.
  void updateDefeat(double dt) {
    _defeatTicker?.update(dt);
  }

  /// Rewinds the death animation for a level restart.
  void resetAnimation() {
    _defeatTicker?.reset();
  }

  void takeDamage() {
    isInvulnerable = true;
    _invulnerabilityTimer = 1.2;
  }

  SpriteAnimationTicker? _currentTicker() {
    if (isDefeated) return _defeatTicker;
    if (_rollRequested) return _rollTicker;
    if (isInvulnerable && _invulnerabilityTimer > 0.8) return _hurtTicker;
    if (!isGrounded || velocity.x.abs() > 10) return _runTicker;
    return _idleTicker;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDefeated) {
      _defeatTicker?.update(dt);
      return;
    }

    if (isInvulnerable) {
      _invulnerabilityTimer -= dt;
      if (_invulnerabilityTimer <= 0) {
        isInvulnerable = false;
      }
    }

    _currentTicker()?.update(dt);

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

    final currentTicker = _currentTicker();
    if (currentTicker != null) {
      // Nearest-neighbour blit keeps the 32px art crisp at 64px.
      blitSprite(canvas, currentTicker.getSprite(), size, _pixelPaint);
    } else {
      // Stylized fallback knight (only if the sheet failed to load)
      final paint = Paint()
        ..color = isInvulnerable
            ? const Color(0xFF9EF5FF)
            : const Color(0xFF5EA0FF);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(10)),
          paint);
      canvas.drawRect(
          Rect.fromLTWH(facing > 0 ? size.x - 18 : 6, 16, 12, 12),
          Paint()..color = Colors.white);
    }

    canvas.restore();
  }

  Rect get bounds => position & size;
}
