// lib/screens/game_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../providers/game_provider.dart';
import '../services/question_generator.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/answer_card.dart';
import '../widgets/combo_display.dart';
import '../widgets/power_up_bar.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  const GameScreen({super.key, required this.mode});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgPulseCtrl;
  late AnimationController _questionCtrl;
  late AnimationController _screenShakeCtrl;
  late Animation<double> _shakeAnim;

  bool _navigatingToResult = false;

  @override
  void initState() {
    super.initState();

    _bgPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _questionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _screenShakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
        parent: _screenShakeCtrl, curve: Curves.easeInOut));

    // Start the game after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().startGame(widget.mode);
    });
  }

  @override
  void dispose() {
    _bgPulseCtrl.dispose();
    _questionCtrl.dispose();
    _screenShakeCtrl.dispose();
    super.dispose();
  }

  void _onAnswerTap(int optionIndex) {
    final provider = context.read<GameProvider>();
    if (!provider.isPlaying) return;

    HapticFeedback.lightImpact();
    provider.submitAnswer(optionIndex);

    if (provider.lastAnswerState == AnswerState.wrong) {
      _screenShakeCtrl.forward(from: 0);
    } else {
      _questionCtrl.forward(from: 0);
    }
  }

  void _navigateToResult() {
    if (_navigatingToResult) return;
    _navigatingToResult = true;
    final result = context.read<GameProvider>().buildResult();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ResultScreen(result: result),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Consumer<GameProvider>(
        builder: (context, game, _) {
          // Navigate to result when game ends
          if (game.isGameOver && !_navigatingToResult) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _navigateToResult());
          }

          return AnimatedBuilder(
            animation: _shakeAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(_shakeAnim.value, 0),
              child: child,
            ),
            child: Stack(
              children: [
                // ── Animated BG ─────────────────────────────────────
                _GameBackground(
                  controller: _bgPulseCtrl,
                  mode: widget.mode,
                  timerPercent: game.timerPercent,
                ),

                // ── Main Content ─────────────────────────────────────
                SafeArea(
                  child: game.status == GameStatus.countdown
                      ? _CountdownOverlay(value: game.countdownValue)
                      : _GameContent(
                          game: game,
                          questionCtrl: _questionCtrl,
                          onAnswerTap: _onAnswerTap,
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Countdown Overlay ────────────────────────────────────────────────────────

class _CountdownOverlay extends StatelessWidget {
  final int value;
  const _CountdownOverlay({required this.value});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value > 0 ? '$value' : 'GO!',
            style: TextStyle(
              color: value > 0 ? AppColors.neonCyan : AppColors.neonGreen,
              fontSize: 96,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
              shadows: AppColors.neonGlow(
                value > 0 ? AppColors.neonCyan : AppColors.neonGreen,
              ).map((s) => Shadow(
                    color: s.color,
                    blurRadius: s.blurRadius,
                  )).toList(),
            ),
          ).animate(key: ValueKey(value)).scale(
                begin: const Offset(1.4, 1.4),
                end: const Offset(1.0, 1.0),
                duration: 400.ms,
                curve: Curves.elasticOut,
              ),
        ],
      ),
    );
  }
}

// ─── Game Content ─────────────────────────────────────────────────────────────

class _GameContent extends StatelessWidget {
  final GameProvider game;
  final AnimationController questionCtrl;
  final ValueChanged<int> onAnswerTap;

  const _GameContent({
    required this.game,
    required this.questionCtrl,
    required this.onAnswerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Top HUD ──────────────────────────────────────────────────
        _TopHUD(game: game),

        // ── Score & Combo ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ScoreDisplay(score: game.score, isDouble: game.isDoubleScore),
              ComboDisplay(combo: game.combo),
            ],
          ),
        ),

        // ── Mode-specific progress ────────────────────────────────────
        if (game.mode == GameMode.timeAttack)
          _TimeAttackProgress(progress: game.timeAttackProgress),

        if (game.mode == GameMode.endless)
          _LivesDisplay(lives: game.livesRemaining),

        const Spacer(),

        // ── Question ──────────────────────────────────────────────────
        if (game.currentQuestion != null)
          _QuestionPanel(
            question: game.currentQuestion!,
            ctrl: questionCtrl,
          ),

        const Spacer(),

        // ── Answer Grid ───────────────────────────────────────────────
        if (game.currentQuestion != null)
          _AnswerGrid(
            question: game.currentQuestion!,
            game: game,
            onTap: onAnswerTap,
          ),

        const SizedBox(height: 12),

        // ── Power-up Bar ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PowerUpBar(
            inventory: game.powerUpInventory,
            onUse: context.read<GameProvider>().activatePowerUp,
            enabled: game.isPlaying,
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Top HUD ──────────────────────────────────────────────────────────────────

class _TopHUD extends StatelessWidget {
  final GameProvider game;
  const _TopHUD({required this.game});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          // Pause button
          GestureDetector(
            onTap: () => _showPauseMenu(context, game),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.bgCard,
                border: Border.all(
                    color: AppColors.neonCyan.withOpacity(0.3)),
              ),
              child: const Icon(Icons.pause_rounded,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),

