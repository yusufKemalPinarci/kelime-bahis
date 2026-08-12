/// Kelime Bahis — kelime uzunluğu / el sabitleri (ekonomisiz sade tasarım).
const int kMinWordLength = 2;
const int kMaxWordLength = 8;

/// Eldeki harf sayısı (kelime uzunluğundan bağımsız).
const int kHandSize = 8;

/// Uzunluk çarpanı: kısa = güvenli/düşük, uzun = risk/ödül.
double lengthMultiplier(int letterCount) {
  switch (letterCount) {
    case 2:
      return 0.7;
    case 3:
      return 0.85;
    case 4:
    case 5:
      return 1.0;
    case 6:
      return 1.25;
    case 7:
      return 1.5;
    case 8:
      return 1.8;
    default:
      return 1.0;
  }
}

bool isValidWordLength(int length) =>
    length >= kMinWordLength && length <= kMaxWordLength;

/// Seri (combo) adımı başına çarpan artışı.
const double kComboStepBonus = 0.15;

/// Art arda oynanan kelime sayısına göre skor çarpanı.
/// streak=1 → x1.0, her ek ardışık kelimede +%15.
double comboMultiplier(int streak) =>
    streak <= 1 ? 1.0 : 1.0 + (streak - 1) * kComboStepBonus;
