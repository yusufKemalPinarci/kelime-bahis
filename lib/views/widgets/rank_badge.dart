import 'package:flutter/material.dart';

import '../../game/rank.dart';
import '../theme/game_colors.dart';
import '../theme/game_theme.dart';

/// Kalıcı rütbe rozeti — ömür boyu puan ilerlemesini gösterir.
/// Koşu kaybetsen bile bu rozet ve altındaki ilerleme kalır.
class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.lifetimeScore});

  final int lifetimeScore;

  @override
  Widget build(BuildContext context) {
    final rank = rankForScore(lifetimeScore);
    final next = nextRankForScore(lifetimeScore);
    final progress = rankProgress(lifetimeScore);

    return Column(
      children: [
        Text(
          rank.name,
          style: const TextStyle(
            fontFamily: GameFonts.display,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: GameColors.gold,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 140,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: GameColors.barTrack,
              color: GameColors.barFill,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          next == null
              ? '$lifetimeScore ömür boyu puan · zirve rütbe'
              : '$lifetimeScore / ${next.threshold} · sıradaki: ${next.name}',
          style: const TextStyle(
            fontFamily: GameFonts.mono,
            fontSize: 10,
            letterSpacing: 0.6,
            color: GameColors.outline,
          ),
        ),
      ],
    );
  }
}
