// lib/services/storage_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_challenge.dart';
import '../models/question.dart';
import '../utils/constants.dart';

/// What changed after a finished game was saved.
class GameOutcome {
  final bool isNewHighScore;
  final bool leveledUp;
  final List<Achievement> newAchievements;

  const GameOutcome({
    required this.isNewHighScore,
    required this.leveledUp,
    required this.newAchievements,
  });
}

/// Single source of truth for everything saved on the device.
/// It is a ChangeNotifier, so screens that watch it refresh automatically.
class StorageService extends ChangeNotifier {
  StorageService._(this._prefs);

  final SharedPreferences _prefs;

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService._(prefs);
    await service._touchLoginStreak();
    return service;
  }

  // ─── Currency, XP, level ───────────────────────────────────────────────────
  int get coins => _prefs.getInt(StorageKeys.coins) ?? 0;
  int get gems => _prefs.getInt(StorageKeys.gems) ?? 0;
  int get xp => _prefs.getInt(StorageKeys.xp) ?? 0;
  int get level => _prefs.getInt(StorageKeys.level) ?? 1;

  double get xpProgress =>
      (xp / GameConstants.xpPerLevel).clamp(0.0, 1.0).toDouble();

  Future<void> addCoins(int amount) async {
    await _prefs.setInt(StorageKeys.coins, coins + amount);
    notifyListeners();
  }

  Future<void> addGems(int amount) async {
    await _prefs.setInt(StorageKeys.gems, gems + amount);
    notifyListeners();
  }

  /// Adds XP and returns true if the player gained at least one level.
  Future<bool> _addXp(int amount) async {
    int newXp = xp + amount;
    int newLevel = level;
    bool leveledUp = false;
    while (newXp >= GameConstants.xpPerLevel) {
      newXp -= GameConstants.xpPerLevel;
      newLevel++;
      leveledUp = true;
    }
    await _prefs.setInt(StorageKeys.xp, newXp);
    await _prefs.setInt(StorageKeys.level, newLevel);
    return leveledUp;
  }

  // ─── High scores ───────────────────────────────────────────────────────────
  Map<String, int> get highScores {
    final raw = _prefs.getString(StorageKeys.highScores);
    if (raw == null) return {};
    try {
      return Map<String, int>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  int getHighScore(GameMode mode) => highScores[mode.name] ?? 0;

  // ─── Statistics ────────────────────────────────────────────────────────────
  int get totalGamesPlayed => _prefs.getInt(StorageKeys.totalGamesPlayed) ?? 0;
  int get totalCorrectAnswers =>
      _prefs.getInt(StorageKeys.totalCorrectAnswers) ?? 0;
  int get totalAnswers => _prefs.getInt(StorageKeys.totalAnswers) ?? 0;
  int get bestCombo => _prefs.getInt(StorageKeys.bestCombo) ?? 0;

  /// Lifetime accuracy in percent, or null if nothing was answered yet.
  double? get overallAccuracy =>
      totalAnswers == 0 ? null : totalCorrectAnswers / totalAnswers * 100;

  /// Saves a finished game: stats, high score, rewards and achievements.
  Future<GameOutcome> recordGame(GameResult r) async {
    final games = totalGamesPlayed + 1;
    final correct = totalCorrectAnswers + r.correctAnswers;
    await _prefs.setInt(StorageKeys.totalGamesPlayed, games);
    await _prefs.setInt(StorageKeys.totalCorrectAnswers, correct);
    await _prefs.setInt(StorageKeys.totalAnswers, totalAnswers + r.totalAnswers);
    if (r.maxCombo > bestCombo) {
      await _prefs.setInt(StorageKeys.bestCombo, r.maxCombo);
    }

    final isNewHighScore = r.score > getHighScore(r.mode);
    if (isNewHighScore) {
      final scores = highScores;
      scores[r.mode.name] = r.score;
      await _prefs.setString(StorageKeys.highScores, jsonEncode(scores));
    }

    await _prefs.setInt(StorageKeys.coins, coins + r.coinsEarned);
    final leveledUp = await _addXp(r.xpEarned);

    final already = unlockedAchievements;
    final fresh = <Achievement>[];
    for (final a in Achievement.all) {
      if (already.contains(a.id)) continue;
      if (_isEarned(a.id, r, correct)) fresh.add(a);
    }
    if (fresh.isNotEmpty) {
      await _prefs.setStringList(
        StorageKeys.achievements,
        [...already, ...fresh.map((a) => a.id)],
      );
    }

    notifyListeners();
    return GameOutcome(
      isNewHighScore: isNewHighScore,
      leveledUp: leveledUp,
      newAchievements: fresh,
    );
  }

  bool _isEarned(String id, GameResult r, int lifetimeCorrect) {
    switch (id) {
      case 'first_game':
        return true;
      case 'score_100':
        return r.score >= 100;
      case 'score_500':
        return r.score >= 500;
      case 'score_1000':
        return r.score >= 1000;
      case 'combo_5':
        return r.maxCombo >= 5;
      case 'combo_10':
        return r.maxCombo >= 10;
      case 'correct_100':
        return lifetimeCorrect >= 100;
      case 'correct_1000':
        return lifetimeCorrect >= 1000;
      case 'perfect_game':
        return r.mode == GameMode.classic &&
            r.wrongAnswers == 0 &&
            r.correctAnswers >= 10;
      case 'speed_demon':
        return r.mode == GameMode.timeAttack && r.timeTakenSeconds < 30;
    }
    return false;
  }

  // ─── Achievements ──────────────────────────────────────────────────────────
  Set<String> get unlockedAchievements =>
      (_prefs.getStringList(StorageKeys.achievements) ?? <String>[]).toSet();

  // ─── Login streak ──────────────────────────────────────────────────────────
  int get loginStreak => _prefs.getInt(StorageKeys.loginStreak) ?? 0;

  Future<void> _touchLoginStreak() async {
    final now = DateTime.now();
    final today = DailyChallenge.dateKeyOf(now);
    final last = _prefs.getString(StorageKeys.lastLoginDate);
    if (last == today) return;

    int streak = 1;
    final lastDate = last == null ? null : DateTime.tryParse(last);
    if (lastDate != null) {
      // Compare calendar days only, so time of day and DST never matter.
      final a = DateTime.utc(now.year, now.month, now.day);
      final b = DateTime.utc(lastDate.year, lastDate.month, lastDate.day);
      if (a.difference(b).inDays == 1) streak = loginStreak + 1;
    }
    await _prefs.setInt(StorageKeys.loginStreak, streak);
    await _prefs.setString(StorageKeys.lastLoginDate, today);
  }

  // ─── Daily spin ────────────────────────────────────────────────────────────
  bool get canSpinToday =>
      _prefs.getString(StorageKeys.dailySpinDate) !=
      DailyChallenge.dateKeyOf(DateTime.now());

  Future<void> markSpinUsed() async {
    await _prefs.setString(
      StorageKeys.dailySpinDate,
      DailyChallenge.dateKeyOf(DateTime.now()),
    );
    notifyListeners();
  }

  // ─── Daily challenges ──────────────────────────────────────────────────────
  bool isChallengeClaimed(DailyChallenge c) =>
      (_prefs.getStringList(StorageKeys.dailyClaimed) ?? <String>[])
          .contains(c.id);

  /// Pays out the reward once. Returns false if it was already claimed.
  Future<bool> claimChallenge(DailyChallenge c) async {
    if (isChallengeClaimed(c)) return false;
    final kept = (_prefs.getStringList(StorageKeys.dailyClaimed) ?? <String>[])
        .where((e) => e.startsWith(c.dateKey))
        .toList()
      ..add(c.id);
    await _prefs.setStringList(StorageKeys.dailyClaimed, kept);
    if (c.coins > 0) await _prefs.setInt(StorageKeys.coins, coins + c.coins);
    if (c.gems > 0) await _prefs.setInt(StorageKeys.gems, gems + c.gems);
    notifyListeners();
    return true;
  }

  // ─── Settings ──────────────────────────────────────────────────────────────
  bool get hapticsEnabled => _prefs.getBool(StorageKeys.haptics) ?? true;

  Future<void> setHaptics(bool value) async {
    await _prefs.setBool(StorageKeys.haptics, value);
    notifyListeners();
  }
}
