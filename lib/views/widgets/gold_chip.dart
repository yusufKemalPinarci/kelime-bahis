import 'package:flutter/material.dart';

import '../theme/game_colors.dart';
import '../theme/game_theme.dart';

/// Compact gold wallet / price badge — no tutorial prose.
class GoldChip extends StatelessWidget {
  const GoldChip({
    super.key,
    required this.amount,
    this.large = false,
    this.muted = false,
    this.prefix,
  });

  final int amount;
  final bool large;
  final bool muted;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    final ink = muted ? GameColors.outline : GameColors.gold;
    final pad = large
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    final coin = large ? 22.0 : 16.0;
    final textSize = large ? 20.0 : 14.0;

    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: GameColors.surfaceHigh,
        borderRadius: BorderRadius.circular(large ? 10 : 99),
        border: Border.all(
          color: (muted ? GameColors.outlineVariant : GameColors.brass)
              .withValues(alpha: muted ? 0.5 : 0.65),
        ),
        boxShadow: large
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CoinGlyph(size: coin, muted: muted),
          const SizedBox(width: 8),
          if (prefix != null) ...[
            Text(
              prefix!,
              style: TextStyle(
                fontFamily: GameFonts.mono,
                fontSize: large ? 11 : 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: ink.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            '$amount',
            style: TextStyle(
              fontFamily: GameFonts.display,
              fontSize: textSize,
              fontWeight: FontWeight.w700,
              color: ink,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Price tag for shop offers (cost vs wallet).
class GoldPriceTag extends StatelessWidget {
  const GoldPriceTag({
    super.key,
    required this.cost,
    required this.affordable,
    this.lockedLabel,
  });

  final int cost;
  final bool affordable;
  final String? lockedLabel;

  @override
  Widget build(BuildContext context) {
    if (lockedLabel != null) {
      return Text(
        lockedLabel!,
        style: const TextStyle(
          fontFamily: GameFonts.mono,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: GameColors.outline,
        ),
      );
    }
    return GoldChip(amount: cost, muted: !affordable);
  }
}

class _CoinGlyph extends StatelessWidget {
  const _CoinGlyph({required this.size, this.muted = false});

  final double size;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final rim = muted ? GameColors.outline : GameColors.brass;
    final face = muted ? GameColors.surfaceHighest : GameColors.gold;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: muted
              ? [GameColors.surfaceHighest, GameColors.surfaceHigh]
              : [GameColors.goldLeafEnd, face, const Color(0xFFB38728)],
        ),
        border: Border.all(color: rim, width: 1.4),
        boxShadow: muted
            ? null
            : [
                BoxShadow(
                  color: GameColors.gold.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      alignment: Alignment.center,
      child: Text(
        '◆',
        style: TextStyle(
          fontSize: size * 0.42,
          height: 1,
          color: muted
              ? GameColors.outlineVariant
              : const Color(0xFF5C3D0A).withValues(alpha: 0.85),
        ),
      ),
    );
  }
}