          const SizedBox(width: 12),

          // Timer / Progress bar
          Expanded(
            child: game.mode == GameMode.zen
                ? _ZenModeBar(questionsAnswered: game.questionsAnswered)
                : game.mode == GameMode.timeAttack
                    ? const SizedBox()
                    : _TimerBar(
                        timeRemaining: game.timeRemaining,
                        timerPercent: game.timerPercent,
                        timerColor: game.timerColor,
                        isFrozen: game.isTimeFrozen,
                      ),
          ),

          const SizedBox(width: 12),

          // Mode badge
          _ModeBadge(mode: game.mode),
        ],
      ),
    );
  }

  void _showPauseMenu(BuildContext context, GameProvider game) {
    game.pauseGame();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PauseDialog(
        onResume: () {
          Navigator.pop(context);
          game.resumeGame();
        },
        onQuit: () {
          Navigator.pop(context);
          game.resetGame();
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─── Timer Bar ────────────────────────────────────────────────────────────────

class _TimerBar extends StatelessWidget {
  final int timeRemaining;
  final double timerPercent;
  final Color timerColor;
  final bool isFrozen;

  const _TimerBar({
    required this.timeRemaining,
    required this.timerPercent,
    required this.timerColor,
    required this.isFrozen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isFrozen ? '❄️ FROZEN' : '$timeRemaining',
              style: TextStyle(
                color: isFrozen ? AppColors.neonCyan : timerColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                shadows: AppColors.neonGlow(isFrozen ? AppColors.neonCyan : timerColor)
                    .map((s) => Shadow(color: s.color, blurRadius: s.blurRadius))
                    .toList(),
              ),
            ),
            Text(
              'TIME',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: timerPercent, end: timerPercent),
            duration: const Duration(milliseconds: 300),
            builder: (_, value, __) => LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: AppColors.bgSurface,
              valueColor: AlwaysStoppedAnimation(
                isFrozen ? AppColors.neonCyan : timerColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ZenModeBar extends StatelessWidget {
  final int questionsAnswered;
  const _ZenModeBar({required this.questionsAnswered});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🧘', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          'ZEN MODE  ·  $questionsAnswered answered',
          style: TextStyle(
            color: AppColors.neonGreen,
            fontSize: 12,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        mode.emoji,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}

// ─── Score Display ────────────────────────────────────────────────────────────

class _ScoreDisplay extends StatefulWidget {
  final int score;
  final bool isDouble;
  const _ScoreDisplay({required this.score, required this.isDouble});

  @override
  State<_ScoreDisplay> createState() => _ScoreDisplayState();
}

class _ScoreDisplayState extends State<_ScoreDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  int _prevScore = 0;

  @override
  void initState() {
    super.initState();
    _prevScore = widget.score;
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _scale = Tween<double>(begin: 1.0, end: 1.25)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
  }

  @override
  void didUpdateWidget(_ScoreDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.score > _prevScore) {
      _ctrl.forward(from: 0).then((_) => _ctrl.reverse());
    }
    _prevScore = widget.score;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SCORE',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            letterSpacing: 2.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        AnimatedBuilder(
          animation: _scale,
          builder: (_, child) => Transform.scale(
            alignment: Alignment.centerLeft,
            scale: _scale.value,
            child: child,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${widget.score}',
                style: TextStyle(
                  color: widget.isDouble
                      ? AppColors.neonYellow
                      : AppColors.neonCyan,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  shadows: AppColors.neonGlow(
                    widget.isDouble
                        ? AppColors.neonYellow
                        : AppColors.neonCyan,
                  ).map((s) => Shadow(color: s.color, blurRadius: s.blurRadius))
                      .toList(),
                ),
              ),
              if (widget.isDouble) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: AppColors.neonYellow.withOpacity(0.2),
                    border: Border.all(
                        color: AppColors.neonYellow.withOpacity(0.6)),
                  ),
                  child: const Text(
                    '×2',
                    style: TextStyle(
                      color: AppColors.neonYellow,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Lives Display ────────────────────────────────────────────────────────────

class _LivesDisplay extends StatelessWidget {
  final int lives;
  const _LivesDisplay({required this.lives});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Row(
        children: [
          Text(
            'LIVES  ',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          ...List.generate(GameConstants.maxMistakesEndless, (i) {
            final active = i < lives;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  '❤️',
                  style: TextStyle(
                    fontSize: 16,
                    color: active ? Colors.white : Colors.white24,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Time Attack Progress ─────────────────────────────────────────────────────

class _TimeAttackProgress extends StatelessWidget {
  final double progress;
  const _TimeAttackProgress({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUESTIONS',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * GameConstants.timeAttackQuestions).round()} / ${GameConstants.timeAttackQuestions}',
                style: TextStyle(
                  color: AppColors.neonYellow,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.bgSurface,
              valueColor: const AlwaysStoppedAnimation(AppColors.neonYellow),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Question Panel ───────────────────────────────────────────────────────────

class _QuestionPanel extends StatelessWidget {
  final Question question;
  final AnimationController ctrl;

  const _QuestionPanel({required this.question, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: Container(
          key: ValueKey(question.questionText),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.bgCard,
            border: Border.all(
              color: AppColors.neonCyan.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonCyan.withOpacity(0.06),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            children: [
              // Question type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.neonCyan.withOpacity(0.08),
                ),
                child: Text(
                  _questionTypeLabel(question.type),
                  style: TextStyle(
                    color: AppColors.neonCyan.withOpacity(0.6),
                    fontSize: 9,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                question.questionText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _questionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.addition:
        return 'ADDITION';
      case QuestionType.subtraction:
        return 'SUBTRACTION';
      case QuestionType.multiplication:
        return 'MULTIPLICATION';
      case QuestionType.division:
        return 'DIVISION';
      case QuestionType.missingNumber:
        return 'MISSING NUMBER';
      case QuestionType.trueFalse:
        return 'TRUE OR FALSE';
      case QuestionType.sequence:
        return 'SEQUENCE';
    }
  }
}

// ─── Answer Grid ──────────────────────────────────────────────────────────────

class _AnswerGrid extends StatelessWidget {
  final Question question;
  final GameProvider game;
  final ValueChanged<int> onTap;

  const _AnswerGrid({
    required this.question,
    required this.game,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.4,
        children: List.generate(question.options.length, (i) {
          return AnswerCard(
            question: question,
            optionIndex: i,
            answerState: game.lastAnswerState,
            selectedIndex: game.selectedOptionIndex,
            hintRemovedIndex: game.hintRemovedOptionIndex,
            onTap: () => onTap(i),
          );
        }),
      ),
    );
  }
}

// ─── Pause Dialog ─────────────────────────────────────────────────────────────

class _PauseDialog extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onQuit;

  const _PauseDialog({required this.onResume, required this.onQuit});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glow icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonCyan.withOpacity(0.1),
                border: Border.all(color: AppColors.neonCyan.withOpacity(0.4)),
                boxShadow: AppTheme.neonGlow(AppColors.neonCyan),
              ),
              child: const Icon(Icons.pause_rounded,
                  color: AppColors.neonCyan, size: 30),
            ),
            const SizedBox(height: 20),
            const Text(
              'PAUSED',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Take a breath...',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onResume,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonCyan,
                  foregroundColor: AppColors.bgDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'RESUME',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: onQuit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.neonRed,
                  side: BorderSide(
                      color: AppColors.neonRed.withOpacity(0.5), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'QUIT GAME',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(
          begin: const Offset(0.85, 0.85),
          duration: 300.ms,
          curve: Curves.elasticOut,
        );
  }
}

// ─── Game Background ──────────────────────────────────────────────────────────

class _GameBackground extends StatelessWidget {
  final AnimationController controller;
  final GameMode mode;
  final double timerPercent;

  const _GameBackground({
    required this.controller,
    required this.mode,
    required this.timerPercent,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _GameBgPainter(
          t: controller.value,
          accentColor: mode.accentColor,
          timerPercent: timerPercent,
        ),
      ),
    );
  }
}

class _GameBgPainter extends CustomPainter {
  final double t;
  final Color accentColor;
  final double timerPercent;

  _GameBgPainter({
    required this.t,
    required this.accentColor,
    required this.timerPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.bgDark,
    );

    final intensity = timerPercent < 0.2 ? (1 - timerPercent / 0.2) * 0.06 : 0.0;
    final baseOpacity = 0.035 + intensity;

    _drawOrb(
      canvas,
      Offset(size.width * (0.15 + 0.05 * _sin(t * 2)), size.height * 0.25),
      size.width * 0.45,
      accentColor.withOpacity(baseOpacity + 0.015 * _sin(t)),
    );

    _drawOrb(
      canvas,
      Offset(size.width * (0.85 - 0.05 * _cos(t * 1.5)), size.height * 0.75),
      size.width * 0.4,
      AppColors.neonPurple.withOpacity(baseOpacity * 0.8),
    );

    // Danger glow at bottom when timer is low
    if (timerPercent < 0.2) {
      _drawOrb(
        canvas,
        Offset(size.width * 0.5, size.height),
        size.width * 0.6,
        AppColors.neonRed.withOpacity(intensity * 0.5),
      );
    }

    // Subtle grid
    final gridPaint = Paint()
      ..color = accentColor.withOpacity(0.025)
      ..strokeWidth = 0.5;
    const spacing = 48.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawOrb(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color, Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  double _sin(double x) => math.sin(x * math.pi);
  double _cos(double x) => math.cos(x * math.pi);

  @override
  bool shouldRepaint(_GameBgPainter old) =>
      old.t != t || old.timerPercent != timerPercent;
}
