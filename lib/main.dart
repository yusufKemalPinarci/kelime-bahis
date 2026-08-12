import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'game/game_controller.dart';
import 'services/ads_controller.dart';
import 'services/purchase_controller.dart';
import 'services/sound_controller.dart';
import 'views/screens/adventure_map_screen.dart';
import 'views/screens/game_screen.dart';
import 'views/screens/home_screen.dart';
import 'views/theme/game_colors.dart';
import 'views/theme/game_theme.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Native splash bootstrap bitene kadar kalsın.
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  final controller = GameController();
  try {
    await controller.bootstrap();
  } catch (e) {
    // Beklenmedik hata: hata ekranı gösterilecek, splash'te takılı kalma.
    controller.bootstrapError ??= 'Başlatma hatası: $e';
  } finally {
    FlutterNativeSplash.remove();
  }

  final adsController = AdsController();
  final purchaseController = PurchaseController(
    onAdsRemovedChanged: adsController.setAdsRemoved,
  );
  final soundController = SoundController();
  // Reklam/mağaza ağ çağrıları ve ses yükleme arka planda başlar — açılışı bloklamaz.
  unawaited(purchaseController.init().then((_) => adsController.init()));
  unawaited(soundController.init());

  runApp(KelimeBahisApp(
    controller: controller,
    adsController: adsController,
    purchaseController: purchaseController,
    soundController: soundController,
  ));
}

class KelimeBahisApp extends StatelessWidget {
  const KelimeBahisApp({
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kelime Bahis',
      debugShowCheckedModeBanner: false,
      theme: buildGameTheme(),
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.bootstrapError != null) {
            return BootstrapErrorScreen(controller: controller);
          }
          return HomeScreen(
            controller: controller,
            adsController: adsController,
            purchaseController: purchaseController,
            soundController: soundController,
          );
        },
      ),
      routes: {
        '/adventure-map': (_) => AdventureMapScreen(controller: controller),
        '/play': (_) => GameScreen(
              controller: controller,
              soundController: soundController,
            ),
      },
    );
  }
}

/// Bootstrap (sözlük/asset) hatasında gösterilen ekran; tekrar dener.
class BootstrapErrorScreen extends StatelessWidget {
  const BootstrapErrorScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: GameColors.gold),
              const SizedBox(height: 16),
              Text(
                'Oyun başlatılamadı',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                controller.bootstrapError ?? 'Bilinmeyen hata.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => controller.bootstrap(),
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
