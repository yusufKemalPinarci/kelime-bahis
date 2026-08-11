import 'package:flutter/material.dart';

import '../../game/letter_bag.dart';
import '../../game/turkish.dart';
import '../theme/game_colors.dart';
import '../theme/game_theme.dart';

/// Bone parchment letter chip (Stitch tactile tile).
class LetterTileChip extends StatefulWidget {
  const LetterTileChip({
    super.key,
    required this.tile,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final LetterTile tile;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<LetterTileChip> createState() => _LetterTileChipState();
}

class _LetterTileChipState extends State<LetterTileChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop;
  late final Animation<double> _popScale;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _popScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.16), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.16, end: 1.0), weight: 65),
    ]).animate(CurvedAnimation(parent: _pop, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _handleTap() {
    _pop.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final tile = widget.tile;
    final selected = widget.selected;
    final compact = widget.compact;
    final w = compact ? 40.0 : 56.0;
    final h = compact ? 46.0 : 70.0;
    final letterSize = compact ? 18.0 : 28.0;
    final pointsSize = compact ? 9.0 : 10.0;
    final radius = compact ? 6.0 : 8.0;

    return AnimatedBuilder(
      animation: _popScale,
      builder: (context, child) =>
          Transform.scale(scale: _popScale.value, child: child),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        transform:
            Matrix4.translationValues(0, selected && !compact ? -6 : 0, 0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(radius),
            child: Ink(
              width: w,
              height: h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                color: GameColors.tile,
                border: Border.all(
                  color:
                      selected ? GameColors.brass : const Color(0x33FFFFFF),
                  width: selected ? 2 : 1,
                ),
                boxShadow: [
                  if (selected)
                    BoxShadow(
                      color: GameColors.brass.withValues(alpha: 0.45),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: selected ? 10 : 4,
                    offset: Offset(0, selected ? 6 : 4),
                  ),
                  const BoxShadow(
                    color: Color(0xCCFFFFFF),
                    blurRadius: 0,
                    offset: Offset(0, 1),
                    spreadRadius: -1,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      toUpperTr(tile.letter),
                      strutStyle: StrutStyle(
                        fontSize: letterSize,
                        height: 1,
                        forceStrutHeight: true,
                      ),
                      style: TextStyle(
                        fontFamily: GameFonts.display,
                        fontFamilyFallback: const [GameFonts.body],
                        fontSize: letterSize,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: GameColors.tileInk,
                      ),
                    ),
                  ),
                  Positioned(
                    right: compact ? 3 : 5,
                    bottom: compact ? 2 : 4,
                    child: Text(
                      '${tile.points}',
                      style: TextStyle(
                        fontFamily: GameFonts.body,
                        fontSize: pointsSize,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: GameColors.tileInk.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
