// lib/screens/mode_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'game_screen.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // ── Header ─────────────────────────────────────────────────
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'SELECT MODE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 16),

              // ── Mode Cards ─────────────────────────────────────────────
              Expanded(
                child: ListView(
                  children: GameMode.values.asMap().entries.map((entry) {
                    final i = entry.key;
                    final mode = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ModeCard(mode: mode)
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: 100 + i * 80),
                            duration: 300.ms,
                          )
                          .slideX(begin: 0.3, end: 0),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mode Card ────────────────────────────────────────────────────────────────
class _ModeCard extends StatefulWidget {
  final GameMode mode;
  const _ModeCard({required this.mode});

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<int> _getHighScore() async {
    final storage = await StorageService.getInstance();
    return storage.getHighScore(widget.mode);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.mode.accentColor;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        _launchGame(context);
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.12),
                color.withOpacity(0.04),
              ],
            ),
            border: Border.all(color: color.withOpacity(0.4), width: 1.5),
            boxShadow: AppTheme.neonGlow(color, intensity: 0.4),
          ),
          child: Row(
            children: [
              // ── Emoji Badge ────────────────────────────────────────────
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: color.withOpacity(0.15),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text(
                    widget.mode.emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // ── Info ───────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.mode.displayName.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.mode.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ── Best Score ─────────────────────────────────────────────
              FutureBuilder<int>(
                future: _getHighScore(),
                builder: (context, snapshot) {
                  final best = snapshot.data ?? 0;
                  if (best == 0) {
                    return Icon(
                      Icons.chevron_right,
                      color: color.withOpacity(0.6),
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$best',
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'BEST',
                        style: TextStyle(
                          color: color.withOpacity(0.5),
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchGame(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => GameScreen(mode: widget.mode),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}
