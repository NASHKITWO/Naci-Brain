// lib/models/question.dart
import '../utils/constants.dart';

class Question {
  final String questionText;
  final int correctAnswer;
  final List<int> options;
  final QuestionType type;
  final Difficulty difficulty;
  final int hintIndex; // index to remove when hint used (-1 if none)

  const Question({
    required this.questionText,
    required this.correctAnswer,
    required this.options,
    required this.type,
    required this.difficulty,
    this.hintIndex = -1,
  });

  int get correctOptionIndex => options.indexOf(correctAnswer);

  Question withHintApplied() {
    // Returns same question; hint is handled in UI by hiding one wrong option
    return this;
  }

  @override
  String toString() {
    return 'Question($questionText, correct: $correctAnswer, options: $options)';
  }
}

// ─── Game Result ──────────────────────────────────────────────────────────────
class GameResult {
  final GameMode mode;
  final int score;
  final int correctAnswers;
  final int wrongAnswers;
  final int maxCombo;
  final int timeTakenSeconds; // For Time Attack
  final int coinsEarned;
  final int xpEarned;
  final DateTime playedAt;

  const GameResult({
    required this.mode,
    required this.score,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.maxCombo,
    required this.timeTakenSeconds,
    this.coinsEarned = 0,
    this.xpEarned = 0,
    required this.playedAt,
  });

  int get totalAnswers => correctAnswers + wrongAnswers;
  double get accuracy =>
      totalAnswers == 0 ? 0 : (correctAnswers / totalAnswers * 100);

  String get grade {
    if (accuracy >= 95) return 'S';
    if (accuracy >= 85) return 'A';
    if (accuracy >= 70) return 'B';
    if (accuracy >= 55) return 'C';
    return 'D';
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.index,
        'score': score,
        'correctAnswers': correctAnswers,
        'wrongAnswers': wrongAnswers,
        'maxCombo': maxCombo,
        'timeTakenSeconds': timeTakenSeconds,
        'playedAt': playedAt.toIso8601String(),
      };

  factory GameResult.fromJson(Map<String, dynamic> json) => GameResult(
        mode: GameMode.values[json['mode'] as int],
        score: json['score'] as int,
        correctAnswers: json['correctAnswers'] as int,
        wrongAnswers: json['wrongAnswers'] as int,
        maxCombo: json['maxCombo'] as int,
        timeTakenSeconds: json['timeTakenSeconds'] as int,
        playedAt: DateTime.parse(json['playedAt'] as String),
      );
}

// ─── Achievement ──────────────────────────────────────────────────────────────
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool unlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.unlocked = false,
    this.unlockedAt,
  });

  static final List<Achievement> all = [
    const Achievement(
      id: 'first_game',
      title: 'First Spark',
      description: 'Complete your first game',
      icon: '🔥',
    ),
    const Achievement(
      id: 'score_100',
      title: 'Getting Warm',
      description: 'Score 100 points in one game',
      icon: '💯',
    ),
    const Achievement(
      id: 'score_500',
      title: 'Brain Burner',
      description: 'Score 500 points in one game',
      icon: '🧠',
    ),
    const Achievement(
      id: 'score_1000',
      title: 'Inferno',
      description: 'Score 1000 points in one game',
      icon: '🌋',
    ),
    const Achievement(
      id: 'combo_5',
      title: 'Hot Streak',
      description: 'Reach a 5x combo',
      icon: '⚡',
    ),
    const Achievement(
      id: 'combo_10',
      title: 'Unstoppable',
      description: 'Reach the max 10x combo',
      icon: '👑',
    ),
    const Achievement(
      id: 'correct_100',
      title: 'Century',
      description: 'Answer 100 questions correctly (total)',
      icon: '💎',
    ),
    const Achievement(
      id: 'correct_1000',
      title: 'Math Master',
      description: 'Answer 1000 questions correctly (total)',
      icon: '🏆',
    ),
    const Achievement(
      id: 'perfect_game',
      title: 'Perfection',
      description: 'Complete Classic Mode with no wrong answers',
      icon: '✨',
    ),
    const Achievement(
      id: 'speed_demon',
      title: 'Speed Demon',
      description: 'Complete Time Attack in under 30 seconds',
      icon: '💨',
    ),
  ];
}
