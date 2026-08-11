import 'package:flutter/material.dart';

import '../../game/turkish.dart';
import '../theme/game_colors.dart';
import '../theme/game_theme.dart';

/// Thin brass-framed HUD chrome.
class BrassPanel extends StatelessWidget {
  const BrassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.align = CrossAxisAlignment.start,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: GameColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GameColors.brass.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: align,
        mainAxisSize: MainAxisSize.min,
        children: [child],
      ),
    );
  }
}

class HudLabel extends StatelessWidget {
  const HudLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      toUpperTr(text),
      style: const TextStyle(
        fontFamily: GameFonts.mono,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.8,
        color: GameColors.gold,
        height: 1,
      ),
    );
  }
}

class InsetSlot extends StatelessWidget {
  const InsetSlot({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: GameColors.bgLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 8,
            offset: Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
      ),
      child: child,
    );
  }
}
