import 'package:flutter/material.dart';

import '../../game/adventure_levels.dart';
import '../../game/game_controller.dart';
import '../theme/game_colors.dart';
import '../theme/game_theme.dart';
import '../widgets/letterpress_button.dart';
import '../widgets/table_surface.dart';

/// Kule haritası — kaydırma yok. Mevcut seviyenin etrafında sabit sayıda
/// düğüm gösterilir (geçilenler soluk, mevcut vurgulu, gelecekler kilitli);
/// alttaki büyük CTA doğrudan mevcut seviyeyi açar.
class AdventureMapScreen extends StatelessWidget {
  const AdventureMapScreen({super.key, required this.controller});

  final GameController controller;

  static const _windowSize = 5;

  List<int> _windowLevels(int current) {
    final maxStart =
        (kAdventureLevelCount - _windowSize + 1).clamp(1, kAdventureLevelCount);
    var start = (current - _windowSize ~/ 2).clamp(1, maxStart);
    return [for (var i = 0; i < _windowSize; i++) start + i]
        .where((l) => l <= kAdventureLevelCount)
        .toList();
  }

  void _enterLevel(BuildContext context, int level) {
    controller.startAdventureLevel(level);
    Navigator.of(context).pushNamed('/play');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final cleared = controller.stats.adventureHighestCleared;
        final currentLevel = (cleared + 1).clamp(1, kAdventureLevelCount);
        final towerConquered = cleared >= kAdventureLevelCount;
        final floorName = floorNameForLevel(currentLevel);
        final levels = _windowLevels(currentLevel);

        return Scaffold(
          body: TableSurface(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BackButton(onTap: () => Navigator.of(context).pop()),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'KULE',
                                style: TextStyle(
                                  fontFamily: GameFonts.display,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                  color: GameColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                towerConquered
                                    ? 'Zirve fethedildi'
                                    : '$floorName · Seviye $currentLevel/$kAdventureLevelCount',
                                style: const TextStyle(
                                  fontFamily: GameFonts.mono,
                                  fontSize: 11,
                                  letterSpacing: 0.6,
                                  color: GameColors.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 340),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < levels.length; i++) ...[
                                if (i > 0) const _PathConnector(),
                                _LevelNode(
                                  level: levels[i],
                                  cleared: levels[i] <= cleared,
                                  current: levels[i] == currentLevel,
                                  unlocked: levels[i] <= currentLevel,
                                  onTap: levels[i] <= currentLevel
                                      ? () => _enterLevel(context, levels[i])
                                      : null,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!towerConquered) ...[
                      Text(
                        adventureLevel(currentLevel).title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: GameFonts.mono,
                          fontSize: 11,
                          letterSpacing: 0.6,
                          color: GameColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      LetterpressButton(
                        label: 'Seviye $currentLevel',
                        onPressed: () => _enterLevel(context, currentLevel),
                      ),
                    ] else
                      LetterpressButton(
                        label: 'Zirveyi tekrar oyna',
                        onPressed: () =>
                            _enterLevel(context, kAdventureLevelCount),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PathConnector extends StatelessWidget {
  const _PathConnector();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 18,
      color: GameColors.outlineVariant.withValues(alpha: 0.6),
    );
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.level,
    required this.cleared,
    required this.current,
    required this.unlocked,
    required this.onTap,
  });

  final int level;
  final bool cleared;
  final bool current;
  final bool unlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final milestone = level % kAdventureLevelsPerFloor == 0;
    final size = current ? 64.0 : 48.0;
    final color = current
        ? GameColors.gold
        : cleared
            ? GameColors.brass.withValues(alpha: 0.85)
            : GameColors.outlineVariant.withValues(alpha: 0.55);

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: current
              ? GameColors.gold.withValues(alpha: 0.18)
              : cleared
                  ? GameColors.surfaceHigh
                  : GameColors.bgLowest,
          border: Border.all(color: color, width: current ? 2.4 : 1.4),
          boxShadow: current
              ? [
                  BoxShadow(
                    color: GameColors.gold.withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: !unlocked
            ? Icon(Icons.lock_rounded,
                size: size * 0.36, color: GameColors.outline)
            : cleared
                ? Icon(Icons.check_rounded, size: size * 0.42, color: color)
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$level',
                        style: TextStyle(
                          fontFamily: GameFonts.display,
                          fontWeight: FontWeight.w700,
                          fontSize: size * 0.34,
                          color: GameColors.ink,
                        ),
                      ),
                      if (milestone)
                        Positioned(
                          top: size * 0.05,
                          child: Icon(Icons.diamond_rounded,
                              size: size * 0.2, color: GameColors.danger),
                        ),
                    ],
                  ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GameColors.surfaceHigh,
            border: Border.all(color: GameColors.outlineVariant),
          ),
          child: const Icon(Icons.arrow_back_rounded,
              size: 18, color: GameColors.inkMuted),
        ),
      ),
    );
  }
}
