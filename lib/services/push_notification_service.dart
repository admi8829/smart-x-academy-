import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.notification != null) {
    final title = message.notification!.title ?? 'New Notification';
    final body = message.notification!.body ?? '';
    await PushNotificationService.saveLocalNotification(title, body);
  }
}

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Initialize Firebase and set up handlers
  static Future<void> initialize() async {
    try {
      // Assuming google-services.json is configured, calling initializeApp automatically reads it.
      await Firebase.initializeApp();

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          final title = message.notification!.title ?? 'New Notification';
          final body = message.notification!.body ?? '';
          debugPrint('Message also contained a notification: $title - $body');
          await saveLocalNotification(title, body);
        }
      });

    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
    }
  }

  static Future<void> saveLocalNotification(String title, String body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList('local_notifications') ?? [];
      final newNotification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'message': body,
        'time': _getFormattedTime(DateTime.now()),
        'is_read': false,
      };
      list.insert(0, jsonEncode(newNotification)); // newest first
      await prefs.setStringList('local_notifications', list);
    } catch (e) {
      debugPrint('Error saving local notification: $e');
    }
  }

  static String _getFormattedTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return "$hour:$minute - ${dt.day}/${dt.month}/${dt.year}";
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
