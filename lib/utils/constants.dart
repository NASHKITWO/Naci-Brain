// lib/utils/constants.dart
import 'package:flutter/material.dart';

// ─── Game Modes ───────────────────────────────────────────────────────────────
enum GameMode { classic, endless, timeAttack, rush, zen }

extension GameModeExtension on GameMode {
  String get displayName {
    switch (this) {
      case GameMode.classic:
        return 'Classic';
      case GameMode.endless:
        return 'Endless';
      case GameMode.timeAttack:
        return 'Time Attack';
      case GameMode.rush:
        return 'Rush';
      case GameMode.zen:
        return 'Zen';
    }
  }

  String get description {
    switch (this) {
      case GameMode.classic:
        return '60 seconds, difficulty rises as you go';
      case GameMode.endless:
        return 'No timer. Three mistakes and you are out';
      case GameMode.timeAttack:
        return '20 questions, fastest time wins';
      case GameMode.rush:
        return '60 seconds, difficulty rises every 10 seconds';
      case GameMode.zen:
        return 'No timer, no pressure, just practice';
    }
  }

  IconData get icon {
    switch (this) {
      case GameMode.classic:
        return Icons.timer_outlined;
      case GameMode.endless:
        return Icons.all_inclusive;
      case GameMode.timeAttack:
        return Icons.bolt;
      case GameMode.rush:
        return Icons.local_fire_department_outlined;
      case GameMode.zen:
        return Icons.spa_outlined;
    }
  }

  /// Modes that run against a countdown clock.
  bool get hasCountdown => this == GameMode.classic || this == GameMode.rush;
}

// ─── Difficulty / Questions ───────────────────────────────────────────────────
enum Difficulty { easy, medium, hard, extreme }

enum QuestionType {
  addition,
  subtraction,
  multiplication,
  division,
  missingNumber,
  trueFalse,
  sequence,
}

// ─── Power-Ups ────────────────────────────────────────────────────────────────
enum PowerUpType { timeFreeze, doubleScore, hint, autoSolve, slowMotion }

extension PowerUpExtension on PowerUpType {
  String get displayName {
    switch (this) {
      case PowerUpType.timeFreeze:
        return 'Time Freeze';
      case PowerUpType.doubleScore:
        return 'Double Score';
      case PowerUpType.hint:
        return 'Hint';
      case PowerUpType.autoSolve:
        return 'Auto Solve';
      case PowerUpType.slowMotion:
        return 'Slow Motion';
    }
  }

  String get shortName {
    switch (this) {
      case PowerUpType.timeFreeze:
        return 'Freeze';
      case PowerUpType.doubleScore:
        return 'Double';
      case PowerUpType.hint:
        return 'Hint';
      case PowerUpType.autoSolve:
        return 'Solve';
      case PowerUpType.slowMotion:
        return 'Slow';
    }
  }

  IconData get icon {
    switch (this) {
      case PowerUpType.timeFreeze:
        return Icons.ac_unit;
      case PowerUpType.doubleScore:
        return Icons.exposure_plus_2;
      case PowerUpType.hint:
        return Icons.lightbulb_outline;
      case PowerUpType.autoSolve:
        return Icons.auto_fix_high;
      case PowerUpType.slowMotion:
        return Icons.slow_motion_video;
    }
  }
}

// ─── Game Constants ───────────────────────────────────────────────────────────
class GameConstants {
  GameConstants._();

  // Timing
  static const int classicDuration = 60;
  static const int timeAttackQuestions = 20;
  static const int rushSpeedInterval = 10;
  static const int maxMistakesEndless = 3;
  static const int comboTimeBonus = 3;
  static const int answerFeedbackMs = 400;

  // Scoring
  static const int baseScore = 10;
  static const int streakBonus = 5;
  static const int speedBonus = 5;
  static const int wrongPenalty = -5;
  static const int comboMaxMultiplier = 10;

  // Power-up durations (seconds of play time, so pausing stops them)
  static const int timeFreezeSeconds = 5;
  static const int doubleScoreSeconds = 10;
  static const int slowMotionSeconds = 8;

  // Power-ups available per game
  static const int powerUpsPerGame = 3;
  static const int autoSolvePerGame = 2;

  // XP per level
  static const int xpPerLevel = 500;
}

// ─── Storage Keys ─────────────────────────────────────────────────────────────
class StorageKeys {
  StorageKeys._();

  static const String highScores = 'high_scores';
  static const String totalGamesPlayed = 'total_games_played';
  static const String totalCorrectAnswers = 'total_correct_answers';
  static const String totalAnswers = 'total_answers';
  static const String bestCombo = 'best_combo';
  static const String coins = 'coins';
  static const String gems = 'gems';
  static const String xp = 'xp';
  static const String level = 'level';
  static const String loginStreak = 'login_streak';
  static const String lastLoginDate = 'last_login_date';
  static const String dailySpinDate = 'daily_spin_date';
  static const String achievements = 'achievements';
  static const String dailyClaimed = 'daily_claimed';
  static const String haptics = 'haptics_enabled';
}
