// lib/screens/achievements_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/question.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  Set<String> _unlocked = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = await StorageService.getInstance();
    setState(() {
      _unlocked = storage.unlockedAchievements;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: Achievement.all.length,
                  itemBuilder: (context, i) {
                    final a = Achievement.all[i];
                    final unlocked = _unlocked.contains(a.id);
                    return _AchievementTile(
                      achievement: a,
                      unlocked: unlocked,
                      index: i,
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

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textSecondary),
          ),
          const Expanded(
            child: Text(
              'ACHIEVEMENTS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  final int index;

  const _AchievementTile({
    required this.achievement,
    required this.unlocked,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? AppColors.neonYellow : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.bgCard,
        border: Border.all(
          color: unlocked
              ? AppColors.neonYellow.withOpacity(0.4)
              : AppColors.textMuted.withOpacity(0.15),
        ),
        boxShadow: unlocked
            ? AppTheme.neonGlow(AppColors.neonYellow, intensity: 0.3)
            : null,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                unlocked ? achievement.icon : '🔒',
                style: TextStyle(
                  fontSize: 22,
                  color: unlocked ? null : Colors.white24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    color: unlocked ? AppColors.textPrimary : AppColors.textMuted,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  achievement.description,
                  style: TextStyle(
                    color: unlocked
                        ? AppColors.textSecondary
                        : AppColors.textMuted.withOpacity(0.6),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          // Status
          if (unlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.neonGreen.withOpacity(0.15),
                border: Border.all(
                    color: AppColors.neonGreen.withOpacity(0.5)),
              ),
              child: const Text(
                '✓',
                style: TextStyle(
                  color: AppColors.neonGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 50 * index), duration: 300.ms)
        .slideX(begin: 0.2, end: 0);
  }
}
