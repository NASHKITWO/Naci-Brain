// lib/widgets/answer_card.dart
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../providers/game_provider.dart';
import '../services/question_generator.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class AnswerCard extends StatefulWidget {
  final Question question;
  final int optionIndex;
  final AnswerState answerState;
  final int selectedIndex;
  final int hintRemovedIndex;
  final VoidCallback onTap;

  const AnswerCard({
    super.key,
    required this.question,
    required this.optionIndex,
    required this.answerState,
    required this.selectedIndex,
    required this.hintRemovedIndex,
    required this.onTap,
  });

  @override
  State<AnswerCard> createState() => _AnswerCardState();
}

class _AnswerCardState extends State<AnswerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(AnswerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.answerState == AnswerState.wrong &&
        widget.selectedIndex == widget.optionIndex) {
      _controller.forward().then((_) => _controller.reset());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isSelected => widget.selectedIndex == widget.optionIndex;
  bool get _isCorrect =>
      widget.question.options[widget.optionIndex] ==
      widget.question.correctAnswer;
  bool get _isHintRemoved => widget.hintRemovedIndex == widget.optionIndex;
  bool get _isAnswered => widget.answerState != AnswerState.none;

  Color get _borderColor {
    if (!_isAnswered) {
      return AppColors.neonCyan.withOpacity(0.2);
    }
    if (_isSelected && widget.answerState == AnswerState.correct) {
      return AppColors.neonGreen;
    }
    if (_isSelected && widget.answerState == AnswerState.wrong) {
      return AppColors.neonRed;
    }
    if (!_isSelected && _isCorrect && widget.answerState == AnswerState.wrong) {
      return AppColors.neonGreen.withOpacity(0.5);
    }
    return AppColors.neonCyan.withOpacity(0.1);
  }

  Color get _bgColor {
    if (!_isAnswered) return AppColors.cardDefault;
    if (_isSelected && widget.answerState == AnswerState.correct) {
      return AppColors.cardCorrect;
    }
    if (_isSelected && widget.answerState == AnswerState.wrong) {
      return AppColors.cardWrong;
    }
    if (!_isSelected && _isCorrect && widget.answerState == AnswerState.wrong) {
      return AppColors.cardCorrect.withOpacity(0.4);
    }
    return AppColors.cardDefault;
  }

  Color get _textColor {
    if (!_isAnswered) return AppColors.textPrimary;
    if (_isSelected && widget.answerState == AnswerState.correct) {
      return AppColors.neonGreen;
    }
    if (_isSelected && widget.answerState == AnswerState.wrong) {
      return AppColors.neonRed;
    }
    if (!_isSelected && _isCorrect && widget.answerState == AnswerState.wrong) {
      return AppColors.neonGreen;
    }
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    if (_isHintRemoved) {
      return Opacity(
        opacity: 0.15,
        child: _buildCard(context),
      );
    }

    return GestureDetector(
      onTapDown: _isAnswered
          ? null
          : (_) => _controller.forward(),
      onTapUp: _isAnswered
          ? null
          : (_) {
              _controller.reverse();
              widget.onTap();
            },
      onTapCancel: _isAnswered ? null : () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          double translateX = 0;
          if (_isSelected && widget.answerState == AnswerState.wrong) {
            translateX = _shakeAnim.value;
          }
          return Transform.translate(
            offset: Offset(translateX, 0),
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: child,
            ),
          );
        },
        child: _buildCard(context),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final label = QuestionGenerator.optionLabel(widget.question, widget.optionIndex);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 64,
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: _isAnswered && _isSelected
            ? AppTheme.subtleGlow(
                widget.answerState == AnswerState.correct
                    ? AppColors.neonGreen
                    : AppColors.neonRed,
              )
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Option label index (A, B, C, D)
          Positioned(
            left: 16,
            child: Text(
              String.fromCharCode(65 + widget.optionIndex),
              style: TextStyle(
                color: _textColor.withOpacity(0.4),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),

          // Answer text
          Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: _textColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
              child: Text(label),
            ),
          ),

          // Correct checkmark / Wrong X
          if (_isAnswered && _isSelected)
            Positioned(
              right: 16,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: widget.answerState == AnswerState.correct
                    ? const Text('✓',
                        key: ValueKey('correct'),
                        style: TextStyle(
                          color: AppColors.neonGreen,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ))
                    : const Text('✗',
                        key: ValueKey('wrong'),
                        style: TextStyle(
                          color: AppColors.neonRed,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        )),
              ),
            ),
        ],
      ),
    );
  }
}
