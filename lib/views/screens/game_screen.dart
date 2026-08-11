import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import '../../game/rank.dart';
import '../../game/scoring.dart';
import '../../game/turkish.dart';
import '../../game/word_length.dart';
import '../../services/ad_config.dart';
import '../../services/ads_controller.dart';
import '../../services/sound_controller.dart';
import '../theme/game_colors.dart';
import '../theme/game_theme.dart';
import '../widgets/brass_panel.dart';
import '../widgets/gold_chip.dart';
import '../widgets/letter_tile_chip.dart';
import '../widgets/letterpress_button.dart';
import '../widgets/level_strip.dart';
import '../widgets/rank_badge.dart';
import '../widgets/score_hud.dart';
import '../widgets/table_surface.dart';
import '../widgets/word_length_meter.dart';

Future<void> _confirmExitRun(BuildContext context, GameController c) async {
  // Kayıt yalnızca bir seviye tamamlandıktan sonra oluşur (bkz.
  // GameController._persistRunState) — Seviye 1'in ortasında henüz yok.
  final resumable = !c.endless && c.stats.hasSavedRun;
  final leave = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: GameColors.surfaceLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text(
        'Koşudan çık?',
        style: TextStyle(
          fontFamily: GameFonts.display,
          fontWeight: FontWeight.w700,
          color: GameColors.ink,
        ),
      ),
      content: Text(
        resumable ? 'Kaldığın yerden devam edebilirsin.' : 'İlerlemen kaybolur.',
        style: const TextStyle(color: GameColors.inkMuted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Vazgeç', style: TextStyle(color: GameColors.outline)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Çık', style: TextStyle(color: GameColors.brand)),
        ),
      ],
    ),
  );
  if (leave == true && context.mounted) {
    Navigator.of(context).popUntil((r) => r.isFirst);
  }
}

/// OYNA butonunun metni — seçim durumuna göre anlamlı geri bildirim verir.
String _playLabel(GameController c) {
  if (c.selected.isEmpty) return 'HARF SEÇ';
  if (c.selected.length < c.requiredLength) {
    return '${c.selected.length}/${c.requiredLength} HARF';
  }
  final preview = c.livePreviewScore;
  if (preview == null) return 'GEÇERSİZ KELİME';
  return 'OYNA · +$preview';
}

