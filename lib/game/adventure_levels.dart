/// Adventure — Kule modu: 100 seviye, 10 kat × 10 oda.
///
/// Seviyeler prosedürel olarak üretilir (RNG yok, deterministik) — kat/oda
/// numarasına göre görev türü döngüsel seçilir ve zorluk parametreleri
/// katla birlikte büyür. Her katın 10. odası iki kısıtın birleştiği bir
/// "kilometre taşı" seviyesidir.
library;

import 'letter_bag.dart';
import 'turkish.dart';

const int kAdventureLevelCount = 100;
const int kAdventureLevelsPerFloor = 10;

const List<String> kAdventureFloorNames = [
  'Zemin Kat',
  'Taş Merdiven',
  'Bakır Kat',
  'Gümüş Kat',
  'Altın Kat',
  'Mermer Kat',
  'Kristal Kat',
  'Gökyüzü Kat',
  'Yıldız Kat',
  'Zirve',
];

/// Yaygından nadire doğru sıralı harf havuzu — `containsLetter` görevlerinde
/// kat arttıkça daha nadir harfler seçilsin diye kullanılır.
const List<String> _kLetterRarityPool = [
  'e', 'a', 'r', 'l', 'k', 'n', 't', 'm', 's', 'd',
  'y', 'u', 'o', 'b', 'g', 'ç', 'h', 'ı', 'i', 'p',
  'ş', 'v', 'z', 'c', 'ö', 'ü', 'f', 'j', 'ğ',
];

enum AdventureTaskKind {
  wordCount,
  exactLength,
  minLength,
  targetScore,
  noRepeatLetters,
  vowelRich,
  consonantHeavy,
  startsWithVowel,
  containsLetter,
  milestone,
}

/// Bir Adventure seviyesinin tam tanımı: hangi görev, hangi parametrelerle,
/// kaç denemede tamamlanmalı.
class AdventureLevelDef {
  const AdventureLevelDef({
    required this.level,
    required this.floorName,
    required this.title,
    required this.description,
    required this.kind,
    required this.target,
    required this.attempts,
    this.exactLength,
    this.minLength,
    this.minVowels,
    this.minConsonants,
    this.noRepeat = false,
    this.startsVowel = false,
    this.requiredLetter,
    this.scoreBased = false,
  });

  final int level;
  final String floorName;
  final String title;
  final String description;
  final AdventureTaskKind kind;

  /// [scoreBased] true ise [target] bir puan eşiği (ilerleme = kazanılan
  /// puan toplamı); değilse [target] bir kelime sayısı (ilerleme = geçerli
  /// kelime adedi).
  final bool scoreBased;

  /// `scoreBased` ise puan hedefi; değilse kelime sayısı hedefi.
  final int target;

  /// Seviye başına toplam el (deneme) hakkı.
  final int attempts;

  final int? exactLength;
  final int? minLength;
  final int? minVowels;
  final int? minConsonants;
  final bool noRepeat;
  final bool startsVowel;
  final String? requiredLetter;

  /// Kelime bu seviyenin kısıtlarını sağlıyor mu? (Sözlükte olma / genel
  /// 2–8 harf aralığı kontrolü ayrıca yapılır, burada yalnızca göreve özel
  /// kısıtlar denetlenir.)
  bool accepts(String rawWord) {
    final w = normalizeTr(rawWord);
    if (exactLength != null && w.length != exactLength) return false;
    if (minLength != null && w.length < minLength!) return false;
    if (minVowels != null) {
      final v = w.split('').where(isVowel).length;
      if (v < minVowels!) return false;
    }
    if (minConsonants != null) {
      final c = w.split('').where(isConsonant).length;
      if (c < minConsonants!) return false;
    }
    if (noRepeat) {
      final letters = w.split('');
      if (letters.toSet().length != letters.length) return false;
    }
    if (startsVowel) {
      if (w.isEmpty || !isVowel(w[0])) return false;
    }
    if (requiredLetter != null && !w.contains(requiredLetter!)) return false;
    return true;
  }
}

