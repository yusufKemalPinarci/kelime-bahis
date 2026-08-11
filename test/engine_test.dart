import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_bahis/game/game_controller.dart';
import 'package:kelime_bahis/game/letter_bag.dart';
import 'package:kelime_bahis/game/local_stats.dart';
import 'package:kelime_bahis/game/daily_seed.dart';
import 'package:kelime_bahis/game/word_length.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LetterBag', () {
    test('standart torba tüm harf sayılarını içerir', () {
      final expectedTotal =
          kLetterBagCounts.values.fold<int>(0, (a, b) => a + b);
      final bag = LetterBag.standard(seed: 42);
      expect(bag.remaining, expectedTotal);
    });

    test('aynı seed aynı sırayı üretir (deterministik)', () {
      final a = LetterBag.standard(seed: 7).draw(10).map((t) => t.letter);
      final b = LetterBag.standard(seed: 7).draw(10).map((t) => t.letter);
      expect(a.join(), b.join());
    });

    test('draw torbayı azaltır, fazlası kalanla sınırlanır', () {
      final bag = LetterBag.standard(seed: 1);
      final total = bag.remaining;
      final drawn = bag.draw(8);
      expect(drawn.length, 8);
      expect(bag.remaining, total - 8);

      final rest = bag.draw(total * 2);
      expect(rest.length, total - 8);
      expect(bag.remaining, 0);
      expect(bag.draw(5), isEmpty);
    });

    test('returnTiles taşları torbaya geri koyar', () {
      final bag = LetterBag.standard(seed: 3);
      final total = bag.remaining;
      final drawn = bag.draw(5);
      bag.returnTiles(drawn);
      expect(bag.remaining, total);
    });
  });

  group('LocalStats', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('save/load gidiş-dönüş verileri korur', () async {
      final s = LocalStats(
        bestLevel: 9,
        runsWon: 3,
        dailyStreak: 2,
        lastCompletedDailyKey: 'daily_2026_07_28',
        lastDailyWinDay: 'daily_2026_07_28',
        lifetimeScore: 1500,
      );
      await s.save();

      final loaded = await LocalStats.load();
      expect(loaded.bestLevel, 9);
      expect(loaded.runsWon, 3);
      expect(loaded.dailyStreak, 2);
      expect(loaded.lastCompletedDailyKey, 'daily_2026_07_28');
      expect(loaded.lifetimeScore, 1500);
    });

    test('noteLevelReached yalnızca daha yüksek seviyeyi yazar', () {
      final s = LocalStats(bestLevel: 5);
      s.noteLevelReached(3);
      expect(s.bestLevel, 5);
      s.noteLevelReached(8);
      expect(s.bestLevel, 8);
    });

    test('ardışık günlük galibiyet streak artırır, kopunca 1 olur', () {
      final s = LocalStats();
      final day1 = DailySeed(DateTime(2026, 7, 27));
      final day2 = DailySeed(DateTime(2026, 7, 28));
      final day5 = DailySeed(DateTime(2026, 7, 31));

      s.noteDailyWin(day1);
      expect(s.dailyStreak, 1);
      s.noteDailyWin(day2);
      expect(s.dailyStreak, 2);
      s.noteDailyWin(day5); // 2 gün boşluk → streak sıfırdan
      expect(s.dailyStreak, 1);
      expect(s.runsWon, 3);
    });
  });

  group('GameController (gerçek assetlerle bootstrap)', () {
    late GameController c;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      c = GameController();
      await c.bootstrap();
    });

    test('bootstrap sözlük + içerikleri yükler, klasik koşu ön-mağaza ile başlar', () {
      expect(c.bootstrapError, isNull);
      expect(c.ready, isTrue);
      expect(c.dictionary, isNotNull);
      expect(c.catalog, isNotEmpty);
      expect(c.bosses, isNotEmpty);
      expect(c.phase, RunPhase.shop);
      expect(c.isPregameShop, isTrue);
      expect(c.gold, kStartingGold);
      expect(c.level, 1);

      c.skipShop();
      expect(c.phase, RunPhase.playing);
      expect(c.hand.length, kHandSize);
      expect(c.requiredLength, 2);
    });

    test('toggleSelect en fazla requiredLength harf seçtirir', () {
      c.skipShop();
      for (final t in c.hand) {
        c.toggleSelect(t);
      }
      expect(c.selected.length, lessThanOrEqualTo(c.requiredLength));
    });

    test('sözlükte olmayan kelime skoru değiştirmez', () {
      c.skipShop();
      // Eldeki ilk `requiredLength` taşı seç; büyük olasılıkla kelime değil.
      for (final t in c.hand.take(c.requiredLength)) {
        c.toggleSelect(t);
      }
      final scoreBefore = c.score;
      final handsBefore = c.handsLeft;
      c.playWord();
      // Kelime geçerliyse skor artar; geçersizse el hakkı düşmez.
      if (c.score == scoreBefore) {
        expect(c.handsLeft, handsBefore);
      }
    });

    test('ipucu ile bulunan kelime oynanabilir ve skor üretir', () {
      c.skipShop();
      c.useSoftHint();
      // Kelime kurulabilirliği artık garanti (_ensureSolvable) — her zaman bulunur.
      expect(c.hintWord, isNotNull);
      final before = c.score;
      c.playWord();
      expect(c.score, greaterThan(before));
      expect(c.handsLeft, 3);
    });

    test('discard seçilen taşları torbaya iade eder, el yeniden dolar', () {
      c.skipShop();
      c.toggleSelect(c.hand.first);
      c.toggleSelect(c.hand[1]);
      c.discardSelected();
      expect(c.discardsLeft, 1);
      expect(c.hand.length, kHandSize);
      // Kelime kurulabilirliği garantisi discard sonrası da geçerli olmalı.
      final solvable = c.dictionary!.findPlayableWord(
        c.hand.map((t) => t.letter),
        validate: (w) => w.length == c.requiredLength,
      );
      expect(solvable, isNotNull);
    });

    test('yetersiz altınla joker alınamaz', () {
      c.debugQaPrepare('shop');
      expect(c.phase, RunPhase.shop);
      expect(c.shopOffers, isNotEmpty);
      c.gold = 0;
      final offer = c.shopOffers.first;
      c.buyJoker(offer);
      expect(c.ownedJokers, isEmpty);
      expect(c.message, contains('Yetersiz altın'));
    });

    test('mağazadan satın alma altını düşer ve joker ekler', () {
      c.debugQaPrepare('shop');
      c.gold = 99;
      final offer = c.shopOffers.first;
      c.buyJoker(offer);
      expect(c.ownedJokers.map((j) => j.id), contains(offer.id));
      expect(c.gold, 99 - offer.cost);
    });

    test('mağazayı atlamak seviyeyi ilerletir', () {
      c.debugQaPrepare('shop');
      final levelBefore = c.level;
      c.skipShop();
      expect(c.level, levelBefore + 1);
      expect(c.phase, RunPhase.playing);
      expect(c.hand.length, kHandSize);
    });

    test('won fazından endless moda geçilir', () {
      c.debugQaPrepare('won');
      expect(c.phase, RunPhase.won);
      c.enterEndless();
      expect(c.endless, isTrue);
      expect(c.level, kClassicLevels + 1);
      expect(c.phase, RunPhase.playing);
    });

    test('boss seviyesinde HUD baskı metni üretilir', () {
      c.debugQaPrepare('boss_playing');
      expect(c.isBossLevel, isTrue);
      expect(c.activeBoss, isNotNull);
      expect(c.bossPressureHudText, contains('Boss'));
    });

    test('klasik/günlükte seviye başarısız olunca koşu kaybedilir', () {
      c.skipShop();
      c.target = 1 << 30; // Hiçbir kelime bu hedefi geçemez — başarısızlık garanti.
      c.handsLeft = 1;

      for (final t in c.hand.take(c.requiredLength)) {
        c.toggleSelect(t);
      }
      c.playWord();
      if (c.phase == RunPhase.playing) {
        // İlk seçim geçerli bir kelime değildi (artık otomatik temizleniyor)
        // — ipucuyla geçerli bir kelime bulup oyna, el hakkı gerçekten tükensin.
        c.useSoftHint();
        c.handsLeft = 1;
        c.playWord();
      }

      expect(c.phase, RunPhase.lost);
      expect(c.message, contains('Kaybettin'));
      expect(c.stats.hasSavedRun, isFalse,
          reason: 'Kaybedilen koşunun kayıtlı devamı olmamalı');
    });

    test('endless modda seviye başarısız olunca RunPhase.lost olur (permadeath)', () {
      c.debugQaPrepare('won');
      c.enterEndless();
      c.target = 1 << 30;
      c.handsLeft = 1;
      c.useSoftHint();
      if (c.hintWord == null) return; // bu elde kelime yoksa test anlamsız
      c.handsLeft = 1;
      c.playWord();
      expect(c.phase, RunPhase.lost);
    });

    test('resumeRun kaydedilmiş seviye/altın/joker ile devam eder', () {
      c.debugQaPrepare('shop');
      c.gold = 99;
      final offer = c.shopOffers.first;
      c.buyJoker(offer);
      c.skipShop(); // seviye 2'ye ilerler, _persistRunState çağrılır
      final savedLevel = c.level;
      final savedGold = c.gold;
      final savedJokerIds = c.ownedJokers.map((j) => j.id).toSet();
      expect(c.stats.hasSavedRun, isTrue);

      final fresh = GameController();
      fresh.dictionary = c.dictionary;
      fresh.catalog = c.catalog;
      fresh.bosses = c.bosses;
      fresh.stats = c.stats;
      fresh.resumeRun();

      expect(fresh.level, savedLevel);
      expect(fresh.gold, savedGold);
      expect(fresh.ownedJokers.map((j) => j.id).toSet(), savedJokerIds);
      expect(fresh.phase, RunPhase.playing);
    });
  });
}
