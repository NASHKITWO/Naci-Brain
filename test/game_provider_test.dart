import 'package:flutter_test/flutter_test.dart';
import 'package:naci_brain/providers/game_provider.dart';
import 'package:naci_brain/utils/constants.dart';

void main() {
  testWidgets('modes without a clock do not end by themselves',
      (WidgetTester tester) async {
    for (final mode in [GameMode.endless, GameMode.timeAttack, GameMode.zen]) {
      final game = GameProvider();
      game.startGame(mode);
      await tester.pump(const Duration(seconds: 3));
      expect(game.status, GameStatus.playing, reason: '$mode');

      await tester.pump(const Duration(seconds: 30));
      expect(game.status, GameStatus.playing, reason: '$mode');
      expect(game.elapsedSeconds, 30, reason: '$mode');
      game.dispose();
    }
  });

  testWidgets('classic ends exactly when the 60 seconds are up',
      (WidgetTester tester) async {
    final game = GameProvider();
    game.startGame(GameMode.classic);
    await tester.pump(const Duration(seconds: 3));
    expect(game.timeRemaining, 60);

    await tester.pump(const Duration(seconds: 59));
    expect(game.timeRemaining, 1);
    expect(game.status, GameStatus.playing);

    await tester.pump(const Duration(seconds: 1));
    expect(game.status, GameStatus.gameOver);
    game.dispose();
  });

  testWidgets('answers are scored and mistakes are counted',
      (WidgetTester tester) async {
    final game = GameProvider();
    game.startGame(GameMode.endless);
    await tester.pump(const Duration(seconds: 3));

    final q1 = game.currentQuestion!;
    game.submitAnswer(q1.options.indexWhere((o) => o != q1.correctAnswer));
    expect(game.wrongAnswers, 1);
    expect(game.livesRemaining, 2);
    expect(game.combo, 0);
    await tester.pump(const Duration(milliseconds: 500));

    final q2 = game.currentQuestion!;
    game.submitAnswer(q2.correctOptionIndex);
    expect(game.correctAnswers, 1);
    expect(game.combo, 1);
    expect(game.score, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 500));

    game.dispose();
  });

  testWidgets('endless ends after three mistakes', (WidgetTester tester) async {
    final game = GameProvider();
    game.startGame(GameMode.endless);
    await tester.pump(const Duration(seconds: 3));

    for (int i = 0; i < 3; i++) {
      final q = game.currentQuestion!;
      game.submitAnswer(q.options.indexWhere((o) => o != q.correctAnswer));
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(game.status, GameStatus.gameOver);
    expect(game.wrongAnswers, 3);
    game.dispose();
  });

  testWidgets('time attack ends after 20 answers', (WidgetTester tester) async {
    final game = GameProvider();
    game.startGame(GameMode.timeAttack);
    await tester.pump(const Duration(seconds: 3));

    for (int i = 0; i < GameConstants.timeAttackQuestions; i++) {
      game.submitAnswer(game.currentQuestion!.correctOptionIndex);
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(game.status, GameStatus.gameOver);
    expect(game.correctAnswers, GameConstants.timeAttackQuestions);
    game.dispose();
  });
}
