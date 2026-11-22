import 'package:flutter/foundation.dart';

class PlatformRules {
  const PlatformRules._();

  /// Paid ads are hidden in the iOS app (App Store rules). The website is not
  /// in the App Store, so it allows them on every phone.
  static bool get paidAdsAllowed =>
      kIsWeb || defaultTargetPlatform != TargetPlatform.iOS;

  /// Google sign-in is wired for the Android app only. On the web the native
  /// flow returns no ID token, so the website uses email and password.
  static bool get googleSignInAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}
