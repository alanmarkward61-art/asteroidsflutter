import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'components/ship.dart';
import 'components/asteroid.dart';

enum GameState { menu, playing, gameOver }

class AsteroidsGame extends FlameGame with HasCollisionDetection {
  late Ship ship;
  GameState gameState = GameState.menu;
  int score = 0;
  int highScore = 0;
  int lives = 3;
  int level = 1;
  bool isSpawning = false;

  final TextPaint textPaint = TextPaint(
    style: const TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Courier'),
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Configure audio (Removed background noise)
    FlameAudio.audioCache.prefix = 'assets/sounds/';
    await FlameAudio.audioCache.loadAll([
      'fire.wav', 'game win fanfare.mp3', 'hit.wav', 'hyperspace.wav', 'thrust.wav'
    ]);

    gameState = GameState.menu;
    overlays.add('Intro');
  }

  void startGame() {
    score = 0;
    lives = 3;
    level = 1;
    gameState = GameState.playing;
    
    removeAll(children);
    overlays.remove('Intro');
    overlays.remove('GameOver');
    overlays.add('Controls');

    ship = Ship(position: size / 2);
    add(ship);
    
    _spawnAsteroidsForLevel();
  }

  void restartGame() {
    startGame();
  }

  void resetHighScore() {
    highScore = 0;
  }

  void _checkHighScore() {
    if (score > highScore) {
      highScore = score;
    }
  }

  void _spawnAsteroidsForLevel() {
    isSpawning = true;
    final random = Random();
    int asteroidCount = 3 + level;
    
    for (int i = 0; i < asteroidCount; i++) {
      Vector2 spawnPos;
      // Ensure asteroids don't spawn exactly on the center
      do {
        spawnPos = Vector2(random.nextDouble() * size.x, random.nextDouble() * size.y);
      } while (spawnPos.distanceTo(size / 2) < 200);

      add(Asteroid(
        position: spawnPos,
        sizeType: AsteroidSize.large,
      ));
    }
    isSpawning = false;
  }

  void onAsteroidDestroyed(Asteroid asteroid) {
    if (gameState != GameState.playing) return;

    FlameAudio.play('hit.wav');
    
    if (asteroid.sizeType == AsteroidSize.large) {
      score += 20;
      add(Asteroid(position: asteroid.position.clone(), sizeType: AsteroidSize.medium));
      add(Asteroid(position: asteroid.position.clone(), sizeType: AsteroidSize.medium));
    } else if (asteroid.sizeType == AsteroidSize.medium) {
      score += 50;
      add(Asteroid(position: asteroid.position.clone(), sizeType: AsteroidSize.small));
      add(Asteroid(position: asteroid.position.clone(), sizeType: AsteroidSize.small));
    } else {
      score += 100;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameState == GameState.playing) {
      // Level progression fix: Check directly in update loop
      if (!isSpawning && children.whereType<Asteroid>().isEmpty) {
        level++;
        _spawnAsteroidsForLevel();
      }
    }
  }

  void onShipDestroyed() {
    if (gameState != GameState.playing) return;
    
    FlameAudio.play('hit.wav');
    
    // Spawn explosion particles
    _spawnExplosion(ship.position.clone());
    
    lives--;
    
    if (lives <= 0) {
      gameState = GameState.gameOver;
      _checkHighScore();
      overlays.remove('Controls');
      overlays.add('GameOver');
    } else {
      // Respawn ship
      ship.reset(size / 2);
    }
  }

  void _spawnExplosion(Vector2 pos) {
    final random = Random();
    add(
      ParticleSystemComponent(
        position: pos,
        particle: Particle.generate(
          count: 30,
          lifespan: 1.0,
          generator: (i) {
            final angle = random.nextDouble() * 2 * pi;
            final speed = random.nextDouble() * 150 + 50;
            final velocity = Vector2(cos(angle), sin(angle)) * speed;
            return AcceleratedParticle(
              speed: velocity, // initial speed
              child: ComputedParticle(
                renderer: (canvas, particle) {
                  final paint = Paint()
                    ..color = random.nextBool() ? Colors.white : Colors.cyan
                    ..strokeWidth = 2.0;
                  // Draw a short line representing a shattered piece
                  canvas.drawLine(Offset.zero, Offset(velocity.normalized().x * 10, velocity.normalized().y * 10), paint);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (gameState == GameState.playing) {
      textPaint.render(canvas, "Score: $score", Vector2(20, 20));
      
      // Draw lives as mini ships
      for (int i = 0; i < lives; i++) {
        _drawMiniShip(canvas, Vector2(size.x - 40 - (i * 30), 30));
      }
    }
  }

  void _drawMiniShip(Canvas canvas, Vector2 pos) {
    final path = Path()
      ..moveTo(pos.x, pos.y - 10)
      ..lineTo(pos.x + 8, pos.y + 10)
      ..lineTo(pos.x, pos.y + 5)
      ..lineTo(pos.x - 8, pos.y + 10)
      ..close();
    
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
      
    canvas.drawPath(path, paint);
  }
}
