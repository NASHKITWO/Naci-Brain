// lib/screens/daily_challenge_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/neon_button.dart';
import 'game_screen.dart';

class DailyChallengeScreen extends StatelessWidget {
  const DailyChallengeScreen({super.key});

  // Deterministic daily seed
  static int get _daySeed {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  static List<_ChallengeData> get _todaysChallenges {
    final rng = Random(_daySeed);
    final modes = GameMode.values;
    return [
      _ChallengeData(
        title: 'Speed Round',
        description: 'Answer 20 questions in Time Attack',
        reward: '🪙 150 Coins',
        icon: '⚡',
        color: AppColors.neonYellow,
        mode: GameMode.timeAttack,
        target: 20,
        type: 'questions',
      ),
      _ChallengeData(
        title: 'Combo King',
        description: 'Reach a ${5 + rng.nextInt(5)}x combo in Classic Mode',
        reward: '💎 3 Gems',
        icon: '🔥',
        color: AppColors.neonOrange,
        mode: GameMode.classic,
        target: 5 + rng.nextInt(5),
        type: 'combo',
      ),
      _ChallengeData(
        title: 'Survivor',
        description: 'Score 200+ points in Endless Mode',
        reward: '🪙 200 Coins + ⚡ Power-Ups',
        icon: '♾️',
        color: AppColors.neonPurple,
        mode: GameMode.endless,
        target: 200,
        type: 'score',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final challenges = _todaysChallenges;
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: AppColors.textSecondary),
                  ),
                  const Expanded(
                    child: Text(
                      'DAILY CHALLENGES',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Resets in
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.neonCyan.withOpacity(0.08),
                  border: Border.all(
                      color: AppColors.neonCyan.withOpacity(0.3)),
                ),
                child: Text(
                  'Resets in ${hours}h ${mins}m',
                  style: const TextStyle(
                    color: AppColors.neonCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            // Challenge cards
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: challenges.length,
                itemBuilder: (context, i) => _ChallengeCard(
                  data: challenges[i],
                  index: i,
                  onPlay: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            GameScreen(mode: challenges[i].mode),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeData {
  final String title, description, reward, icon, type;
  final Color color;
  final GameMode mode;
  final int target;

  const _ChallengeData({
    required this.title,
    required this.description,
    required this.reward,
    required this.icon,
    required this.color,
    required this.mode,
    required this.target,
    required this.type,
  });
}

class _ChallengeCard extends StatelessWidget {
  final _ChallengeData data;
  final int index;
  final VoidCallback onPlay;

  const _ChallengeCard({
    required this.data,
    required this.index,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            data.color.withOpacity(0.14),
            data.color.withOpacity(0.05),
          ],
        ),
        border:
            Border.all(color: data.color.withOpacity(0.45), width: 1.5),
        boxShadow: AppTheme.neonGlow(data.color, intensity: 0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: data.color.withOpacity(0.15),
                  border: Border.all(color: data.color.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text(data.icon,
                      style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title.toUpperCase(),
                      style: TextStyle(
                        color: data.color,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Reward banner
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: data.color.withOpacity(0.08),
              border:
                  Border.all(color: data.color.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Text(
                  'REWARD  ',
                  style: TextStyle(
                    color: data.color.withOpacity(0.6),
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  data.reward,
                  style: TextStyle(
                    color: data.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          NeonButton(
            label: 'START CHALLENGE',
            color: data.color,
            height: 46,
            onTap: onPlay,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 150 * index), duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }
}
