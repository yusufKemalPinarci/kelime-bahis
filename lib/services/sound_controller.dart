import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kısa oyun ses efektlerini çalar (dokunma, başarı/hata, seviye geçme,
/// combo, satın alma). Sesler `scripts/generate_sfx.dart` ile sentezlenip
/// `assets/audio/sfx/`'e gömülmüş — offline, lisans riski yok.
///
/// `AdsController`/`PurchaseController` ile aynı savunma felsefesi: herhangi
/// bir ses çalma hatası oyunu asla bloklamaz/crash ettirmez. `GameController`
/// bu sınıfa hiç dokunmaz — tetikleme tamamen UI katmanında kalır, oyun
/// mantığı platform ses API'lerinden bağımsız/test edilebilir kalır.
class SoundController {
  static const _kEnabledKey = 'sfx_enabled';

  bool _enabled = true;
  bool get enabled => _enabled;

  AudioPool? _tap;
  AudioPool? _success;
  AudioPool? _error;
  AudioPool? _levelClear;
  AudioPool? _purchase;
  AudioPlayer? _combo;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_kEnabledKey) ?? true;
    } catch (e) {
      debugPrint('Ses tercihi okunamadı: $e');
    }

    try {
      _tap = await AudioPool.createFromAsset(
        path: 'audio/sfx/tap.wav',
        maxPlayers: 3,
      );
      _success = await AudioPool.createFromAsset(
        path: 'audio/sfx/success.wav',
        maxPlayers: 2,
      );
      _error = await AudioPool.createFromAsset(
        path: 'audio/sfx/error.wav',
        maxPlayers: 2,
      );
      _levelClear = await AudioPool.createFromAsset(
        path: 'audio/sfx/level_clear.wav',
        maxPlayers: 2,
      );
      _purchase = await AudioPool.createFromAsset(
        path: 'audio/sfx/purchase.wav',
        maxPlayers: 2,
      );
      final combo = AudioPlayer();
      await combo.setReleaseMode(ReleaseMode.stop);
      await combo.setSource(AssetSource('audio/sfx/combo.wav'));
      _combo = combo;
    } catch (e) {
      debugPrint('Ses efektleri yüklenemedi: $e');
    }
  }

  Future<void> toggleEnabled() async {
    _enabled = !_enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kEnabledKey, _enabled);
    } catch (e) {
      debugPrint('Ses tercihi kaydedilemedi: $e');
    }
  }

  void playTap() => _play(_tap);
  void playSuccess() => _play(_success);
  void playError() => _play(_error);
  void playLevelClear() => _play(_levelClear);
  void playPurchase() => _play(_purchase);

  /// Seri (combo) sesi — `streak` arttıkça perde yükselir, ayrı dosyaya
  /// gerek yok.
  void playCombo(int streak) {
    if (!_enabled) return;
    final player = _combo;
    if (player == null) return;
    final rate = 1.0 + (streak - 1).clamp(0, 8) * 0.08;
    () async {
      try {
        await player.setPlaybackRate(rate);
        await player.seek(Duration.zero);
        await player.resume();
      } catch (e) {
        debugPrint('Combo sesi çalınamadı: $e');
      }
    }();
  }

  void _play(AudioPool? pool) {
    if (!_enabled || pool == null) return;
    pool.start().catchError((Object e) {
      debugPrint('Ses çalınamadı: $e');
      // AudioPool.start() dönüşü StopFunction bekliyor; hata durumunda
      // çağıran taraf zaten sesi umursamıyor, boş bir stop fonksiyonu yeterli.
      return () async {};
    });
  }

  Future<void> dispose() async {
    await _tap?.dispose();
    await _success?.dispose();
    await _error?.dispose();
    await _levelClear?.dispose();
    await _purchase?.dispose();
    await _combo?.dispose();
  }
}
