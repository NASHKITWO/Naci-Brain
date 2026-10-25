// lib/screens/splash_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    // Background orbs animation
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Icon pulse animation
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Navigate to HomeScreen after 3 seconds
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // ── Animated Background ──────────────────────────────────
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _SplashBgPainter(t: _bgCtrl.value),
            ),
          ),

          // ── Main Content ─────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── App Icon ───────────────────────────────────────
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, child) => Transform.scale(
                    scale: _pulseAnim.value,
                    child: child,
                  ),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonCyan.withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: AppColors.neonOrange.withOpacity(0.25),
                          blurRadius: 60,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: Image.asset(
                        'assets/images/icon.png',
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.4, 0.4),
                      end: const Offset(1.0, 1.0),
                      duration: 700.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 36),

                // ── NACI text ─────────────────────────────────────
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [AppColors.neonCyan, Color(0xFF0090CC)],
                  ).createShader(b),
                  child: const Text(
                    'NACI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 58,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      height: 0.95,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 500.ms)
                    .slideY(begin: 0.3, end: 0),

                // ── BRAIN text ──────────────────────────────────────
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [AppColors.neonOrange, AppColors.neonPink],
                  ).createShader(b),
                  child: const Text(
                    'BRAIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 58,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      height: 0.95,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 550.ms, duration: 500.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 14),

                // ── Tagline ────────────────────────────────────────
                Text(
                  'FAST MATH  ·  HUGE COMBOS  ·  NO MERCY',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 500.ms),

                const SizedBox(height: 28),

                // ── Credit ─────────────────────────────────────────
                Text(
                  'Dikembangkan oleh Muhammad Ikhsan',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1000.ms, duration: 500.ms),
                const SizedBox(height: 4),
                Text(
                  'Teknik Informatika · Universitas Pamulang',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1000.ms, duration: 500.ms),

                const SizedBox(height: 40),

                // ── Loading dots ───────────────────────────────────
                _LoadingDots()
                    .animate()
                    .fadeIn(delay: 1200.ms, duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading Dots ─────────────────────────────────────────────────────────────

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final t = (_ctrl.value - delay).clamp(0.0, 1.0);
            final opacity = math.sin(t * math.pi).clamp(0.2, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonCyan.withOpacity(opacity),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonCyan.withOpacity(opacity * 0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

// ─── Background Painter ───────────────────────────────────────────────────────

class _SplashBgPainter extends CustomPainter {
  final double t;
  _SplashBgPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.bgDark,
    );

    // Cyan top orb
    _orb(
      canvas,
      Offset(
        size.width * (0.5 + 0.1 * math.sin(t * math.pi * 2)),
        size.height * (0.25 + 0.05 * math.cos(t * math.pi * 3)),
      ),
      size.width * 0.55,
      AppColors.neonCyan.withOpacity(0.055 + 0.025 * math.sin(t * math.pi)),
    );

    // Orange bottom orb
    _orb(
      canvas,
      Offset(
        size.width * (0.5 - 0.08 * math.cos(t * math.pi * 2)),
        size.height * (0.78 + 0.04 * math.sin(t * math.pi * 2)),
      ),
      size.width * 0.48,
      AppColors.neonOrange.withOpacity(0.04 + 0.015 * math.cos(t * math.pi)),
    );

    // Purple side orb
    _orb(
      canvas,
      Offset(
        size.width * (0.15 + 0.06 * math.sin(t * math.pi)),
        size.height * 0.5,
      ),
      size.width * 0.35,
      AppColors.neonPurple.withOpacity(0.03 + 0.012 * math.sin(t * math.pi * 2)),
    );

    // Dot grid
    final dotPaint = Paint()
      ..color = AppColors.neonCyan.withOpacity(0.04)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;
    const gap = 44.0;
    for (double x = gap; x < size.width; x += gap) {
      for (double y = gap; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }
  }

  void _orb(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color, Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_SplashBgPainter old) => old.t != t;
}
