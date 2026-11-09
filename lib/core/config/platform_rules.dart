import 'package:flutter/foundation.dart';

class PlatformRules {
  const PlatformRules._();

  static bool get paidAdsAllowed => defaultTargetPlatform != TargetPlatform.iOS;

  static bool get googleSignInAvailable =>
      defaultTargetPlatform == TargetPlatform.android;
}
