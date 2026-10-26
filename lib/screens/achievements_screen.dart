// lib/screens/achievements_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import '../widgets/app_ui.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final unlocked = context.watch<StorageService>().unlockedAchievements;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Achievements'),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: InfoChip(
                icon: Icons.emoji_events_outlined,
                label: '${unlocked.length} / ${Achievement.all.length} unlocked',
                accent: unlocked.isNotEmpty,
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                itemCount: Achievement.all.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final a = Achievement.all[i];
                  return _AchievementTile(
                    achievement: a,
                    unlocked: unlocked.contains(a.id),
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

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;

  const _AchievementTile({required this.achievement, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final iconColor = unlocked ? AppColors.accent : AppColors.textMuted;

    return AppCard(
      highlighted: unlocked,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.1),
            ),
            child: Icon(
              unlocked ? achievement.icon : Icons.lock_outline,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    color: unlocked ? AppColors.text : AppColors.textDim,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            const Icon(Icons.check_circle_outline, color: AppColors.accent),
        ],
      ),
    );
  }
}
