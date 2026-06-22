import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/asteroids_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock to landscape mode for arcade feel
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Hide system UI (fullscreen)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GameWidget(
          game: AsteroidsGame(),
          overlayBuilderMap: {
            'Intro': (context, AsteroidsGame game) {
              return IntroOverlay(game: game);
            },
            'Controls': (context, AsteroidsGame game) {
              return ControlsOverlay(game: game);
            },
            'GameOver': (context, AsteroidsGame game) {
              return GameOverOverlay(game: game);
            },
          },
        ),
      ),
    ),
  );
}

class IntroOverlay extends StatefulWidget {
  final AsteroidsGame game;
  const IntroOverlay({Key? key, required this.game}) : super(key: key);

  @override
  State<IntroOverlay> createState() => _IntroOverlayState();
}

class _IntroOverlayState extends State<IntroOverlay> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          border: Border.all(color: Colors.cyan, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "ASTEROIDS",
              style: TextStyle(color: Colors.cyan, fontSize: 64, fontFamily: 'Courier', fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "HIGH SCORE: ${widget.game.highScore}",
              style: const TextStyle(color: Colors.yellowAccent, fontSize: 28, fontFamily: 'Courier'),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: Colors.cyan, width: 2),
              ),
              onPressed: () {
                widget.game.startGame();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                child: Text("START GAME", style: TextStyle(color: Colors.cyan, fontSize: 24, fontFamily: 'Courier')),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                widget.game.resetHighScore();
                setState(() {});
              },
              child: const Text("Reset High Score", style: TextStyle(color: Colors.redAccent, fontFamily: 'Courier')),
            ),
          ],
        ),
      ),
    );
  }
}

class ControlsOverlay extends StatelessWidget {
  final AsteroidsGame game;
  const ControlsOverlay({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Rotation
              Row(
                children: [
                  _buildButton(Icons.rotate_left, () => game.ship.isRotatingLeft = true, () => game.ship.isRotatingLeft = false),
                  const SizedBox(width: 20),
                  _buildButton(Icons.rotate_right, () => game.ship.isRotatingRight = true, () => game.ship.isRotatingRight = false),
                ],
              ),
              // Center: Hyperspace
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildButton(Icons.flash_on, () => game.ship.hyperspace(), null),
              ),
              // Right side: Thrust and Fire
              Row(
                children: [
                  _buildButton(Icons.rocket_launch, () => game.ship.isThrusting = true, () => game.ship.isThrusting = false),
                  const SizedBox(width: 20),
                  _buildButton(Icons.gps_fixed, () => game.ship.fire(), null),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(IconData icon, VoidCallback onDown, VoidCallback? onUp) {
    return GestureDetector(
      onPanDown: (_) => onDown(),
      onPanEnd: (_) { if (onUp != null) onUp(); },
      onPanCancel: () { if (onUp != null) onUp(); },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 2),
        ),
        child: Icon(icon, color: Colors.cyan, size: 36),
      ),
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  final AsteroidsGame game;
  const GameOverOverlay({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool newHighScore = game.score > 0 && game.score == game.highScore;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          border: Border.all(color: Colors.cyan, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "GAME OVER",
              style: TextStyle(color: Colors.redAccent, fontSize: 48, fontFamily: 'Courier', fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (newHighScore)
              const Text(
                "NEW HIGH SCORE!",
                style: TextStyle(color: Colors.yellowAccent, fontSize: 24, fontFamily: 'Courier', fontWeight: FontWeight.bold),
              ),
            Text(
              "Score: ${game.score}",
              style: const TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Courier'),
            ),
            Text(
              "High Score: ${game.highScore}",
              style: const TextStyle(color: Colors.white70, fontSize: 20, fontFamily: 'Courier'),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: Colors.cyan, width: 2),
              ),
              onPressed: () {
                game.restartGame();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Text("PLAY AGAIN", style: TextStyle(color: Colors.cyan, fontSize: 20, fontFamily: 'Courier')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
