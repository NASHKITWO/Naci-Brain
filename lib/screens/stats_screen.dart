// lib/screens/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/app_ui.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<StorageService>();
    final accuracy = s.overallAccuracy;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Stats'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _PlayerCard(storage: s),
                  const SizedBox(height: 24),
                  const SectionLabel('Overall'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          label: 'Games played',
                          value: '${s.totalGamesPlayed}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatTile(
                          label: 'Correct answers',
                          value: '${s.totalCorrectAnswers}',
                          accent: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          label: 'Accuracy',
                          value: accuracy == null
                              ? '—'
                              : '${accuracy.toStringAsFixed(0)}%',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatTile(
                          label: 'Best combo',
                          value: s.bestCombo == 0 ? '—' : '×${s.bestCombo}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          label: 'Day streak',
                          value: '${s.loginStreak}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel('High scores'),
                  const SizedBox(height: 10),
                  for (final mode in GameMode.values) ...[
                    _HighScoreRow(mode: mode, score: s.getHighScore(mode)),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final StorageService storage;
  const _PlayerCard({required this.storage});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${storage.level}',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${storage.xp} / ${GameConstants.xpPerLevel} XP',
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  InfoChip(
                    icon: Icons.monetization_on_outlined,
                    label: '${storage.coins}',
                  ),
                  const SizedBox(height: 6),
                  InfoChip(
                    icon: Icons.diamond_outlined,
                    label: '${storage.gems}',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: storage.xpProgress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighScoreRow extends StatelessWidget {
  final GameMode mode;
  final int score;
  const _HighScoreRow({required this.mode, required this.score});

  @override
  Widget build(BuildContext context) {
    final has = score > 0;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            mode.icon,
            size: 20,
            color: has ? AppColors.accent : AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mode.displayName,
              style: TextStyle(
                color: has ? AppColors.text : AppColors.textMuted,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            has ? '$score' : '—',
            style: TextStyle(
              color: has ? AppColors.text : AppColors.textMuted,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
