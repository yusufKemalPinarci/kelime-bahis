import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_bahis/crew/kelime_crew.dart';
import 'package:kelime_bahis/game/daily_seed.dart';
import 'package:kelime_bahis/game/game_controller.dart';
import 'package:kelime_bahis/game/scoring.dart';
import 'package:kelime_bahis/game/turkish.dart';
import 'package:kelime_bahis/game/word_dictionary.dart';
import 'package:kelime_bahis/game/word_length.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sözlük 2–8 harfli kelimeyi tutar', () {
    final d = WordDictionary([
      'elma',
      'armut',
      'kitap',
      'kalem',
      'ev',
      'çay',
      'kısa',
      'x',
    ]);
    expect(d.contains('kitap'), isTrue);
    expect(d.contains('kalem'), isTrue);
    expect(d.contains('elma'), isTrue);
    expect(d.contains('çay'), isTrue);
    expect(d.contains('kısa'), isTrue);
    expect(d.contains('ev'), isTrue);
    expect(d.contains('x'), isFalse);
    expect(d.contains('xyzab'), isFalse);
    expect(d.size, 7);
  });

  test('uzunluk çarpanı kısa kelimeyi cezalandırır', () {
    expect(lengthMultiplier(3), 0.85);
    expect(lengthMultiplier(8), greaterThan(lengthMultiplier(5)));
    // Uzunluk çarpanı artık ayrı bir metin notu olarak gösterilmiyor —
    // etkisini skor kırılımının `multiplier` alanından doğrula.
    final short = scoreWord(word: 'çay', jokers: const []);
    expect(short.multiplier, lengthMultiplier(3));
    final eight = scoreWord(word: 'okulları', jokers: const []);
    expect(eight.multiplier, lengthMultiplier(8));
    expect(lengthMultiplier(8), greaterThan(lengthMultiplier(3)));
  });

  test('comboMultiplier seri arttıkça büyür', () {
    expect(comboMultiplier(1), 1.0);
    expect(comboMultiplier(2), closeTo(1.15, 1e-9));
    expect(comboMultiplier(3), closeTo(1.30, 1e-9));
    expect(comboMultiplier(4), closeTo(1.45, 1e-9));
  });

  test('scoreWord comboStreak arttıkça skoru artırır', () {
    final noCombo = scoreWord(word: 'kalem', jokers: const [], comboStreak: 1);
    final withCombo =
        scoreWord(word: 'kalem', jokers: const [], comboStreak: 3);
    // Seri çarpanı artık ayrı bir metin notu olarak gösterilmiyor (rozette
    // görünüyor) — etkisini `multiplier` alanı ve toplam skordan doğrula.
    expect(noCombo.multiplier, 1.0);
    expect(withCombo.multiplier, closeTo(comboMultiplier(3), 1e-9));
    expect(withCombo.total, greaterThan(noCombo.total));
  });

  test('Türkçe büyük harf ı/i ayırır', () {
    expect(toUpperTr('kısa'), 'KISA');
    expect(toUpperTr('kisi'), 'KİSİ');
    expect(normalizeTr('KISA'), 'kısa');
    expect(normalizeTr('KİSİ'), 'kisi');
  });

  test('skor joker ile artar', () {
    final plain = scoreWord(word: 'kalem', jokers: const []);
    final boosted = scoreWord(
      word: 'kalem',
      jokers: const [
        JokerCard(
          id: 'n',
          name: 'Nokta',
          description: '',
          kind: JokerKind.flatBonus,
          value: 5,
        ),
      ],
    );
    expect(boosted.total, greaterThan(plain.total));
  });

  test('nadir harf jokerı çalışır', () {
    final plain = scoreWord(word: 'şeker', jokers: const []);
    final rare = scoreWord(
      word: 'şeker',
      jokers: const [
        JokerCard(
          id: 'r',
          name: 'Nadir',
          description: '',
          kind: JokerKind.rareLetterBonus,
          value: 6,
        ),
      ],
    );
    expect(rare.total, greaterThan(plain.total));
  });

  test('daily seed aynı gün aynı değer', () {
    final a = DailySeed.fromDate(DateTime(2026, 7, 24));
    final b = DailySeed.fromDate(DateTime(2026, 7, 24));
    final c = DailySeed.fromDate(DateTime(2026, 7, 25));
    expect(a.value, b.value);
    expect(a.value, isNot(c.value));
    expect(a.label, '24.07.2026');
  });

  test('boss tekil yasa', () {
    const boss = BossModifier(
      id: 't',
      name: 'Tekil',
      description: '',
      rule: BossRule.noDuplicateLetters,
      value: 1,
    );
    expect(boss.validate('ellek'), isNotNull);
    expect(boss.validate('kalem'), isNull);
  });

  test('boss min/max uzunluk', () {
    const minBoss = BossModifier(
      id: 'm',
      name: 'Uzun',
      description: '',
      rule: BossRule.minLength,
      value: 5,
    );
    const maxBoss = BossModifier(
      id: 'x',
      name: 'Kısa',
      description: '',
      rule: BossRule.maxLength,
      value: 4,
    );
    expect(minBoss.validate('çay'), isNotNull);
    expect(minBoss.validate('kalem'), isNull);
    expect(maxBoss.validate('kalem'), isNotNull);
    expect(maxBoss.validate('elma'), isNull);
  });

  test('findPlayableWordOfLength yalnızca hedef uzunluğu tarar', () {
    final d = WordDictionary(['elma', 'mal', 'kitap', 'kalem', 'su']);
    d.buildAnagramIndex();
    // Elde hem 2 hem 3 hem de daha uzun harfler var ama yalnızca 2 harfli
    // ("su") aranmalı — daha uzun kelimeler asla dönmemeli.
    final word = d.findPlayableWordOfLength(
      2,
      ['k', 'a', 'l', 'e', 'm', 't', 'i', 's', 'u'],
    );
    expect(word, 'su');

    // Elde 3 harfli kelime kurulamıyorsa (harfler yetersiz) null dönmeli,
    // 2 ya da 4+ harfli bir alternatif asla döndürülmemeli.
    final none = d.findPlayableWordOfLength(3, ['s', 'u']);
    expect(none, isNull);
  });

  test('anagram soft hint uzun kelime tercih eder', () {
    final d = WordDictionary(['elma', 'mal', 'kitap', 'kalem', 'su']);
    final word = d.findPlayableWord(['k', 'a', 'l', 'e', 'm', 't', 'i', 's']);
    expect(word, isNotNull);
    expect(isValidWordLength(word!.length), isTrue);
    expect(['kitap', 'kalem'].contains(word), isTrue);
  });

  test('handSize ve kelime aralığı sabitleri', () {
    expect(kHandSize, 8);
    expect(kMinWordLength, 2);
    expect(kMaxWordLength, 8);
    expect(kShortWordExactLength, 3);
  });

  test('uzun kelime jokerı yalnızca 6+ harfte', () {
    final short = scoreWord(
      word: 'kalem',
      jokers: const [
        JokerCard(
          id: 'b',
          name: 'Uzun',
          description: '',
          kind: JokerKind.longWordMult,
          value: 1.5,
        ),
      ],
    );
    final long = scoreWord(
      word: 'okullar',
      jokers: const [
        JokerCard(
          id: 'b',
          name: 'Uzun',
          description: '',
          kind: JokerKind.longWordMult,
          value: 1.5,
        ),
      ],
    );
    final plainLong = scoreWord(word: 'okullar', jokers: const []);
    expect(short.notes.any((n) => n.contains('Uzun')), isFalse);
    expect(long.total, greaterThan(plainLong.total));
  });

  test('kısa kelime jokerı yalnızca tam 3 harfte', () {
    final three = scoreWord(
      word: 'çay',
      jokers: const [
        JokerCard(
          id: 'k',
          name: 'Kısa',
          description: '',
          kind: JokerKind.shortWordMult,
          value: 1.25,
        ),
      ],
    );
    final four = scoreWord(
      word: 'elma',
      jokers: const [
        JokerCard(
          id: 'k',
          name: 'Kısa',
          description: '',
          kind: JokerKind.shortWordMult,
          value: 1.25,
        ),
      ],
    );
    final plainThree = scoreWord(word: 'çay', jokers: const []);
    expect(three.total, greaterThan(plainThree.total));
    expect(four.notes.any((n) => n.contains('Kısa')), isFalse);
  });

  test('ekonomi sabitleri', () {
    expect(kMaxJokerSlots, 3);
    expect(kClassicLevels, 7);
  });

  test('lengthForLevel 2den 8e döngü kurar', () {
    expect(lengthForLevel(1), 2);
    expect(lengthForLevel(7), 8);
    expect(lengthForLevel(8), 2); // endless döngüsü
    expect(lengthForLevel(14), 8);
  });

  test('boss hedef ×1.1 tek kaynak', () {
    expect(kBossTargetMultiplier, 1.1);
    expect(isBossLevelNumber(4), isTrue);
    expect(isBossLevelNumber(3), isFalse);
    final normal = computeLevelTarget(level: 3);
    final boss = computeLevelTarget(level: 4);
    final base4 = computeBaseLevelTarget(level: 4);
    expect(boss, (base4 * kBossTargetMultiplier).round());
    expect(boss, greaterThan(normal));
  });

  test('BossModifier dialogHint opsiyonel parse', () {
    final withHint = BossModifier.fromJson({
      'id': 't',
      'name': 'Tekil',
      'description': 'Açıklama',
      'rule': 'noDuplicateLetters',
      'value': 1,
      'dialogHint': '  Joker ipucu  ',
    });
    expect(withHint.dialogHint, 'Joker ipucu');
    final without = BossModifier.fromJson({
      'id': 't2',
      'name': 'X',
      'description': '',
      'rule': 'minLength',
      'value': 2,
    });
    expect(without.dialogHint, isNull);
  });

  test('debate crew onay üretir', () async {
    final crew = buildDebateCrew();
    final result = await crew.kickoff();
    final decisions = result.context.get<List<dynamic>>('decisions') ?? [];
    expect(decisions.length, lessThanOrEqualTo(5));
    final ids = decisions.map((d) => d['id']).toSet();
    expect(ids.contains('first_run_tips'), isFalse);
    expect(ids.contains('new_jokers_v2'), isFalse);
  });

  test('orta harf jokerı skoru artirir', () {
    final plain = scoreWord(word: 'kalem', jokers: const []);
    final mid = scoreWord(
      word: 'kalem',
      jokers: const [
        JokerCard(
          id: 'o',
          name: 'Orta',
          description: '',
          kind: JokerKind.middleLetterDouble,
          value: 2,
        ),
      ],
    );
    expect(mid.total, greaterThan(plain.total));
  });

  group('GameController — sabit uzunluk seviyeler', () {
    late GameController controller;

    setUp(() async {
      controller = GameController();
      await controller.bootstrap();
    });

    test('klasik koşu ön-mağaza ile başlar', () {
      expect(controller.phase, RunPhase.shop);
      expect(controller.isPregameShop, isTrue);
      expect(controller.level, 1);
    });

    test('her seviyede el, gerekli uzunlukta kelime kurabilir (tam koşu)', () {
      controller.skipShop(); // ön-mağazayı geç, 1. seviyeye gir
      for (var lvl = 1; lvl <= kClassicLevels; lvl++) {
        expect(controller.level, lvl);
        expect(controller.requiredLength, lengthForLevel(lvl));

        final word = controller.dictionary!.findPlayableWord(
          controller.hand.map((t) => t.letter),
          validate: (w) =>
              w.length == controller.requiredLength &&
              controller.activeBoss?.validate(w) == null,
        );
        expect(
          word,
          isNotNull,
          reason: 'Seviye $lvl (${controller.requiredLength} harf) için '
              'elden kelime kurulamadı: '
              '${controller.hand.map((t) => t.letter).join()}',
        );

        // Test edilen şey her elde kelime kurulabilirliği garantisi — oyun
        // dengesi (hedefe ulaşmak kaç el sürer) değil, o yüzden hedefi
        // doğrudan doldurup seviyeyi netleştiriyoruz.
        controller.score = controller.target;
        expect(controller.selectWordFromHand(word!), isTrue);
        controller.playWord();

        expect(controller.phase, RunPhase.shop);
        controller.skipShop();
      }
      expect(controller.phase, RunPhase.won);
    });

    test('usePass handsLeft\'i harcamaz', () {
      controller.skipShop();
      final handsBefore = controller.handsLeft;
      final passesBefore = controller.passesLeft;
      controller.usePass();
      expect(controller.handsLeft, handsBefore);
      expect(controller.passesLeft, passesBefore - 1);
    });

    test('comboStreak art arda kelime oynadıkça artar, yeni seviyede sıfırlanır', () {
      controller.skipShop(); // ön-mağazayı geç, 1. seviyeye gir
      expect(controller.comboStreak, 0);

      String? nextWord() => controller.dictionary!.findPlayableWordOfLength(
            controller.requiredLength,
            controller.hand.map((t) => t.letter),
            validate: (w) =>
                !controller.playedThisLevel.contains(w) &&
                controller.activeBoss?.validate(w) == null,
          );

      final first = nextWord();
      expect(first, isNotNull);
      expect(controller.selectWordFromHand(first!), isTrue);
      controller.playWord();
      expect(controller.comboStreak, 1);

      if (controller.phase == RunPhase.playing) {
        final second = nextWord();
        expect(second, isNotNull);
        expect(controller.selectWordFromHand(second!), isTrue);
        controller.playWord();
        expect(controller.comboStreak, 2);
      }

      // Seviye netleşip bir sonrakine geçildiğinde seri sıfırlanmalı.
      controller.score = controller.target;
      final finisher = nextWord();
      if (finisher != null) {
        controller.selectWordFromHand(finisher);
        controller.playWord();
        if (controller.phase == RunPhase.shop) {
          controller.skipShop();
          expect(controller.comboStreak, 0);
        }
      }
    });

    test('joker satın almak mağazadan çıkarmaz — sadece skipShop çıkarır', () {
      // Ön-mağazadayız; en az bir joker alacak kadar altın olduğundan emin ol.
      controller.gold = 99;
      final offer = controller.shopOffers.isNotEmpty
          ? controller.shopOffers.first
          : null;
      expect(offer, isNotNull);
      controller.buyJoker(offer!);
      expect(controller.ownedJokers.map((j) => j.id), contains(offer.id));
      expect(controller.phase, RunPhase.shop,
          reason: 'Satın alma mağazadan çıkarmamalı');
      expect(controller.isPregameShop, isTrue);

      controller.skipShop();
      expect(controller.phase, RunPhase.playing);
    });
  });
}
