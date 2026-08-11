import 'package:flutter/material.dart';

import 'game_colors.dart';

abstract final class GameFonts {
  static const display = 'LibreCaslonText';
  static const body = 'WorkSans';
  static const mono = 'JetBrainsMono';
}

ThemeData buildGameTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      surface: GameColors.bg,
      onSurface: GameColors.ink,
      primary: GameColors.ink,
      onPrimary: GameColors.tileInk,
      secondary: GameColors.brand,
      onSecondary: GameColors.brandOn,
      tertiary: GameColors.gold,
      onTertiary: GameColors.tileInk,
      error: GameColors.danger,
      outline: GameColors.outline,
    ),
    scaffoldBackgroundColor: GameColors.bg,
    fontFamily: GameFonts.body,
    appBarTheme: const AppBarTheme(
      backgroundColor: GameColors.bg,
      foregroundColor: GameColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: GameFonts.display,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        color: GameColors.ink,
      ),
    ),
    dividerColor: GameColors.outlineVariant,
  );

  return base.copyWith(
    textTheme: base.textTheme
        .apply(
          bodyColor: GameColors.ink,
          displayColor: GameColors.ink,
          fontFamily: GameFonts.body,
        )
        .copyWith(
          displayLarge: const TextStyle(
            fontFamily: GameFonts.display,
            fontSize: 48,
            fontWeight: FontWeight.w700,
            height: 1.1,
            letterSpacing: -0.5,
            color: GameColors.ink,
          ),
          displayMedium: const TextStyle(
            fontFamily: GameFonts.display,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: GameColors.ink,
          ),
          headlineMedium: const TextStyle(
            fontFamily: GameFonts.display,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: GameColors.ink,
          ),
          titleMedium: const TextStyle(
            fontFamily: GameFonts.body,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: GameColors.inkMuted,
          ),
          bodyLarge: const TextStyle(
            fontFamily: GameFonts.body,
            fontSize: 18,
            height: 1.6,
            color: GameColors.ink,
          ),
          bodyMedium: const TextStyle(
            fontFamily: GameFonts.body,
            fontSize: 16,
            height: 1.5,
            color: GameColors.ink,
          ),
          labelLarge: const TextStyle(
            fontFamily: GameFonts.mono,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
            color: GameColors.gold,
          ),
        ),
  );
}
