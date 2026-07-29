/// Kelime Bahis — değişken kelime uzunluğu (el boyutu ayrı).
const int kMinWordLength = 2;
const int kMaxWordLength = 8;

/// Eldeki harf sayısı (kelime uzunluğundan bağımsız).
const int kHandSize = 8;

/// Uzun kelime joker eşiği (≥).
const int kLongWordThreshold = 6;

/// Kısa kelime joker eşiği — yalnızca tam 2 harf.
const int kShortWordExactLength = 2;

/// Seviye başına en fazla bu kadar ≤3 harfli kelime.
const int kMaxShortWordsPerLevel = 2;

/// Maksimum joker slotu.
const int kMaxJokerSlots = 5;

/// Mağaza reroll altın maliyeti.
const int kShopRerollCost = 1;

/// Uzunluk çarpanı: kısa = güvenli/düşük, uzun = risk/ödül.
double lengthMultiplier(int letterCount) {
  switch (letterCount) {
    case 2:
      return 0.5;
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
