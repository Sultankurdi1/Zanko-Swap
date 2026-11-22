import 'package:flutter/foundation.dart';

class PlatformRules {
  const PlatformRules._();

  /// Paid ads are hidden in the iOS app (App Store rules). The website is not
  /// in the App Store, so it allows them on every phone.
  static bool get paidAdsAllowed =>
      kIsWeb || defaultTargetPlatform != TargetPlatform.iOS;

  /// Google sign-in: the Android app uses the native Google flow, the website
  /// uses Supabase's redirect flow (see SignInScreen._google).
  static bool get googleSignInAvailable =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.android;
}
