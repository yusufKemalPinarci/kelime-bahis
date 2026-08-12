import 'letter_bag.dart';
import 'turkish.dart';
import 'word_length.dart';

/// Bir kelimenin oynanmasından doğan puan kırılımı.
class ScoreBreakdown {
  const ScoreBreakdown({
    required this.base,
    required this.multiplier,
    required this.total,
  });

  final int base;
  final double multiplier;
  final int total;
}

/// Harf puanları + uzunluk çarpanı + seri (combo) çarpanı — ekonomi/joker yok.
ScoreBreakdown scoreWord({
  required String word,
  int comboStreak = 1,
}) {
  final letters = normalizeTr(word).split('');
  var base = 0;
  for (final l in letters) {
    base += kLetterPoints[l] ?? 1;
  }

  final mult = lengthMultiplier(letters.length) * comboMultiplier(comboStreak);
  final total = (base * mult).round();
  return ScoreBreakdown(base: base, multiplier: mult, total: total);
}
