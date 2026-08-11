import 'package:flutter/foundation.dart';

/// Reklam kimlikleri — AdMob konsolundaki Kelime Bahis uygulamasının gerçek ID'leri.
///
/// Debug build'lerde Google'ın resmi test reklam ID'leri kullanılır — gerçek
/// ID'lerle kendi cihazında test edip tıklarsan/çok görüntülersen AdMob
/// hesabın geçersiz trafik nedeniyle askıya alınabilir. Release build'de
/// davranış değişmez, gerçek ID'ler kullanılır.
abstract final class AdConfig {
  /// Google'ın herkese açık test reklam ID'leri (resmi dokümantasyon).
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  /// AdMob konsolu → Reklam birimleri → Banner.
  static const String _liveBannerAdUnitId =
      'ca-app-pub-6704147140468357/7943082501';

  /// AdMob konsolu → Reklam birimleri → Ödüllü.
  static const String _liveRewardedAdUnitId =
      'ca-app-pub-6704147140468357/7274812750';

  static String get bannerAdUnitId =>
      kDebugMode ? _testBannerAdUnitId : _liveBannerAdUnitId;

  static String get rewardedAdUnitId =>
      kDebugMode ? _testRewardedAdUnitId : _liveRewardedAdUnitId;

  /// Ödüllü reklam sonunda mağazada kazandırılan altın.
  static const int rewardedGoldAmount = 3;

  /// Play Console → Uygulama içi ürünler → tek seferlik, non-consumable ürün ID'si.
  /// Play Console'da aynı ID ile ürün oluşturulmalı.
  static const String removeAdsProductId = 'remove_ads';
}
