// lib/screens/result_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/daily_challenge.dart';
import '../models/question.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/app_ui.dart';
import 'game_screen.dart';

class ResultScreen extends StatefulWidget {
  final GameResult result;
  final DailyChallenge? challenge;

  const ResultScreen({super.key, required this.result, this.challenge});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  GameOutcome? _outcome;
  bool? _challengeMet;
  bool _challengePaid = false;

  @override
  void initState() {
    super.initState();
    _save();
  }

  /// Saves the game exactly once: stats, high score, rewards, achievements
  /// and (if this was a daily challenge) the challenge reward.
  Future<void> _save() async {
    final storage = context.read<StorageService>();
    final outcome = await storage.recordGame(widget.result);

    bool? met;
    bool paid = false;
    final challenge = widget.challenge;
    if (challenge != null) {
      met = challenge.isMet(widget.result);
      if (met) paid = await storage.claimChallenge(challenge);
    }

    if (!mounted) return;
    setState(() {
      _outcome = outcome;
      _challengeMet = met;
      _challengePaid = paid;
    });
  }

  static String _fmt(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final outcome = _outcome;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(r.mode.icon, size: 16, color: AppColors.textDim),
                    const SizedBox(width: 6),
                    Text(
                      r.mode.displayName.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _GradeBadge(grade: r.grade),
                const SizedBox(height: 20),
                const SectionLabel('Final score'),
                const SizedBox(height: 4),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: r.score),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOut,
                  builder: (_, value, __) => Text(
                    '$value',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 60,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
                if (outcome != null && outcome.isNewHighScore) ...[
                  const SizedBox(height: 8),
                  const InfoChip(
                    icon: Icons.emoji_events_outlined,
                    label: 'New high score',
                    accent: true,
                  ),
                ],
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: 'Correct',
                        value: '${r.correctAnswers}',
                        accent: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        label: 'Wrong',
                        value: '${r.wrongAnswers}',
                        alert: r.wrongAnswers > 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(label: 'Best combo', value: '×${r.maxCombo}'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        label: 'Accuracy',
                        value: '${r.accuracy.toStringAsFixed(0)}%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: 'Time',
                        value: _fmt(r.timeTakenSeconds),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        label: 'Coins',
                        value: '+${r.coinsEarned}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        label: 'XP',
                        value: '+${r.xpEarned}',
                      ),
                    ),
                  ],
                ),
                if (widget.challenge != null && _challengeMet != null) ...[
                  const SizedBox(height: 16),
                  _ChallengeBanner(
                    challenge: widget.challenge!,
                    met: _challengeMet!,
                    paid: _challengePaid,
                  ),
                ],
                if (outcome != null && outcome.leveledUp) ...[
                  const SizedBox(height: 16),
                  const _Banner(
                    icon: Icons.bolt,
                    title: 'Level up',
                    subtitle: 'You reached a new level.',
                  ),
                ],
                if (outcome != null)
                  for (final a in outcome.newAchievements) ...[
                    const SizedBox(height: 16),
                    _Banner(
                      icon: a.icon,
                      title: 'Achievement unlocked',
                      subtitle: '${a.title} · ${a.description}',
                    ),
                  ],
                const SizedBox(height: 28),
                AppButton(
                  label: 'Play again',
                  icon: Icons.replay,
                  onTap: () => Navigator.of(context).pushReplacement(
                    fadeRoute(
                      GameScreen(mode: r.mode, challenge: widget.challenge),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Main menu',
                  icon: Icons.home_outlined,
                  outlined: true,
                  onTap: () => Navigator.of(context)
                      .popUntil((route) => route.isFirst),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradeBadge extends StatelessWidget {
  final String grade;
  const _GradeBadge({required this.grade});

  @override
  Widget build(BuildContext context) {
    final good = grade == 'S' || grade == 'A' || grade == 'B';
    final color = good ? AppColors.accent : AppColors.textDim;
    return Container(
      width: 88,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
      ),
      child: Text(
        grade,
        style: TextStyle(
          color: color,
          fontSize: 44,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Banner({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      highlighted: true,
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeBanner extends StatelessWidget {
  final DailyChallenge challenge;
  final bool met;
  final bool paid;

  const _ChallengeBanner({
    required this.challenge,
    required this.met,
    required this.paid,
  });

  @override
  Widget build(BuildContext context) {
    if (!met) {
      return AppCard(
        child: Row(
          children: [
            const Icon(Icons.today_outlined, color: AppColors.textDim),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Challenge not reached yet: ${challenge.description}',
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return _Banner(
      icon: Icons.today_outlined,
      title: paid ? 'Challenge complete' : 'Challenge already claimed today',
      subtitle: paid
          ? '${challenge.title} · +${challenge.rewardLabel}'
          : challenge.title,
    );
  }
}
