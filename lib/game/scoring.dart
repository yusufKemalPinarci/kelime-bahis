import 'letter_bag.dart';
import 'turkish.dart';
import 'word_length.dart';

enum JokerKind {
  vowelBonus,
  consonantBonus,
  longWordMult,
  shortWordMult,
  duplicateBonus,
  lastLetterDouble,
  firstLetterDouble,
  middleLetterDouble,
  exactLengthBonus,
  flatBonus,
  rareLetterBonus,
  consonantStack,
}

class JokerCard {
  const JokerCard({
    required this.id,
    required this.name,
    required this.description,
    required this.kind,
    required this.value,
    this.meta,
  });

  final String id;
  final String name;
  final String description;
  final JokerKind kind;
  final double value;
  final int? meta;

  factory JokerCard.fromJson(Map<String, dynamic> json) {
    return JokerCard(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      kind: JokerKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => JokerKind.flatBonus,
      ),
      value: (json['value'] as num).toDouble(),
      meta: (json['meta'] as num?)?.toInt(),
    );
  }
}

enum BossRule {
  minConsonants,
  maxLength,
  minLength,
  maxVowels,
  minVowels,
  noDuplicateLetters,
  startsWithVowel,
}

class BossModifier {
  const BossModifier({
    required this.id,
    required this.name,
    required this.description,
    required this.rule,
    required this.value,
  });

  final String id;
  final String name;
  final String description;
  final BossRule rule;
  final int value;

  factory BossModifier.fromJson(Map<String, dynamic> json) {
    return BossModifier(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      rule: BossRule.values.firstWhere(
        (r) => r.name == json['rule'],
        orElse: () => BossRule.minLength,
      ),
      value: (json['value'] as num).toInt(),
    );
  }

  String? validate(String word) {
    final letters = normalizeTr(word).split('');
    final vowels = letters.where(isVowel).length;
    final consonants = letters.where(isConsonant).length;

    switch (rule) {
      case BossRule.minConsonants:
        if (consonants < value) {
          return 'En az $value sessiz harf gerekli';
        }
      case BossRule.maxLength:
        if (letters.length > value) {
          return 'En fazla $value harf';
        }
      case BossRule.minLength:
        if (letters.length < value) {
          return 'En az $value harf gerekli';
        }
      case BossRule.maxVowels:
        if (vowels > value) {
          return 'En fazla $value sesli harf';
        }
      case BossRule.minVowels:
        if (vowels < value) {
          return 'En az $value sesli harf gerekli';
        }
      case BossRule.noDuplicateLetters:
        if (letters.toSet().length != letters.length) {
          return 'Aynı harf tekrar edemez';
        }
      case BossRule.startsWithVowel:
        if (letters.isEmpty || !isVowel(letters.first)) {
          return 'Kelime sesli harfle başlamalı';
        }
    }
    return null;
  }
}

class ScoreBreakdown {
  const ScoreBreakdown({
    required this.base,
    required this.bonus,
    required this.multiplier,
    required this.total,
    required this.notes,
  });

  final int base;
  final int bonus;
  final double multiplier;
  final int total;
  final List<String> notes;
}

const _rareLetters = {'j', 'ğ', 'f', 'ö', 'v', 'ü', 'ş', 'ç'};

ScoreBreakdown scoreWord({
  required String word,
  required List<JokerCard> jokers,
}) {
  final letters = normalizeTr(word).split('');
  var base = 0;
  for (var i = 0; i < letters.length; i++) {
    var p = kLetterPoints[letters[i]] ?? 1;
    final mid = letters.length ~/ 2;
    final isMiddle = letters.length % 2 == 1
        ? i == mid
        : i == mid - 1 || i == mid;
    for (final j in jokers) {
      if (j.kind == JokerKind.lastLetterDouble && i == letters.length - 1) {
        p = (p * j.value).round();
      }
      if (j.kind == JokerKind.firstLetterDouble && i == 0) {
        p = (p * j.value).round();
      }
      if (j.kind == JokerKind.middleLetterDouble && isMiddle) {
        p = (p * j.value).round();
      }
    }
    base += p;
  }

  var bonus = 0;
  var mult = 1.0;
  final notes = <String>[];

  for (final j in jokers) {
    switch (j.kind) {
      case JokerKind.vowelBonus:
        final v = letters.where(isVowel).length;
        final add = (v * j.value).round();
        bonus += add;
        if (add > 0) notes.add('${j.name}: +$add');
      case JokerKind.consonantBonus:
        final c = letters.where(isConsonant).length;
        final add = (c * j.value).round();
        bonus += add;
        if (add > 0) notes.add('${j.name}: +$add');
      case JokerKind.longWordMult:
        // 5 harf modunda her geçerli kelime bu çarpanı alır.
        if (letters.length == kWordLength) {
          mult *= j.value;
          notes.add('${j.name}: x${j.value}');
        }
      case JokerKind.shortWordMult:
        // Çift harf varsa çarpan (eski kısa-kelime slotu yeniden kullanıldı).
        final freq = <String, int>{};
        for (final l in letters) {
          freq[l] = (freq[l] ?? 0) + 1;
        }
        if (freq.values.any((c) => c >= 2)) {
          mult *= j.value;
          notes.add('${j.name}: x${j.value}');
        }
      case JokerKind.duplicateBonus:
        final freq = <String, int>{};
        for (final l in letters) {
          freq[l] = (freq[l] ?? 0) + 1;
        }
        if (freq.values.any((c) => c >= 2)) {
          bonus += j.value.round();
          notes.add('${j.name}: +${j.value.round()}');
        }
      case JokerKind.lastLetterDouble:
      case JokerKind.firstLetterDouble:
      case JokerKind.middleLetterDouble:
        break;
      case JokerKind.exactLengthBonus:
        if (letters.length == (j.meta ?? 3)) {
          bonus += j.value.round();
          notes.add('${j.name}: +${j.value.round()}');
        }
      case JokerKind.flatBonus:
        bonus += j.value.round();
        notes.add('${j.name}: +${j.value.round()}');
      case JokerKind.rareLetterBonus:
        final rares = letters.where(_rareLetters.contains).length;
        final add = (rares * j.value).round();
        bonus += add;
        if (add > 0) notes.add('${j.name}: +$add');
      case JokerKind.consonantStack:
        final c = letters.where(isConsonant).length;
        if (c >= (j.meta ?? 3)) {
          bonus += j.value.round();
          notes.add('${j.name}: +${j.value.round()}');
        }
    }
  }

  final total = ((base + bonus) * mult).round();
  return ScoreBreakdown(
    base: base,
    bonus: bonus,
    multiplier: mult,
    total: total,
    notes: notes,
  );
}
