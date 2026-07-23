import 'package:flutter/material.dart';

import 'game/game_controller.dart';
import 'views/screens/game_screen.dart';
import 'views/screens/home_screen.dart';
import 'views/theme/game_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = GameController();
  await controller.bootstrap();
  runApp(KelimeBahisApp(controller: controller));
}

class KelimeBahisApp extends StatelessWidget {
  const KelimeBahisApp({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: GameColors.brand,
        brightness: Brightness.dark,
        surface: GameColors.bgTop,
      ),
      scaffoldBackgroundColor: GameColors.bgBottom,
      fontFamily: 'Segoe UI',
    );

    return MaterialApp(
      title: 'Kelime Bahis',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: base.textTheme.apply(
          bodyColor: GameColors.ink,
          displayColor: GameColors.ink,
        ),
      ),
      home: HomeScreen(controller: controller),
      routes: {
        '/play': (_) => GameScreen(controller: controller),
      },
    );
  }
}
