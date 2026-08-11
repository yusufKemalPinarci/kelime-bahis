import 'package:flutter/material.dart';

import '../theme/game_colors.dart';

/// Dark wood table + vignette (offline; no remote texture).
class TableSurface extends StatelessWidget {
  const TableSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.15,
          colors: [
            Color(0xFF2A2218),
            GameColors.bg,
            GameColors.bgLowest,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Soft grain stripes
          CustomPaint(painter: _GrainPainter()),
          // Vignette
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.95,
                colors: [Colors.transparent, Color(0xD9000000)],
                stops: [0.35, 1.0],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x14ECE1D5)
      ..strokeWidth = 1;
    for (var y = 0.0; y < size.height; y += 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 0.6), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
