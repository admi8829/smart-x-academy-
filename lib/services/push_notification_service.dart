import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/notification_list_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/notes_screen.dart';

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
    title ??= 'New Notification';
    body ??= '';

    final prefs = await SharedPreferences.getInstance();
    final String userName = prefs.getString('user_fullName') ?? prefs.getString('user_name') ?? 'ተማሪ';
    final String personalizedTitle = title.replaceAll('[name]', userName);
    final String personalizedBody = body.replaceAll('[name]', userName);

    await PushNotificationService.saveLocalNotification(
      personalizedTitle,
      personalizedBody,
      data: message.data,
    );

    final String notificationId = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
    await PushNotificationService.showLocalNotificationWithActions(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: personalizedTitle,
      body: personalizedBody,
      payload: jsonEncode({
        'id': notificationId,
        ...message.data,
      }),
      actionsPayload: message.data['actions']?.toString(),
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
          final actionId = response.actionId;
          final p = response.payload;
          if (actionId != null && actionId.isNotEmpty) {
            await _handleCustomAction(actionId, p);
          } else {
            await _navigateToNotificationScreen();
          }
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
            actionsPayload: message.data['actions']?.toString(),
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
    String? actionsPayload,
  }) async {
    try {
      // Ensure Flutter Local Notifications is initialized in this isolate/context
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );
      
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          final actionId = response.actionId;
          final p = response.payload;
          if (actionId != null && actionId.isNotEmpty) {
            await _handleCustomAction(actionId, p);
          } else {
            await _navigateToNotificationScreen();
          }
        },
      );

      List<AndroidNotificationAction> androidActions = [];
      if (actionsPayload != null && actionsPayload.isNotEmpty) {
        try {
          final List<dynamic> parsedActions = jsonDecode(actionsPayload);
          for (var i = 0; i < parsedActions.length && i < 3; i++) {
            final act = parsedActions[i];
            if (act is Map) {
              final aId = act['id']?.toString() ?? '';
              final aTitle = act['title']?.toString() ?? '';
              if (aId.isNotEmpty && aTitle.isNotEmpty) {
                androidActions.add(
                  AndroidNotificationAction(
                    aId,
                    aTitle,
                    showsUserInterface: true,
                    cancelNotification: true,
                  ),
                );
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing actions: $e');
        }
      }

      final AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        'smart_x_channel_id',
        'Smart X Notifications',
        channelDescription: 'Main Notification Channel for Smart X Academy',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        playSound: true,
        enableLights: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(body),
        actions: androidActions.isNotEmpty ? androidActions : null,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
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
        'actions': data?['actions'],
        'grade': data?['grade']?.toString(),
        'subjectId': data?['subjectId']?.toString(),
        'unitNumber': data?['unitNumber']?.toString(),
        'unitTitle': data?['unitTitle']?.toString(),
        'themeColor': data?['themeColor']?.toString(),
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

  static Color _parseThemeColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return const Color(0xFF3B82F6);
    try {
      if (colorStr.startsWith('#')) {
        final hex = colorStr.replaceAll('#', '');
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          return Color(int.parse(hex, radix: 16));
        }
      } else if (colorStr.startsWith('0x') || colorStr.startsWith('0X')) {
        final hex = colorStr.substring(2);
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          return Color(int.parse(hex, radix: 16));
        }
      }
      
      switch (colorStr.toLowerCase()) {
        case 'red': return Colors.red;
        case 'blue': return Colors.blue;
        case 'green': return Colors.green;
        case 'orange': return Colors.orange;
        case 'purple': return Colors.purple;
        case 'teal': return Colors.teal;
        case 'amber': return Colors.amber;
        case 'pink': return Colors.pink;
      }
    } catch (_) {}
    return const Color(0xFF3B82F6);
  }

  static Future<void> _handleCustomAction(String actionId, String? payloadStr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool('isDarkMode') ?? false;
      final languageCode = prefs.getString('languageCode') ?? 'en';
      final int userGrade = prefs.getInt('user_grade') ?? 12;

      Map<String, dynamic> data = {};
      if (payloadStr != null && payloadStr.isNotEmpty) {
        try {
          data = jsonDecode(payloadStr) as Map<String, dynamic>;
        } catch (_) {}
      }

      final grade = int.tryParse(data['grade']?.toString() ?? '') ?? userGrade;
      final subjectId = data['subjectId']?.toString() ?? 'physics';
      final unitNumber = int.tryParse(data['unitNumber']?.toString() ?? '') ?? 1;
      final unitTitle = data['unitTitle']?.toString() ?? 'Unit $unitNumber';
      final themeColor = _parseThemeColor(data['themeColor']?.toString());

      if (actionId == 'read' || actionId == 'አንብብ') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => NotesScreen(
              grade: grade,
              subjectId: subjectId,
              unitNumber: unitNumber,
              unitTitle: unitTitle,
              themeColor: themeColor,
              isDarkMode: isDarkMode,
              languageCode: languageCode,
            ),
          ),
        );
      } else if (actionId == 'quiz' || actionId == 'ፈተና ጀምር') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => QuizScreen(
              mode: QuizMode.exam,
              grade: grade,
              subjectId: subjectId,
              unitNumber: unitNumber,
              isDarkMode: isDarkMode,
              languageCode: languageCode,
            ),
          ),
        );
      } else {
        await _navigateToNotificationScreen();
      }
    } catch (e) {
      debugPrint('Error in _handleCustomAction: $e');
      await _navigateToNotificationScreen();
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
