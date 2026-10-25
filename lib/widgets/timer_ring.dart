// lib/widgets/timer_ring.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class TimerRing extends StatefulWidget {
  final int timeRemaining;
  final int totalTime;
  final bool isDanger;
  final bool isWarning;

  const TimerRing({
    super.key,
    required this.timeRemaining,
    this.totalTime = GameConstants.classicDuration,
    this.isDanger = false,
    this.isWarning = false,
  });

  @override
  State<TimerRing> createState() => _TimerRingState();
}

class _TimerRingState extends State<TimerRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(TimerRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDanger && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isDanger && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _timerColor {
    if (widget.isDanger) return AppColors.timerDanger;
    if (widget.isWarning) return AppColors.timerWarning;
    return AppColors.timerNormal;
  }

  double get _progress {
    if (widget.totalTime <= 0) return 0;
    return widget.timeRemaining / widget.totalTime;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) => Transform.scale(
        scale: widget.isDanger ? _pulseAnim.value : 1.0,
        child: SizedBox(
          width: 90,
          height: 90,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(90, 90),
                painter: _TimerRingPainter(
                  progress: _progress,
                  color: _timerColor,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: _timerColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                    child: Text(widget.timeRemaining.toString()),
                  ),
                  Text(
                    'sec',
                    style: TextStyle(
                      color: _timerColor.withOpacity(0.6),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
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
}

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _TimerRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = color.withOpacity(0.12);
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = color.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, sweepAngle, false, glowPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, sweepAngle, false, progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_TimerRingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Lives Display ────────────────────────────────────────────────────────────
class LivesDisplay extends StatelessWidget {
  final int lives;
  final int maxLives;

  const LivesDisplay({
    super.key,
    required this.lives,
    this.maxLives = GameConstants.maxMistakesEndless,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxLives, (i) {
        final active = i < lives;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? AppColors.neonRed.withOpacity(0.2)
                  : Colors.transparent,
              border: Border.all(
                color: active
                    ? AppColors.neonRed
                    : AppColors.neonRed.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow:
                  active ? AppTheme.subtleGlow(AppColors.neonRed) : null,
            ),
            child: Center(
              child: Text(
                active ? '♥' : '♡',
                style: TextStyle(
                  fontSize: 12,
                  color: active
                      ? AppColors.neonRed
                      : AppColors.neonRed.withOpacity(0.3),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Countdown Widget ─────────────────────────────────────────────────────────
class CountdownWidget extends StatefulWidget {
  const CountdownWidget({super.key});

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  int _count = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _scale = Tween<double>(begin: 0.5, end: 1.4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
    _startCountdown();
  }

  void _startCountdown() {
    _ctrl.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_count > 1) {
        setState(() => _count--);
        _ctrl.reset();
        _ctrl.forward();
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Opacity(
          opacity: _opacity.value,
          child: Text(
            _count.toString(),
            style: const TextStyle(
              color: AppColors.neonCyan,
              fontSize: 96,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
