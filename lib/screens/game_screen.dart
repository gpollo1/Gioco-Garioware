import 'package:flutter/material.dart';
import '../game/game_controller.dart';
import '../widgets/hud.dart';
import 'splash_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GameController controller = GameController();

  int sequenceStep = 0;
  bool showPointsScreen = false;
  bool showLoseScreen = false;
  bool waitingDoubleTap = false;

  int gameNumber = 1; // contatore partite

  @override
  void initState() {
    super.initState();

    controller.onUpdate = () {
      if (controller.isShowingSequence && !waitingDoubleTap) {
        startWinSequence();
      }
      setState(() {});
    };

    controller.onGameOver = startLoseSequence;

    controller.start();
  }

  void startWinSequence() async {
    controller.isShowingSequence = false;

    // blocca il pesce durante la sequenza
    controller.stop();

    sequenceStep = 1;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 600));

    sequenceStep = 2;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 600));

    sequenceStep = 3;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 600));

    showPointsScreen = true;
    waitingDoubleTap = true; // aspetta doppio tap
    setState(() {});
  }

  void continueAfterWin() {
    if (!waitingDoubleTap) return;

    waitingDoubleTap = false;
    showPointsScreen = false;
    sequenceStep = 0;

    gameNumber++;
    controller.nextLevel();
    controller.startTimer();
    controller.listenAccelerometer();

    setState(() {});
  }

  void startLoseSequence() {
    showLoseScreen = true;
    controller.stop();
    setState(() {});
  }

  @override
  void dispose() {
    controller.stop();
    super.dispose();
  }

  String fishAsset() => "assets/images/fish_${controller.fishDirection}.png";

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: continueAfterWin,
      child: Scaffold(
        body: Stack(
          children: [
            // Sfondo mare
            Positioned.fill(
              child: Image.asset("assets/images/mare.png", fit: BoxFit.cover),
            ),

            // Pesce (libero movimento in X e Y)
            Align(
              alignment: Alignment(controller.fishX, controller.fishY),
              child: Image.asset(fishAsset(), width: 60),
            ),

            // Nemici (gabbiani)
            ...controller.enemies.map(
                  (e) => Align(
                alignment: Alignment(e.position.dx, e.position.dy),
                child: Image.asset("assets/images/enemy.png", width: 50),
              ),
            ),

            // Goal (barca)
            Align(
              alignment: Alignment(controller.goal.position.dx, controller.goal.position.dy),
              child: Image.asset("assets/images/goal.png", width: 60),
            ),

            // Bonus (vite extra)
            if (controller.bonus != null)
              Align(
                alignment: Alignment(controller.bonus!.position.dx, controller.bonus!.position.dy),
                child: Image.asset("assets/images/bonus.png", width: 50),
              ),

            // HUD: score + vite con icone
            Positioned(
              top: 40,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset("assets/images/points.png", width: 25),
                      const SizedBox(width: 5),
                      Text(
                        "${controller.score}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 3, color: Colors.black)],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset("assets/images/bonus.png", width: 25),
                      const SizedBox(width: 5),
                      Text(
                        "${controller.lives}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 3, color: Colors.black)],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Barra tempo più evidente
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: controller.timeProgress,
                minHeight: 12,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ),

            // sequenza vittoria 3 frame (presa1,2,3)
            if (sequenceStep > 0)
              Positioned.fill(
                child: Image.asset(
                  "assets/images/presa$sequenceStep.png",
                  fit: BoxFit.contain,
                ),
              ),

            // schermata punti ridotta
            if (showPointsScreen)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          "assets/images/points.png",
                          width: 150,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Partita $gameNumber\nPesci catturati: ${controller.fishesCaught}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 36,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(blurRadius: 5, color: Colors.black)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // schermata perdita (pescatore)
            if (showLoseScreen)
              Positioned.fill(
                child: Column(
                  children: [
                    Expanded(
                      child: Image.asset(
                        "assets/images/hai_perso.png",
                        fit: BoxFit.contain,
                        height: 300, // immagine più piccola
                      ),
                    ),
                    const SizedBox(height: 20),
                    // info punteggio e vite
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset("assets/images/points.png", width: 30),
                        const SizedBox(width: 5),
                        Text(
                          "${controller.score}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(blurRadius: 3, color: Colors.black)],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Image.asset("assets/images/bonus.png", width: 30),
                        const SizedBox(width: 5),
                        Text(
                          "${controller.lives}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(blurRadius: 3, color: Colors.black)],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    IconButton(
                      iconSize: 60,
                      color: Colors.white,
                      icon: const Icon(Icons.arrow_circle_left),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const SplashScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}