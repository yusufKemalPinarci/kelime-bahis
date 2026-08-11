import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import '../../services/ads_controller.dart';
import '../../services/purchase_controller.dart';
import '../../services/sound_controller.dart';
import '../theme/game_colors.dart';
import '../theme/game_theme.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/gold_chip.dart';
import '../widgets/letterpress_button.dart';
import '../widgets/rank_badge.dart';
import '../widgets/table_surface.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.adsController,
    required this.purchaseController,
    required this.soundController,
  });

  final GameController controller;
  final AdsController adsController;
  final PurchaseController purchaseController;
  final SoundController soundController;

  void _play(BuildContext context, RunMode mode) {
    controller.startNewRun(runMode: mode);
    Navigator.of(context).pushNamed('/play');
  }

  void _resume(BuildContext context) {
    controller.resumeRun();
    Navigator.of(context).pushNamed('/play');
  }

  bool get _saveIsClassic =>
      controller.stats.hasSavedRun && controller.stats.savedRunMode == 'classic';

  bool get _saveIsDaily =>
      controller.stats.hasSavedRun && controller.stats.savedRunMode == 'daily';

  /// Farklı modda taze başlarken, varsa mevcut kaydı silmeden önce onay alır.
  Future<void> _startFresh(BuildContext context, RunMode mode) async {
    if (controller.stats.hasSavedRun) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: GameColors.surfaceLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text(
            'Yeni koşu başlat?',
            style: TextStyle(
              fontFamily: GameFonts.display,
              fontWeight: FontWeight.w700,
              color: GameColors.ink,
            ),
          ),
          content: const Text(
            'Yarım kalan koşun silinecek.',
            style: TextStyle(color: GameColors.inkMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç', style: TextStyle(color: GameColors.outline)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yeni koşu', style: TextStyle(color: GameColors.brand)),
            ),
          ],
        ),
      );
      if (discard != true) return;
      controller.stats.clearSavedRun();
    }
    if (context.mounted) _play(context, mode);
  }

  void _qaJump(BuildContext context, String scene) {
    if (!kDebugMode) return;
    controller.debugQaPrepare(scene);
    Navigator.of(context).pushNamed('/play');
  }

  void _showQaSheet(BuildContext context) {
    if (!kDebugMode) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: GameColors.surfaceLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'QA screenshot atlama',
                style: TextStyle(
                  fontFamily: GameFonts.display,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ListTile(
              title: const Text('Mağaza (L1)'),
              onTap: () {
                Navigator.pop(ctx);
                _qaJump(context, 'shop');
              },
            ),
            ListTile(
              title: const Text('Boss mağaza diyaloğu'),
              onTap: () {
                Navigator.pop(ctx);
                _qaJump(context, 'boss_shop');
              },
            ),
            ListTile(
              title: const Text('Boss playing'),
              onTap: () {
                Navigator.pop(ctx);
                _qaJump(context, 'boss_playing');
              },
            ),
            ListTile(
              title: const Text('Kazandı'),
              onTap: () {
                Navigator.pop(ctx);
                _qaJump(context, 'won');
              },
            ),
            ListTile(
              title: const Text('Kaybetti'),
              onTap: () {
                Navigator.pop(ctx);
                _qaJump(context, 'lost');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, adsController, purchaseController]),
      builder: (context, _) {
        final dailyDone = !controller.dailyAvailableToday;
        final purchaseError = purchaseController.lastErrorMessage;
        if (purchaseError != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(purchaseError)));
            purchaseController.clearLastError();
          });
        }
        return Scaffold(
          body: TableSurface(
            child: SafeArea(
              child: Stack(
                children: [
                  Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 36),
                            GestureDetector(
                              onLongPress: kDebugMode
                                  ? () => _showQaSheet(context)
                                  : null,
                              child: ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFFBF953F),
                                    Color(0xFFFCF6BA),
                                    Color(0xFFB38728),
                                    Color(0xFFFBF5B7),
                                    Color(0xFFAA771C),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: Text(
                                  'KELİME\nBAHİS',
                                  textAlign: TextAlign.center,
                                  strutStyle: const StrutStyle(
                                    fontSize: 52,
                                    height: 0.95,
                                    forceStrutHeight: true,
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(
                                        fontSize: 52,
                                        height: 0.95,
                                        letterSpacing: -1,
                                        fontFamilyFallback: const [
                                          GameFonts.body,
                                        ],
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: 120,
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    GameColors.gold.withValues(alpha: 0.5),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 36),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: const [
                                _DemoTile('K', 5, -2),
                                _DemoTile('E', 1, 1),
                                _DemoTile('L', 1, -1),
                                _DemoTile('İ', 1, 2),
                                _DemoTile('M', 2, -2),
                                _DemoTile('E', 1, 1),
                              ],
                            ),
                            const SizedBox(height: 28),
                            const _PlayLoopHint(),
                          ],
                        ),
                      ),
                    ),
                    RankBadge(lifetimeScore: controller.stats.lifetimeScore),
                    const SizedBox(height: 10),
                    Text(
                      '${controller.dictionary?.size ?? 0} kelime · '
                      'rekor seviye ${controller.stats.bestLevel}',
                      style: const TextStyle(
                        fontFamily: GameFonts.mono,
                        fontSize: 11,
                        letterSpacing: 0.8,
                        color: GameColors.outline,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LetterpressButton(
                      label: _saveIsClassic
                          ? 'Seviye ${controller.stats.savedRunLevel}'
                          : 'OYNA',
                      onPressed: () => _saveIsClassic
                          ? _resume(context)
                          : _startFresh(context, RunMode.classic),
                    ),
                    if (_saveIsClassic) ...[
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => _startFresh(context, RunMode.classic),
                        child: const Text(
                          'Yeni koşu başlat',
                          style: TextStyle(
                            fontFamily: GameFonts.mono,
                            fontSize: 11,
                            color: GameColors.outline,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    BrassOutlinedButton(
                      label: _saveIsDaily
                          ? 'Günlük · devam et (Seviye ${controller.stats.savedRunLevel})'
                          : dailyDone
                              ? 'Günlük tamam · ${controller.dailyLabel}'
                              : 'Günlük · ${controller.dailyLabel}',
                      onPressed: _saveIsDaily
                          ? () => _resume(context)
                          : dailyDone
                              ? null
                              : () => _startFresh(context, RunMode.daily),
                    ),
                    if (purchaseController.canPurchase) ...[
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: purchaseController.purchasePending
                            ? null
                            : purchaseController.buyRemoveAds,
                        child: Text(
                          purchaseController.purchasePending
                              ? 'İşleniyor…'
                              : 'Reklamları kaldır'
                                  '${purchaseController.removeAdsPriceLabel != null ? ' · ${purchaseController.removeAdsPriceLabel}' : ''}',
                          style: const TextStyle(
                            fontFamily: GameFonts.mono,
                            fontSize: 11,
                            letterSpacing: 0.6,
                            color: GameColors.outline,
                          ),
                        ),
                      ),
                    ],
                    BannerAdSlot(adsController: adsController),
                  ],
                ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _SoundToggleButton(soundController: soundController),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Sağ üstte her zaman görünen ses aç/kapa tutamacı.
class _SoundToggleButton extends StatefulWidget {
  const _SoundToggleButton({required this.soundController});

  final SoundController soundController;

  @override
  State<_SoundToggleButton> createState() => _SoundToggleButtonState();
}

class _SoundToggleButtonState extends State<_SoundToggleButton> {
  @override
  Widget build(BuildContext context) {
    final enabled = widget.soundController.enabled;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () async {
          await widget.soundController.toggleEnabled();
          if (mounted) setState(() {});
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GameColors.surfaceHigh,
            border: Border.all(color: GameColors.outlineVariant),
          ),
          child: Icon(
            enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            size: 18,
            color: GameColors.inkMuted,
          ),
        ),
      ),
    );
  }
}

/// Silent loop: word → gold → bonus. No numbered tutorial.
class _PlayLoopHint extends StatelessWidget {
  const _PlayLoopHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _LoopNode(label: 'KELİME', child: _MiniWord()),
        _Arrow(),
        const _LoopNode(
          label: 'ALTIN',
          child: GoldChip(amount: 5),
        ),
        _Arrow(),
        const _LoopNode(label: 'BONUS', child: _MiniBonus()),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '›',
        style: TextStyle(
          fontFamily: GameFonts.display,
          fontSize: 22,
          color: GameColors.outline.withValues(alpha: 0.7),
          height: 1,
        ),
      ),
    );
  }
}

