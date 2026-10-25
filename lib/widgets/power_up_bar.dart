// lib/widgets/power_up_bar.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class PowerUpBar extends StatelessWidget {
  final Map<PowerUpType, int> inventory;
  final Function(PowerUpType) onUse;
  final bool enabled;

  const PowerUpBar({
    super.key,
    required this.inventory,
    required this.onUse,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: PowerUpType.values.map((type) {
        final count = inventory[type] ?? 0;
        return _PowerUpButton(
          type: type,
          count: count,
          onTap: count > 0 && enabled ? () => onUse(type) : null,
        );
      }).toList(),
    );
  }
}

class _PowerUpButton extends StatefulWidget {
  final PowerUpType type;
  final int count;
  final VoidCallback? onTap;

  const _PowerUpButton({
    required this.type,
    required this.count,
    this.onTap,
  });

  @override
  State<_PowerUpButton> createState() => _PowerUpButtonState();
}

class _PowerUpButtonState extends State<_PowerUpButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.count > 0 && widget.onTap != null;
    final color = widget.type.color;

    return GestureDetector(
      onTapDown: available ? (_) => _ctrl.forward() : null,
      onTapUp: available
          ? (_) {
              _ctrl.reverse();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: available ? () => _ctrl.reverse() : null,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: available ? 1.0 : 0.35,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: color.withOpacity(0.1),
                  border: Border.all(
                    color: available
                        ? color.withOpacity(0.6)
                        : color.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: available ? AppTheme.subtleGlow(color) : null,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        widget.type.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    // Count badge
                    if (widget.count > 0)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                          child: Center(
                            child: Text(
                              '${widget.count}',
                              style: const TextStyle(
                                color: AppColors.bgDark,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _shortName(widget.type),
                style: TextStyle(
                  color: available ? color.withOpacity(0.8) : AppColors.textMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortName(PowerUpType type) {
    switch (type) {
      case PowerUpType.timeFreeze:
        return 'FREEZE';
      case PowerUpType.doubleScore:
        return '×2 SCORE';
      case PowerUpType.hint:
        return 'HINT';
      case PowerUpType.autoSolve:
        return 'AUTO';
      case PowerUpType.slowMotion:
        return 'SLOW';
    }
  }
}
