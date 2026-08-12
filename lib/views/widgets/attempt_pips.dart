import 'package:flutter/material.dart';

import '../theme/game_colors.dart';
import '../theme/game_theme.dart';

/// Adventure'da kalan deneme (el) hakkı — noktalar + sayı.
class AttemptPips extends StatelessWidget {
  const AttemptPips({super.key, required this.remaining, required this.max});

  final int remaining;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < remaining
                  ? GameColors.gold
                  : GameColors.outlineVariant.withValues(alpha: 0.55),
              border: i < remaining
                  ? Border.all(color: GameColors.brass.withValues(alpha: 0.7))
                  : null,
            ),
          ),
        ],
        const SizedBox(width: 6),
        Text(
          '$remaining/$max hak',
          style: TextStyle(
            fontFamily: GameFonts.mono,
            fontSize: 11,
            letterSpacing: 0.4,
            color: remaining <= 1 ? GameColors.danger : GameColors.outline,
            fontWeight: remaining <= 1 ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
