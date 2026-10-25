// lib/services/question_generator.dart
import 'dart:math';
import '../models/question.dart';
import '../utils/constants.dart';

class QuestionGenerator {
  static final Random _rng = Random();
  static int _counter = 0;

  // ─── Public API ────────────────────────────────────────────────────────────

  static Question generate({required Difficulty difficulty}) {
    _counter++;
    final type = _pickType(difficulty);
    return _build(type, difficulty);
  }

  /// Returns display label for an option (handles True/False mapping)
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
    final total = weights.fold(0, (s, w) => s + w.$2);
    int roll = _rng.nextInt(total);
    for (final (type, weight) in weights) {
      roll -= weight;
      if (roll < 0) return type;
    }
    return weights.last.$1;
  }

  // ─── Question Builders ─────────────────────────────────────────────────────

  static Question _build(QuestionType type, Difficulty d) {
    switch (type) {
      case QuestionType.addition:      return _addition(d);
      case QuestionType.subtraction:   return _subtraction(d);
      case QuestionType.multiplication: return _multiplication(d);
      case QuestionType.division:      return _division(d);
      case QuestionType.missingNumber: return _missingNumber(d);
      case QuestionType.trueFalse:     return _trueFalse(d);
      case QuestionType.sequence:      return _sequence(d);
    }
  }

  static int _maxNum(Difficulty d) {
    switch (d) {
      case Difficulty.easy:    return 20;
      case Difficulty.medium:  return 50;
      case Difficulty.hard:    return 100;
      case Difficulty.extreme: return 200;
    }
  }

  static int _r(int max) => _rng.nextInt(max) + 1;

  static Question _addition(Difficulty d) {
    final max = _maxNum(d);
    final a = _r(max), b = _r(max);
    return Question(
      questionText: '$a + $b = ?',
      correctAnswer: a + b,
      options: _opts(a + b, max * 2),
      type: QuestionType.addition,
      difficulty: d,
    );
  }

  static Question _subtraction(Difficulty d) {
    final max = _maxNum(d);
    int a = _r(max), b = _r(max);
    if (b > a) { final t = a; a = b; b = t; }
    return Question(
      questionText: '$a − $b = ?',
      correctAnswer: a - b,
      options: _opts(a - b, max),
      type: QuestionType.subtraction,
      difficulty: d,
    );
  }

  static Question _multiplication(Difficulty d) {
    final maxF = d == Difficulty.easy ? 5 : d == Difficulty.medium ? 10 : d == Difficulty.hard ? 12 : 20;
    final a = _r(maxF) + 1, b = _r(maxF) + 1;
    return Question(
      questionText: '$a × $b = ?',
      correctAnswer: a * b,
      options: _opts(a * b, maxF * maxF),
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
      options: _opts(ans, maxF),
      type: QuestionType.division,
      difficulty: d,
    );
  }

  static Question _missingNumber(Difficulty d) {
    final max = _maxNum(d);
    final a = _r(max), b = _r(max);
    final sum = a + b;
    // Randomly hide either a or b
    if (_rng.nextBool()) {
      return Question(
        questionText: '? + $b = $sum',
        correctAnswer: a,
        options: _opts(a, max),
        type: QuestionType.missingNumber,
        difficulty: d,
      );
    } else {
      return Question(
        questionText: '$a + ? = $sum',
        correctAnswer: b,
        options: _opts(b, max),
        type: QuestionType.missingNumber,
        difficulty: d,
      );
    }
  }

  static Question _trueFalse(Difficulty d) {
    final max = _maxNum(d);
    final a = _r(max), b = _r(max);
    final real = a + b;
    final isCorrect = _rng.nextBool();
    final shown = isCorrect ? real : real + (_rng.nextInt(5) + 1) * (_rng.nextBool() ? 1 : -1);
    return Question(
      questionText: '$a + $b = $shown',
      correctAnswer: isCorrect ? 1 : 0,
      options: const [0, 1], // 0 = FALSE, 1 = TRUE
      type: QuestionType.trueFalse,
      difficulty: d,
    );
  }

  static Question _sequence(Difficulty d) {
    final step = _r(d == Difficulty.easy ? 4 : d == Difficulty.medium ? 8 : 15);
    final start = _r(20);
    // Show 4 terms, hide one in the middle
    final terms = List.generate(5, (i) => start + i * step);
    final hideIdx = _rng.nextInt(3) + 1; // hide index 1, 2, or 3
    final correct = terms[hideIdx];
    final display = terms.asMap().entries
        .map((e) => e.key == hideIdx ? '?' : '${e.value}')
        .take(4)
        .join(', ');
    return Question(
      questionText: '$display, ...',
      correctAnswer: correct,
      options: _opts(correct, start + 5 * step),
      type: QuestionType.sequence,
      difficulty: d,
    );
  }

  // ─── Options Generator ─────────────────────────────────────────────────────

  static List<int> _opts(int correct, int maxVal) {
    final set = <int>{correct};
    int attempts = 0;
    final upper = maxVal > correct + 20 ? maxVal : correct + 20;
    while (set.length < 4 && attempts < 60) {
      attempts++;
      final strategy = _rng.nextInt(3);
      int candidate;
      if (strategy == 0) {
        candidate = correct + (_rng.nextInt(5) + 1) * (_rng.nextBool() ? 1 : -1);
      } else if (strategy == 1) {
        candidate = correct + (_rng.nextInt(15) + 5) * (_rng.nextBool() ? 1 : -1);
      } else {
        candidate = 1 + _rng.nextInt(upper);
      }
      if (candidate > 0 && candidate != correct) set.add(candidate);
    }
    // Guaranteed fallback
    int off = 1;
    while (set.length < 4) { set.add(correct + off++); }

    return set.toList()..shuffle(_rng);
  }
}
