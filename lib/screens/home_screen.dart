// lib/screens/home_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/neon_button.dart';
import 'achievements_screen.dart';
import 'daily_challenge_screen.dart';
import 'mode_selection_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgCtrl;
  StorageService? _storage;
  int _coins = 0;
  int _level = 1;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _loadData();
  }

  Future<void> _loadData() async {
    final s = await StorageService.getInstance();
    final streak = await s.checkAndUpdateLoginStreak();
    if (mounted) {
      setState(() {
        _storage = s;
        _coins = s.coins;
        _level = s.level;
        _streak = streak;
      });
    }
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  void _push(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ).then((_) => _loadData()); // Refresh data on return
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          _HomeBackground(controller: _bgCtrl),
          SafeArea(
            child: Column(
              children: [
                // ── Top Bar ─────────────────────────────────────────────
                _buildTopBar(),

                const Spacer(flex: 2),

                // ── Logo ────────────────────────────────────────────────
                _buildLogo(),

                const SizedBox(height: 6),
                _buildTagline(),

                const Spacer(flex: 2),

                // ── Streak Banner ────────────────────────────────────────
                if (_streak > 1) _buildStreakBanner(),

                // ── Best Score Preview ───────────────────────────────────
                _buildBestScores(),

                const Spacer(flex: 1),

                // ── PLAY Button ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: NeonButton(
                    label: 'PLAY',
                    icon: '▶',
                    color: AppColors.neonCyan,
                    height: 66,
                    onTap: () => _push(const ModeSelectionScreen()),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 500.ms)
                      .slideY(begin: 0.3, end: 0),
                ),

                const SizedBox(height: 14),

                // ── Quick Actions ────────────────────────────────────────
                _buildQuickActions(),

                const SizedBox(height: 12),

                // ── Bottom Nav Row ───────────────────────────────────────
                _buildBottomNav(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Level badge
          _Chip(
            icon: '⚡',
            label: 'LV $_level',
            color: AppColors.neonPurple,
          ),

          // Coins
          _Chip(
            icon: '🪙',
            label: '$_coins',
            color: AppColors.neonYellow,
          ),

          // Settings
          GestureDetector(
            onTap: () => _showSettings(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.bgCard,
                border: Border.all(
                    color: AppColors.textMuted.withOpacity(0.3)),
              ),
              child: const Icon(Icons.settings_outlined,
                  color: AppColors.textSecondary, size: 18),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [AppColors.neonCyan, Color(0xFF0080FF)],
          ).createShader(b),
          child: const Text(
            'NACI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 78,
              fontWeight: FontWeight.w900,
              letterSpacing: -3,
              height: 0.88,
            ),
          ),
        ),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [AppColors.neonOrange, AppColors.neonPink],
          ).createShader(b),
          child: const Text(
            'BRAIN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 78,
              fontWeight: FontWeight.w900,
              letterSpacing: -3,
              height: 0.88,
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(
          begin: const Offset(0.82, 0.82),
          curve: Curves.elasticOut,
          duration: 900.ms,
        );
  }

  Widget _buildTagline() {
    return Text(
      'FAST MATH  ·  HUGE COMBOS  ·  NO MERCY',
      style: TextStyle(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.5,
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Widget _buildStreakBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: [
              AppColors.neonOrange.withOpacity(0.2),
              AppColors.neonYellow.withOpacity(0.15),
            ],
          ),
          border: Border.all(
              color: AppColors.neonOrange.withOpacity(0.5)),
          boxShadow: AppTheme.neonGlow(AppColors.neonOrange,
              intensity: 0.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              '$_streak DAY STREAK!',
              style: const TextStyle(
                color: AppColors.neonYellow,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3, end: 0);
  }

  Widget _buildBestScores() {
    if (_storage == null) return const SizedBox(height: 20);
    final scores = _storage!.highScores;
    if (scores.isEmpty) return const SizedBox(height: 20);

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: top.map((e) {
          final mode = GameMode.values
              .firstWhere((m) => m.name == e.key,
                  orElse: () => GameMode.classic);
          final color = mode.accentColor;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${e.value}',
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    shadows: AppColors.neonGlow(color)
                        .map((s) => Shadow(
                            color: s.color, blurRadius: s.blurRadius))
                        .toList(),
                  ),
                ),
                Text(
                  mode.emoji,
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'BEST',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 8,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 350.ms, duration: 400.ms);
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'DAILY',
              icon: '📅',
              color: AppColors.neonGreen,
              onTap: () => _push(const DailyChallengeScreen()),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              label: 'SPIN',
              icon: '🎰',
              color: AppColors.neonPurple,
              onTap: () => _showDailySpin(),
            ),
          ),
        ],
      ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
    );
  }

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavButton(
              icon: '📊',
              label: 'STATS',
              onTap: () => _push(const StatsScreen())),
          _NavButton(
              icon: '🏆',
              label: 'AWARDS',
              onTap: () => _push(const AchievementsScreen())),
        ],
      ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SettingsSheet(storage: _storage),
    ).then((_) => _loadData());
  }

  void _showDailySpin() {
    final canSpin = _storage?.canSpinToday ?? true;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _DailySpinSheet(canSpin: canSpin),
    ).then((_) => _loadData());
  }
}

