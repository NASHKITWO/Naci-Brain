import 'package:flutter_test/flutter_test.dart';
import 'package:naci_brain/models/daily_challenge.dart';
import 'package:naci_brain/models/question.dart';
import 'package:naci_brain/services/storage_service.dart';
import 'package:naci_brain/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('a finished game updates stats, high score, rewards and achievements',
      () async {
    final storage = await StorageService.create();
    const result = GameResult(
      mode: GameMode.classic,
      score: 120,
      correctAnswers: 12,
      wrongAnswers: 0,
      maxCombo: 6,
      timeTakenSeconds: 60,
    );

    final outcome = await storage.recordGame(result);

    expect(outcome.isNewHighScore, isTrue);
    expect(storage.getHighScore(GameMode.classic), 120);
    expect(storage.totalGamesPlayed, 1);
    expect(storage.totalCorrectAnswers, 12);
    expect(storage.totalAnswers, 12);
    expect(storage.bestCombo, 6);
    expect(storage.coins, result.coinsEarned);
    expect(storage.xp, result.xpEarned);
    expect(
      outcome.newAchievements.map((a) => a.id),
      containsAll(['first_game', 'score_100', 'combo_5', 'perfect_game']),
    );

    // A lower score later is not a new high score and unlocks nothing twice.
    final again = await storage.recordGame(const GameResult(
      mode: GameMode.classic,
      score: 50,
      correctAnswers: 5,
      wrongAnswers: 1,
      maxCombo: 2,
      timeTakenSeconds: 60,
    ));
    expect(again.isNewHighScore, isFalse);
    expect(again.newAchievements, isEmpty);
    expect(storage.getHighScore(GameMode.classic), 120);
    expect(storage.totalGamesPlayed, 2);
  });

  test('xp rolls over into levels', () async {
    final storage = await StorageService.create();
    final outcome = await storage.recordGame(const GameResult(
      mode: GameMode.zen,
      score: 5000,
      correctAnswers: 100,
      wrongAnswers: 0,
      maxCombo: 20,
      timeTakenSeconds: 300,
    ));
    expect(outcome.leveledUp, isTrue);
    expect(storage.level, 3);
    expect(storage.xp, 0);
  });

  test('a daily challenge reward can only be claimed once', () async {
    final storage = await StorageService.create();
    final challenge = DailyChallenge.forDate(DateTime.now())[0];

    expect(await storage.claimChallenge(challenge), isTrue);
    expect(storage.coins, challenge.coins);
    expect(await storage.claimChallenge(challenge), isFalse);
    expect(storage.coins, challenge.coins);
    expect(storage.isChallengeClaimed(challenge), isTrue);
  });

  test('daily challenge descriptions match their real targets', () {
    final day = DateTime(2026, 10, 26);
    final list = DailyChallenge.forDate(day);
    final again = DailyChallenge.forDate(day);

    expect(list.length, 3);
    for (int i = 0; i < list.length; i++) {
      expect(list[i].description, again[i].description);
      expect(list[i].description, contains('${list[i].target}'));
    }
  });

  test('the first launch starts a one day streak', () async {
    final storage = await StorageService.create();
    expect(storage.loginStreak, 1);
  });
}
