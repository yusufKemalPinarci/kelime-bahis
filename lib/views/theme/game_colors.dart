import 'package:flutter/material.dart';

/// Stitch «Kelime Bahis» design tokens — dark wood wager table.
abstract final class GameColors {
  // Surfaces
  static const bg = Color(0xFF17130C);
  static const bgLowest = Color(0xFF120D07);
  static const surfaceLow = Color(0xFF201B13);
  static const surface = Color(0xFF241F17);
  static const surfaceHigh = Color(0xFF2F2921);
  static const surfaceHighest = Color(0xFF3A342C);

  // Ink / parchment
  static const ink = Color(0xFFECE1D5);
  static const inkMuted = Color(0xFFD2C4BE);
  static const outline = Color(0xFF9B8E89);
  static const outlineVariant = Color(0xFF4E4541);

  // Accents
  static const brand = Color(0xFFC0533E); // terracotta CTA
  static const brandDeep = Color(0xFF892B1A);
  static const brandOn = Color(0xFFECE1D5);
  static const gold = Color(0xFFE9C349);
  static const brass = Color(0xFFD4AF37);
  static const goldLeafEnd = Color(0xFFFCF6BA);

  // Tiles
  static const tile = Color(0xFFE5DACE); // bone parchment
  static const tileInk = Color(0xFF1A0F0A);
  static const tileEdge = Color(0xFFB0A498);

  // Feedback
  static const success = Color(0xFF3D9B6E);
  static const danger = Color(0xFFFFB4AB);
  static const dangerDeep = Color(0xFF93000A);
  static const bossBg = Color(0xFF3A1C1C);
  static const bossInk = Color(0xFFFFC9C9);

  // Progress — track needs to read against the dark table bg even at 0% fill.
  static const barTrack = Color(0xFF3A342C);
  static const barFill = gold;

  // Legacy aliases (call sites)
  static const bgTop = bg;
  static const bgBottom = bgLowest;
  static const muted = inkMuted;
  static const tileSelected = brass;
  static const tileSelectedInk = tileInk;
}
