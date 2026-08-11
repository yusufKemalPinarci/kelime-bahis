import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../services/ads_controller.dart';

/// Banner reklam yuvası — reklam yoksa/kaldırılmışsa hiç yer kaplamaz.
class BannerAdSlot extends StatelessWidget {
  const BannerAdSlot({super.key, required this.adsController});

  final AdsController adsController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: adsController,
      builder: (context, _) {
        final ad = adsController.bannerAd;
        if (ad == null) return const SizedBox.shrink();
        return Container(
          alignment: Alignment.center,
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          margin: const EdgeInsets.only(top: 8),
          child: AdWidget(ad: ad),
        );
      },
    );
  }
}
