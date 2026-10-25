// lib/screens/result_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../models/question.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/neon_button.dart';
import 'home_screen.dart';
import 'game_screen.dart';

class ResultScreen extends StatefulWidget {
  final GameResult result;
  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreCtrl;
  late Animation<int> _scoreAnim;
  late ConfettiController _confettiCtrl;
  late AnimationController _bgCtrl;

  bool _isNewHighScore = false;
  int _coinsEarned = 0;
  int _xpEarned = 0;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _scoreCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnim = IntTween(begin: 0, end: widget.result.score).animate(
      CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOut),
    );

    _confettiCtrl = ConfettiController(
      duration: const Duration(seconds: 4),
    );

    _init();
  }

  Future<void> _init() async {
    // Save result
    final storage = await StorageService.getInstance();
    _isNewHighScore =
        await storage.updateHighScore(widget.result.mode, widget.result.score);
    await storage.addCoins(widget.result.coinsEarned);
    await storage.addXp(widget.result.xpEarned);

    if (mounted) {
      setState(() {
        _coinsEarned = widget.result.coinsEarned;
        _xpEarned = widget.result.xpEarned;
      });
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _scoreCtrl.forward();
      if (_isNewHighScore || widget.result.accuracy >= 0.9) {
        _confettiCtrl.play();
        HapticFeedback.heavyImpact();
      }
    }
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _confettiCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  Color get _gradeColor {
    switch (widget.result.grade) {
      case 'S':
        return AppColors.neonYellow;
      case 'A':
        return AppColors.neonGreen;
      case 'B':
        return AppColors.neonCyan;
      case 'C':
        return AppColors.neonOrange;
      default:
        return AppColors.neonRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // ── Background ──────────────────────────────────────────────
          _ResultBackground(controller: _bgCtrl, mode: widget.result.mode),

          // ── Confetti ────────────────────────────────────────────────
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              gravity: 0.2,
              colors: const [
                AppColors.neonCyan,
                AppColors.neonYellow,
                AppColors.neonPink,
                AppColors.neonGreen,
                AppColors.neonPurple,
              ],
              createParticlePath: (size) {
                final path = Path();
                path.addOval(Rect.fromCircle(
                    center: Offset.zero, radius: size.width / 2));
                return path;
              },
            ),
          ),

          // ── Content ─────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // ── Mode badge ─────────────────────────────────────
                  _ModeBadge(mode: widget.result.mode),
                  const SizedBox(height: 24),

                  // ── Grade ──────────────────────────────────────────
                  _GradeDisplay(
                    grade: widget.result.grade,
                    color: _gradeColor,
                    isNewHighScore: _isNewHighScore,
                  ),
                  const SizedBox(height: 24),

                  // ── Score ──────────────────────────────────────────
                  _ScoreDisplay(
                    scoreAnim: _scoreAnim,
                    gradeColor: _gradeColor,
                  ),
                  const SizedBox(height: 28),

                  // ── Stats Grid ─────────────────────────────────────
                  _StatsGrid(result: widget.result),
                  const SizedBox(height: 20),

                  // ── Rewards ────────────────────────────────────────
                  _RewardsRow(coins: _coinsEarned, xp: _xpEarned),
                  const SizedBox(height: 28),

                  // ── Action Buttons ─────────────────────────────────
                  NeonButton(
                    label: 'PLAY AGAIN',
                    icon: '▶',
                    color: widget.result.mode.accentColor,
                    height: 60,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) =>
                              GameScreen(mode: widget.result.mode),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                          transitionDuration:
                              const Duration(milliseconds: 300),
                        ),
                      );
                    },
                  )
                      .animate()
                      .fadeIn(delay: 800.ms, duration: 400.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 12),

                  NeonButton(
                    label: 'MAIN MENU',
                    icon: '🏠',
                    outlined: true,
                    color: AppColors.textMuted,
                    height: 52,
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) =>
                              const HomeScreen(),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                          transitionDuration:
                              const Duration(milliseconds: 300),
                        ),
                        (_) => false,
                      );
                    },
                  )
                      .animate()
                      .fadeIn(delay: 900.ms, duration: 400.ms),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mode Badge ───────────────────────────────────────────────────────────────

