import 'package:flutter/material.dart';

import '../theme/game_colors.dart';

/// Adventure (Macera) modu için basit, vektörel bir kule silueti — üstte bayrak.
class TowerIcon extends StatelessWidget {
  const TowerIcon({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _TowerPainter()),
    );
  }
}

class _TowerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [GameColors.goldLeafEnd, GameColors.gold, GameColors.brass],
    ).createShader(Offset.zero & size);
    final fill = Paint()..shader = gradient;
    final stroke = Paint()
      ..color = GameColors.bgLowest.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.02;

    final w = size.width;
    final h = size.height;

    // 4 daralan kat + bayrak direği.
    final tiers = [
      Rect.fromLTWH(w * 0.10, h * 0.62, w * 0.80, h * 0.28),
      Rect.fromLTWH(w * 0.20, h * 0.44, w * 0.60, h * 0.20),
      Rect.fromLTWH(w * 0.28, h * 0.28, w * 0.44, h * 0.18),
      Rect.fromLTWH(w * 0.36, h * 0.16, w * 0.28, h * 0.14),
    ];
    for (final r in tiers) {
      final rr = RRect.fromRectAndRadius(r, Radius.circular(w * 0.03));
      canvas.drawRRect(rr, fill);
      canvas.drawRRect(rr, stroke);
    }

    final pole = Paint()
      ..color = GameColors.brass
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.5, h * 0.16),
      Offset(w * 0.5, h * 0.02),
      pole,
    );
    final flag = Path()
      ..moveTo(w * 0.5, h * 0.02)
      ..lineTo(w * 0.72, h * 0.07)
      ..lineTo(w * 0.5, h * 0.12)
      ..close();
    canvas.drawPath(flag, Paint()..color = GameColors.brand);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Classic modu için iki çakışık harf taşı — sonsuz kelime akışını simgeler.
class TileStackIcon extends StatelessWidget {
  const TileStackIcon({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    final tile = size * 0.62;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -0.18,
            child: _MiniTile(width: tile, letter: 'K'),
          ),
          Transform.translate(
            offset: Offset(size * 0.16, size * 0.08),
            child: Transform.rotate(
              angle: 0.14,
              child: _MiniTile(width: tile, letter: 'B'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTile extends StatelessWidget {
  const _MiniTile({required this.width, required this.letter});

  final double width;
  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 1.15,
      decoration: BoxDecoration(
        color: GameColors.tile,
        borderRadius: BorderRadius.circular(width * 0.14),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: width * 0.5,
          color: GameColors.tileInk,
        ),
      ),
    );
  }
}
