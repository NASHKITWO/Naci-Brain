import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';
import '../utils/app_theme.dart';

enum AnswerButtonState { normal, correct, wrong, disabled }

class AnswerButton extends StatefulWidget {
  final int value;
  final VoidCallback? onTap;
  final AnswerButtonState state;
  final bool isRemoved;

  const AnswerButton({
    super.key,
    required this.value,
    this.onTap,
    this.state = AnswerButtonState.normal,
    this.isRemoved = false,
  });

  @override
  State<AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<AnswerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 80));
    _scaleAnim = Tween(begin: 1.0, end: 0.93).animate(
        CurvedAnimation(parent: _pressController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  Color get _borderColor {
    switch (widget.state) {
      case AnswerButtonState.correct:
        return AppColors.neonGreen;
      case AnswerButtonState.wrong:
        return AppColors.neonRed;
      case AnswerButtonState.disabled:
        return AppColors.textMuted;
      case AnswerButtonState.normal:
        return AppColors.neonCyan.withOpacity(0.5);
    }
  }

  Color get _bgColor {
    switch (widget.state) {
      case AnswerButtonState.correct:
        return AppColors.neonGreen.withOpacity(0.2);
      case AnswerButtonState.wrong:
        return AppColors.neonRed.withOpacity(0.2);
      case AnswerButtonState.disabled:
        return AppColors.textMuted.withOpacity(0.05);
      case AnswerButtonState.normal:
        return AppColors.bgCard;
    }
  }

  Color get _textColor {
    switch (widget.state) {
      case AnswerButtonState.correct:
        return AppColors.neonGreen;
      case AnswerButtonState.wrong:
        return AppColors.neonRed;
      case AnswerButtonState.disabled:
        return AppColors.textMuted;
      case AnswerButtonState.normal:
        return AppColors.textPrimary;
    }
  }

  List<BoxShadow> get _shadow {
    switch (widget.state) {
      case AnswerButtonState.correct:
        return AppColors.neonGlow(AppColors.neonGreen, spread: 8);
      case AnswerButtonState.wrong:
        return AppColors.neonGlow(AppColors.neonRed, spread: 6);
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isRemoved) {
      return Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.bgCard.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.textMuted.withOpacity(0.2), width: 1),
        ),
        child: const Center(
            child: Text('✕',
                style: TextStyle(color: Colors.transparent))),
      );
    }

    final isDisabled = widget.state == AnswerButtonState.disabled;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => _pressController.forward(),
      onTapUp: isDisabled
          ? null
          : (_) {
              _pressController.reverse();
              widget.onTap?.call();
            },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 64,
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _borderColor, width: 2),
            boxShadow: _shadow,
          ),
          child: Center(
            child: Text(
              '${widget.value}',
              style: TextStyle(
                color: _textColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        )
            .animate(target: widget.state == AnswerButtonState.wrong ? 1 : 0)
            .shake(duration: 300.ms, hz: 4, offset: const Offset(6, 0)),
      ),
    );
  }
}
