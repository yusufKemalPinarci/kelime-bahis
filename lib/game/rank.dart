/// Kalıcı rütbe sistemi — ömür boyu puan (`LocalStats.lifetimeScore`)
/// üzerinden ilerler. Koşu kaybetsen bile rütbe kalıcıdır.
class Rank {
  const Rank(this.name, this.threshold);

  final String name;
  final int threshold;
}

const List<Rank> kRanks = [
  Rank('Çaylak', 0),
  Rank('Sözcük Çırağı', 400),
  Rank('Harf Ustası', 1200),
  Rank('Kelime Kalfası', 3000),
  Rank('Dil Üstadı', 7000),
  Rank('Sözlük Efendisi', 15000),
  Rank('Kelime Baronu', 30000),
];

int _rankIndexForScore(int lifetimeScore) {
  var idx = 0;
  for (var i = 0; i < kRanks.length; i++) {
    if (lifetimeScore >= kRanks[i].threshold) idx = i;
  }
  return idx;
}

/// Verilen ömür boyu puana karşılık gelen mevcut rütbe.
Rank rankForScore(int lifetimeScore) => kRanks[_rankIndexForScore(lifetimeScore)];

/// Bir sonraki rütbe — zirvedeyse null.
Rank? nextRankForScore(int lifetimeScore) {
  final idx = _rankIndexForScore(lifetimeScore);
  if (idx >= kRanks.length - 1) return null;
  return kRanks[idx + 1];
}

/// Mevcut rütbe içindeki ilerleme (0.0–1.0). Zirvedeyse 1.0.
double rankProgress(int lifetimeScore) {
  final current = rankForScore(lifetimeScore);
  final next = nextRankForScore(lifetimeScore);
  if (next == null) return 1.0;
  final span = next.threshold - current.threshold;
  if (span <= 0) return 1.0;
  return ((lifetimeScore - current.threshold) / span).clamp(0.0, 1.0);
}
