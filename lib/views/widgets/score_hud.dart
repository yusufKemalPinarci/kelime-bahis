import 'package:flutter/material.dart';

import '../theme/game_colors.dart';
import '../theme/game_theme.dart';

/// Kalan deneme hakkı — noktalar + sayı. Hak biterse koşu kaybedilir, bu
/// yüzden görünürlüğü önemli (bkz. GameController.playWord). ScoreHud'un
/// içinde, sayfanın en üstünde gösterilir.
class HandsPips extends StatelessWidget {
  const HandsPips({
    super.key,
    required this.remaining,
    this.max = 4,
  });

  final int remaining;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < remaining
                  ? GameColors.gold
                  : GameColors.outlineVariant.withValues(alpha: 0.55),
              border: i < remaining
                  ? Border.all(
                      color: GameColors.brass.withValues(alpha: 0.7),
                    )
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

/// Compact score strip: big current / muted target + bar.
class ScoreHud extends StatelessWidget {
  const ScoreHud({
    super.key,
    required this.score,
    required this.target,
    required this.progress,
    this.flash,
    this.flashScale = 1.05,
    this.levelLabel,
    this.boss = false,
    required this.handsLeft,
    this.handsMax = 4,
  });

  final int score;
  final int target;
  final double progress;
  final Animation<double>? flash;

  /// Skor arttığında ölçek animasyonunun ne kadar büyüyeceği — büyük
  /// combo'larda daha "patlayan" bir his için çağıran taraf artırabilir.
  final double flashScale;
  final String? levelLabel;
  final bool boss;

  /// Kalan deneme hakkı — sayfanın en üstünde, kaçırılmayacak şekilde
  /// gösterilir (bkz. HandsPips).
  final int handsLeft;
  final int handsMax;

  @override
  Widget build(BuildContext context) {
    final scoreText = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$score',
            style: TextStyle(
              fontFamily: GameFonts.display,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: boss ? GameColors.bossInk : GameColors.ink,
            ),
          ),
          TextSpan(
            text: ' / $target',
            style: TextStyle(
              fontFamily: GameFonts.mono,
              fontSize: 13,
              letterSpacing: 0.6,
              color: boss
                  ? GameColors.bossInk.withValues(alpha: 0.65)
                  : GameColors.outline,
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: boss ? GameColors.bossBg : GameColors.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: boss
              ? GameColors.danger.withValues(alpha: 0.4)
              : GameColors.brass.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (levelLabel != null) ...[
                Text(
                  levelLabel!,
                  style: TextStyle(
                    fontFamily: GameFonts.mono,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: boss ? GameColors.bossInk : GameColors.gold,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: flash == null
                    ? scoreText
                    : ScaleTransition(
                        scale:
                            Tween(begin: 1.0, end: flashScale).animate(flash!),
                        alignment: Alignment.centerLeft,
                        child: scoreText,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          HandsPips(remaining: handsLeft, max: handsMax),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: GameColors.barTrack,
              color: boss ? GameColors.danger : GameColors.barFill,
            ),
          ),
        ],
      ),
    );
  }
}
