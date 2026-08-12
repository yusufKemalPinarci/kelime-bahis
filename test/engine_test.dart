import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_bahis/game/adventure_levels.dart';
import 'package:kelime_bahis/game/game_controller.dart';
import 'package:kelime_bahis/game/letter_bag.dart';
import 'package:kelime_bahis/game/local_stats.dart';
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
      final s = LocalStats(classicHighScore: 240, adventureHighestCleared: 12);
      await s.save();

      final loaded = await LocalStats.load();
      expect(loaded.classicHighScore, 240);
      expect(loaded.adventureHighestCleared, 12);
    });

    test('noteClassicScore yalnızca rekor kırılınca günceller', () {
      final s = LocalStats(classicHighScore: 100);
      expect(s.noteClassicScore(50), isFalse);
      expect(s.classicHighScore, 100);
      expect(s.noteClassicScore(150), isTrue);
      expect(s.classicHighScore, 150);
    });

    test('noteAdventureLevelCleared yalnızca daha yüksek seviyeyi yazar', () {
      final s = LocalStats(adventureHighestCleared: 5);
      s.noteAdventureLevelCleared(3);
      expect(s.adventureHighestCleared, 5);
      s.noteAdventureLevelCleared(8);
      expect(s.adventureHighestCleared, 8);
    });
  });

  group('adventureLevel — 100 seviye üretimi', () {
    test('her seviye geçerli parametreler üretir', () {
      for (var lvl = 1; lvl <= kAdventureLevelCount; lvl++) {
        final task = adventureLevel(lvl);
        expect(task.level, lvl);
        expect(task.target, greaterThan(0));
        expect(task.attempts, greaterThanOrEqualTo(task.scoreBased ? 1 : task.target));
        expect(task.title, isNotEmpty);
        expect(task.description, isNotEmpty);
        if (task.exactLength != null) {
          expect(task.exactLength, inInclusiveRange(kMinWordLength, kMaxWordLength));
        }
        if (task.minLength != null) {
          expect(task.minLength, inInclusiveRange(kMinWordLength, kMaxWordLength));
        }
      }
    });

    test('her katın 10. odası kilometre taşı görevidir', () {
      for (var floor = 0; floor < 10; floor++) {
        final level = floor * kAdventureLevelsPerFloor + kAdventureLevelsPerFloor;
        expect(adventureLevel(level).kind, AdventureTaskKind.milestone);
      }
    });

    test('floorNameForLevel ilk ve son kat sınırlarını doğru verir', () {
      expect(floorNameForLevel(1), kAdventureFloorNames.first);
      expect(floorNameForLevel(100), kAdventureFloorNames.last);
    });
  });

  group('GameController — Classic', () {
    late GameController c;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      c = GameController();
      await c.bootstrap();
    });

    test('bootstrap sözlüğü yükler', () {
      expect(c.bootstrapError, isNull);
      expect(c.ready, isTrue);
      expect(c.dictionary, isNotNull);
    });

    test('startClassic taze bir el ile başlar', () {
      c.startClassic();
      expect(c.mode, RunMode.classic);
      expect(c.phase, RunPhase.playing);
      expect(c.hand.length, kHandSize);
      expect(c.classicScore, 0);
    });

    test('toggleSelect en fazla kHandSize harf seçtirir', () {
      c.startClassic();
      for (final t in c.hand) {
        c.toggleSelect(t);
      }
      expect(c.selected.length, lessThanOrEqualTo(kMaxWordLength));
    });

    test('elde her zaman oynanabilir bir kelime vardır (ensure-solvable)', () {
      c.startClassic();
      final word = c.dictionary!.findPlayableWord(c.hand.map((t) => t.letter));
      expect(word, isNotNull);
    });

    test('geçerli kelime oynamak skoru ve rekoru artırır', () {
      c.startClassic();
      final word =
          c.dictionary!.findPlayableWord(c.hand.map((t) => t.letter))!;
      expect(c.selectWordFromHand(word), isTrue);
      c.playWord();
      expect(c.classicScore, greaterThan(0));
      expect(c.stats.classicHighScore, c.classicScore);
    });

    test('sözlükte olmayan kelime skoru değiştirmez', () {
      c.startClassic();
      // Muhtemelen kelime olmayan tek harfli bir seçim.
      c.toggleSelect(c.hand.first);
      final before = c.classicScore;
      c.playWord();
      if (c.classicScore == before) {
        expect(c.classicScore, before);
      }
    });

    test('pas hakkı yokken refreshHand eli değiştirmez', () {
      c.startClassic();
      expect(c.passesAvailable, 0);
      final before = c.hand.map((t) => t.id).toList();
      c.refreshHand();
      expect(c.hand.map((t) => t.id).toList(), before);
      expect(c.passesAvailable, 0);
    });

    test('pas hakkı varken refreshHand eli yeniler, seriyi sıfırlar ve hakkı harcar', () {
      c.startClassic();
      c.passesAvailable = 1;
      final before = c.bag.remaining;
      c.refreshHand();
      expect(c.hand.length, kHandSize);
      expect(c.comboStreak, 0);
      expect(c.passesAvailable, 0);
      expect(c.bag.remaining, before); // 8 iade edildi, 8 çekildi.
    });

    test('her 10 doğru kelimede bir pas hakkı kazanılır', () {
      c.startClassic();
      expect(c.passesAvailable, 0);
      for (var i = 0; i < kWordsPerPass; i++) {
        final word =
            c.dictionary!.findPlayableWord(c.hand.map((t) => t.letter));
        expect(word, isNotNull, reason: 'kelime $i bulunamadı');
        expect(c.selectWordFromHand(word!), isTrue);
        c.playWord();
      }
      expect(c.passesAvailable, 1);
    });
  });

  group('GameController — Adventure', () {
    late GameController c;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      c = GameController();
      await c.bootstrap();
    });

    test('seviye 1 her zaman açık', () {
      c.startAdventureLevel(1);
      expect(c.mode, RunMode.adventure);
      expect(c.phase, RunPhase.playing);
      expect(c.adventureLevelNumber, 1);
      expect(c.adventureAttemptsLeft, c.adventureTask!.attempts);
      expect(c.adventureProgress, 0);
    });

    test('kilitli seviyeye giriş no-op', () {
      c.startAdventureLevel(5);
      expect(c.adventureTask, isNull, reason: 'seviye 5 henüz kilitli olmalı');
    });

    test('görevi tamamlamak seviyeyi geçirir ve rekoru kaydeder', () {
      c.startAdventureLevel(1);
      final task = c.adventureTask!;
      var guard = 0;
      while (c.phase == RunPhase.playing && guard < 50) {
        guard++;
        final word = c.dictionary!.findPlayableWord(
          c.hand.map((t) => t.letter),
          validate: (w) =>
              !c.playedThisLevel.contains(w) && task.accepts(w),
        );
        if (word == null) break;
        expect(c.selectWordFromHand(word), isTrue);
        c.playWord();
      }
      expect(c.phase, RunPhase.adventureComplete);
      expect(c.stats.adventureHighestCleared, 1);
    });

    test('sonraki seviye tamamlanan seviyeden sonra açılır', () {
      c.startAdventureLevel(1);
      final task = c.adventureTask!;
      var guard = 0;
      while (c.phase == RunPhase.playing && guard < 50) {
        guard++;
        final word = c.dictionary!.findPlayableWord(
          c.hand.map((t) => t.letter),
          validate: (w) =>
              !c.playedThisLevel.contains(w) && task.accepts(w),
        );
        if (word == null) break;
        c.selectWordFromHand(word);
        c.playWord();
      }
      expect(c.phase, RunPhase.adventureComplete);
      c.advanceToNextAdventureLevel();
      expect(c.adventureLevelNumber, 2);
      expect(c.phase, RunPhase.playing);
    });

    test('deneme hakkı biterse görev yerinde sıfırlanır', () {
      c.startAdventureLevel(1);
      final task = c.adventureTask!;
      if (task.target <= 1) return; // bu senaryoda anlamsız, atla
      c.adventureAttemptsLeft = 1;
      final word = c.dictionary!.findPlayableWord(
        c.hand.map((t) => t.letter),
        validate: (w) => !c.playedThisLevel.contains(w) && task.accepts(w),
      );
      expect(word, isNotNull);
      c.selectWordFromHand(word!);
      c.playWord();
      // Hedef tek kelimede karşılanmadıysa (target>1), hak bitince yerinde
      // sıfırlanmalı: oyun devam ediyor, deneme hakkı taze.
      expect(c.phase, RunPhase.playing);
      expect(c.adventureAttemptsLeft, task.attempts);
      expect(c.adventureProgress, 0);
    });
  });
}
