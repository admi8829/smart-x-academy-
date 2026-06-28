import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';
import '../screens/notification_list_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.notification != null) {
    final title = message.notification!.title ?? 'New Notification';
    final body = message.notification!.body ?? '';
    await PushNotificationService.saveLocalNotification(title, body, data: message.data);
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
          final String? actionId = response.actionId;
          final String? payload = response.payload;
          
          if (actionId != null && payload != null) {
            debugPrint('Local Notification Action Tapped: $actionId, payload: $payload');
            String notificationId = 'push_${DateTime.now().millisecondsSinceEpoch}';
            try {
              final data = jsonDecode(payload);
              notificationId = data['id'] ?? notificationId;
            } catch (_) {}
            
            if (actionId == 'interested') {
              await NotificationService.saveFeedback(notificationId, 'Interested');
            } else if (actionId == 'not_interested') {
              await NotificationService.saveFeedback(notificationId, 'Not Interested');
            }
          }

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

        if (message.notification != null) {
          final title = message.notification!.title ?? 'New Notification';
          final body = message.notification!.body ?? '';
          
          final prefs = await SharedPreferences.getInstance();
          final userName = prefs.getString('user_name') ?? prefs.getString('user_fullName') ?? 'ተማሪ';
          final personalizedBody = body.replaceAll('[name]', userName);
          
          debugPrint('Message also contained a notification: $title - $personalizedBody');
          
          await saveLocalNotification(title, personalizedBody, data: message.data);

          // Show local notification with action buttons
          final String notificationId = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
          await showLocalNotificationWithActions(
            id: DateTime.now().millisecondsSinceEpoch % 100000,
            title: title,
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
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'interested',
            'Interested',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'not_interested',
            'Not Interested',
            showsUserInterface: true,
          ),
        ],
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
      
      // Personalization: Extract 'user_name' from SharedPreferences and replace [name] placeholder (fallback to 'ተማሪ')
      final String userName = prefs.getString('user_name') ?? prefs.getString('user_fullName') ?? 'ተማሪ';
      final String personalizedBody = body.replaceAll('[name]', userName);

      // Extract URL if any exists in message body or data
      String? url;
      if (data != null && data['url'] != null) {
        url = data['url'].toString();
      } else {
        url = _extractUrl(personalizedBody);
      }

      final newNotification = {
        'id': data?['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
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
