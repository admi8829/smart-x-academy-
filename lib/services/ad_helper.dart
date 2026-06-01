import 'dart:io';

class AdHelper {
  /// Returns the Android AdMob Test Banner Unit ID.
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /// Returns the Android AdMob Test Interstitial Unit ID.
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /// Returns the Android AdMob Test Rewarded Video Unit ID.
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
