// lib/screens/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  StorageService? _storage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await StorageService.getInstance();
    setState(() => _storage = s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: _storage == null
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final s = _storage!;
    final scores = s.highScores;
    final accuracy = s.totalGamesPlayed > 0
        ? (s.totalCorrectAnswers / (s.totalGamesPlayed * 20) * 100)
            .clamp(0, 100)
            .toStringAsFixed(1)
        : '—';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: AppColors.textSecondary),
                ),
                const Expanded(
                  child: Text(
                    'STATS',
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
          ),
        ),

        // ── Player Card ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: _PlayerCard(storage: s),
          ),
        ),

        // ── Global Stats ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel('OVERALL'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: _StatBox(
                            label: 'GAMES PLAYED',
                            value: '${s.totalGamesPlayed}',
                            icon: '🎮',
                            color: AppColors.neonCyan,
                            delay: 100)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _StatBox(
                            label: 'CORRECT',
                            value: '${s.totalCorrectAnswers}',
                            icon: '✓',
                            color: AppColors.neonGreen,
                            delay: 200)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: _StatBox(
                            label: 'LOGIN STREAK',
                            value: '${s.loginStreak}d',
                            icon: '🔥',
                            color: AppColors.neonOrange,
                            delay: 300)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _StatBox(
                            label: 'LEVEL',
                            value: '${s.level}',
                            icon: '⚡',
                            color: AppColors.neonPurple,
                            delay: 400)),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── High Scores ──────────────────────────────────────────────
        if (scores.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: _SectionLabel('HIGH SCORES'),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final mode = GameMode.values[i];
                final score = scores[mode.name] ?? 0;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: _HighScoreRow(mode: mode, score: score, index: i),
                );
              },
              childCount: GameMode.values.length,
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final StorageService storage;
  const _PlayerCard({required this.storage});

  @override
  Widget build(BuildContext context) {
    final xpForNext = storage.level * 500;
    final xpProgress = (storage.xp / xpForNext).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.neonCyan.withOpacity(0.12),
            AppColors.neonPurple.withOpacity(0.08),
          ],
        ),
        border: Border.all(color: AppColors.neonCyan.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonCyan.withOpacity(0.15),
                  border: Border.all(
                      color: AppColors.neonCyan.withOpacity(0.5), width: 2),
                  boxShadow: AppTheme.neonGlow(AppColors.neonCyan),
                ),
                child: const Center(
                  child: Text('🧠', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LEVEL ${storage.level}',
                      style: const TextStyle(
                        color: AppColors.neonCyan,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '${storage.xp} / $xpForNext XP',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Coins + Gems
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _CurrencyChip(icon: '🪙', value: '${storage.coins}',
                      color: AppColors.neonYellow),
                  const SizedBox(height: 6),
                  _CurrencyChip(icon: '💎', value: '${storage.gems}',
                      color: AppColors.neonCyan),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // XP bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: xpProgress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: AppColors.bgSurface,
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.neonCyan),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }
}

class _CurrencyChip extends StatelessWidget {
  final String icon, value;
  final Color color;
  const _CurrencyChip(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 3,
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value, icon;
  final Color color;
  final int delay;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.bgCard,
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 8,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

class _HighScoreRow extends StatelessWidget {
  final GameMode mode;
  final int score;
  final int index;

  const _HighScoreRow(
      {required this.mode, required this.score, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = mode.accentColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.bgCard,
        border: Border.all(
            color: score > 0 ? color.withOpacity(0.3) : Colors.transparent),
      ),
      child: Row(
        children: [
          Text(mode.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mode.displayName.toUpperCase(),
              style: TextStyle(
                color: score > 0 ? color : AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Text(
            score > 0 ? '$score' : '—',
            style: TextStyle(
              color: score > 0 ? color : AppColors.textMuted,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          if (score > 0)
            Text('pts',
                style: TextStyle(
                    color: color.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 * index), duration: 300.ms)
        .slideX(begin: 0.2, end: 0);
  }
}
