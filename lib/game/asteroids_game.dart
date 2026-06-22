import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'components/ship.dart';
import 'components/asteroid.dart';

enum GameState { playing, gameOver }

class AsteroidsGame extends FlameGame with HasCollisionDetection {
  late Ship ship;
  GameState gameState = GameState.playing;
  int score = 0;
  int lives = 3;
  int level = 1;

  final TextPaint textPaint = TextPaint(
    style: const TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Courier'),
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Configure audio
    FlameAudio.audioCache.prefix = 'assets/sounds/';
    await FlameAudio.audioCache.loadAll([
      'background 2.wav', 'background.wav', 'fire.wav', 
      'game win fanfare.mp3', 'hit.wav', 'hyperspace.wav', 'thrust.wav'
    ]);

    // Start background music
    FlameAudio.bgm.initialize();
    FlameAudio.bgm.play('background.wav', volume: 0.5);

    _startGame();
  }

  void _startGame() {
    score = 0;
    lives = 3;
    level = 1;
    gameState = GameState.playing;
    
    removeAll(children);
    overlays.add('Controls');
    overlays.remove('GameOver');

    ship = Ship(position: size / 2);
    add(ship);
    
    _spawnAsteroidsForLevel();
  }

  void restartGame() {
    _startGame();
  }

  void _spawnAsteroidsForLevel() {
    final random = Random();
    int asteroidCount = 3 + level;
    
    for (int i = 0; i < asteroidCount; i++) {
      Vector2 spawnPos;
      // Ensure asteroids don't spawn exactly on the ship
      do {
        spawnPos = Vector2(random.nextDouble() * size.x, random.nextDouble() * size.y);
      } while (spawnPos.distanceTo(size / 2) < 150);

      add(Asteroid(
        position: spawnPos,
        sizeType: AsteroidSize.large,
      ));
    }
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

    _checkLevelComplete();
  }

  void _checkLevelComplete() {
    // Schedule a microtask or future to check next frame, since children might not be removed yet
    Future.delayed(Duration.zero, () {
      final asteroids = children.whereType<Asteroid>();
      if (asteroids.isEmpty) {
        level++;
        _spawnAsteroidsForLevel();
      }
    });
  }

  void onShipDestroyed() {
    if (gameState != GameState.playing) return;
    
    FlameAudio.play('hit.wav');
    lives--;
    
    if (lives <= 0) {
      gameState = GameState.gameOver;
      overlays.remove('Controls');
      overlays.add('GameOver');
    } else {
      // Respawn ship
      ship.reset(size / 2);
      // Wait, we need to ensure the center is clear. 
      // For simplicity, we just reset it and give it a brief invulnerability if needed.
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    textPaint.render(canvas, "Score: $score", Vector2(20, 20));
    
    // Draw lives as mini ships
    for (int i = 0; i < lives; i++) {
      _drawMiniShip(canvas, Vector2(size.x - 40 - (i * 30), 30));
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
