// lib/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';
import '../utils/constants.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // ─── Coins & Gems ──────────────────────────────────────────────────────────
  int get coins => _prefs?.getInt(StorageKeys.coins) ?? 0;
  int get gems => _prefs?.getInt(StorageKeys.gems) ?? 0;

  Future<void> addCoins(int amount) async {
    await _prefs?.setInt(StorageKeys.coins, coins + amount);
  }

  Future<void> spendCoins(int amount) async {
    final current = coins;
    if (current >= amount) {
      await _prefs?.setInt(StorageKeys.coins, current - amount);
    }
  }

  Future<void> addGems(int amount) async {
    await _prefs?.setInt(StorageKeys.gems, gems + amount);
  }

  // ─── XP & Level ────────────────────────────────────────────────────────────
  int get xp => _prefs?.getInt(StorageKeys.xp) ?? 0;
  int get level => _prefs?.getInt(StorageKeys.level) ?? 1;

  Future<void> addXp(int amount) async {
    var currentXp = xp + amount;
    var currentLevel = level;

    while (currentXp >= GameConstants.xpPerLevel) {
      currentXp -= GameConstants.xpPerLevel;
      currentLevel++;
    }

    await _prefs?.setInt(StorageKeys.xp, currentXp);
    await _prefs?.setInt(StorageKeys.level, currentLevel);
  }

  // ─── High Scores ───────────────────────────────────────────────────────────
  Map<String, int> get highScores {
    final json = _prefs?.getString(StorageKeys.highScores);
    if (json == null) return {};
    return Map<String, int>.from(jsonDecode(json) as Map);
  }

  Future<bool> updateHighScore(GameMode mode, int score) async {
    final scores = highScores;
    final key = mode.name;
    if ((scores[key] ?? 0) < score) {
      scores[key] = score;
      await _prefs?.setString(StorageKeys.highScores, jsonEncode(scores));
      return true; // New high score!
    }
    return false;
  }

  int getHighScore(GameMode mode) => highScores[mode.name] ?? 0;

  // ─── Statistics ────────────────────────────────────────────────────────────
  int get totalGamesPlayed =>
      _prefs?.getInt(StorageKeys.totalGamesPlayed) ?? 0;
  int get totalCorrectAnswers =>
      _prefs?.getInt(StorageKeys.totalCorrectAnswers) ?? 0;

  Future<void> recordGame(GameResult result) async {
    await _prefs?.setInt(
      StorageKeys.totalGamesPlayed,
      totalGamesPlayed + 1,
    );
    await _prefs?.setInt(
      StorageKeys.totalCorrectAnswers,
      totalCorrectAnswers + result.correctAnswers,
    );
    await updateHighScore(result.mode, result.score);
    await addXp(result.score ~/ 10 + result.correctAnswers * 5);
    await addCoins(result.score ~/ 20 + result.maxCombo);
  }

  // ─── Login Streak ──────────────────────────────────────────────────────────
  int get loginStreak => _prefs?.getInt(StorageKeys.loginStreak) ?? 0;

  Future<int> checkAndUpdateLoginStreak() async {
    final lastLogin = _prefs?.getString(StorageKeys.lastLoginDate);
    final today = DateTime.now();
    final todayStr = today.toIso8601String().substring(0, 10);

    if (lastLogin == null) {
      await _prefs?.setInt(StorageKeys.loginStreak, 1);
      await _prefs?.setString(StorageKeys.lastLoginDate, todayStr);
      return 1;
    }

    final lastDate = DateTime.parse(lastLogin);
    final diff = today.difference(lastDate).inDays;

    if (diff == 0) return loginStreak; // Already logged in today
    if (diff == 1) {
      // Consecutive day
      final newStreak = loginStreak + 1;
      await _prefs?.setInt(StorageKeys.loginStreak, newStreak);
      await _prefs?.setString(StorageKeys.lastLoginDate, todayStr);
      return newStreak;
    } else {
      // Streak broken
      await _prefs?.setInt(StorageKeys.loginStreak, 1);
      await _prefs?.setString(StorageKeys.lastLoginDate, todayStr);
      return 1;
    }
  }

  // ─── Daily Spin ────────────────────────────────────────────────────────────
  bool get canSpinToday {
    final lastSpin = _prefs?.getString(StorageKeys.dailySpinDate);
    if (lastSpin == null) return true;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return lastSpin != today;
  }

  Future<void> markSpinUsed() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _prefs?.setString(StorageKeys.dailySpinDate, today);
  }

  // ─── Achievements ──────────────────────────────────────────────────────────
  Set<String> get unlockedAchievements {
    final list = _prefs?.getStringList(StorageKeys.achievements) ?? [];
    return list.toSet();
  }

  Future<bool> unlockAchievement(String id) async {
    final unlocked = unlockedAchievements;
    if (unlocked.contains(id)) return false;
    unlocked.add(id);
    await _prefs?.setStringList(
      StorageKeys.achievements,
      unlocked.toList(),
    );
    return true;
  }

  // ─── Settings ──────────────────────────────────────────────────────────────
  Map<String, dynamic> get settings {
    final json = _prefs?.getString(StorageKeys.settings);
    if (json == null) {
      return {
        'soundEnabled': true,
        'hapticEnabled': true,
        'notificationsEnabled': true,
      };
    }
    return Map<String, dynamic>.from(jsonDecode(json) as Map);
  }

  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    await _prefs?.setString(StorageKeys.settings, jsonEncode(newSettings));
  }

  bool get soundEnabled => settings['soundEnabled'] as bool? ?? true;
  bool get hapticEnabled => settings['hapticEnabled'] as bool? ?? true;
}
