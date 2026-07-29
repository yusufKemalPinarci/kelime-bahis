import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_bahis/crew/kelime_crew.dart';
import 'package:kelime_bahis/game/daily_seed.dart';
import 'package:kelime_bahis/game/scoring.dart';
import 'package:kelime_bahis/game/word_dictionary.dart';
import 'package:kelime_bahis/game/word_length.dart';

void main() {
  test('sözlük 2–8 harfli kelimeyi tutar', () {
    final d = WordDictionary(['elma', 'armut', 'kitap', 'kalem', 'ev', 'çay', 'x']);
    expect(d.contains('kitap'), isTrue);
    expect(d.contains('kalem'), isTrue);
    expect(d.contains('elma'), isTrue);
    expect(d.contains('ev'), isTrue);
    expect(d.contains('çay'), isTrue);
    expect(d.contains('x'), isFalse);
    expect(d.contains('xyzab'), isFalse);
    expect(d.size, 6);
  });

  test('uzunluk çarpanı kısa kelimeyi cezalandırır', () {
    expect(lengthMultiplier(2), 0.5);
    expect(lengthMultiplier(8), greaterThan(lengthMultiplier(5)));
    final short = scoreWord(word: 'su', jokers: const []);
    final mid = scoreWord(word: 'kalem', jokers: const []);
    expect(mid.total, greaterThan(short.total));
    expect(short.notes.any((n) => n.contains('Uzunluk')), isTrue);
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

  test('kısa kelime jokerı yalnızca tam 2 harfte', () {
    final two = scoreWord(
      word: 'su',
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
    final plainTwo = scoreWord(word: 'su', jokers: const []);
    expect(two.total, greaterThan(plainTwo.total));
    expect(three.notes.any((n) => n.contains('Kısa')), isFalse);
  });

  test('ekonomi sabitleri', () {
    expect(kMaxJokerSlots, 5);
    expect(kShopRerollCost, 1);
    expect(kMaxShortWordsPerLevel, 2);
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
}
