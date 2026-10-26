// lib/models/daily_challenge.dart
import 'dart:math';
import '../utils/constants.dart';
import 'question.dart';

enum ChallengeKind { combo, score, time }

class DailyChallenge {
  final String dateKey;
  final int index;
  final String title;
  final String description;
  final GameMode mode;
  final ChallengeKind kind;
  final int target;
  final int coins;
  final int gems;

  const DailyChallenge({
    required this.dateKey,
    required this.index,
    required this.title,
    required this.description,
    required this.mode,
    required this.kind,
    required this.target,
    this.coins = 0,
    this.gems = 0,
  });

  String get id => '$dateKey:$index';

  bool isMet(GameResult r) {
    if (r.mode != mode) return false;
    switch (kind) {
      case ChallengeKind.combo:
        return r.maxCombo >= target;
      case ChallengeKind.score:
        return r.score >= target;
      case ChallengeKind.time:
        return r.timeTakenSeconds <= target;
    }
  }

  String get rewardLabel {
    final parts = <String>[];
    if (coins > 0) parts.add('$coins coins');
    if (gems > 0) parts.add('$gems gems');
    return parts.join(' + ');
  }

  static String dateKeyOf(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// Same date always yields the same challenges (targets are drawn once,
  /// so the description and the real target can never disagree).
  static List<DailyChallenge> forDate(DateTime d) {
    final key = dateKeyOf(d);
    final rng = Random(d.year * 10000 + d.month * 100 + d.day);
    final timeTarget = 40 + 5 * rng.nextInt(4);
    final comboTarget = 5 + rng.nextInt(5);
    final scoreTarget = 200 + 50 * rng.nextInt(5);

    return [
      DailyChallenge(
        dateKey: key,
        index: 0,
        title: 'Speed Round',
        description: 'Finish Time Attack in $timeTarget seconds or less',
        mode: GameMode.timeAttack,
        kind: ChallengeKind.time,
        target: timeTarget,
        coins: 150,
      ),
      DailyChallenge(
        dateKey: key,
        index: 1,
        title: 'Combo Streak',
        description: 'Reach a ${comboTarget}x combo in Classic',
        mode: GameMode.classic,
        kind: ChallengeKind.combo,
        target: comboTarget,
        gems: 3,
      ),
      DailyChallenge(
        dateKey: key,
        index: 2,
        title: 'Survivor',
        description: 'Score $scoreTarget or more in Endless',
        mode: GameMode.endless,
        kind: ChallengeKind.score,
        target: scoreTarget,
        coins: 200,
      ),
    ];
  }
}
