import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_bahis/game/game_controller.dart';
import 'package:kelime_bahis/main.dart';
import 'package:kelime_bahis/services/ads_controller.dart';
import 'package:kelime_bahis/services/purchase_controller.dart';
import 'package:kelime_bahis/services/sound_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ana ekran markayı gösterir', (tester) async {
    final controller = GameController();
    // Skip asset bootstrap; dictionary null until loaded — home still renders.
    // AdsController/PurchaseController/SoundController kasıtlı olarak init()
    // edilmiyor — testte gerçek platform kanalına (AdMob/Play Billing/ses)
    // dokunulmasın.
    await tester.pumpWidget(KelimeBahisApp(
      controller: controller,
      adsController: AdsController(),
      purchaseController: PurchaseController(),
      soundController: SoundController(),
    ));
    expect(find.text('KELİME\nBAHİS'), findsOneWidget);
    expect(find.text('OYNA'), findsOneWidget);
  });
}
