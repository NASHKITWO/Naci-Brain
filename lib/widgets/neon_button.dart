import 'package:flutter/material.dart';
import '../utils/constants.dart';

class NeonButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final double width;
  final double height;
  final String? icon;
  final bool outlined;

  const NeonButton({
    super.key,
    required this.label,
    this.onTap,
    this.color = AppColors.neonCyan,
    this.width = double.infinity,
    this.height = 56,
    this.icon,
    this.outlined = false,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnim = Tween(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.outlined
                ? Colors.transparent
                : widget.color.withOpacity(0.15),
            border: Border.all(color: widget.color, width: 2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppColors.neonGlow(widget.color, spread: 6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Text(widget.icon!, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
