import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import '../theme/game_colors.dart';
import '../widgets/letter_tile_chip.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  GameController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(_onUpdate);
  }

  @override
  void dispose() {
    c.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (c.phase == RunPhase.starter) {
      return _StarterView(controller: c);
    }
    if (c.phase == RunPhase.shop) {
      return _ShopView(controller: c);
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

    return Scaffold(
      backgroundColor: GameColors.bgBottom,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '5 harfli Türkçe kelime kur · hedefi geç',
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
            Text(
              '${c.score} / ${c.target} puan',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: GameColors.ink,
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
            if (c.ownedJokers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: c.ownedJokers
                    .map(
                      (j) => Chip(
                        label: Text(j.name, style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: GameColors.tile,
                        side: const BorderSide(color: GameColors.tileEdge),
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
                fontSize: 44,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: GameColors.tileSelected,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              preview == null
                  ? (c.selectedWord.isEmpty
                      ? 'Harflere dokun'
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

class _StarterView extends StatelessWidget {
  const _StarterView({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Joker seç (isteğe bağlı)'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...controller.starterOffers.map(
              (j) => Card(
                color: GameColors.tile,
                child: ListTile(
                  title: Text(j.name),
                  subtitle: Text(j.description),
                  onTap: () => controller.pickStarter(j),
                ),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => controller.pickStarter(null),
              child: const Text('Atla, direkt oyna'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopView extends StatelessWidget {
  const _ShopView({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mağaza — bir joker al'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Joker skorunu güçlendirir. Beğenmezsen geç.',
              style: TextStyle(color: GameColors.muted),
            ),
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
            if (controller.lastEfficiencyBonus > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Hızlı bitirme bonusu: +${controller.lastEfficiencyBonus}',
                style: const TextStyle(color: GameColors.barFill),
              ),
            ],
            const SizedBox(height: 16),
            ...controller.shopOffers.map(
              (j) => Card(
                color: GameColors.tile,
                child: ListTile(
                  title: Text(j.name),
                  subtitle: Text(j.description),
                  trailing: const Icon(Icons.add),
                  onTap: () => controller.advanceAfterShop(j),
                ),
              ),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed:
                  controller.shopRerollsLeft > 0 ? controller.rerollShop : null,
              child: Text('Yenile (${controller.shopRerollsLeft})'),
            ),
            TextButton(
              onPressed: () => controller.advanceAfterShop(null),
              child: const Text('Geç'),
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
