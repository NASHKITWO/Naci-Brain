// lib/widgets/answer_card.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

enum AnswerCardState {
  idle, // waiting for a tap
  correct, // the player picked the right answer
  wrong, // the player picked a wrong answer
  reveal, // shows the right answer after a mistake
  dimmed, // not chosen, after answering
  removed, // eliminated by the hint power-up
}

class AnswerCard extends StatelessWidget {
  final String label;
  final String letter;
  final AnswerCardState state;
  final VoidCallback onTap;

  const AnswerCard({
    super.key,
    required this.label,
    required this.letter,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (state == AnswerCardState.removed) {
      return Opacity(opacity: 0.2, child: _card());
    }
    return _card();
  }

  Color get _fill {
    switch (state) {
      case AnswerCardState.correct:
        return AppColors.accent.withValues(alpha: 0.14);
      case AnswerCardState.wrong:
        return AppColors.danger.withValues(alpha: 0.14);
      case AnswerCardState.reveal:
        return AppColors.accent.withValues(alpha: 0.08);
      default:
        return AppColors.surface;
    }
  }

  Color get _stroke {
    switch (state) {
      case AnswerCardState.correct:
        return AppColors.accent;
      case AnswerCardState.wrong:
        return AppColors.danger;
      case AnswerCardState.reveal:
        return AppColors.accent.withValues(alpha: 0.5);
      default:
        return AppColors.border;
    }
  }

  Color get _textColor {
    switch (state) {
      case AnswerCardState.correct:
      case AnswerCardState.reveal:
        return AppColors.accent;
      case AnswerCardState.wrong:
        return AppColors.danger;
      case AnswerCardState.dimmed:
        return AppColors.textMuted;
      default:
        return AppColors.text;
    }
  }

  Widget _card() {
    final tappable = state == AnswerCardState.idle;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 64,
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _stroke, width: 1.5),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: tappable ? onTap : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 16,
                child: Text(
                  letter,
                  style: TextStyle(
                    color: _textColor.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (state == AnswerCardState.correct ||
                  state == AnswerCardState.wrong)
                Positioned(
                  right: 14,
                  child: Icon(
                    state == AnswerCardState.correct
                        ? Icons.check
                        : Icons.close,
                    size: 20,
                    color: _textColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
