import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_api_availability/google_api_availability.dart';

class GmsAndAdsService {
  static bool isGmsAvailable = false;
  static bool isFirebaseInitialized = false;
  static bool isAdMobInitialized = false;
  static String? fcmToken;
  static String? statusMessage;

  /// Starts asynchronous background initialization of GMS, Firebase and AdMob.
  /// This ensures absolutely zero startup lag or UI freezes.
  static void initializeBackground() {
    statusMessage = "Starting system checklist...";
    Future.microtask(() async {
      try {
        await initializeServices();
      } catch (e) {
        statusMessage = "Encountered initial error: $e";
        if (kDebugMode) {
          print("Error in background helper initialization: $e");
        }
      }
    });
  }

  /// Check GMS, initialize Firebase & AdMob safely
  static Future<void> initializeServices() async {
    // 1. Perform GMS check (safely handling errors)
    isGmsAvailable = await _checkGmsAvailability();
    
    if (!isGmsAvailable) {
      statusMessage = "Non-GMS Device detected. Safe Mode active.";
      if (kDebugMode) {
        print("GMS/Google Play Services are missing or unavailable. Skipping Firebase and AdMob initialization cleanly.");
      }
      return;
    }

    statusMessage = "GMS Verified. Initializing services...";
    if (kDebugMode) {
      print("GMS/Google Play Services are available. Proceeding with Firebase and AdMob initialization.");
    }

    // 2. Initialize Firebase Core
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: _currentFirebaseOptions,
        );
      }
      isFirebaseInitialized = true;
      if (kDebugMode) {
        print("Firebase successfully initialized.");
      }
      
      // Request and setup Firebase Push Notifications
      await _setupNotifications();
    } catch (e) {
      statusMessage = "Firebase error: $e";
      if (kDebugMode) {
        print("Failed to initialize Firebase: $e");
      }
    }

    // 3. Initialize Google Mobile Ads (AdMob)
    try {
      await MobileAds.instance.initialize();
      isAdMobInitialized = true;
      if (kDebugMode) {
        print("AdMob successfully initialized.");
      }
      statusMessage = "All systems operational (GMS Active).";
    } catch (e) {
      statusMessage = "AdMob error: $e";
      if (kDebugMode) {
        print("Failed to initialize AdMob: $e");
      }
    }
  }

  /// Private helper to check GMS availability
  static Future<bool> _checkGmsAvailability() async {
    if (!Platform.isAndroid) {
      // Non-Android platforms are not constrained by Google Play Services
      return true;
    }
    try {
      const googleApiCheck = GoogleApiAvailability.instance;
      final availability = await googleApiCheck.checkPlayServicesAvailability();
      return availability == GooglePlayServicesAvailability.success;
    } catch (e) {
      if (kDebugMode) {
        print("Exception during GMS check: $e");
      }
      return false;
    }
  }

  /// Set up push notifications
  static Future<void> _setupNotifications() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Request permissions (especially useful for iOS & Android 13+)
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('User notification permission status: ${settings.authorizationStatus}');
      }

      // Get FCM token
      fcmToken = await messaging.getToken();
      if (kDebugMode) {
        print("FCM Token: $fcmToken");
      }

      // Handle background or foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('FCM Foreground: Message data: ${message.data}');
        }
        if (message.notification != null && kDebugMode) {
          print('FCM Title: ${message.notification?.title}');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error during notifications setup: $e");
      }
    }
  }

  /// Return current platform appropriate firebase options
  static FirebaseOptions get _currentFirebaseOptions {
    if (Platform.isIOS) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyBbDTLG9q0yCzXA-vzffB2hwSRoDeaXymA',
        appId: '1:629000096457:ios:ca9e524da1729a4afedb18',
        messagingSenderId: '629000096457',
        projectId: 'smart-x-academy',
        storageBucket: 'smart-x-academy.firebasestorage.app',
        iosBundleId: 'com.smartxacademy.app',
      );
    }
    return const FirebaseOptions(
      apiKey: 'AIzaSyBbDTLG9q0yCzXA-vzffB2hwSRoDeaXymA',
      appId: '1:629000096457:android:ca9e524da1729a4afedb18',
      messagingSenderId: '629000096457',
      projectId: 'smart-x-academy',
      storageBucket: 'smart-x-academy.firebasestorage.app',
    );
  }
}

/// A highly polished, GMS-safe AdMob banner widget
class SmartXAdsBannerWidget extends StatefulWidget {
  final AdSize adSize;
  const SmartXAdsBannerWidget({
    super.key,
    this.adSize = AdSize.banner,
  });

  @override
  State<SmartXAdsBannerWidget> createState() => _SmartXAdsBannerWidgetState();
}

class _SmartXAdsBannerWidgetState extends State<SmartXAdsBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    // If GMS is not available, or AdMob has not successfully initialized,
    // do not attempt to load standard AdMob to avoid core crashes or errors.
    if (!GmsAndAdsService.isGmsAvailable || !GmsAndAdsService.isAdMobInitialized) {
      setState(() {
        _failed = true;
      });
      return;
    }

    try {
      _bannerAd = BannerAd(
        adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Official Google AdMob test banner unit ID
        size: widget.adSize,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            setState(() {
              _isLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            if (kDebugMode) {
              print('AdMob Banner Ad failed to load: $error');
            }
            ad.dispose();
            setState(() {
              _failed = true;
            });
          },
        ),
      )..load();
    } catch (e) {
      if (kDebugMode) {
        print("AdMob error in widget container: $e");
      }
      setState(() {
        _failed = true;
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (_failed) {
      // Non-GMS or AdMob failed placeholder banner (Designed with exact visual quality)
      return Container(
        width: double.infinity,
        height: widget.adSize.height.toDouble(),
        margin: const EdgeInsets.symmetric(vertical: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D2353).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.security_rounded,
                color: Color(0xFF1E88E5),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Smart X Clean Safe Mode",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: isDark ? Colors.white : const Color(0xFF1E2843),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    !GmsAndAdsService.isGmsAvailable
                        ? "Running without Google Play Services. No ads or tracking."
                        : "Educational Content Enabled.",
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "PREMIUM",
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!_isLoaded) {
      // Sleek shimmering/loading placeholder state
      return Container(
        width: double.infinity,
        height: widget.adSize.height.toDouble(),
        margin: const EdgeInsets.symmetric(vertical: 12.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF1E88E5),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "Preparing sponsor banner...",
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    // Return the actual Google Mobile Ads widget
    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
