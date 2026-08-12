import 'package:flutter/material.dart';

import '../theme/game_colors.dart';
import '../theme/game_theme.dart';

/// Classic modda sol üstte her zaman görünen rekor rozeti.
class HighScoreBadge extends StatelessWidget {
  const HighScoreBadge({super.key, required this.highScore});

  final int highScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: GameColors.surfaceHigh,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: GameColors.brass.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded, size: 14, color: GameColors.gold),
          const SizedBox(width: 6),
          Text(
            'REKOR · $highScore',
            style: const TextStyle(
              fontFamily: GameFonts.mono,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: GameColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}
