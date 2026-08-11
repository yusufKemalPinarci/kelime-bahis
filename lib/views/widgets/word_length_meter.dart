import 'package:flutter/material.dart';

import '../theme/game_colors.dart';

/// Bu seviyenin gerektirdiği tam uzunluğa göre dolan basit bir gösterge —
/// artık serbest aralık yok, tek hedef var.
class WordLengthMeter extends StatelessWidget {
  const WordLengthMeter({super.key, required this.length, required this.target});

  final int length;
  final int target;

  @override
  Widget build(BuildContext context) {
    final ready = length == target;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < target; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          _Seg(filled: i < length, ready: ready),
        ],
      ],
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({required this.filled, required this.ready});

  final bool filled;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    Color fill;
    if (!filled) {
      fill = GameColors.outlineVariant.withValues(alpha: 0.55);
    } else if (ready) {
      fill = GameColors.gold;
    } else {
      fill = GameColors.brass;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: 10,
      height: 5,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}
