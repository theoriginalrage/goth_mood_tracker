import 'package:flutter/foundation.dart';

const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
const _realBanner = 'ca-app-pub-0932354922534500/5338517500';

// TODO: create an interstitial in AdMob and add its ID here
const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
const _realInterstitial = 'REPLACE_WITH_REAL_INTERSTITIAL';

String get bannerUnitId => kReleaseMode ? _realBanner : _testBanner;
String get interstitialUnitId =>
    kReleaseMode ? _realInterstitial : _testInterstitial;

