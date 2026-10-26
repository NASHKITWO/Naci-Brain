// lib/models/question.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class Question {
  final String questionText;
  final int correctAnswer;
  final List<int> options;
  final QuestionType type;
  final Difficulty difficulty;

  const Question({
    required this.questionText,
    required this.correctAnswer,
    required this.options,
    required this.type,
    required this.difficulty,
  });

  int get correctOptionIndex => options.indexOf(correctAnswer);

  @override
  String toString() =>
      'Question($questionText, correct: $correctAnswer, options: $options)';
}

// ─── Game Result ──────────────────────────────────────────────────────────────
class GameResult {
  final GameMode mode;
  final int score;
  final int correctAnswers;
  final int wrongAnswers;
  final int maxCombo;
  final int timeTakenSeconds;

  const GameResult({
    required this.mode,
    required this.score,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.maxCombo,
    required this.timeTakenSeconds,
  });

  int get totalAnswers => correctAnswers + wrongAnswers;

  /// Accuracy in percent (0-100).
  double get accuracy =>
      totalAnswers == 0 ? 0 : correctAnswers / totalAnswers * 100;

  String get grade {
    if (totalAnswers == 0) return '-';
    if (accuracy >= 95) return 'S';
    if (accuracy >= 85) return 'A';
    if (accuracy >= 70) return 'B';
    if (accuracy >= 55) return 'C';
    return 'D';
  }

  /// Rewards are computed in one place so the result screen and the saved
  /// totals always agree.
  int get coinsEarned => score ~/ 20 + maxCombo;
  int get xpEarned => score ~/ 10 + correctAnswers * 5;
}

// ─── Achievement ──────────────────────────────────────────────────────────────
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  static const List<Achievement> all = [
    Achievement(
      id: 'first_game',
      title: 'First Spark',
      description: 'Complete your first game',
      icon: Icons.flag_outlined,
    ),
    Achievement(
      id: 'score_100',
      title: 'Getting Warm',
      description: 'Score 100 points in one game',
      icon: Icons.trending_up,
    ),
    Achievement(
      id: 'score_500',
      title: 'Brain Burner',
      description: 'Score 500 points in one game',
      icon: Icons.psychology_outlined,
    ),
    Achievement(
      id: 'score_1000',
      title: 'Inferno',
      description: 'Score 1000 points in one game',
      icon: Icons.military_tech_outlined,
    ),
    Achievement(
      id: 'combo_5',
      title: 'Hot Streak',
      description: 'Reach a 5x combo',
      icon: Icons.bolt,
    ),
    Achievement(
      id: 'combo_10',
      title: 'Unstoppable',
      description: 'Reach a 10x combo',
      icon: Icons.whatshot,
    ),
    Achievement(
      id: 'correct_100',
      title: 'Century',
      description: 'Answer 100 questions correctly (total)',
      icon: Icons.check_circle_outline,
    ),
    Achievement(
      id: 'correct_1000',
      title: 'Math Master',
      description: 'Answer 1000 questions correctly (total)',
      icon: Icons.emoji_events_outlined,
    ),
    Achievement(
      id: 'perfect_game',
      title: 'Perfection',
      description: 'Finish Classic with 10+ correct and no mistakes',
      icon: Icons.auto_awesome,
    ),
    Achievement(
      id: 'speed_demon',
      title: 'Speed Demon',
      description: 'Finish Time Attack in under 30 seconds',
      icon: Icons.speed,
    ),
  ];
}
