import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      // Assuming google-services.json is configured, calling initializeApp automatically reads it.
      await Firebase.initializeApp();

      // Request permission for iOS/Web and devices on Android 13+
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission for push notifications');
      } else {
        debugPrint('User declined or has not accepted permission');
      }

      // Handle raw Firebase configuration where FCM tokens are used for specific messages
      String? token = await _fcm.getToken();
      debugPrint("FCM Registration Token: $token");

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
      debugPrint('Error initializing Firebase / FCM: $e');
    }
  }
}
