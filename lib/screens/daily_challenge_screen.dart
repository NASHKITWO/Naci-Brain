// lib/screens/daily_challenge_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/daily_challenge.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/app_ui.dart';
import 'game_screen.dart';

class DailyChallengeScreen extends StatelessWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final now = DateTime.now();
    final challenges = DailyChallenge.forDate(now);

    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final left = tomorrow.difference(now);
    final resets = 'Resets in ${left.inHours}h ${left.inMinutes % 60}m';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Daily challenges'),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: InfoChip(icon: Icons.schedule, label: resets),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                itemCount: challenges.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final c = challenges[i];
                  return _ChallengeCard(
                    challenge: c,
                    done: storage.isChallengeClaimed(c),
                    onPlay: () => Navigator.of(context).push(
                      fadeRoute(GameScreen(mode: c.mode, challenge: c)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final DailyChallenge challenge;
  final bool done;
  final VoidCallback onPlay;

  const _ChallengeCard({
    required this.challenge,
    required this.done,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      highlighted: done,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  challenge.mode.icon,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      challenge.description,
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (done)
                const Icon(Icons.check_circle_outline,
                    color: AppColors.accent),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SectionLabel('Reward'),
              const SizedBox(width: 10),
              Text(
                challenge.rewardLabel,
                style: TextStyle(
                  color: done ? AppColors.textMuted : AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppButton(
            label: done ? 'Completed · play again' : 'Start challenge',
            outlined: done,
            height: 46,
            onTap: onPlay,
          ),
        ],
      ),
    );
  }
}
