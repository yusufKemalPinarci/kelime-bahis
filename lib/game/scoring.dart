import 'dart:math' as math;

import 'letter_bag.dart';
import 'turkish.dart';
import 'word_length.dart';

// --- Tur 8 denge sabitleri (BalanceAgent; harf puanları değişmedi) ---

/// Boss seviyelerinde hedef çarpanı. Skor formülüne uygulanmaz; yalnızca target.
const double kBossTargetMultiplier = 1.1;

/// Boss aralığı: [levelsBeforeBoss] normal + 1 boss (varsayılan L4, L8, …).
const int kLevelsBeforeBoss = 3;

/// Joker JSON `cost` bandı — ContentAgent bu aralıkta tutsun.
const int kJokerCostMin = 3;
const int kJokerCostMax = 6;

/// Çarpan türü joker `value` üst sınırı (content şişirmesin).
const double kJokerMultCap = 2.0;

/// Düz bonus joker `value` üst sınırı.
const int kJokerFlatBonusCap = 12;

/// Seviye numarası boss mu? (`level % (levelsBeforeBoss+1) == 0`)
bool isBossLevelNumber(
  int level, {
  int levelsBeforeBoss = kLevelsBeforeBoss,
}) {
  if (level <= 0) return false;
  final period = levelsBeforeBoss + 1;
  return level % period == 0;
}

/// Uzunluk → `tr_words.txt`'ten ölçülen medyan ham harf-puanı toplamı
/// (dev-analiz: her uzunluk kovasındaki tüm kelimelerin harf puanları
/// toplanıp medyanı alındı). Hedef eğrisi artık jenerik bir üstel fonksiyon
/// değil, bu gerçek veriye dayanıyor — seviye uzunluğu değiştiğinde
/// (`lengthForLevel`) oynanabilirlik otomatik ölçekleniyor.
const Map<int, int> kMedianRawWordScore = {
  2: 4,
  3: 7,
  4: 8,
  5: 10,
  6: 12,
  7: 13,
  8: 15,
};

/// Bir turda oynanabilecek el sayısı ile aynı (bkz. GameController).
const int kHandsPerLevel = 4;

/// 4 el boyunca ortalama seri (combo) çarpanı: (1.0+1.15+1.30+1.45)/4.
const double kAvgComboMultiplier = 1.225;

/// Hedefi "tipik" toplam skorun bu oranına ayarla — tamamı değil, rahat
/// oynanabilir bir pay bırak.
const double kTargetComfortFactor = 0.6;

/// Endless'ta her tam turda (7 seviye) hedef bu oranda büyür.
const double kEndlessLapGrowth = 1.25;

/// Boss çarpanı olmadan, uzunluk + tur (lap) büyümesiyle hesaplanan baz hedef.
int computeBaseLevelTarget({required int level}) {
  final length = lengthForLevel(level);
  final medianRaw = kMedianRawWordScore[length] ?? 10;
  final typical = medianRaw * lengthMultiplier(length);
  var target =
      (typical * kHandsPerLevel * kAvgComboMultiplier * kTargetComfortFactor)
          .round();
  final lap = (level - 1) ~/ kClassicLevels;
  if (lap > 0) {
    target = (target * math.pow(kEndlessLapGrowth, lap)).round();
  }
  return target < 1 ? 1 : target;
}

/// Efektif seviye hedefi — boss'ta (4'ün katları + final seviye) ×
/// [kBossTargetMultiplier], skor cezası yok. `endless=true` iken boss
/// uygulanmaz (bkz. GameController.isBossLevel).
int computeLevelTarget({required int level, bool endless = false}) {
  final base = computeBaseLevelTarget(level: level);
  final isBoss =
      !endless && (isBossLevelNumber(level) || level == kClassicLevels);
  if (isBoss) {
    return (base * kBossTargetMultiplier).round();
  }
  return base;
}

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
  /// Skora etki etmez — seviye bitince ekstra altın (bkz. GameController).
  extraGold,
  /// Skora etki etmez — seviye başına ekstra pas hakkı (bkz. GameController).
  extraPass,
}

class JokerCard {
  const JokerCard({
    required this.id,
    required this.name,
    required this.description,
    required this.kind,
    required this.value,
    this.meta,
    this.cost = 4, // orta band (kJokerCostMin–kJokerCostMax)
  });

  final String id;
  final String name;
  final String description;
  final JokerKind kind;
  final double value;
  final int? meta;
  final int cost;

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
      cost: (json['cost'] as num?)?.toInt() ?? 4,
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
    this.dialogHint,
  });

  final String id;
  final String name;
  final String description;
  final BossRule rule;
  final int value;

  /// Mağaza→boss diyalogunda joker sinerji satırı (opsiyonel; content JSON).
  final String? dialogHint;

  factory BossModifier.fromJson(Map<String, dynamic> json) {
    final hint = json['dialogHint'];
    return BossModifier(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      rule: BossRule.values.firstWhere(
        (r) => r.name == json['rule'],
        orElse: () => BossRule.minLength,
      ),
      value: (json['value'] as num).toInt(),
      dialogHint: hint is String && hint.trim().isNotEmpty ? hint.trim() : null,
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
  int comboStreak = 1,
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

  // Uzunluk ve seri çarpanları skora uygulanır ama ayrı bir metin notu
  // olarak gösterilmez — seri zaten oyun ekranındaki rozette görünüyor,
  // uzunluk etkisi toplam skordan zaten hissediliyor. Bu listede yalnızca
  // joker bonusları (düz +N puan) kalır.
  mult *= lengthMultiplier(letters.length);
  mult *= comboMultiplier(comboStreak);

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
        if (letters.length >= kLongWordThreshold) {
          mult *= j.value;
          notes.add('${j.name}: x${j.value}');
        }
      case JokerKind.shortWordMult:
        if (letters.length == kShortWordExactLength) {
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
      case JokerKind.extraGold:
      case JokerKind.extraPass:
        break;
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
