// lib/widgets/combo_display.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ComboDisplay extends StatelessWidget {
  final int combo;
  const ComboDisplay({super.key, required this.combo});

  @override
  Widget build(BuildContext context) {
    // Keep the height stable so the layout never jumps when a combo starts.
    return SizedBox(
      height: 34,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: combo < 2
            ? const SizedBox.shrink(key: ValueKey('none'))
            : Container(
                key: ValueKey(combo),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '×$combo',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'COMBO',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 10,
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