String floorNameForLevel(int level) {
  final idx = ((level - 1) ~/ kAdventureLevelsPerFloor)
      .clamp(0, kAdventureFloorNames.length - 1);
  return kAdventureFloorNames[idx];
}

/// [level] (1..100) için görev tanımını üretir.
AdventureLevelDef adventureLevel(int level) {
  final clamped = level.clamp(1, kAdventureLevelCount);
  final tier = (clamped - 1) ~/ kAdventureLevelsPerFloor; // 0..9
  final posInFloor = (clamped - 1) % kAdventureLevelsPerFloor + 1; // 1..10
  final floorName = kAdventureFloorNames[tier];

  if (posInFloor == kAdventureLevelsPerFloor) {
    return _milestoneLevel(clamped, tier, floorName);
  }

  final kinds = AdventureTaskKind.values
      .where((k) => k != AdventureTaskKind.milestone)
      .toList();
  final kind = kinds[(clamped + tier) % kinds.length];

  switch (kind) {
    case AdventureTaskKind.wordCount:
      final target = 2 + tier + (posInFloor > 5 ? 1 : 0);
      return AdventureLevelDef(
        level: clamped,
        floorName: floorName,
        title: 'Kelime Seli',
        description: '$target kelime oyna.',
        kind: kind,
        target: target,
        attempts: target + 3,
      );

    case AdventureTaskKind.exactLength:
      final length = 2 + ((tier + posInFloor) % 7);
      final target = 2 + tier ~/ 3;
      return AdventureLevelDef(
        level: clamped,
        floorName: floorName,
        title: length <= 3 ? 'Kısa Seri' : 'Tam Ölçü',
        description: '$target tane tam $length harfli kelime oyna.',
        kind: kind,
        target: target,
        attempts: target + 3,
        exactLength: length,
      );

    case AdventureTaskKind.minLength:
      final length = (4 + tier ~/ 2).clamp(4, 7);
      final target = 2 + tier ~/ 4;
      return AdventureLevelDef(
        level: clamped,
        floorName: floorName,
        title: 'Uzun Nefes',
        description: '$target tane en az $length harfli kelime oyna.',
        kind: kind,
        target: target,
        attempts: target + 3,
        minLength: length,
      );

    case AdventureTaskKind.targetScore:
      final target = 30 + tier * 15 + posInFloor * 3;
      final attempts = 6 + tier;
      return AdventureLevelDef(
        level: clamped,
        floorName: floorName,
        title: 'Puan Avcısı',
        description: '$target puana ulaş ($attempts hamlede).',
        kind: kind,
        target: target,
        attempts: attempts,
        scoreBased: true,
      );

    case AdventureTaskKind.noRepeatLetters:
      final target = 2 + tier ~/ 2;
      return AdventureLevelDef(
        level: clamped,
        floorName: floorName,
        title: 'Temiz Harfler',
        description: '$target kelime oyna (harf tekrarsız).',
        kind: kind,
        target: target,
        attempts: target + 3,
        noRepeat: true,
      );

    case AdventureTaskKind.vowelRich:
      final minVowels = (2 + tier ~/ 3).clamp(2, 4);
      final target = 2 + tier ~/ 3;
      return AdventureLevelDef(
        level: clamped,
        floorName: floorName,
        title: 'Sesli Fırtına',
        description: '$target kelime oyna (en az $minVowels sesli harf).',
        kind: kind,
        target: target,
        attempts: target + 4,
        minVowels: minVowels,
      );

    case AdventureTaskKind.consonantHeavy:
      final minConsonants = (3 + tier ~/ 2).clamp(3, 6);
      final target = 2 + tier ~/ 4;
      return AdventureLevelDef(
        level: clamped,
        floorName: floorName,
        title: 'Sessiz Duvar',
        description:
            '$target kelime oyna (en az $minConsonants sessiz harf).',
        kind: kind,
        target: target,
        attempts: target + 4,
        minConsonants: minConsonants,
      );

    case AdventureTaskKind.startsWithVowel:
      final target = 2 + tier ~/ 3;
      return AdventureLevelDef(
        level: clamped,
        floorName: floorName,
        title: 'Sesli Başlangıç',
        description: '$target kelime oyna (sesli harfle başlayan).',
        kind: kind,
        target: target,
        attempts: target + 3,
        startsVowel: true,
      );

    case AdventureTaskKind.containsLetter:
      final letterIdx =
          (clamped * 5 + tier) % _kLetterRarityPool.length;
      final letter = _kLetterRarityPool[letterIdx];
      final target = 2 + tier ~/ 4;
      return AdventureLevelDef(
        level: clamped,
        floorName: floorName,
        title: 'Harf Avı: ${toUpperTr(letter)}',
        description:
            "$target kelime oyna ('${toUpperTr(letter)}' harfini içeren).",
        kind: kind,
        target: target,
        attempts: target + 3,
        requiredLetter: letter,
      );

    case AdventureTaskKind.milestone:
      return _milestoneLevel(clamped, tier, floorName); // unreachable
  }
}

