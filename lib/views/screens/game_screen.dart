import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import '../../game/scoring.dart';
import '../../game/word_length.dart';
import '../theme/game_colors.dart';
import '../widgets/letter_tile_chip.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  GameController get c => widget.controller;
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

  void _showJokerSheet(JokerCard j) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: GameColors.bgBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              j.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: GameColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              j.description,
              style: const TextStyle(color: GameColors.muted, height: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Fiyat: ${j.cost} altın',
              style: const TextStyle(color: GameColors.barFill),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (c.phase == RunPhase.shop) {
      return _ShopView(controller: c, onInspect: _showJokerSheet);
    }
    if (c.phase == RunPhase.won || c.phase == RunPhase.lost) {
      return _EndView(controller: c);
    }

    final title = c.endless
        ? 'Endless ${c.level}'
        : c.mode == RunMode.daily
            ? 'Günlük · ${c.level}'
            : 'Seviye ${c.level}';

    final preview = c.livePreviewScore;
    final scoreNotes = c.lastScore?.notes ?? const <String>[];
    final flash = CurvedAnimation(parent: _scoreFlash, curve: Curves.easeOut);

    return Scaffold(
      backgroundColor: GameColors.bgBottom,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
                child: Text(
                'Altın ${c.gold}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: GameColors.barFill,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'El 8 · 2–8 harf seç · uzun kelime daha çok puan',
              style: TextStyle(
                color: GameColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: c.progressToTarget,
                minHeight: 10,
                backgroundColor: GameColors.barTrack,
                color: GameColors.barFill,
              ),
            ),
            const SizedBox(height: 6),
            ScaleTransition(
              scale: Tween(begin: 1.0, end: 1.08).animate(flash),
              child: Text(
                '$_displayedScore / ${c.target} puan',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: GameColors.ink,
                ),
              ),
            ),
            if (c.activeBoss != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GameColors.bossBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Boss: ${c.activeBoss!.name} — ${c.activeBoss!.description}',
                  style: const TextStyle(color: Color(0xFFFFC9C9)),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              c.message,
              style: const TextStyle(color: GameColors.ink, fontSize: 15),
            ),
            if (scoreNotes.isNotEmpty) ...[
              const SizedBox(height: 6),
              FadeTransition(
                opacity: Tween(begin: 0.4, end: 1.0).animate(flash),
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
                            color: const Color(0xFF243028),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: GameColors.barFill.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Text(
                            n,
                            style: const TextStyle(
                              color: GameColors.barFill,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            if (c.ownedJokers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: c.ownedJokers
                    .map(
                      (j) => ActionChip(
                        label: Text(j.name, style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: GameColors.tile,
                        side: const BorderSide(color: GameColors.tileEdge),
                        onPressed: () => _showJokerSheet(j),
                      ),
                    )
                    .toList(),
              ),
            ],
            const Spacer(),
            Text(
              c.selectedWord.isEmpty ? '—' : c.selectedWord.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: GameColors.tileSelected,
              ),
            ),
            if (c.selected.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
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
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: LetterTileChip(
                          tile: tile,
                          selected: true,
                          onTap: () => c.toggleSelect(tile),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Text(
                'Sürükle: harf sırasını değiştir',
                textAlign: TextAlign.center,
                style: TextStyle(color: GameColors.muted, fontSize: 11),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              preview == null
                  ? (c.selectedWord.isEmpty
                      ? 'Elinden 2–8 harf seç'
                      : 'Geçerli kelime değil')
                  : '+$preview puan · OYNA’ya bas',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: preview == null ? GameColors.muted : GameColors.barFill,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: c.hand.map((tile) {
                return LetterTileChip(
                  tile: tile,
                  selected: c.selected.contains(tile),
                  onTap: () => c.toggleSelect(tile),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: c.discardSelected,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GameColors.muted,
                      side: const BorderSide(color: GameColors.tileEdge),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('DEĞİŞTİR (${c.discardsLeft})'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: c.hintsLeft > 0 ? c.useSoftHint : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GameColors.muted,
                      side: const BorderSide(color: GameColors.tileEdge),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('İPUCU (${c.hintsLeft})'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: GameColors.brand,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: c.playWord,
              child: Text(
                'OYNA  ·  ${c.handsLeft} hak',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: c.clearSelection,
                  child: const Text('Seçimi sil', style: TextStyle(fontSize: 13)),
                ),
                TextButton(
                  onPressed: c.sortHand,
                  child: const Text('Sırala', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopView extends StatelessWidget {
  const _ShopView({required this.controller, required this.onInspect});

  final GameController controller;
  final void Function(JokerCard) onInspect;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mağaza · Altın ${controller.gold}'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Joker al (max $kMaxJokerSlots). Slot doluysa en ucuzu satılır.',
              style: const TextStyle(color: GameColors.muted),
            ),
            if (controller.lastGoldEarned > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Seviye ödülü: +${controller.lastGoldEarned} altın'
                '${controller.lastEfficiencyBonus > 0 ? ' · verim +${controller.lastEfficiencyBonus}' : ''}',
                style: const TextStyle(color: GameColors.barFill),
              ),
            ],
            if (controller.upcomingBossPreview != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A2418),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Sıradaki boss: ${controller.upcomingBossPreview!.name}\n'
                  '${controller.upcomingBossPreview!.description}',
                  style: const TextStyle(color: Color(0xFFFFE0C2)),
                ),
              ),
            ],
            if (controller.ownedJokers.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Jokerlerin (dokun: sat)',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: controller.ownedJokers
                    .map(
                      (j) => GestureDetector(
                        onLongPress: () => onInspect(j),
                        child: ActionChip(
                          label: Text(j.name),
                          onPressed: () => controller.sellJoker(j),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            ...controller.shopOffers.map(
              (j) => Card(
                color: GameColors.tile,
                child: ListTile(
                  title: Text(j.name),
                  subtitle: Text(j.description),
                  trailing: Text(
                    '${j.cost} altın',
                    style: TextStyle(
                      color: controller.gold >= j.cost
                          ? GameColors.barFill
                          : GameColors.danger,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onTap: () => controller.buyJoker(j),
                  onLongPress: () => onInspect(j),
                ),
              ),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: controller.shopRerollsLeft > 0 &&
                      controller.gold >= kShopRerollCost
                  ? controller.rerollShop
                  : null,
              child: Text(
                'Yenile (${controller.shopRerollsLeft}) · $kShopRerollCost altın',
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: GameColors.brand),
              onPressed: controller.skipShop,
              child: const Text('Devam et'),
            ),
          ],
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
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                won ? 'BİTTİ — KAZANDIN' : 'KOŞU BİTTİ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: won ? GameColors.barFill : GameColors.danger,
                ),
              ),
              const SizedBox(height: 8),
              Text(controller.message, textAlign: TextAlign.center),
              if (!won) ...[
                const SizedBox(height: 16),
                Text(
                  'Seviye ${controller.level} · $gap puan eksik',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: GameColors.muted),
                ),
                if (controller.bestWordPlayed != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'En iyi kelime: ${controller.bestWordPlayed} '
                      '(+${controller.bestWordScore})',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: GameColors.barFill,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              if (won && !controller.endless) ...[
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: GameColors.brand,
                  ),
                  onPressed: controller.enterEndless,
                  child: const Text('DEVAM ET (endless)'),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton(
                onPressed: () =>
                    controller.startNewRun(runMode: controller.mode),
                child: const Text('Yeniden oyna'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Ana ekran'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
