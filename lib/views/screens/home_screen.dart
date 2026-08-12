import 'package:flutter/material.dart';

import '../../game/adventure_levels.dart';
import '../../game/game_controller.dart';
import '../../services/ads_controller.dart';
import '../../services/purchase_controller.dart';
import '../../services/sound_controller.dart';
import '../theme/game_colors.dart';
import '../theme/game_theme.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/mode_icons.dart';
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

  void _playClassic(BuildContext context) {
    controller.startClassic();
    Navigator.of(context).pushNamed('/play');
  }

  void _openAdventureMap(BuildContext context) {
    Navigator.of(context).pushNamed('/adventure-map');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, adsController, purchaseController]),
      builder: (context, _) {
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

        final nextAdventureLevel =
            (controller.stats.adventureHighestCleared + 1)
                .clamp(1, kAdventureLevelCount);
        final adventureSubtitle = controller.stats.adventureHighestCleared > 0
            ? 'Seviye $nextAdventureLevel / $kAdventureLevelCount'
            : 'Kuleye ilk adım · $kAdventureLevelCount seviye';
        final classicSubtitle = controller.stats.classicHighScore > 0
            ? 'Rekor ${controller.stats.classicHighScore}'
            : 'Sınırsız kelime · sonsuz puan';

        return Scaffold(
          body: TableSurface(
            child: SafeArea(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Flexible(
                          flex: 3,
                          child: Center(
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
                              child: const Text(
                                'KELİME\nBAHİS',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: GameFonts.display,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w700,
                                  height: 0.98,
                                  letterSpacing: -1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          flex: 5,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _ModeButton(
                                  title: 'MACERA',
                                  subtitle: adventureSubtitle,
                                  icon: const TowerIcon(),
                                  onTap: () => _openAdventureMap(context),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Expanded(
                                child: _ModeButton(
                                  title: 'KLASİK',
                                  subtitle: classicSubtitle,
                                  icon: const TileStackIcon(),
                                  onTap: () => _playClassic(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (purchaseController.canPurchase)
                          Align(
                            alignment: Alignment.center,
                            child: TextButton(
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
                          ),
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

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: GameColors.surfaceHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GameColors.brass.withValues(alpha: 0.5)),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                icon,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: GameFonts.display,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: GameColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: GameFonts.mono,
                          fontSize: 11.5,
                          letterSpacing: 0.4,
                          color: GameColors.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: GameColors.outline, size: 26),
              ],
            ),
          ),
        ),
      ),
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
