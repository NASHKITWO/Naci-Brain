// lib/services/question_generator.dart
import 'dart:math';
import '../models/question.dart';
import '../utils/constants.dart';

class QuestionGenerator {
  QuestionGenerator._();

  static final Random _rng = Random();

  // ─── Public API ────────────────────────────────────────────────────────────

  static Question generate({required Difficulty difficulty}) {
    final type = _pickType(difficulty);
    return _build(type, difficulty);
  }

  /// Display label for an option (handles True/False mapping).
  static String optionLabel(Question question, int index) {
    if (question.type == QuestionType.trueFalse) {
      return question.options[index] == 1 ? 'TRUE' : 'FALSE';
    }
    return question.options[index].toString();
  }

  // ─── Type Selection ────────────────────────────────────────────────────────

  static QuestionType _pickType(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return _weighted([
          (QuestionType.addition, 40),
          (QuestionType.subtraction, 35),
          (QuestionType.trueFalse, 15),
          (QuestionType.missingNumber, 10),
        ]);
      case Difficulty.medium:
        return _weighted([
          (QuestionType.addition, 20),
          (QuestionType.subtraction, 20),
          (QuestionType.multiplication, 30),
          (QuestionType.trueFalse, 15),
          (QuestionType.missingNumber, 15),
        ]);
      case Difficulty.hard:
        return _weighted([
          (QuestionType.addition, 10),
          (QuestionType.subtraction, 10),
          (QuestionType.multiplication, 25),
          (QuestionType.division, 25),
          (QuestionType.missingNumber, 15),
          (QuestionType.sequence, 15),
        ]);
      case Difficulty.extreme:
        return _weighted([
          (QuestionType.multiplication, 20),
          (QuestionType.division, 20),
          (QuestionType.missingNumber, 20),
          (QuestionType.sequence, 20),
          (QuestionType.trueFalse, 20),
        ]);
    }
  }

  static QuestionType _weighted(List<(QuestionType, int)> weights) {
    final total = weights.fold(0, (sum, w) => sum + w.$2);
    int roll = _rng.nextInt(total);
    for (final w in weights) {
      roll -= w.$2;
      if (roll < 0) return w.$1;
    }
    return weights.last.$1;
  }

  // ─── Question Builders ─────────────────────────────────────────────────────

  static Question _build(QuestionType type, Difficulty d) {
    switch (type) {
      case QuestionType.addition:
        return _addition(d);
      case QuestionType.subtraction:
        return _subtraction(d);
      case QuestionType.multiplication:
        return _multiplication(d);
      case QuestionType.division:
        return _division(d);
      case QuestionType.missingNumber:
        return _missingNumber(d);
      case QuestionType.trueFalse:
        return _trueFalse(d);
      case QuestionType.sequence:
        return _sequence(d);
    }
  }

  static int _maxNum(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return 20;
      case Difficulty.medium:
        return 50;
      case Difficulty.hard:
        return 100;
      case Difficulty.extreme:
        return 200;
    }
  }

  /// Random int in 1..max (inclusive).
  static int _r(int max) => _rng.nextInt(max) + 1;

  static Question _addition(Difficulty d) {
    final max = _maxNum(d);
    final a = _r(max), b = _r(max);
    return Question(
      questionText: '$a + $b = ?',
      correctAnswer: a + b,
      options: _opts(a + b),
      type: QuestionType.addition,
      difficulty: d,
    );
  }

  static Question _subtraction(Difficulty d) {
    final max = _maxNum(d);
    int a = _r(max), b = _r(max);
    if (b > a) {
      final t = a;
      a = b;
      b = t;
    }
    return Question(
      questionText: '$a − $b = ?',
      correctAnswer: a - b,
      options: _opts(a - b),
      type: QuestionType.subtraction,
      difficulty: d,
    );
  }

  static Question _multiplication(Difficulty d) {
    final maxF = d == Difficulty.easy
        ? 5
        : d == Difficulty.medium
            ? 10
            : d == Difficulty.hard
                ? 12
                : 20;
    final a = _r(maxF) + 1, b = _r(maxF) + 1;
    return Question(
      questionText: '$a × $b = ?',
      correctAnswer: a * b,
      options: _opts(a * b),
      type: QuestionType.multiplication,
      difficulty: d,
    );
  }

  static Question _division(Difficulty d) {
    final maxF = d == Difficulty.hard ? 12 : 20;
    final b = _r(maxF) + 1;
    final ans = _r(maxF) + 1;
    return Question(
      questionText: '${b * ans} ÷ $b = ?',
      correctAnswer: ans,
      options: _opts(ans),
      type: QuestionType.division,
      difficulty: d,
    );
  }

  static Question _missingNumber(Difficulty d) {
    final max = _maxNum(d);
    final a = _r(max), b = _r(max);
    final sum = a + b;
    if (_rng.nextBool()) {
      return Question(
        questionText: '? + $b = $sum',
        correctAnswer: a,
        options: _opts(a),
        type: QuestionType.missingNumber,
        difficulty: d,
      );
    }
    return Question(
      questionText: '$a + ? = $sum',
      correctAnswer: b,
      options: _opts(b),
      type: QuestionType.missingNumber,
      difficulty: d,
    );
  }

  static Question _trueFalse(Difficulty d) {
    final max = _maxNum(d);
    final a = _r(max), b = _r(max);
    final real = a + b;
    final isCorrect = _rng.nextBool();
    final shown = isCorrect ? real : _wrongSum(real);
    return Question(
      questionText: '$a + $b = $shown',
      correctAnswer: isCorrect ? 1 : 0,
      options: const [0, 1], // 0 = FALSE, 1 = TRUE
      type: QuestionType.trueFalse,
      difficulty: d,
    );
  }

  /// A plausible but wrong sum: never equal to [real] and never below 1.
  static int _wrongSum(int real) {
    int v = real;
    while (v == real || v < 1) {
      v = real + (_rng.nextInt(5) + 1) * (_rng.nextBool() ? 1 : -1);
    }
    return v;
  }

  static Question _sequence(Difficulty d) {
    final step =
        _r(d == Difficulty.easy ? 4 : d == Difficulty.medium ? 8 : 15);
    final start = _r(20);
    final terms = List.generate(5, (i) => start + i * step);
    final hideIdx = _rng.nextInt(3) + 1; // hide index 1, 2 or 3
    final correct = terms[hideIdx];
    final display = terms
        .asMap()
        .entries
        .map((e) => e.key == hideIdx ? '?' : '${e.value}')
        .take(4)
        .join(', ');
    return Question(
      questionText: '$display, ...',
      correctAnswer: correct,
      options: _opts(correct),
      type: QuestionType.sequence,
      difficulty: d,
    );
  }

  // ─── Options Generator ─────────────────────────────────────────────────────

  /// Builds 4 distinct options (the correct one plus 3 near-miss distractors),
  /// shuffled.
  static List<int> _opts(int correct) {
    final set = <int>{correct};
    int attempts = 0;
    while (set.length < 4 && attempts < 60) {
      attempts++;
      final close = _rng.nextBool();
      final span = close ? 5 : 15;
      final base = close ? 1 : 5;
      final candidate =
          correct + (_rng.nextInt(span) + base) * (_rng.nextBool() ? 1 : -1);
      if (candidate > 0 && candidate != correct) set.add(candidate);
    }
    // Guaranteed fallback so we always return 4 options.
    int off = 1;
    while (set.length < 4) {
      set.add(correct + off++);
    }
    return set.toList()..shuffle(_rng);
  }
}
