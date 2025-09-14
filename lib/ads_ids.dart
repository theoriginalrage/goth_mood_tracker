import 'package:flutter/foundation.dart';

// Google test units (must be used for dev)
const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';

// Your real units (release only)
const _realBanner = 'ca-app-pub-0932354922534500/5338517500';
const _realInterstitial = 'ca-app-pub-0932354922534500/8734018797';

String get bannerUnitId => kReleaseMode ? _realBanner : _testBanner;
String get interstitialUnitId => kReleaseMode ? _realInterstitial : _testInterstitial;

