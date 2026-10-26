import 'package:flutter_test/flutter_test.dart';
import 'package:naci_brain/services/question_generator.dart';
import 'package:naci_brain/utils/constants.dart';

void main() {
  test('every question has distinct options that include the answer', () {
    for (final d in Difficulty.values) {
      for (int i = 0; i < 500; i++) {
        final q = QuestionGenerator.generate(difficulty: d);
        final expected = q.type == QuestionType.trueFalse ? 2 : 4;
        expect(q.options.length, expected, reason: '$q');
        expect(q.options.toSet().length, expected, reason: '$q');
        expect(q.options.contains(q.correctAnswer), isTrue, reason: '$q');
      }
    }
  });

  test('the stated answer is mathematically correct', () {
    final arithmetic = RegExp(r'^(\d+) ([+−×÷]) (\d+) = \?$');
    final truth = RegExp(r'^(\d+) \+ (\d+) = (\d+)$');

    for (final d in Difficulty.values) {
      for (int i = 0; i < 500; i++) {
        final q = QuestionGenerator.generate(difficulty: d);

        final m = arithmetic.firstMatch(q.questionText);
        if (m != null) {
          final a = int.parse(m.group(1)!);
          final b = int.parse(m.group(3)!);
          final op = m.group(2)!;
          int expected;
          if (op == '+') {
            expected = a + b;
          } else if (op == '−') {
            expected = a - b;
          } else if (op == '×') {
            expected = a * b;
          } else {
            expected = a ~/ b;
            expect(a % b, 0, reason: '$q');
          }
          expect(q.correctAnswer, expected, reason: '$q');
        }

        final t = truth.firstMatch(q.questionText);
        if (t != null) {
          final sum = int.parse(t.group(1)!) + int.parse(t.group(2)!);
          final shown = int.parse(t.group(3)!);
          expect(q.correctAnswer == 1, sum == shown, reason: '$q');
          expect(shown, greaterThan(0), reason: '$q');
        }
      }
    }
  });
}
