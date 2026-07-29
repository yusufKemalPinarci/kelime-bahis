import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import '../theme/game_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final GameController controller;

  void _play(BuildContext context, RunMode mode) {
    controller.startNewRun(runMode: mode);
    Navigator.of(context).pushNamed('/play');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final dailyDone = !controller.dailyAvailableToday;
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [GameColors.bgTop, GameColors.bgBottom],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KELİME\nBAHİS',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 68,
                            height: 0.92,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: GameColors.ink,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '8 harflik elden 2–8 harfli Türkçe kelime kur.\n'
                      'Uzun kelime daha çok puan · joker topla.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: GameColors.muted,
                            height: 1.45,
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A221C),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF3A4A40)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nasıl oynanır?',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: GameColors.ink,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '1. Elinden 2–8 harf seç (sürükleyerek sırala)\n'
                            '2. Türkçe kelime kur — uzun = daha çok puan\n'
                            '3. OYNA → hedefi geç → altınla joker al',
                            style: TextStyle(
                              color: GameColors.muted,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${controller.dictionary?.size ?? 0} Türkçe kelime · '
                      'rekor seviye ${controller.stats.bestLevel}',
                      style: const TextStyle(color: GameColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: GameColors.brand,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _play(context, RunMode.classic),
                        child: const Text(
                          'OYNA',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: dailyDone
                            ? null
                            : () => _play(context, RunMode.daily),
                        child: Text(
                          dailyDone
                              ? 'Günlük tamam · ${controller.dailyLabel}'
                              : 'Günlük meydan okuma · ${controller.dailyLabel}',
                          style: const TextStyle(color: GameColors.muted),
                        ),
                      ),
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
