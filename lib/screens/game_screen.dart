// lib/screens/game_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/daily_challenge.dart';
import '../models/question.dart';
import '../providers/game_provider.dart';
import '../services/question_generator.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/answer_card.dart';
import '../widgets/app_ui.dart';
import '../widgets/combo_display.dart';
import '../widgets/power_up_bar.dart';
import 'result_screen.dart';

enum _PauseAction { resume, quit, finish }

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final DailyChallenge? challenge;

  const GameScreen({super.key, required this.mode, this.challenge});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final GameProvider _game;
  bool _started = false;
  bool _leaving = false;
  bool _pauseOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = context.read<GameProvider>();

    // Start after the first frame; calling startGame() while building would
    // notify listeners in the middle of a build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _game.startGame(widget.mode);
      _started = true;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Leaving this screen must never leave a game running in the background.
    _game.stopSilently();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _game.isPlaying) {
      _openPause();
    }
  }

  Future<void> _openPause() async {
    if (_pauseOpen || !_game.isPlaying) return;
    _pauseOpen = true;
    _game.pauseGame();

    final action = await showDialog<_PauseAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PauseDialog(isZen: widget.mode == GameMode.zen),
    );
    _pauseOpen = false;
    if (!mounted) return;

    if (action == _PauseAction.quit) {
      Navigator.of(context).pop();
    } else if (action == _PauseAction.finish) {
      _game.finishGame();
    } else {
      // Resume button or Android back button.
      _game.resumeGame();
    }
  }

  void _onAnswerTap(int index) {
    if (!_game.isPlaying) return;
    if (context.read<StorageService>().hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    _game.submitAnswer(index);
  }

  void _goToResult() {
    if (_leaving || !mounted) return;
    _leaving = true;
    final result = _game.buildResult();
    Navigator.of(context).pushReplacement(
      fadeRoute(ResultScreen(result: result, challenge: widget.challenge)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_game.isPlaying) {
          _openPause();
        } else if (_game.status == GameStatus.countdown ||
            _game.status == GameStatus.idle) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Consumer<GameProvider>(
            builder: (context, game, _) {
              if (_started && game.isGameOver && !_leaving) {
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _goToResult());
              }
              if (game.status == GameStatus.countdown || !_started) {
                return _Countdown(value: game.countdownValue);
              }
              return _GameContent(
                game: game,
                onPause: _openPause,
                onAnswer: _onAnswerTap,
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Countdown ────────────────────────────────────────────────────────────────

class _Countdown extends StatelessWidget {
  final int value;
  const _Countdown({required this.value});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'GET READY',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              '$value',
              key: ValueKey(value),
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 96,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Game content ─────────────────────────────────────────────────────────────

class _GameContent extends StatelessWidget {
  final GameProvider game;
  final VoidCallback onPause;
  final ValueChanged<int> onAnswer;

  const _GameContent({
    required this.game,
    required this.onPause,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final question = game.currentQuestion;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _TopBar(game: game, onPause: onPause),
          const SizedBox(height: 16),
          _ScoreRow(game: game),
          const SizedBox(height: 14),
          _ModeProgress(game: game),
          Expanded(
            child: Center(
              child: question == null
                  ? const SizedBox.shrink()
                  : _QuestionCard(question: question),
            ),
          ),
          if (question != null) _AnswerGrid(game: game, onTap: onAnswer),
          const SizedBox(height: 20),
          PowerUpBar(game: game),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final GameProvider game;
  final VoidCallback onPause;
  const _TopBar({required this.game, required this.onPause});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: game.isPlaying ? onPause : null,
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.pause, size: 20, color: AppColors.textDim),
            ),
          ),
        ),
        const Spacer(),
        Icon(game.mode.icon, size: 16, color: AppColors.textDim),
        const SizedBox(width: 6),
        Text(
          game.mode.displayName.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textDim,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final GameProvider game;
  const _ScoreRow({required this.game});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Score'),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${game.score}',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (game.isDoubleScore) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '×2',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const Spacer(),
        ComboDisplay(combo: game.combo),
      ],
    );
  }
}

/// The mode-specific strip under the score: clock, question progress, lives…
class _ModeProgress extends StatelessWidget {
  final GameProvider game;
  const _ModeProgress({required this.game});

  @override
  Widget build(BuildContext context) {
    switch (game.mode) {
      case GameMode.classic:
      case GameMode.rush:
        final low = game.timeRemaining <= 5 && !game.isTimeFrozen;
        final label = game.isTimeFrozen
            ? 'FROZEN  ${game.timeRemaining}s'
            : '${game.timeRemaining}s';
        return _Bar(
          label: label,
          value: game.timerPercent,
          alert: low,
        );
      case GameMode.timeAttack:
        return _Bar(
          label:
              '${game.questionsAnswered} / ${GameConstants.timeAttackQuestions}'
              '   ·   ${_fmt(game.elapsedSeconds)}',
          value: game.timeAttackProgress,
        );
      case GameMode.endless:
        return Row(
          children: [
            const SectionLabel('Lives'),
            const SizedBox(width: 10),
            ...List.generate(GameConstants.maxMistakesEndless, (i) {
              final alive = i < game.livesRemaining;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  alive ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: alive ? AppColors.danger : AppColors.textMuted,
                ),
              );
            }),
            const Spacer(),
            Text(
              '${game.questionsAnswered} answered',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        );
      case GameMode.zen:
        return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${game.questionsAnswered} answered  ·  ${_fmt(game.elapsedSeconds)}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        );
    }
  }

  static String _fmt(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

class _Bar extends StatelessWidget {
  final String label;
  final double value;
  final bool alert;

  const _Bar({required this.label, required this.value, this.alert = false});

  @override
  Widget build(BuildContext context) {
    final color = alert ? AppColors.danger : AppColors.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: alert ? AppColors.danger : AppColors.textDim,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: AppColors.surfaceHigh,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Question question;
  const _QuestionCard({required this.question});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SectionLabel(_label(question.type)),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                question.questionText,
                key: ValueKey(question.questionText),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _label(QuestionType type) {
    switch (type) {
      case QuestionType.addition:
        return 'Addition';
      case QuestionType.subtraction:
        return 'Subtraction';
      case QuestionType.multiplication:
        return 'Multiplication';
      case QuestionType.division:
        return 'Division';
      case QuestionType.missingNumber:
        return 'Missing number';
      case QuestionType.trueFalse:
        return 'True or false';
      case QuestionType.sequence:
        return 'Sequence';
    }
  }
}

class _AnswerGrid extends StatelessWidget {
  final GameProvider game;
  final ValueChanged<int> onTap;
  const _AnswerGrid({required this.game, required this.onTap});

  AnswerCardState _stateFor(int i, Question q) {
    if (i == game.hintRemovedOptionIndex) return AnswerCardState.removed;
    if (game.lastAnswerState == AnswerState.none) return AnswerCardState.idle;
    if (i == game.selectedOptionIndex) {
      return game.lastAnswerState == AnswerState.correct
          ? AnswerCardState.correct
          : AnswerCardState.wrong;
    }
    if (game.lastAnswerState == AnswerState.wrong &&
        q.options[i] == q.correctAnswer) {
      return AnswerCardState.reveal;
    }
    return AnswerCardState.dimmed;
  }

  @override
  Widget build(BuildContext context) {
    final q = game.currentQuestion!;

    Widget card(int i) => Expanded(
          child: AnswerCard(
            label: QuestionGenerator.optionLabel(q, i),
            letter: String.fromCharCode(65 + i),
            state: _stateFor(i, q),
            onTap: () => onTap(i),
          ),
        );

    final rows = <Widget>[];
    for (int i = 0; i < q.options.length; i += 2) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 10));
      rows.add(
        Row(
          children: [
            card(i),
            const SizedBox(width: 10),
            if (i + 1 < q.options.length)
              card(i + 1)
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      );
    }
    return Column(children: rows);
  }
}

// ─── Pause dialog ─────────────────────────────────────────────────────────────

class _PauseDialog extends StatelessWidget {
  final bool isZen;
  const _PauseDialog({required this.isZen});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paused',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Take a breath.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Resume',
              icon: Icons.play_arrow_rounded,
              onTap: () => Navigator.of(context).pop(_PauseAction.resume),
            ),
            if (isZen) ...[
              const SizedBox(height: 10),
              AppButton(
                label: 'Finish session',
                icon: Icons.flag_outlined,
                outlined: true,
                onTap: () => Navigator.of(context).pop(_PauseAction.finish),
              ),
            ],
            const SizedBox(height: 10),
            AppButton(
              label: 'Quit without saving',
              outlined: true,
              onTap: () => Navigator.of(context).pop(_PauseAction.quit),
            ),
          ],
        ),
      ),
    );
  }
}
