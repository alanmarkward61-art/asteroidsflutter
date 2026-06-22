import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../asteroids_game.dart';
import 'asteroid.dart';

class Bullet extends PositionComponent with CollisionCallbacks, HasGameRef<AsteroidsGame> {
  final Vector2 direction;
  final double speed = 600.0;
  final double maxLifespan = 1.0;
  double lifespan = 0;

  Bullet({required Vector2 position, required this.direction})
      : super(position: position, size: Vector2(4, 4), anchor: Anchor.center) {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.gameState != GameState.playing) return;

    position += direction * speed * dt;
    lifespan += dt;

    if (lifespan >= maxLifespan) {
      removeFromParent();
    }

    // Wrap around
    if (position.x < 0) position.x = gameRef.size.x;
    if (position.x > gameRef.size.x) position.x = 0;
    if (position.y < 0) position.y = gameRef.size.y;
    if (position.y > gameRef.size.y) position.y = 0;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = Colors.white;
    
    final glowPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    canvas.drawCircle(const Offset(2, 2), 2, glowPaint);
    canvas.drawCircle(const Offset(2, 2), 1.5, paint);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Asteroid) {
      removeFromParent();
      other.removeFromParent();
      gameRef.onAsteroidDestroyed(other);
    }
  }
}
