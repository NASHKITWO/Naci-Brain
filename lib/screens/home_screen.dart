// lib/screens/home_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/app_ui.dart';
import 'achievements_screen.dart';
import 'daily_challenge_screen.dart';
import 'mode_selection_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(fadeRoute(screen));
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top bar ────────────────────────────────────────────────
              Row(
                children: [
                  InfoChip(icon: Icons.bolt, label: 'Lv ${storage.level}'),
                  const SizedBox(width: 8),
                  InfoChip(
                    icon: Icons.monetization_on_outlined,
                    label: '${storage.coins}',
                  ),
                  const SizedBox(width: 8),
                  InfoChip(
                    icon: Icons.diamond_outlined,
                    label: '${storage.gems}',
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showSettings(context),
                    icon: const Icon(Icons.settings_outlined),
                    color: AppColors.textDim,
                    tooltip: 'Settings',
                  ),
                ],
              ),

              const SizedBox(height: 56),

              // ── Logo ───────────────────────────────────────────────────
              const Text(
                'Naci',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const Text(
                'Brain',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Fast math. Big combos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),

              const SizedBox(height: 32),

              if (storage.loginStreak > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Center(
                    child: InfoChip(
                      icon: Icons.local_fire_department_outlined,
                      label: '${storage.loginStreak} day streak',
                      accent: true,
                    ),
                  ),
                ),

              _BestScores(storage: storage),

              const SizedBox(height: 24),

              // ── Actions ────────────────────────────────────────────────
              AppButton(
                label: 'Play',
                icon: Icons.play_arrow_rounded,
                height: 60,
                onTap: () => _push(context, const ModeSelectionScreen()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Daily',
                      icon: Icons.today_outlined,
                      outlined: true,
                      height: 52,
                      onTap: () =>
                          _push(context, const DailyChallengeScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Spin',
                      icon: Icons.card_giftcard,
                      outlined: true,
                      height: 52,
                      onTap: () => _showSpin(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Stats',
                      icon: Icons.bar_chart_rounded,
                      outlined: true,
                      height: 52,
                      onTap: () => _push(context, const StatsScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Awards',
                      icon: Icons.emoji_events_outlined,
                      outlined: true,
                      height: 52,
                      onTap: () =>
                          _push(context, const AchievementsScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const _SettingsSheet(),
    );
  }

  void _showSpin(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _SpinSheet(),
    );
  }
}

// ─── Best scores ──────────────────────────────────────────────────────────────

class _BestScores extends StatelessWidget {
  final StorageService storage;
  const _BestScores({required this.storage});

  @override
  Widget build(BuildContext context) {
    final entries = GameMode.values
        .map((m) => MapEntry(m, storage.getHighScore(m)))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: entries.take(3).map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              Text(
                '${e.value}',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(e.key.icon, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    e.key.displayName,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Settings ─────────────────────────────────────────────────────────────────

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.vibration, color: AppColors.textDim),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Haptic feedback',
                    style: TextStyle(color: AppColors.text, fontSize: 15),
                  ),
                ),
                Switch(
                  value: storage.hapticsEnabled,
                  onChanged: (v) =>
                      context.read<StorageService>().setHaptics(v),
                ),
              ],
            ),
            const Divider(height: 32),
            const Text(
              'Naci Brain  ·  v1.0.0',
              style: TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
            const SizedBox(height: 6),
            const Text(
              'Developed by Muhammad Ikhsan\n'
              'Teknik Informatika, Universitas Pamulang',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Based on Brain Burn by ali-hasssan (MIT License)',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Daily spin ───────────────────────────────────────────────────────────────

class _Prize {
  final String label;
  final int coins;
  final int gems;
  final int weight;
  const _Prize(this.label, {this.coins = 0, this.gems = 0, this.weight = 1});
}

class _SpinSheet extends StatefulWidget {
  const _SpinSheet();

  @override
  State<_SpinSheet> createState() => _SpinSheetState();
}

class _SpinSheetState extends State<_SpinSheet> {
  static const List<_Prize> _prizes = [
    _Prize('25 coins', coins: 25, weight: 30),
    _Prize('50 coins', coins: 50, weight: 30),
    _Prize('100 coins', coins: 100, weight: 20),
    _Prize('200 coins', coins: 200, weight: 8),
    _Prize('3 gems', gems: 3, weight: 9),
    _Prize('5 gems', gems: 5, weight: 3),
  ];

  bool _busy = false;
  _Prize? _won;

  _Prize _roll() {
    final total = _prizes.fold<int>(0, (sum, p) => sum + p.weight);
    int roll = Random().nextInt(total);
    for (final p in _prizes) {
      roll -= p.weight;
      if (roll < 0) return p;
    }
    return _prizes.last;
  }

  Future<void> _spin() async {
    final storage = context.read<StorageService>();
    if (_busy || _won != null || !storage.canSpinToday) return;
    setState(() => _busy = true);

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final prize = _roll();
    await storage.markSpinUsed();
    if (prize.coins > 0) await storage.addCoins(prize.coins);
    if (prize.gems > 0) await storage.addGems(prize.gems);

    if (!mounted) return;
    setState(() {
      _busy = false;
      _won = prize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSpin = context.watch<StorageService>().canSpinToday;
    final won = _won;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Daily spin',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              won != null
                  ? 'Reward added to your balance'
                  : canSpin
                      ? 'One free spin every day'
                      : 'Come back tomorrow',
              style: const TextStyle(color: AppColors.textDim, fontSize: 13),
            ),
            const SizedBox(height: 28),
            AnimatedScale(
              scale: _busy ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOut,
              child: Container(
                width: 120,
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
                child: Icon(
                  won != null ? Icons.check : Icons.card_giftcard,
                  size: 48,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (won != null)
              Text(
                'You won ${won.label}',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              AppButton(
                label: _busy
                    ? 'Spinning…'
                    : canSpin
                        ? 'Spin'
                        : 'Already spun today',
                onTap: canSpin && !_busy ? _spin : null,
              ),
          ],
        ),
      ),
    );
  }
}
