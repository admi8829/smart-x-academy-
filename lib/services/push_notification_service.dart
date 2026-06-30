import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/notification_list_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
  String? title;
  String? body;
  
  if (message.notification != null) {
    title = message.notification!.title;
    body = message.notification!.body;
  }
  
  title ??= message.data['title']?.toString();
  body ??= message.data['body']?.toString() ?? message.data['message']?.toString();
  
  if (title != null || body != null) {
    await PushNotificationService.saveLocalNotification(
      title ?? 'New Notification',
      body ?? '',
      data: message.data,
    );
  }
}

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Initialize Firebase and set up handlers
  static Future<void> initialize() async {
    try {
      // Assuming google-services.json is configured, calling initializeApp automatically reads it.
      await Firebase.initializeApp();

      // Initialize Flutter Local Notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          // Ensure tapping the notification opens the application and routes to NotificationListScreen properly
          await _navigateToNotificationScreen();
        },
      );

      // Handle notification when app is opened from a background state via tapping a notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('App opened via FCM notification tap: ${message.messageId}');
        _navigateToNotificationScreen();
      });

      // Handle notification when app is opened from a terminated state via tapping a notification
      _fcm.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          debugPrint('App opened from terminated state via FCM notification tap: ${message.messageId}');
          _navigateToNotificationScreen();
        }
      });

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        String? title;
        String? body;

        if (message.notification != null) {
          title = message.notification!.title;
          body = message.notification!.body;
        }

        title ??= message.data['title']?.toString();
        body ??= message.data['body']?.toString() ?? message.data['message']?.toString();

        if (title != null || body != null) {
          title ??= 'New Notification';
          body ??= '';

          final prefs = await SharedPreferences.getInstance();
          final userName = prefs.getString('user_fullName') ?? prefs.getString('user_name') ?? 'ተማሪ';
          final personalizedTitle = title.replaceAll('[name]', userName);
          final personalizedBody = body.replaceAll('[name]', userName);

          debugPrint('Message also contained a notification: $personalizedTitle - $personalizedBody');

          await saveLocalNotification(personalizedTitle, personalizedBody, data: message.data);

          // Show local notification with action buttons
          final String notificationId = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
          await showLocalNotificationWithActions(
            id: DateTime.now().millisecondsSinceEpoch % 100000,
            title: personalizedTitle,
            body: personalizedBody,
            payload: jsonEncode({
              'id': notificationId,
              ...message.data,
            }),
          );
        }
      });

    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
    }
  }

  static Future<void> showLocalNotificationWithActions({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        'smart_x_channel_id',
        'Smart X Notifications',
        channelDescription: 'Main Notification Channel for Smart X Academy',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  static Future<void> saveLocalNotification(String title, String body, {Map<String, dynamic>? data}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList('local_notifications') ?? [];
      
      // Personalization: Extract 'user_fullName' or 'user_name' from SharedPreferences and replace [name] placeholder (fallback to 'ተማሪ')
      final String userName = prefs.getString('user_fullName') ?? prefs.getString('user_name') ?? 'ተማሪ';
      final String personalizedBody = body.replaceAll('[name]', userName);
      final String personalizedTitle = title.replaceAll('[name]', userName);

      // Extract URL if any exists in message body or data
      String? url;
      if (data != null && data['url'] != null) {
        url = data['url'].toString();
      } else {
        url = _extractUrl(personalizedBody);
      }

      final newNotification = {
        'id': data?['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'title': personalizedTitle,
        'message': personalizedBody,
        'time': _getFormattedTime(DateTime.now()),
        'is_read': false,
        'url': url,
      };
      list.insert(0, jsonEncode(newNotification)); // newest first
      await prefs.setStringList('local_notifications', list);
    } catch (e) {
      debugPrint('Error saving local notification: $e');
    }
  }

  static String? _extractUrl(String text) {
    final RegExp urlRegExp = RegExp(
      r'https?:\/\/[^\s]+',
      caseSensitive: false,
    );
    final Match? match = urlRegExp.firstMatch(text);
    return match?.group(0);
  }

  static String _getFormattedTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return "$hour:$minute - ${dt.day}/${dt.month}/${dt.year}";
  }

  static Future<void> _navigateToNotificationScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool('isDarkMode') ?? false;
      final languageCode = prefs.getString('languageCode') ?? 'en';
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => NotificationListScreen(
            isDarkMode: isDarkMode,
            languageCode: languageCode,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to NotificationListScreen: $e');
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
