import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_bahis/crew/kelime_crew.dart';
import 'package:kelime_bahis/game/adventure_levels.dart';
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
    final short = scoreWord(word: 'çay');
    expect(short.multiplier, lengthMultiplier(3));
    final eight = scoreWord(word: 'okulları');
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
    final noCombo = scoreWord(word: 'kalem', comboStreak: 1);
    final withCombo = scoreWord(word: 'kalem', comboStreak: 3);
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

  test('findPlayableWordOfLength yalnızca hedef uzunluğu tarar', () {
    final d = WordDictionary(['elma', 'mal', 'kitap', 'kalem', 'su']);
    d.buildAnagramIndex();
    final word = d.findPlayableWordOfLength(
      2,
      ['k', 'a', 'l', 'e', 'm', 't', 'i', 's', 'u'],
    );
    expect(word, 'su');

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

  test('pickRandomWordMatching serbest uzunlukta havuzdan seçer', () {
    final d = WordDictionary(['elma', 'mal', 'kitap', 'kalem', 'su']);
    d.buildAnagramIndex();
    final word = d.pickRandomWordMatching(
      validate: (w) => w.length >= 4,
      rng: Random(1),
    );
    expect(word, isNotNull);
    expect(word!.length, greaterThanOrEqualTo(4));

    final none = d.pickRandomWordMatching(
      validate: (w) => w.length >= 9,
      rng: Random(1),
    );
    expect(none, isNull);
  });

  test('handSize ve kelime aralığı sabitleri', () {
    expect(kHandSize, 8);
    expect(kMinWordLength, 2);
    expect(kMaxWordLength, 8);
  });

  group('AdventureLevelDef.accepts', () {
    test('harf tekrarsız kısıt', () {
      final t = adventureLevelForTest(noRepeat: true);
      expect(t.accepts('ellek'), isFalse);
      expect(t.accepts('kalem'), isTrue);
    });

    test('min/tam uzunluk kısıtları', () {
      final minT = adventureLevelForTest(minLength: 5);
      expect(minT.accepts('çay'), isFalse);
      expect(minT.accepts('kalem'), isTrue);

      final exactT = adventureLevelForTest(exactLength: 4);
      expect(exactT.accepts('kalem'), isFalse);
      expect(exactT.accepts('elma'), isTrue);
    });

    test('sesli/sessiz eşikleri', () {
      final vowelT = adventureLevelForTest(minVowels: 3);
      expect(vowelT.accepts('elma'), isFalse);
      expect(vowelT.accepts('okullar'), isTrue);

      final consT = adventureLevelForTest(minConsonants: 4);
      expect(consT.accepts('elma'), isFalse);
      expect(consT.accepts('kalemler'), isTrue);
    });

    test('sesli harfle başlama ve belirli harf içerme', () {
      final startT = adventureLevelForTest(startsVowel: true);
      expect(startT.accepts('elma'), isTrue);
      expect(startT.accepts('kalem'), isFalse);

      final letterT = adventureLevelForTest(requiredLetter: 'ş');
      expect(letterT.accepts('şeker'), isTrue);
      expect(letterT.accepts('kalem'), isFalse);
    });
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
}

/// Test yardımcı fabrikası — tek bir kısıtı izole test etmek için minimal
/// bir [AdventureLevelDef] üretir.
AdventureLevelDef adventureLevelForTest({
  int? exactLength,
  int? minLength,
  int? minVowels,
  int? minConsonants,
  bool noRepeat = false,
  bool startsVowel = false,
  String? requiredLetter,
}) {
  return AdventureLevelDef(
    level: 1,
    floorName: 'Test',
    title: 'Test',
    description: 'Test',
    kind: AdventureTaskKind.wordCount,
    target: 1,
    attempts: 1,
    exactLength: exactLength,
    minLength: minLength,
    minVowels: minVowels,
    minConsonants: minConsonants,
    noRepeat: noRepeat,
    startsVowel: startsVowel,
    requiredLetter: requiredLetter,
  );
}
