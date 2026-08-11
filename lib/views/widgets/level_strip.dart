import 'package:flutter/material.dart';

import '../../game/scoring.dart';
import '../theme/game_colors.dart';

/// 12 seviyelik ilerleme şeridi — geçilen/mevcut/gelecek seviyeler ve
/// boss seviyeleri (üstte küçük nokta) tek bakışta görünür.
class LevelStrip extends StatelessWidget {
  const LevelStrip({
    super.key,
    required this.currentLevel,
    this.totalLevels = 12,
  });

  final int currentLevel;
  final int totalLevels;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= totalLevels; i++) ...[
          if (i > 1) const SizedBox(width: 4),
          _LevelPip(
            passed: i < currentLevel,
            current: i == currentLevel,
            boss: isBossLevelNumber(i),
          ),
        ],
      ],
    );
  }
}

class _LevelPip extends StatelessWidget {
  const _LevelPip({
    required this.passed,
    required this.current,
    required this.boss,
  });

  final bool passed;
  final bool current;
  final bool boss;

  @override
  Widget build(BuildContext context) {
    final filled = passed || current;
    final color = current
        ? GameColors.gold
        : passed
            ? GameColors.brass.withValues(alpha: 0.75)
            : GameColors.outlineVariant.withValues(alpha: 0.6);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 5,
          child: boss
              ? Icon(
                  Icons.diamond,
                  size: 6,
                  color: current
                      ? GameColors.gold
                      : GameColors.danger.withValues(alpha: 0.75),
                )
              : null,
        ),
        const SizedBox(height: 2),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: current ? 18 : 14,
          height: 8,
          decoration: BoxDecoration(
            color: filled ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color, width: 1),
            boxShadow: current
                ? [
                    BoxShadow(
                      color: GameColors.gold.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}
