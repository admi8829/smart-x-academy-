import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Initialize Firebase and set up handlers
  static Future<void> initialize() async {
    try {
      // Assuming google-services.json is configured, calling initializeApp automatically reads it.
      await Firebase.initializeApp();

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification!.title} - ${message.notification!.body}');
          // Optionally, display a local snackbar or toast here
        }
      });

    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
    }
  }

  // Request permission for iOS/Web and devices on Android 13+ after Splash Screen completes
  static Future<void> requestNotificationPermission() async {
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission for push notifications');
        String? token = await _fcm.getToken();
        debugPrint("FCM Registration Token: $token");
      } else {
        debugPrint('User declined or has not accepted permission');
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }
}