class _LoopNode extends StatelessWidget {
  const _LoopNode({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        child,
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: GameFonts.mono,
            fontSize: 9,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
            color: GameColors.outline,
          ),
        ),
      ],
    );
  }
}

class _MiniWord extends StatelessWidget {
  const _MiniWord();

  @override
  Widget build(BuildContext context) {
    return Text(
      'KELİME',
      style: TextStyle(
        fontFamily: GameFonts.display,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: GameColors.gold.withValues(alpha: 0.9),
      ),
    );
  }
}

class _MiniBonus extends StatelessWidget {
  const _MiniBonus();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 36,
      decoration: BoxDecoration(
        color: GameColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: GameColors.brass.withValues(alpha: 0.55),
        ),
      ),
      alignment: Alignment.center,
      child: const Text(
        '×2',
        style: TextStyle(
          fontFamily: GameFonts.display,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: GameColors.ink,
        ),
      ),
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile(this.letter, this.points, this.tilt);

  final String letter;
  final int points;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tilt * 0.0174533,
      child: Container(
        width: 48,
        height: 58,
        decoration: BoxDecoration(
          color: GameColors.tile,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                letter,
                style: const TextStyle(
                  fontFamily: GameFonts.display,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: GameColors.tileInk,
                ),
              ),
            ),
            Positioned(
              right: 4,
              bottom: 3,
              child: Text(
                '$points',
                style: TextStyle(
                  fontFamily: GameFonts.body,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: GameColors.tileInk.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
