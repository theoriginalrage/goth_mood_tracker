import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ads_ids.dart';

class HistoryBanner extends StatefulWidget {
  const HistoryBanner({super.key});
  @override
  State<HistoryBanner> createState() => _HistoryBannerState();
}

class _HistoryBannerState extends State<HistoryBanner> {
  BannerAd? _ad;

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, err) { ad.dispose(); setState(() => _ad = null); },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: _ad!.size.width.toDouble(),
        height: _ad!.size.height.toDouble(),
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}

