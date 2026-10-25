// lib/utils/constants.dart
import 'package:flutter/material.dart';

// ─── Game Modes ───────────────────────────────────────────────────────────────
enum GameMode {
  classic,
  endless,
  timeAttack,
  rush,
  zen,
}

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
        return 'Rush Mode';
      case GameMode.zen:
        return 'Zen Mode';
    }
  }

  String get description {
    switch (this) {
      case GameMode.classic:
        return '60-second challenge\nwith increasing difficulty';
      case GameMode.endless:
        return 'Survive until you make\n3 mistakes';
      case GameMode.timeAttack:
        return 'Answer 20 questions\nas fast as possible';
      case GameMode.rush:
        return 'Speed increases every\n10 seconds. How far can you go?';
      case GameMode.zen:
        return 'No timer. No pressure.\nJust pure math practice';
    }
  }

  String get emoji {
    switch (this) {
      case GameMode.classic:
        return '⏱';
      case GameMode.endless:
        return '♾️';
      case GameMode.timeAttack:
        return '⚡';
      case GameMode.rush:
        return '🔥';
      case GameMode.zen:
        return '🧘';
    }
  }

  Color get accentColor {
    switch (this) {
      case GameMode.classic:
        return AppColors.neonCyan;
      case GameMode.endless:
        return AppColors.neonPurple;
      case GameMode.timeAttack:
        return AppColors.neonYellow;
      case GameMode.rush:
        return AppColors.neonOrange;
      case GameMode.zen:
        return AppColors.neonGreen;
    }
  }
}

// ─── Difficulty ───────────────────────────────────────────────────────────────
enum Difficulty { easy, medium, hard, extreme }

// ─── Question Types ───────────────────────────────────────────────────────────
enum QuestionType {
  addition,
  subtraction,
  multiplication,
  division,
  missingNumber,
  trueFalse,
  sequence,
}

// ─── Power-Up Types ───────────────────────────────────────────────────────────
enum PowerUpType {
  timeFreeze,
  doubleScore,
  hint,
  autoSolve,
  slowMotion,
}

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

  String get icon {
    switch (this) {
      case PowerUpType.timeFreeze:
        return '❄️';
      case PowerUpType.doubleScore:
        return '×2';
      case PowerUpType.hint:
        return '💡';
      case PowerUpType.autoSolve:
        return '🤖';
      case PowerUpType.slowMotion:
        return '🐢';
    }
  }

  Color get color {
    switch (this) {
      case PowerUpType.timeFreeze:
        return AppColors.neonCyan;
      case PowerUpType.doubleScore:
        return AppColors.neonYellow;
      case PowerUpType.hint:
        return AppColors.neonGreen;
      case PowerUpType.autoSolve:
        return AppColors.neonPurple;
      case PowerUpType.slowMotion:
        return AppColors.neonOrange;
    }
  }
}

// ─── Colors ───────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Background
  static const Color bgDark = Color(0xFF050510);
  static const Color bgCard = Color(0xFF0D0D1A);
  static const Color bgSurface = Color(0xFF12122A);

  // Neon Palette
  static const Color neonCyan = Color(0xFF00F5FF);
  static const Color neonPurple = Color(0xFFBF00FF);
  static const Color neonYellow = Color(0xFFFFE600);
  static const Color neonGreen = Color(0xFF00FF88);
  static const Color neonOrange = Color(0xFFFF6B00);
  static const Color neonPink = Color(0xFFFF006E);
  static const Color neonRed = Color(0xFFFF003C);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0D0);
  static const Color textMuted = Color(0xFF606080);

  // Answer Card States
  static const Color cardDefault = Color(0xFF1A1A35);
  static const Color cardCorrect = Color(0xFF003320);
  static const Color cardWrong = Color(0xFF330011);
  static const Color cardHint = Color(0xFF1A1A00);

  // Timer
  static const Color timerNormal = neonCyan;
  static const Color timerWarning = neonYellow;
  static const Color timerDanger = neonRed;

  // Neon glow helper (returns BoxShadow list)
  static List<BoxShadow> neonGlow(Color color, {double spread = 8}) {
    return [
      BoxShadow(color: color.withOpacity(0.5), blurRadius: spread, spreadRadius: spread / 4),
      BoxShadow(color: color.withOpacity(0.25), blurRadius: spread * 2.5, spreadRadius: spread / 2),
    ];
  }

  // Combo Multiplier Colors
  static List<Color> comboColors = [
    const Color(0xFFFFFFFF), // x1
    const Color(0xFF00F5FF), // x2
    const Color(0xFF00FF88), // x3
    const Color(0xFFFFE600), // x4
    const Color(0xFFFF6B00), // x5
    const Color(0xFFFF006E), // x6+
  ];
}

// ─── Game Constants ───────────────────────────────────────────────────────────
class GameConstants {
  GameConstants._();

  // Timing
  static const int classicDuration = 60;
  static const int timeAttackQuestions = 20;
  static const int rushSpeedInterval = 10;
  static const int maxMistakesEndless = 3;

  // Scoring
  static const int baseScore = 10;
  static const int streakBonus = 5;
  static const int wrongPenalty = -5;
  static const double speedBonusMax = 1.5;
  static const int comboMaxMultiplier = 10;

  // Streak milestones
  static const List<int> streakMilestones = [5, 10, 20, 50];

  // Timers (in milliseconds)
  static const int questionAnswerDelay = 400;
  static const int nextQuestionDelay = 600;

  // Power-up durations
  static const int timeFreezeSeconds = 5;
  static const int doubleScoreSeconds = 10;
  static const int slowMotionSeconds = 5;

  // Answer options count
  static const int answerOptionsCount = 4;

  // XP per level
  static const int xpPerLevel = 500;
}

// ─── Storage Keys ─────────────────────────────────────────────────────────────
class StorageKeys {
  StorageKeys._();

  static const String highScores = 'high_scores';
  static const String totalGamesPlayed = 'total_games_played';
  static const String totalCorrectAnswers = 'total_correct_answers';
  static const String coins = 'coins';
  static const String gems = 'gems';
  static const String xp = 'xp';
  static const String level = 'level';
  static const String loginStreak = 'login_streak';
  static const String lastLoginDate = 'last_login_date';
  static const String dailySpinDate = 'daily_spin_date';
  static const String unlockedThemes = 'unlocked_themes';
  static const String achievements = 'achievements';
  static const String settings = 'settings';
}
