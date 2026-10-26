// lib/widgets/power_up_bar.dart
import 'package:flutter/material.dart';
import '../providers/game_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class PowerUpBar extends StatelessWidget {
  final GameProvider game;
  const PowerUpBar({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: PowerUpType.values.map((type) {
        return _PowerUpButton(
          type: type,
          count: game.powerUpInventory[type] ?? 0,
          active: game.isPowerUpActive(type),
          enabled: game.canUsePowerUp(type),
          onTap: () => game.activatePowerUp(type),
        );
      }).toList(),
    );
  }
}

class _PowerUpButton extends StatelessWidget {
  final PowerUpType type;
  final int count;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  const _PowerUpButton({
    required this.type,
    required this.count,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = (enabled || active) ? AppColors.text : AppColors.textMuted;

    return Opacity(
      opacity: (enabled || active) ? 1.0 : 0.45,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Material(
                  color: active
                      ? AppColors.accent.withValues(alpha: 0.14)
                      : AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: active ? AppColors.accent : AppColors.border,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: enabled ? onTap : null,
                    child: Center(
                      child: Icon(
                        type.icon,
                        size: 24,
                        color: active ? AppColors.accent : color,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            type.shortName,
            style: TextStyle(
              color: active ? AppColors.accent : AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