/// "Seri ×N" rozeti — art arda oynanan kelime sayısı arttıkça pop-in
/// animasyonuyla yeniden belirir, yüzdelik bonusu gösterir ve rengi
/// outline→brass→gold'a koyulaşır (3+ seride küçük bir alev ikonuyla).
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
    final pct = ((comboMultiplier(streak) - 1) * 100).round();

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
          boxShadow: hot
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: 0.5,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hot) ...[
              Icon(Icons.local_fire_department_rounded, size: 13, color: color),
              const SizedBox(width: 3),
            ],
            Text(
              'Seri ×$streak · +$pct%',
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

/// Sol üstte her zaman görünen çıkış tutamacı — sistem geri tuşuna bağımlı kalmasın.
class _ExitIconButton extends StatelessWidget {
  const _ExitIconButton({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () => _confirmExitRun(context, controller),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GameColors.surfaceHigh,
            border: Border.all(color: GameColors.outlineVariant),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            size: 18,
            color: GameColors.inkMuted,
          ),
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.controller,
    required this.adsController,
    required this.soundController,
  });

  final GameController controller;
  final AdsController adsController;
  final SoundController soundController;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  GameController get c => widget.controller;
  SoundController get sound => widget.soundController;
  late final AnimationController _scoreFlash;
  int _displayedScore = 0;

  @override
  void initState() {
    super.initState();
    _displayedScore = c.score;
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
    if (c.score != _displayedScore) {
      _scoreFlash.forward(from: 0);
      setState(() => _displayedScore = c.score);
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (c.phase == RunPhase.shop) {
      return _ShopView(
        controller: c,
        adsController: widget.adsController,
        soundController: sound,
      );
    }
    if (c.phase == RunPhase.won || c.phase == RunPhase.lost) {
      return _EndView(controller: c);
    }

    final title = c.endless
        ? 'Endless ${c.level} · ${c.requiredLength} harf'
        : c.mode == RunMode.daily
            ? 'Günlük ${c.level} · ${c.requiredLength} harf'
            : 'Seviye ${c.level} · ${c.requiredLength} harf';

    final preview = c.livePreviewScore;
    final scoreNotes = c.lastScore?.notes ?? const <String>[];
    final flash = CurvedAnimation(parent: _scoreFlash, curve: Curves.easeOut);
    final boss = c.activeBoss;

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
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _ExitIconButton(controller: c),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ScoreHud(
                        score: _displayedScore,
                        target: c.target,
                        progress: c.progressToTarget,
                        flash: flash,
                        flashScale: 1.05 + c.comboStreak * 0.02,
                        levelLabel: title,
                        boss: boss != null,
                        handsLeft: c.handsLeft,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: GoldChip(amount: c.gold),
                    ),
                  ],
                ),
              ),
              if (!c.endless) ...[
                const SizedBox(height: 10),
                LevelStrip(currentLevel: c.level, totalLevels: kClassicLevels),
              ],
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (boss != null) ...[
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          decoration: BoxDecoration(
                            color: GameColors.bossBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  GameColors.danger.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      boss.name,
                                      style: const TextStyle(
                                        fontFamily: GameFonts.display,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: GameColors.bossInk,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: GameColors.dangerDeep
                                          .withValues(alpha: 0.45),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      '+${((kBossTargetMultiplier - 1) * 100).round()}%',
                                      style: const TextStyle(
                                        fontFamily: GameFonts.mono,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: GameColors.bossInk,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                boss.description,
                                style: TextStyle(
                                  color: GameColors.bossInk
                                      .withValues(alpha: 0.9),
                                  height: 1.35,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 10),
                      ],
                      if (scoreNotes.isNotEmpty) ...[
                        FadeTransition(
                          opacity:
                              Tween(begin: 0.4, end: 1.0).animate(flash),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: scoreNotes
                                .take(4)
                                .map(
                                  (n) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: GameColors.surface,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: GameColors.gold
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      n,
                                      style: const TextStyle(
                                        fontFamily: GameFonts.mono,
                                        color: GameColors.gold,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (c.ownedJokers.isNotEmpty) ...[
                        Builder(builder: (context) {
                          final notes =
                              c.livePreviewBreakdown?.notes ?? const <String>[];
                          return Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: c.ownedJokers.map((j) {
                              final active =
                                  notes.any((n) => n.startsWith('${j.name}:'));
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? GameColors.gold.withValues(alpha: 0.18)
                                      : GameColors.surfaceHigh,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: active
                                        ? GameColors.gold
                                        : GameColors.brass
                                            .withValues(alpha: 0.45),
                                    width: active ? 1.4 : 1,
                                  ),
                                ),
                                child: Text(
                                  j.name,
                                  style: TextStyle(
                                    fontFamily: GameFonts.mono,
                                    fontSize: 11,
                                    letterSpacing: 0.6,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: active
                                        ? GameColors.gold
                                        : GameColors.inkMuted,
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }),
                        const SizedBox(height: 14),
                      ],
                      Text(
                        c.selectedWord.isEmpty
                            ? '—'
                            : toUpperTr(c.selectedWord),
                        textAlign: TextAlign.center,
                        strutStyle: const StrutStyle(
                          fontSize: 36,
                          height: 1,
                          forceStrutHeight: true,
                        ),
                        style: TextStyle(
                          fontFamily: GameFonts.display,
                          fontFamilyFallback: const [GameFonts.body],
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                          color: c.selectedWord.isEmpty
                              ? GameColors.outlineVariant
                              : GameColors.gold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      WordLengthMeter(
                        length: c.selected.length,
                        target: c.requiredLength,
                      ),
                      if (preview != null) ...[
                        const SizedBox(height: 8),
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
                      if (c.selected.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ReorderableListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  buildDefaultDragHandles: false,
                                  onReorder: (oldIndex, newIndex) {
                                    if (newIndex > oldIndex) newIndex -= 1;
                                    c.moveSelected(oldIndex, newIndex);
                                  },
                                  itemCount: c.selected.length,
                                  itemBuilder: (context, index) {
                                    final tile = c.selected[index];
                                    return ReorderableDragStartListener(
                                      key: ValueKey(tile.id),
                                      index: index,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        child: LetterTileChip(
                                          tile: tile,
                                          selected: true,
                                          compact: true,
                                          onTap: () {
                                            sound.playTap();
                                            c.toggleSelect(tile);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: c.clearSelection,
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                              ),
                              color: GameColors.outline,
                              tooltip: 'Seçimi sil',
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 18),
                      InsetSlot(
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
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: BrassOutlinedButton(
                            label: 'DEĞİŞTİR (${c.discardsLeft})',
                            onPressed: c.discardSelected,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: BrassOutlinedButton(
                            label: 'PAS (${c.passesLeft})',
                            onPressed: c.passesLeft > 0 ? c.usePass : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: BrassOutlinedButton(
                            label: 'İPUCU (${c.hintsLeft})',
                            onPressed:
                                c.hintsLeft > 0 ? c.useSoftHint : null,
                          ),
                        ),
                      ],
                    ),
                    if (c.comboStreak > 1) ...[
                      const SizedBox(height: 10),
                      Center(child: _ComboBadge(streak: c.comboStreak)),
                    ],
                    const SizedBox(height: 8),
                    LetterpressButton(
                      label: _playLabel(c),
                      onPressed: () {
                        final scoreBefore = c.score;
                        final selectedBefore = c.selected.isNotEmpty;
                        final wasPlaying = c.phase == RunPhase.playing;
                        c.playWord();
                        if (wasPlaying && c.phase != RunPhase.playing) {
                          sound.playLevelClear();
                        } else if (c.score > scoreBefore) {
                          sound.playSuccess();
                          if (c.comboStreak > 1) sound.playCombo(c.comboStreak);
                        } else if (selectedBefore) {
                          sound.playError();
                        }
                        // selectedBefore==false: "harf seç" uyarısı, ses gerekmiyor.
                      },
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

class _ShopView extends StatelessWidget {
  const _ShopView({
    required this.controller,
    required this.adsController,
    required this.soundController,
  });

  final GameController controller;
  final AdsController adsController;
  final SoundController soundController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, adsController]),
      builder: (context, _) {
        final slotsFull = controller.ownedJokers.length >= kMaxJokerSlots;
        final boss = controller.upcomingBossPreview;
        final gold = controller.gold;

        return Scaffold(
          body: TableSurface(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4, right: 10),
                          child: _ExitIconButton(controller: controller),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.isPregameShop
                                    ? 'Koşu Başlıyor'
                                    : 'Bonus',
                                style: const TextStyle(
                                  fontFamily: GameFonts.display,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: GameColors.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                controller.isPregameShop
                                    ? 'Başlamadan önce bir bonus al'
                                    : 'Altınla birini al',
                                style: const TextStyle(
                                  fontFamily: GameFonts.mono,
                                  fontSize: 11,
                                  letterSpacing: 0.8,
                                  color: GameColors.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TweenAnimationBuilder<int>(
                              tween: IntTween(begin: 0, end: gold),
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) =>
                                  GoldChip(amount: value, large: true),
                            ),
                            if (controller.lastGoldEarned > 0) ...[
                              const SizedBox(height: 6),
                              Text(
                                '+${controller.lastGoldEarned}',
                                style: const TextStyle(
                                  fontFamily: GameFonts.mono,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: GameColors.gold,
                                ),
                              ),
                            ],
                            if (adsController.isRewardedReady) ...[
                              const SizedBox(height: 6),
                              TextButton(
                                onPressed: () => adsController.showRewarded(
                                  onReward: () => controller.grantBonusGold(
                                    AdConfig.rewardedGoldAmount,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'İzle · +${AdConfig.rewardedGoldAmount} altın',
                                  style: const TextStyle(
                                    fontFamily: GameFonts.mono,
                                    fontSize: 11,
                                    letterSpacing: 0.4,
                                    color: GameColors.gold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    if (boss != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: GameColors.bossBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: GameColors.danger.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              boss.name,
                              style: const TextStyle(
                                fontFamily: GameFonts.display,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: GameColors.bossInk,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              boss.description,
                              style: const TextStyle(
                                color: GameColors.bossInk,
                                height: 1.35,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (controller.ownedJokers.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (var i = 0; i < kMaxJokerSlots; i++)
                            _BonusSlot(
                              name: i < controller.ownedJokers.length
                                  ? controller.ownedJokers[i].name
                                  : null,
                            ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 6,
                        children: List.generate(
                          kMaxJokerSlots,
                          (_) => const _BonusSlot(name: null),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        children: [
                          if (slotsFull)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Slotlar dolu',
                                style: TextStyle(
                                  color: GameColors.outline,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ...controller.shopOffers.map((j) {
                            final canBuy = !slotsFull && gold >= j.cost;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Material(
                                color: GameColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: canBuy
                                      ? () {
                                          soundController.playPurchase();
                                          controller.buyJoker(j);
                                        }
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: canBuy
                                            ? GameColors.brass
                                                .withValues(alpha: 0.55)
                                            : GameColors.outlineVariant,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                j.name,
                                                style: TextStyle(
                                                  fontFamily:
                                                      GameFonts.display,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color: canBuy
                                                      ? GameColors.ink
                                                      : GameColors.outline,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                j.description,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: canBuy
                                                      ? GameColors.inkMuted
                                                      : GameColors.outline
                                                          .withValues(
                                                          alpha: 0.8),
                                                  height: 1.35,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        GoldPriceTag(
                                          cost: j.cost,
                                          affordable: canBuy,
                                          lockedLabel:
                                              slotsFull ? 'DOLU' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    LetterpressButton(
                      label: controller.isPregameShop ? 'Başla' : 'Atla',
                      onPressed: controller.skipShop,
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

class _BonusSlot extends StatelessWidget {
  const _BonusSlot({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final filled = name != null;
    return Container(
      constraints: const BoxConstraints(minWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: filled ? GameColors.surfaceHigh : GameColors.bgLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: filled
              ? GameColors.brass.withValues(alpha: 0.5)
              : GameColors.outlineVariant,
          style: filled ? BorderStyle.solid : BorderStyle.solid,
        ),
      ),
      child: Text(
        filled ? name! : '·',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: GameFonts.mono,
          fontSize: 11,
          letterSpacing: 0.4,
          color: filled ? GameColors.inkMuted : GameColors.outlineVariant,
        ),
      ),
    );
  }
}

class _EndView extends StatelessWidget {
  const _EndView({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final won = controller.phase == RunPhase.won;
    final gap = (controller.target - controller.score).clamp(0, 1 << 30);
    final best = controller.bestWordPlayed;

    return Scaffold(
      body: TableSurface(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (won)
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
                        'BİTTİ — KAZANDIN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: GameFonts.display,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    )
                  else
                    const Text(
                      'KOŞU BİTTİ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: GameFonts.display,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: GameColors.brand,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    width: 72,
                    height: 2,
                    color: (won ? GameColors.gold : GameColors.brand)
                        .withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    won
                        ? 'Büyük ikramiye sizin oldu'
                        : 'Hedefe $gap puan kala elendin',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: GameFonts.mono,
                      fontSize: 11,
                      letterSpacing: 1.6,
                      color: GameColors.outline,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    controller.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GameColors.inkMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          label: 'Seviye',
                          value: '${controller.level}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatBox(
                          label: 'Puan',
                          value: '${controller.score}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (controller.rankedUpThisRun) ...[
                    Text(
                      'YENİ RÜTBE · ${rankForScore(controller.stats.lifetimeScore).name}',
                      style: const TextStyle(
                        fontFamily: GameFonts.mono,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: GameColors.gold,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  RankBadge(lifetimeScore: controller.stats.lifetimeScore),
                  if (controller.lifetimeScoreGainedThisRun > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      '+${controller.lifetimeScoreGainedThisRun} ömür boyu puan',
                      style: const TextStyle(
                        fontFamily: GameFonts.mono,
                        fontSize: 11,
                        letterSpacing: 0.6,
                        color: GameColors.inkMuted,
                      ),
                    ),
                  ],
                  if (!won && best != null) ...[
                    const SizedBox(height: 22),
                    const HudLabel('En iyi kelimen'),
                    const SizedBox(height: 10),
                    Text(
                      toUpperTr(best),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: GameFonts.display,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        color: GameColors.gold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: GameColors.bgLowest.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: GameColors.brass.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        '+${controller.bestWordScore} PUAN',
                        style: const TextStyle(
                          fontFamily: GameFonts.mono,
                          fontSize: 11,
                          letterSpacing: 1.4,
                          color: GameColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (won && !controller.endless) ...[
                    LetterpressButton(
                      label: 'Devam et (endless)',
                      onPressed: controller.enterEndless,
                    ),
                    const SizedBox(height: 10),
                  ],
                  LetterpressButton(
                    label: 'Yeniden oyna',
                    onPressed: () =>
                        controller.startNewRun(runMode: controller.mode),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    child: const Text(
                      'ANA EKRAN',
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
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GameColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GameColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          HudLabel(label),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: GameFonts.display,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
