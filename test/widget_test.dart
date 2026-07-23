import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_bahis/game/game_controller.dart';
import 'package:kelime_bahis/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ana ekran markayı gösterir', (tester) async {
    final controller = GameController();
    // Skip asset bootstrap; dictionary null until loaded — home still renders.
    await tester.pumpWidget(KelimeBahisApp(controller: controller));
    expect(find.textContaining('KELİME'), findsOneWidget);
    expect(find.text('OYNA'), findsOneWidget);
  });
}
