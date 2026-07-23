import 'package:flutter/material.dart';

import '../../game/letter_bag.dart';
import '../theme/game_colors.dart';

class LetterTileChip extends StatelessWidget {
  const LetterTileChip({
    super.key,
    required this.tile,
    required this.selected,
    required this.onTap,
  });

  final LetterTile tile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, selected ? -4 : 0, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            width: 58,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: selected
                    ? const [Color(0xFFF0C98A), GameColors.tileSelected]
                    : const [Color(0xFF3A3028), GameColors.tile],
              ),
              border: Border.all(
                color: selected ? const Color(0xFFFFE6B8) : GameColors.tileEdge,
                width: selected ? 2 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: selected ? 0.35 : 0.25),
                  blurRadius: selected ? 10 : 6,
                  offset: Offset(0, selected ? 6 : 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tile.letter.toUpperCase(),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: selected
                        ? GameColors.tileSelectedInk
                        : GameColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tile.points}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? GameColors.tileSelectedInk.withValues(alpha: 0.7)
                        : GameColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
