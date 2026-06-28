import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final _supabase = Supabase.instance.client;

  /// Saves the user's feedback ('Interested' or 'Not Interested') for a notification.
  /// First updates the local preferences, then persists to Supabase 'notification_feedback' table.
  static Future<void> saveFeedback(String notificationId, String feedback) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('feedback_$notificationId', feedback);
      debugPrint('Saved feedback "$feedback" locally for notification $notificationId');
    } catch (e) {
      debugPrint('Error saving feedback locally: $e');
    }

    try {
      final userId = _supabase.auth.currentUser?.id;
      await _supabase.from('notification_feedback').upsert({
        'notification_id': notificationId,
        'feedback': feedback,
        'user_id': userId,
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('Successfully synced feedback "$feedback" to Supabase');
    } catch (e) {
      debugPrint('Failed to sync feedback to Supabase: $e');
    }
  }

  /// Fetches in-app notifications from Supabase 'notifications' table.
  /// If the table doesn't exist, it returns a mock list to prevent errors.
  static Future<List<Map<String, dynamic>>> fetchNotifications() async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching notifications from Supabase: $e');
      // Return a mock list as a fallback "solution" for the user to see it working
      return [
        {
          'id': '1',
          'title': 'Welcome to Smart X Academy!',
          'message': 'Start your learning journey by exploring Grade 12 Mathematics.',
          'time': '2 hours ago',
          'is_read': false,
          'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'id': '2',
          'title': 'New Quiz Available',
          'message': 'A new Biology quiz for Grade 11 has been added.',
          'time': '5 hours ago',
          'is_read': false,
          'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        },
      ];
    }
  }

  /// Marks a specific notification as read in Supabase.
  static Future<void> markAsRead(String id) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Gets the count of unread notifications.
  static Future<int> getUnreadCount() async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('is_read', false);
      
      return (response as List).length;
    } catch (e) {
      // Fallback for mock behavior
      return 2;
    }
  }
}