/// Her katın 10. odası: iki kısıtın birleştiği daha zor bir görev.
AdventureLevelDef _milestoneLevel(int level, int tier, String floorName) {
  final target = 3 + tier ~/ 3;
  final attempts = target + 4;
  final combo = tier % 5;

  switch (combo) {
    case 0:
      final length = (5 + tier ~/ 3).clamp(5, 7);
      return AdventureLevelDef(
        level: level,
        floorName: floorName,
        title: 'İkili Meydan Okuma',
        description:
            '$target tane en az $length harfli, harf tekrarsız kelime oyna.',
        kind: AdventureTaskKind.milestone,
        target: target,
        attempts: attempts,
        minLength: length,
        noRepeat: true,
      );
    case 1:
      final minVowels = (2 + tier ~/ 3).clamp(2, 4);
      final length = 2 + ((tier + 3) % 7);
      return AdventureLevelDef(
        level: level,
        floorName: floorName,
        title: 'İkili Meydan Okuma',
        description:
            '$target tane tam $length harfli, en az $minVowels sesli kelime oyna.',
        kind: AdventureTaskKind.milestone,
        target: target,
        attempts: attempts,
        exactLength: length,
        minVowels: minVowels,
      );
    case 2:
      final minConsonants = (3 + tier ~/ 2).clamp(3, 6);
      return AdventureLevelDef(
        level: level,
        floorName: floorName,
        title: 'İkili Meydan Okuma',
        description:
            '$target kelime oyna (en az $minConsonants sessiz, sesli harfle başlayan).',
        kind: AdventureTaskKind.milestone,
        target: target,
        attempts: attempts,
        minConsonants: minConsonants,
        startsVowel: true,
      );
    case 3:
      final letterIdx = (level * 5 + tier) % _kLetterRarityPool.length;
      final letter = _kLetterRarityPool[letterIdx];
      final length = (4 + tier ~/ 2).clamp(4, 7);
      return AdventureLevelDef(
        level: level,
        floorName: floorName,
        title: 'İkili Meydan Okuma',
        description:
            "$target tane en az $length harfli, '${toUpperTr(letter)}' harfini içeren kelime oyna.",
        kind: AdventureTaskKind.milestone,
        target: target,
        attempts: attempts,
        minLength: length,
        requiredLetter: letter,
      );
    default:
      final score = 40 + tier * 18;
      final attempts = 6 + tier;
      return AdventureLevelDef(
        level: level,
        floorName: floorName,
        title: 'İkili Meydan Okuma',
        description:
            '$score puana ulaş ($attempts hamlede) — harf tekrarı olmadan.',
        kind: AdventureTaskKind.milestone,
        target: score,
        attempts: attempts,
        noRepeat: true,
        scoreBased: true,
      );
  }
}
