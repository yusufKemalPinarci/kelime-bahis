import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// Banner + ödüllü reklam yaşam döngüsünü sarar. Reklam yüklenemezse
/// (ağ yok, doldurulmadı, vb.) sessizce boş kalır — oyunu asla bloklamaz.
class AdsController extends ChangeNotifier {
  BannerAd? _bannerAd;
  RewardedAd? _rewardedAd;
  bool _adsRemoved = false;
  bool _loadingRewarded = false;

  BannerAd? get bannerAd => _adsRemoved ? null : _bannerAd;
  bool get isRewardedReady => !_adsRemoved && _rewardedAd != null;
  bool get adsRemoved => _adsRemoved;

  Future<void> init() async {
    // AB/İngiltere kullanıcıları için reklam istemeden önce UMP/GDPR onayı
    // alınmalı (AdMob politikası). Onay akışı başarısız olsa/atlansa bile
    // oyun asla bloklanmaz — sadece reklam yüklenmeyebilir.
    final params = ConsentRequestParameters(
      consentDebugSettings: kDebugMode
          ? ConsentDebugSettings(
              debugGeography: DebugGeography.debugGeographyEea,
            )
          : null,
    );
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () => ConsentForm.loadAndShowConsentFormIfRequired((formError) {
        if (formError != null) {
          debugPrint('UMP formu: ${formError.errorCode} ${formError.message}');
        }
        _initializeIfAllowed();
      }),
      (error) {
        debugPrint('UMP onay bilgisi alınamadı: ${error.errorCode} ${error.message}');
        _initializeIfAllowed();
      },
    );
  }

  Future<void> _initializeIfAllowed() async {
    if (!await ConsentInformation.instance.canRequestAds()) {
      debugPrint('Reklam isteme izni yok (onay eksik/reddedildi) — reklamsız devam.');
      return;
    }
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('MobileAds init başarısız: $e');
      return;
    }
    if (!_adsRemoved) {
      _loadBanner();
      _loadRewarded();
    }
  }

  /// PurchaseController "reklamları kaldır" satın alımını doğruladığında çağırır.
  void setAdsRemoved(bool removed) {
    if (_adsRemoved == removed) return;
    _adsRemoved = removed;
    if (removed) {
      _bannerAd?.dispose();
      _bannerAd = null;
      _rewardedAd?.dispose();
      _rewardedAd = null;
    }
    notifyListeners();
  }

  void _loadBanner() {
    BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _bannerAd = ad as BannerAd;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner reklam yüklenemedi: $error');
        },
      ),
    ).load();
  }

  void _loadRewarded() {
    if (_loadingRewarded || _adsRemoved) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: AdConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded = false;
          _rewardedAd = ad;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _loadingRewarded = false;
          debugPrint('Ödüllü reklam yüklenemedi: $error');
        },
      ),
    );
  }

  /// Ödüllü reklamı gösterir; kazanıldığında [onReward] çağrılır.
  /// Reklam hazır değilse hiçbir şey yapmaz (UI çağrıdan önce [isRewardedReady] kontrol etmeli).
  void showRewarded({required VoidCallback onReward}) {
    final ad = _rewardedAd;
    if (ad == null) return;
    _rewardedAd = null;
    notifyListeners();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewarded();
      },
    );
    ad.show(
      onUserEarnedReward: (ad, reward) => onReward(),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }
}
