/// Kelime Bahis — değişken kelime uzunluğu (el boyutu ayrı).
const int kMinWordLength = 2;
const int kMaxWordLength = 8;

/// Eldeki harf sayısı (kelime uzunluğundan bağımsız).
const int kHandSize = 8;

/// Uzun kelime joker eşiği (≥).
const int kLongWordThreshold = 6;

/// Kısa kelime joker eşiği — yalnızca tam 3 harf.
const int kShortWordExactLength = 3;

/// Maksimum bonus (joker) slotu.
const int kMaxJokerSlots = 3;

/// Klasik koşudaki seviye sayısı (2→8 harf, her seviye bir uzunluk).
const int kClassicLevels = 7;

/// Seviye numarasından o seviyenin zorunlu kelime uzunluğunu hesaplar.
/// Klasik koşuda 1→2 harf ... 7→8 harf; endless'ta aynı formül döngü olarak
/// devam eder (8→2 harf, 9→3 harf, ...).
int lengthForLevel(int level) => 2 + ((level - 1) % kClassicLevels);

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

/// Bir seviyede art arda oynanan kelime sayısına göre skor çarpanı.
/// streak=1 (seviyedeki ilk kelime) → x1.0, her ek ardışık kelimede +%15.
/// Bir seviyede en fazla 4 el olduğu için doğal bir üst sınırı var.
double comboMultiplier(int streak) =>
    streak <= 1 ? 1.0 : 1.0 + (streak - 1) * kComboStepBonus;
