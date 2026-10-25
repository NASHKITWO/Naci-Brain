// lib/widgets/timer_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';

class TimerWidget extends StatelessWidget {
  final int timeRemaining;
  final int totalTime;
  final bool isFrozen;

  const TimerWidget({
    super.key,
    required this.timeRemaining,
    required this.totalTime,
    this.isFrozen = false,
  });

  Color get _color {
    if (isFrozen) return AppColors.neonCyan;
    if (timeRemaining <= 5) return AppColors.timerDanger;
    if (timeRemaining <= 15) return AppColors.timerWarning;
    return AppColors.timerNormal;
  }

  double get _progress => (timeRemaining / totalTime).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Timer number
        Text(
          isFrozen ? '❄️  $timeRemaining' : '$timeRemaining',
          style: TextStyle(
            color: _color,
            fontSize: 52,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            shadows: AppColors.neonGlow(_color)
                .map((s) => Shadow(color: s.color, blurRadius: s.blurRadius))
                .toList(),
          ),
        )
            .animate(target: timeRemaining <= 5 && !isFrozen ? 1 : 0)
            .shake(duration: 500.ms, hz: 2)
            .then()
            .shimmer(color: AppColors.neonRed),

        const SizedBox(height: 8),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: _progress,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_color, _color.withValues(alpha: 0.6)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: AppColors.neonGlow(_color, spread: 3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
