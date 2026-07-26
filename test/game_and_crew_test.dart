import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_bahis/crew/kelime_crew.dart';
import 'package:kelime_bahis/game/daily_seed.dart';
import 'package:kelime_bahis/game/scoring.dart';
import 'package:kelime_bahis/game/word_dictionary.dart';
import 'package:kelime_bahis/game/word_length.dart';

void main() {
  test('sözlük yalnızca 5 harfli kelimeyi tutar', () {
    final d = WordDictionary(['elma', 'armut', 'kitap', 'kalem', 'ev']);
    expect(d.contains('kitap'), isTrue);
    expect(d.contains('kalem'), isTrue);
    expect(d.contains('armut'), isTrue);
    expect(d.contains('elma'), isFalse);
    expect(d.contains('xyzab'), isFalse);
    expect(d.size, 3);
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

  test('anagram soft hint 5 harfli bulur', () {
    final d = WordDictionary(['elma', 'mal', 'kitap', 'kalem']);
    final word = d.findPlayableWord(['k', 'a', 'l', 'e', 'm', 't', 'i']);
    expect(word, isNotNull);
    expect(word!.length, kWordLength);
    expect(['kitap', 'kalem'].contains(word), isTrue);
  });

  test('debate crew onay üretir', () async {
    final crew = buildDebateCrew();
    final result = await crew.kickoff();
    final decisions = result.context.get<List<dynamic>>('decisions') ?? [];
    expect(decisions.length, lessThanOrEqualTo(4));
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

  test('besli carpan her 5 harfte uygulanir', () {
    final plain = scoreWord(word: 'kalem', jokers: const []);
    final boosted = scoreWord(
      word: 'kalem',
      jokers: const [
        JokerCard(
          id: 'b',
          name: 'Beşli',
          description: '',
          kind: JokerKind.longWordMult,
          value: 1.4,
        ),
      ],
    );
    expect(boosted.total, greaterThan(plain.total));
  });
}
