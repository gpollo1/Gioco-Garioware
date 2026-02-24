import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'game_objects.dart';
import 'package:flutter/material.dart';

class GameController {
  double fishX = 0;
  double fishY = 0;

  int score = 0;
  int lives = 3;
  int level = 1;

  double timeProgress = 1.0;
  String fishDirection = "down";

  final Random random = Random();

  List<Enemy> enemies = [];
  Goal goal = Goal(Offset.zero);
  Bonus? bonus;

  int fishesCaught = 0;
  bool isShowingSequence = false;
  bool isGameOver = false;

  Timer? gameTimer;
  StreamSubscription? accelSub;

  VoidCallback? onUpdate;
  VoidCallback? onGameOver;

  bool waitingNextRound = false;

  void start() {
    startLevel();
    startTimer();
    listenAccelerometer();
  }

  void startLevel() {
    final double minDistance = 0.25;

    // Spawn pesce
    fishX = random.nextDouble() * 2 - 1;
    fishY = random.nextDouble() * 2 - 1;

    enemies.clear();
    int enemyCount = 2 + level;

    // Spawn nemici
    for (int i = 0; i < enemyCount; i++) {
      Offset pos;
      bool tooClose;
      do {
        pos = Offset(random.nextDouble() * 2 - 1, random.nextDouble() * 2 - 1);
        tooClose = false;
        if ((pos - Offset(fishX, fishY)).distance < minDistance) {
          tooClose = true;
          continue;
        }
        for (var e in enemies) {
          if ((pos - e.position).distance < minDistance) {
            tooClose = true;
            break;
          }
        }
      } while (tooClose);
      enemies.add(Enemy(pos));
    }

    // Spawn goal (barca)
    Offset goalPos;
    bool goalTooClose;
    do {
      goalPos = Offset(random.nextDouble() * 2 - 1, random.nextDouble() * 2 - 1);
      goalTooClose = false;
      if ((goalPos - Offset(fishX, fishY)).distance < minDistance) {
        goalTooClose = true;
        continue;
      }
      for (var e in enemies) {
        if ((goalPos - e.position).distance < minDistance) {
          goalTooClose = true;
          break;
        }
      }
    } while (goalTooClose);
    goal = Goal(goalPos);

    // Spawn bonus
    bonus = null;
    if (random.nextDouble() < 0.25) {
      Offset bonusPos;
      bool bonusTooClose;
      do {
        bonusPos =
            Offset(random.nextDouble() * 2 - 1, random.nextDouble() * 2 - 1);
        bonusTooClose = false;
        if ((bonusPos - Offset(fishX, fishY)).distance < minDistance) {
          bonusTooClose = true;
          continue;
        }
        for (var e in enemies) {
          if ((bonusPos - e.position).distance < minDistance) {
            bonusTooClose = true;
            break;
          }
        }
        if ((bonusPos - goal.position).distance < minDistance) {
          bonusTooClose = true;
        }
      } while (bonusTooClose);

      bonus = Bonus(bonusPos);
    }

    timeProgress = 1.0;
    onUpdate?.call();
  }

  void listenAccelerometer() {
    accelSub = accelerometerEvents.listen((event) {
      // Movimento X e Y
      fishX -= event.x * 0.03;
      fishY += event.y * 0.03;

      fishX = fishX.clamp(-1.2, 1.2);
      fishY = fishY.clamp(-1.2, 1.2);

      // Direzione pesce
      if (event.y < -1) fishDirection = "up";
      if (event.y > 1) fishDirection = "down";
      if (event.x > 1) fishDirection = "left";
      if (event.x < -1) fishDirection = "right";

      checkCollisions();
      onUpdate?.call();
    });
  }

  void startTimer() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      timeProgress -= 0.002 * (1 + level * 0.2);

      if (timeProgress <= 0) {
        loseLife();
      }

      onUpdate?.call();
    });
  }

  void checkCollisions() {
    Offset fishPos = Offset(fishX, fishY);

    // Nemici: tocca gabbiano → perdi 1 vita ma non game over
    for (var e in enemies) {
      if ((fishPos - e.position).distance < 0.15) {
        lives--;
        enemies.remove(e); // gabbiano toccato sparisce
        onUpdate?.call();
        if (lives <= 0) {
          isGameOver = true;
          onGameOver?.call();
          stop();
        }
        return; // esce subito dalla funzione
      }
    }

    // Goal
    if ((fishPos - goal.position).distance < 0.15) {
      isShowingSequence = true;
      fishesCaught++;
      onUpdate?.call();
      return;
    }

    // Bonus
    if (bonus != null && (fishPos - bonus!.position).distance < 0.15) {
      lives++;
      bonus = null;
    }
  }

  void loseLife() {
    lives--;
    if (lives <= 0) {
      isGameOver = true;
      onGameOver?.call();
      stop();
    } else {
      startLevel();
    }
  }

  void nextLevel() {
    score += 100;
    level++;
    startLevel();
  }

  void stop() {
    gameTimer?.cancel();
    accelSub?.cancel();
  }
}