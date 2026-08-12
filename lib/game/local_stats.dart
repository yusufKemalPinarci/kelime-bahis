import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kalıcı, ekonomisiz istatistikler: Classic'te en yüksek oturum skoru ve
/// Adventure'da temizlenmiş en yüksek seviye.
class LocalStats {
  LocalStats({
    this.classicHighScore = 0,
    this.adventureHighestCleared = 0,
  });

  /// Classic modda ulaşılan en yüksek oturum skoru — her zaman sol üstte gösterilir.
  int classicHighScore;

  /// Adventure'da tamamlanmış en yüksek seviye numarası (0 = henüz yok,
  /// seviye 1 oynanabilir).
  int adventureHighestCleared;

  static const _kClassicHighScore = 'classic_high_score';
  static const _kAdventureHighestCleared = 'adventure_highest_cleared';

  static Future<LocalStats> load() async {
    // İstatistik okunamazsa oyun varsayılanlarla açılmalı — asla crash etme.
    try {
      final p = await SharedPreferences.getInstance();
      return LocalStats(
        classicHighScore: p.getInt(_kClassicHighScore) ?? 0,
        adventureHighestCleared: p.getInt(_kAdventureHighestCleared) ?? 0,
      );
    } catch (e) {
      debugPrint('LocalStats.load başarısız, varsayılanlar kullanılıyor: $e');
      return LocalStats();
    }
  }

  Future<void> save() async {
    // Fire-and-forget çağrılabilir; yazma hatası oyunu düşürmemeli.
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_kClassicHighScore, classicHighScore);
      await p.setInt(_kAdventureHighestCleared, adventureHighestCleared);
    } catch (e) {
      debugPrint('LocalStats.save başarısız: $e');
    }
  }

  /// [score] mevcut rekoru geçiyorsa günceller. Geçtiyse true döner.
  bool noteClassicScore(int score) {
    if (score > classicHighScore) {
      classicHighScore = score;
      return true;
    }
    return false;
  }

  void noteAdventureLevelCleared(int level) {
    if (level > adventureHighestCleared) adventureHighestCleared = level;
  }
}
