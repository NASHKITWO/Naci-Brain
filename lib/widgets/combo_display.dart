// lib/widgets/combo_display.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class ComboDisplay extends StatefulWidget {
  final int combo;
  final bool flash;

  const ComboDisplay({super.key, required this.combo, this.flash = false});

  @override
  State<ComboDisplay> createState() => _ComboDisplayState();
}

class _ComboDisplayState extends State<ComboDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(ComboDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.combo != oldWidget.combo && widget.combo > 1) {
      _ctrl.forward().then((_) => _ctrl.reverse());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _comboColor {
    final idx = (widget.combo - 1).clamp(0, AppColors.comboColors.length - 1);
    return AppColors.comboColors[idx];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.combo <= 1 && !widget.flash) {
      return const SizedBox(height: 36);
    }

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (_, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: child,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _comboColor.withOpacity(0.1),
              border: Border.all(
                color: _comboColor.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: AppTheme.neonGlow(_comboColor, intensity: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '×${widget.combo}',
                  style: TextStyle(
                    color: _comboColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ).withNeonGlow(_comboColor),
                ),
                const SizedBox(width: 6),
                Text(
                  'COMBO',
                  style: TextStyle(
                    color: _comboColor.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Score Pop Overlay ────────────────────────────────────────────────────────
class ScorePop extends StatefulWidget {
  final int delta;
  final Offset position;
  final VoidCallback onDone;

  const ScorePop({
    super.key,
    required this.delta,
    required this.position,
    required this.onDone,
  });

  @override
  State<ScorePop> createState() => _ScorePopState();
}

class _ScorePopState extends State<ScorePop> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _opacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 1, curve: Curves.easeIn)),
    );
    _offset = Tween<double>(begin: 0, end: -40).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.delta >= 0;
    final color = isPositive ? AppColors.neonGreen : AppColors.neonRed;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: Offset(0, _offset.value),
          child: Text(
            isPositive ? '+${widget.delta}' : '${widget.delta}',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ).withNeonGlow(color),
          ),
        ),
      ),
    );
  }
}

// ─── Streak Milestone Banner ──────────────────────────────────────────────────
class StreakMilestoneBanner extends StatefulWidget {
  final int streak;
  const StreakMilestoneBanner({super.key, required this.streak});

  @override
  State<StreakMilestoneBanner> createState() => _StreakMilestoneBannerState();
}

class _StreakMilestoneBannerState extends State<StreakMilestoneBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slide = Tween<double>(begin: -80, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.4)),
    );
    _ctrl.forward();
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
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: Offset(0, _slide.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              gradient: LinearGradient(
                colors: [
                  AppColors.neonYellow.withOpacity(0.2),
                  AppColors.neonOrange.withOpacity(0.2),
                ],
              ),
              border: Border.all(color: AppColors.neonYellow, width: 1),
              boxShadow: AppTheme.neonGlow(AppColors.neonYellow),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  '${widget.streak} STREAK!',
                  style: const TextStyle(
                    color: AppColors.neonYellow,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '+3s',
                  style: TextStyle(
                    color: AppColors.neonCyan,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