class _ModeBadge extends StatelessWidget {
  final GameMode mode;
  const _ModeBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    final color = mode.accentColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(mode.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            mode.displayName.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─── Grade Display ────────────────────────────────────────────────────────────

class _GradeDisplay extends StatelessWidget {
  final String grade;
  final Color color;
  final bool isNewHighScore;

  const _GradeDisplay({
    required this.grade,
    required this.color,
    required this.isNewHighScore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isNewHighScore)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  AppColors.neonYellow.withOpacity(0.2),
                  AppColors.neonOrange.withOpacity(0.2),
                ],
              ),
              border: Border.all(color: AppColors.neonYellow),
              boxShadow: AppTheme.neonGlow(AppColors.neonYellow),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🏆', style: TextStyle(fontSize: 14)),
                SizedBox(width: 6),
                Text(
                  'NEW HIGH SCORE!',
                  style: TextStyle(
                    color: AppColors.neonYellow,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).scale(
                begin: const Offset(0.8, 0.8),
                curve: Curves.elasticOut,
              ),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.6), width: 2),
            boxShadow: AppTheme.neonGlow(color),
          ),
          child: Center(
            child: Text(
              grade,
              style: TextStyle(
                color: color,
                fontSize: 52,
                fontWeight: FontWeight.w900,
                shadows: AppColors.neonGlow(color)
                    .map((s) => Shadow(color: s.color, blurRadius: s.blurRadius))
                    .toList(),
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 100.ms, duration: 500.ms)
            .scale(
              begin: const Offset(0.5, 0.5),
              curve: Curves.elasticOut,
              duration: 700.ms,
            ),
      ],
    );
  }
}

// ─── Score Display ────────────────────────────────────────────────────────────

class _ScoreDisplay extends StatelessWidget {
  final Animation<int> scoreAnim;
  final Color gradeColor;

  const _ScoreDisplay({
    required this.scoreAnim,
    required this.gradeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'FINAL SCORE',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: scoreAnim,
          builder: (_, __) => Text(
            '${scoreAnim.value}',
            style: TextStyle(
              color: gradeColor,
              fontSize: 64,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
              height: 1,
              shadows: AppColors.neonGlow(gradeColor)
                  .map((s) => Shadow(color: s.color, blurRadius: s.blurRadius))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Stats Grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final GameResult result;
  const _StatsGrid({required this.result});

  @override
  Widget build(BuildContext context) {
    final accuracy = result.totalAnswers == 0
        ? 0.0
        : result.correctAnswers / result.totalAnswers * 100;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.9,
      children: [
        _StatCard(
          label: 'CORRECT',
          value: '${result.correctAnswers}',
          icon: '✓',
          color: AppColors.neonGreen,
          delay: 200,
        ),
        _StatCard(
          label: 'WRONG',
          value: '${result.wrongAnswers}',
          icon: '✗',
          color: AppColors.neonRed,
          delay: 300,
        ),
        _StatCard(
          label: 'MAX COMBO',
          value: '×${result.maxCombo}',
          icon: '⚡',
          color: AppColors.neonYellow,
          delay: 400,
        ),
        _StatCard(
          label: 'ACCURACY',
          value: '${accuracy.toStringAsFixed(0)}%',
          icon: '🎯',
          color: AppColors.neonCyan,
          delay: 500,
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;
  final int delay;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.bgCard,
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms);
  }
}

// ─── Rewards Row ──────────────────────────────────────────────────────────────

class _RewardsRow extends StatelessWidget {
  final int coins;
  final int xp;

  const _RewardsRow({required this.coins, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.bgCard,
        border: Border.all(
            color: AppColors.neonYellow.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _RewardItem(
            icon: '🪙',
            value: '+$coins',
            label: 'COINS',
            color: AppColors.neonYellow,
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.textMuted.withOpacity(0.3),
          ),
          _RewardItem(
            icon: '⚡',
            value: '+$xp',
            label: 'XP',
            color: AppColors.neonPurple,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 600.ms, duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

class _RewardItem extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color color;

  const _RewardItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        Text(
          'EARNED  $label',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Result Background ────────────────────────────────────────────────────────

class _ResultBackground extends StatelessWidget {
  final AnimationController controller;
  final GameMode mode;

  const _ResultBackground(
      {required this.controller, required this.mode});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _ResultBgPainter(
          t: controller.value,
          accentColor: mode.accentColor,
        ),
      ),
    );
  }
}

class _ResultBgPainter extends CustomPainter {
  final double t;
  final Color accentColor;

  _ResultBgPainter({required this.t, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.bgDark,
    );

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * (0.3 + 0.05 * math.sin(t * math.pi))),
      size.width * 0.6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accentColor.withOpacity(0.06),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.3),
          radius: size.width * 0.6,
        )),
    );
  }

  @override
  bool shouldRepaint(_ResultBgPainter old) => old.t != t;
}
