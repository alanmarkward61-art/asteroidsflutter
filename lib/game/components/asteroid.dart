import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../asteroids_game.dart';

enum AsteroidSize { large, medium, small }

class Asteroid extends PositionComponent with CollisionCallbacks, HasGameRef<AsteroidsGame> {
  final AsteroidSize sizeType;
  Vector2 velocity = Vector2.zero();
  double rotationalSpeed = 0;
  bool isDestroyed = false;
  
  late Path polygonPath;

  Asteroid({required Vector2 position, required this.sizeType})
      : super(position: position, anchor: Anchor.center) {
    
    double radius;
    switch (sizeType) {
      case AsteroidSize.large: radius = 40; break;
      case AsteroidSize.medium: radius = 20; break;
      case AsteroidSize.small: radius = 10; break;
    }
    size = Vector2.all(radius * 2);

    final random = Random();
    
    // Randomize velocity based on size
    double baseSpeed = 50 + random.nextDouble() * 50;
    if (sizeType == AsteroidSize.medium) baseSpeed *= 1.5;
    if (sizeType == AsteroidSize.small) baseSpeed *= 2.0;

    final angle = random.nextDouble() * 2 * pi;
    velocity = Vector2(cos(angle), sin(angle)) * baseSpeed;
    
    rotationalSpeed = (random.nextDouble() - 0.5) * 2.0;

    // Generate jagged polygon
    polygonPath = _generateAsteroidPath(radius);
    
    // For simplicity, circular hitbox
    add(CircleHitbox(radius: radius, position: Vector2.all(radius)));
  }

  Path _generateAsteroidPath(double radius) {
    final random = Random();
    final path = Path();
    int points = 8 + random.nextInt(5);
    
    for (int i = 0; i < points; i++) {
      double a = (i / points) * 2 * pi;
      // Variance in radius to make it jagged
      double r = radius * (0.7 + random.nextDouble() * 0.3);
      double px = radius + cos(a) * r;
      double py = radius + sin(a) * r;
      
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    return path;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.gameState != GameState.playing) return;

    position += velocity * dt;
    angle += rotationalSpeed * dt;

    // Screen wrap
    if (position.x < -size.x) position.x = gameRef.size.x + size.x;
    if (position.x > gameRef.size.x + size.x) position.x = -size.x;
    if (position.y < -size.y) position.y = gameRef.size.y + size.y;
    if (position.y > gameRef.size.y + size.y) position.y = -size.y;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    Color strokeColor;
    switch (sizeType) {
      case AsteroidSize.large: strokeColor = Colors.white; break;
      case AsteroidSize.medium: strokeColor = Colors.cyan; break;
      case AsteroidSize.small: strokeColor = Colors.purpleAccent; break;
    }

    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0; // Crisp thick vector lines instead of blurry glow

    canvas.drawPath(polygonPath, paint);
  }
}