// ─── Chip ─────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String icon, label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label, icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.4)),
          boxShadow: AppTheme.neonGlow(color, intensity: 0.25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}

// ─── Nav Button ───────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final String icon, label;
  final VoidCallback onTap;

  const _NavButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 8,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Animated Background ──────────────────────────────────────────────────────

class _HomeBackground extends StatelessWidget {
  final AnimationController controller;
  const _HomeBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _HomeBgPainter(t: controller.value),
      ),
    );
  }
}

class _HomeBgPainter extends CustomPainter {
  final double t;
  _HomeBgPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = AppColors.bgDark);

    _orb(canvas,
        Offset(size.width * (0.18 + 0.08 * math.sin(t * math.pi * 2)),
            size.height * (0.22 + 0.04 * math.cos(t * math.pi * 3))),
        size.width * 0.5,
        AppColors.neonCyan.withOpacity(0.045 + 0.018 * math.sin(t * math.pi)));

    _orb(canvas,
        Offset(size.width * (0.82 - 0.07 * math.cos(t * math.pi * 2.5)),
            size.height * (0.72 + 0.05 * math.sin(t * math.pi * 2))),
        size.width * 0.45,
        AppColors.neonPurple.withOpacity(0.04 + 0.015 * math.cos(t * math.pi)));

    _orb(canvas,
        Offset(size.width * 0.5,
            size.height * (0.5 + 0.08 * math.sin(t * math.pi * 1.5))),
        size.width * 0.3,
        AppColors.neonOrange.withOpacity(0.022 + 0.01 * math.sin(t * math.pi * 3)));

    // Dot grid
    final paint = Paint()
      ..color = AppColors.neonCyan.withOpacity(0.04)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;
    const gap = 44.0;
    for (double x = gap; x < size.width; x += gap) {
      for (double y = gap; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  void _orb(Canvas c, Offset center, double r, Color color) {
    c.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(colors: [color, Colors.transparent])
            .createShader(
                Rect.fromCircle(center: center, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_HomeBgPainter old) => old.t != t;
}

// ─── Settings Sheet ───────────────────────────────────────────────────────────

class _SettingsSheet extends StatefulWidget {
  final StorageService? storage;
  const _SettingsSheet({this.storage});

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  bool _sound = true;
  bool _haptic = true;

  @override
  void initState() {
    super.initState();
    if (widget.storage != null) {
      _sound = widget.storage!.soundEnabled;
      _haptic = widget.storage!.hapticEnabled;
    }
  }

  Future<void> _save() async {
    final s = await StorageService.getInstance();
    await s.updateSettings({'soundEnabled': _sound, 'hapticEnabled': _haptic});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SETTINGS',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3)),
          const SizedBox(height: 20),
          _Toggle(
            icon: '🔊',
            label: 'Sound Effects',
            value: _sound,
            onChanged: (v) {
              setState(() => _sound = v);
              _save();
            },
          ),
          _Toggle(
            icon: '📳',
            label: 'Haptic Feedback',
            value: _haptic,
            onChanged: (v) {
              setState(() => _haptic = v);
              _save();
            },
          ),
          const SizedBox(height: 8),
          Text(
            'v1.0.0  ·  Naci Brain',
            style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                letterSpacing: 1.5),
          ),
          const SizedBox(height: 6),
          Text(
            'Dikembangkan oleh Muhammad Ikhsan\nTeknik Informatika, Universitas Pamulang',
            style: TextStyle(
                color: AppColors.textMuted, fontSize: 10, height: 1.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Berdasarkan Brain Burn oleh ali-hasssan (MIT License)',
            style: TextStyle(
                color: AppColors.textMuted, fontSize: 10, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String icon, label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.neonCyan,
            trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
                  ? AppColors.neonCyan.withOpacity(0.3)
                  : AppColors.bgSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Daily Spin Sheet ─────────────────────────────────────────────────────────

class _DailySpinSheet extends StatefulWidget {
  final bool canSpin;
  const _DailySpinSheet({required this.canSpin});

  @override
  State<_DailySpinSheet> createState() => _DailySpinSheetState();
}

class _DailySpinSheetState extends State<_DailySpinSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _spinning = false;
  bool _done = false;
  String _rewardLabel = '';

  final List<(String, String, int)> _prizes = [
    ('🪙', '50 Coins', 50),
    ('💎', '5 Gems', 0),
    ('🪙', '100 Coins', 100),
    ('⚡', 'Power-Ups ×3', 0),
    ('🪙', '25 Coins', 25),
    ('💎', '3 Gems', 0),
    ('🔥', '200 Coins', 200),
    ('🎯', 'Power-Ups ×5', 0),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_spinning || _done || !widget.canSpin) return;
    setState(() => _spinning = true);

    final idx = DateTime.now().millisecond % _prizes.length;
    final prize = _prizes[idx];

    await _ctrl.forward();

    final storage = await StorageService.getInstance();
    await storage.markSpinUsed();
    if (prize.$3 > 0) await storage.addCoins(prize.$3);

    setState(() {
      _done = true;
      _rewardLabel = '${prize.$1} ${prize.$2}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('DAILY SPIN',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3)),
          const SizedBox(height: 4),
          Text(
            widget.canSpin ? 'Spin to win rewards!' : 'Come back tomorrow!',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Spin wheel
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final angle =
                  _ctrl.value * 6 * math.pi + math.pi * 0.25;
              return Transform.rotate(
                angle: angle,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [
                        AppColors.neonCyan,
                        AppColors.neonPurple,
                        AppColors.neonYellow,
                        AppColors.neonOrange,
                        AppColors.neonPink,
                        AppColors.neonGreen,
                        AppColors.neonCyan,
                      ],
                    ),
                    boxShadow: AppTheme.neonGlow(AppColors.neonCyan),
                  ),
                  child: Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bgDark,
                      ),
                      child: Center(
                        child: Text(
                          _done
                              ? _rewardLabel.split(' ').first
                              : '🎰',
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          if (_done)
            Text(
              'You won: $_rewardLabel!',
              style: const TextStyle(
                  color: AppColors.neonYellow,
                  fontSize: 18,
                  fontWeight: FontWeight.w800),
            )
          else
            NeonButton(
              label: widget.canSpin ? 'SPIN!' : 'ALREADY SPUN',
              color: widget.canSpin
                  ? AppColors.neonPurple
                  : AppColors.textMuted,
              width: 200,
              height: 52,
              onTap: widget.canSpin && !_spinning ? _spin : null,
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
