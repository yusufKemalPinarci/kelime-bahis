import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_config.dart';

/// Tek seferlik "reklamları kaldır" satın alımını sarar. Mağaza her zaman
/// erişilebilir olmayabilir (ağ yok, ürün henüz Play Console'da yayınlanmamış
/// vb.) — bu durumlarda satın alma butonu sessizce devre dışı kalır.
class PurchaseController extends ChangeNotifier {
  PurchaseController({this.onAdsRemovedChanged});

  /// Satın alma doğrulandığında çağrılır (örn. `AdsController.setAdsRemoved`).
  final void Function(bool removed)? onAdsRemovedChanged;

  static const _kAdsRemovedKey = 'ads_removed';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool _adsRemoved = false;
  bool _storeAvailable = false;
  bool _purchasePending = false;
  ProductDetails? _removeAdsProduct;
  String? _lastErrorMessage;

  bool get adsRemoved => _adsRemoved;
  bool get storeAvailable => _storeAvailable;
  bool get purchasePending => _purchasePending;
  String? get removeAdsPriceLabel => _removeAdsProduct?.price;

  /// Kullanıcıya gösterilecek son satın alma hatası (varsa). UI bunu
  /// gösterdikten sonra [clearLastError] ile temizlemeli.
  String? get lastErrorMessage => _lastErrorMessage;

  void clearLastError() {
    if (_lastErrorMessage == null) return;
    _lastErrorMessage = null;
    notifyListeners();
  }
  bool get canPurchase =>
      _storeAvailable && !_adsRemoved && _removeAdsProduct != null;

  Future<void> init() async {
    // Önce yerel önbellek: mağazaya ulaşamasak bile önceki satın alım UI'da yansısın.
    try {
      final prefs = await SharedPreferences.getInstance();
      _adsRemoved = prefs.getBool(_kAdsRemovedKey) ?? false;
      if (_adsRemoved) onAdsRemovedChanged?.call(true);
      notifyListeners();
    } catch (e) {
      debugPrint('Satın alma önbelleği okunamadı: $e');
    }

    try {
      _storeAvailable = await _iap.isAvailable();
    } catch (e) {
      debugPrint('Mağaza erişilemedi: $e');
      _storeAvailable = false;
    }
    if (!_storeAvailable) {
      notifyListeners();
      return;
    }

    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (e) => debugPrint('Satın alma akışı hatası: $e'),
    );

    try {
      final response =
          await _iap.queryProductDetails({AdConfig.removeAdsProductId});
      if (response.productDetails.isNotEmpty) {
        _removeAdsProduct = response.productDetails.first;
      }
    } catch (e) {
      debugPrint('Ürün bilgisi alınamadı: $e');
    }

    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Satın alımlar geri yüklenemedi: $e');
    }
    notifyListeners();
  }

  void buyRemoveAds() {
    final product = _removeAdsProduct;
    if (product == null || _adsRemoved) return;
    _purchasePending = true;
    _lastErrorMessage = null;
    notifyListeners();
    _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.productID != AdConfig.removeAdsProductId) continue;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _purchasePending = false;
          _markAdsRemoved();
        case PurchaseStatus.error:
          _purchasePending = false;
          _lastErrorMessage = 'Satın alma tamamlanamadı. Lütfen tekrar deneyin.';
          debugPrint('Satın alma hatası: ${purchase.error}');
        case PurchaseStatus.canceled:
          _purchasePending = false;
      }
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
    notifyListeners();
  }

  Future<void> _markAdsRemoved() async {
    if (_adsRemoved) return;
    _adsRemoved = true;
    onAdsRemovedChanged?.call(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kAdsRemovedKey, true);
    } catch (e) {
      debugPrint('Satın alma önbelleğe yazılamadı: $e');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
