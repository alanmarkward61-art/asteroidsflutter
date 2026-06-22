import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import '../asteroids_game.dart';
import 'asteroid.dart';
import 'bullet.dart';

class Ship extends PositionComponent with CollisionCallbacks, HasGameRef<AsteroidsGame> {
  static const double rotationSpeed = 3.0; // Radians per second
  static const double thrustPower = 200.0;
  static const double drag = 0.98; // Friction/Inertia decay
  static const double maxSpeed = 400.0;

  Vector2 velocity = Vector2.zero();
  bool isRotatingLeft = false;
  bool isRotatingRight = false;
  bool isThrusting = false;
  
  double fireCooldown = 0;
  static const double fireRate = 0.25;

  Ship({required Vector2 position})
      : super(position: position, size: Vector2(20, 30), anchor: Anchor.center) {
    add(PolygonHitbox([
      Vector2(10, 0),
      Vector2(20, 30),
      Vector2(10, 25),
      Vector2(0, 30),
    ]));
  }

  void reset(Vector2 newPosition) {
    position = newPosition;
    velocity = Vector2.zero();
    angle = 0;
  }

  void fire() {
    if (fireCooldown > 0) return;
    
    FlameAudio.play('fire.wav', volume: 0.5);
    
    // Bullet spawns at the nose of the ship
    final direction = Vector2(cos(angle - pi / 2), sin(angle - pi / 2));
    final nosePosition = position + direction * (size.y / 2);
    
    final bullet = Bullet(position: nosePosition, direction: direction);
    gameRef.add(bullet);
    
    fireCooldown = fireRate;
  }

  void hyperspace() {
    FlameAudio.play('hyperspace.wav');
    final random = Random();
    
    // Randomize position
    position = Vector2(random.nextDouble() * gameRef.size.x, random.nextDouble() * gameRef.size.y);
    velocity = Vector2.zero(); // Optional: zero out velocity to save them
    
    // Risk of death logic can go here (e.g. 1 in 6 chance to just blow up)
    if (random.nextInt(6) == 0) {
      gameRef.onShipDestroyed();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (gameRef.gameState != GameState.playing) return;

    if (fireCooldown > 0) {
      fireCooldown -= dt;
    }

    if (isRotatingLeft) {
      angle -= rotationSpeed * dt;
    }
    if (isRotatingRight) {
      angle += rotationSpeed * dt;
    }

    if (isThrusting) {
      // Angle is 0 when pointing UP in Flame (if we draw it that way).
      // Standard math: UP is -pi/2.
      final direction = Vector2(cos(angle - pi / 2), sin(angle - pi / 2));
      velocity += direction * thrustPower * dt;
      
      // We could loop the thrust sound, but for now we'll just let it drift.
    }

    // Apply drag
    velocity *= drag;

    // Cap speed
    if (velocity.length > maxSpeed) {
      velocity = velocity.normalized() * maxSpeed;
    }

    position += velocity * dt;

    // Screen wrap
    if (position.x < 0) position.x = gameRef.size.x;
    if (position.x > gameRef.size.x) position.x = 0;
    if (position.y < 0) position.y = gameRef.size.y;
    if (position.y > gameRef.size.y) position.y = 0;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final path = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x, size.y)
      ..lineTo(size.x / 2, size.y - 5)
      ..lineTo(0, size.y)
      ..close();
    
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
      
    // Add glowing cyan effect
    final glowPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    if (isThrusting) {
      final flamePath = Path()
        ..moveTo(size.x / 2 - 4, size.y - 3)
        ..lineTo(size.x / 2, size.y + 10) // flame tip
        ..lineTo(size.x / 2 + 4, size.y - 3);

      final flamePaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
        
      canvas.drawPath(flamePath, flamePaint);
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Asteroid && gameRef.gameState == GameState.playing) {
      gameRef.onShipDestroyed();
      other.removeFromParent();
      gameRef.onAsteroidDestroyed(other);
    }
  }
}
