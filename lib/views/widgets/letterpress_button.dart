import 'package:flutter/material.dart';

import '../theme/game_colors.dart';
import '../theme/game_theme.dart';

/// Terracotta high-stakes CTA with letterpress feel.
class LetterpressButton extends StatelessWidget {
  const LetterpressButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.subtitle,
    this.expanded = true,
  });

  final String label;
  final String? subtitle;
  final VoidCallback? onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            color: enabled ? GameColors.brand : GameColors.surfaceHigh,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? const Color(0x33FFFFFF)
                  : GameColors.outlineVariant,
            ),
            boxShadow: enabled
                ? const [
                    BoxShadow(
                      color: Color(0xFF630F03),
                      offset: Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Color(0x1AFFFFFF),
                      offset: Offset(0, -1),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: subtitle == null ? 18 : 14,
              horizontal: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: GameFonts.display,
                    fontSize: subtitle == null ? 20 : 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: enabled ? GameColors.brandOn : GameColors.outline,
                    shadows: enabled
                        ? const [
                            Shadow(
                              color: Color(0x80000000),
                              offset: Offset(-1, -1),
                            ),
                            Shadow(
                              color: Color(0x1AFFFFFF),
                              offset: Offset(1, 1),
                            ),
                          ]
                        : null,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!.toUpperCase(),
                    style: TextStyle(
                      fontFamily: GameFonts.mono,
                      fontSize: 10,
                      letterSpacing: 1.4,
                      color: enabled
                          ? GameColors.brandOn.withValues(alpha: 0.8)
                          : GameColors.outline,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (!expanded) return child;
    return SizedBox(width: double.infinity, child: child);
  }
}

class BrassOutlinedButton extends StatelessWidget {
  const BrassOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: GameColors.ink,
        disabledForegroundColor: GameColors.outline,
        side: BorderSide(
          color: onPressed == null
              ? GameColors.outlineVariant.withValues(alpha: 0.4)
              : GameColors.brass.withValues(alpha: 0.55),
        ),
        backgroundColor: GameColors.surfaceHigh,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: GameFonts.mono,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}
