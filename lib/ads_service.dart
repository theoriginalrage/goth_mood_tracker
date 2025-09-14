import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ads_ids.dart';

class AdsService {
  static InterstitialAd? _i;
  static int _savesSinceAd = 0;

  static Future<void> init() async => _load();

  static Future<void> _load() async {
    await InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _i = ad,
        onAdFailedToLoad: (_) => _i = null,
      ),
    );
  }

  static Future<void> onSave() async {
    _savesSinceAd++;
    if (_savesSinceAd >= 3 && _i != null) {
      _savesSinceAd = 0;
      await _i!.show();
      _i = null;
      _load();
    }
  }

  static void dispose() {
    _i?.dispose();
    _i = null;
  }
}

