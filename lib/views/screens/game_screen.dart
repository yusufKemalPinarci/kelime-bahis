import 'package:flutter/material.dart';

import '../../game/adventure_levels.dart';
import '../../game/game_controller.dart';
import '../../game/turkish.dart';
import '../../services/sound_controller.dart';
import '../theme/game_colors.dart';
import '../theme/game_theme.dart';
import '../widgets/attempt_pips.dart';
import '../widgets/brass_panel.dart';
import '../widgets/high_score_badge.dart';
import '../widgets/letter_tile_chip.dart';
import '../widgets/letterpress_button.dart';
import '../widgets/table_surface.dart';

/// Sol üstte her zaman görünen geri tutamacı.
class _BackIconButton extends StatelessWidget {
  const _BackIconButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () => Navigator.of(context).pop(),
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

/// "Seri ×N" rozeti.
class _ComboBadge extends StatelessWidget {
  const _ComboBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final hot = streak >= 3;
    final color = streak >= 4
        ? GameColors.gold
        : streak == 3
            ? GameColors.brass
            : GameColors.outline;

    return TweenAnimationBuilder<double>(
      key: ValueKey(streak),
      tween: Tween(begin: 0.55, end: 1.0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color, width: hot ? 1.4 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hot) ...[
              Icon(Icons.local_fire_department_rounded, size: 13, color: color),
              const SizedBox(width: 3),
            ],
            Text(
              'Seri ×$streak',
              style: TextStyle(
                fontFamily: GameFonts.mono,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alt kontrol satırındaki kare çöp kovası butonu — tek dokunuşla seçili
/// harflerin tamamını temizler.
class _TrashIconButton extends StatelessWidget {
  const _TrashIconButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: GameColors.ink,
          disabledForegroundColor: GameColors.outline,
          side: BorderSide(
            color: enabled
                ? GameColors.brass.withValues(alpha: 0.55)
                : GameColors.outlineVariant.withValues(alpha: 0.4),
          ),
          backgroundColor: GameColors.surfaceHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: const Icon(Icons.delete_outline_rounded, size: 20),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.controller,
    required this.soundController,
  });

  final GameController controller;
  final SoundController soundController;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  GameController get c => widget.controller;
  SoundController get sound => widget.soundController;
  late final AnimationController _scoreFlash;
  int _displayedPrimary = 0;

  int get _primaryValue =>
      c.mode == RunMode.classic ? c.classicScore : c.adventureProgress;

  @override
  void initState() {
    super.initState();
    _displayedPrimary = _primaryValue;
    _scoreFlash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    c.addListener(_onUpdate);
  }

  @override
  void dispose() {
    c.removeListener(_onUpdate);
    _scoreFlash.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (!mounted) return;
    if (_primaryValue != _displayedPrimary) {
      _scoreFlash.forward(from: 0);
      setState(() => _displayedPrimary = _primaryValue);
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (c.phase == RunPhase.adventureComplete) {
      return _AdventureCompleteView(controller: c);
    }

    final adventure = c.mode == RunMode.adventure;
    final task = c.adventureTask;
    final preview = c.livePreviewScore;
    final flash = CurvedAnimation(parent: _scoreFlash, curve: Curves.easeOut);

    return Scaffold(
      body: TableSurface(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: _BackIconButton(),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: adventure
                          ? _AdventureHeader(controller: c, task: task!)
                          : _ClassicHeader(controller: c, flash: flash),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (adventure && task != null) ...[
                            Container(
                              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                              decoration: BoxDecoration(
                                color: GameColors.surfaceHigh,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: GameColors.brass.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                task.description,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: GameColors.inkMuted,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (c.message.isNotEmpty) ...[
                            Text(
                              c.message,
                              style: const TextStyle(
                                color: GameColors.inkMuted,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            c.selectedWord.isEmpty
                                ? '—'
                                : toUpperTr(c.selectedWord),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: GameFonts.display,
                              fontFamilyFallback: const [GameFonts.body],
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                              color: c.selectedWord.isEmpty
                                  ? GameColors.outlineVariant
                                  : GameColors.gold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            adventure && task!.exactLength != null
                                ? '${c.selected.length}/${task.exactLength} harf'
                                : '${c.selected.length} harf',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: GameFonts.mono,
                              fontSize: 11,
                              letterSpacing: 1,
                              color: GameColors.outline,
                            ),
                          ),
                          if (preview != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              '+$preview',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: GameFonts.mono,
                                fontSize: 14,
                                letterSpacing: 1,
                                color: GameColors.gold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Center(
                        child: InsetSlot(
                          padding: const EdgeInsets.all(12),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: c.hand.map((tile) {
                              return LetterTileChip(
                                tile: tile,
                                selected: c.selected.contains(tile),
                                onTap: () {
                                  sound.playTap();
                                  c.toggleSelect(tile);
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Column(
                  children: [
                    if (c.comboStreak > 1) ...[
                      Center(child: _ComboBadge(streak: c.comboStreak)),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        _TrashIconButton(
                          enabled: c.selected.isNotEmpty,
                          onPressed: () {
                            sound.playTap();
                            c.clearSelection();
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: BrassOutlinedButton(
                            label: 'PAS (${c.passesAvailable})',
                            onPressed:
                                c.passesAvailable > 0 ? c.refreshHand : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: LetterpressButton(
                            label: c.selected.isEmpty
                                ? 'HARF SEÇ'
                                : preview != null
                                    ? 'OYNA · +$preview'
                                    : 'GEÇERSİZ',
                            onPressed: () {
                              final before = _primaryValue;
                              c.playWord();
                              if (c.phase == RunPhase.adventureComplete) {
                                sound.playLevelClear();
                              } else if (_primaryValue > before) {
                                sound.playSuccess();
                                if (c.comboStreak > 1) {
                                  sound.playCombo(c.comboStreak);
                                }
                              } else if (c.selected.isEmpty) {
                                sound.playError();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassicHeader extends StatelessWidget {
  const _ClassicHeader({required this.controller, required this.flash});

  final GameController controller;
  final Animation<double> flash;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        HighScoreBadge(highScore: controller.stats.classicHighScore),
        const Spacer(),
        ScaleTransition(
          scale: Tween(begin: 1.0, end: 1.08).animate(flash),
          child: Text(
            '${controller.classicScore}',
            style: const TextStyle(
              fontFamily: GameFonts.display,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: GameColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _AdventureHeader extends StatelessWidget {
  const _AdventureHeader({required this.controller, required this.task});

  final GameController controller;
  final AdventureLevelDef task;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${task.floorName} · Seviye ${task.level}',
                style: const TextStyle(
                  fontFamily: GameFonts.mono,
                  fontSize: 11,
                  letterSpacing: 0.8,
                  color: GameColors.outline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AttemptPips(
              remaining: controller.adventureAttemptsLeft,
              max: task.attempts,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                task.title,
                style: const TextStyle(
                  fontFamily: GameFonts.display,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: GameColors.gold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${controller.adventureProgress}/${task.target}',
              style: const TextStyle(
                fontFamily: GameFonts.mono,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: GameColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: controller.adventureProgressRatio,
            minHeight: 6,
            backgroundColor: GameColors.barTrack,
            color: GameColors.barFill,
          ),
        ),
      ],
    );
  }
}

class _AdventureCompleteView extends StatelessWidget {
  const _AdventureCompleteView({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final level = controller.adventureLevelNumber;
    final hasNext = level < kAdventureLevelCount;

    return Scaffold(
      body: TableSurface(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFBF953F),
                      Color(0xFFFCF6BA),
                      Color(0xFFB38728),
                      Color(0xFFFBF5B7),
                      Color(0xFFAA771C),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'SEVİYE TAMAMLANDI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: GameFonts.display,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${floorNameForLevel(level)} · Seviye $level',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: GameFonts.mono,
                    fontSize: 12,
                    letterSpacing: 0.8,
                    color: GameColors.outline,
                  ),
                ),
                const SizedBox(height: 36),
                if (hasNext) ...[
                  LetterpressButton(
                    label: 'Sonraki seviye',
                    onPressed: controller.advanceToNextAdventureLevel,
                  ),
                  const SizedBox(height: 10),
                ] else ...[
                  const Text(
                    'Kuleyi fethettin!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: GameFonts.display,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: GameColors.gold,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'HARİTAYA DÖN',
                    style: TextStyle(
                      fontFamily: GameFonts.mono,
                      fontSize: 12,
                      letterSpacing: 1.6,
                      color: GameColors.outline,
                    ),
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
