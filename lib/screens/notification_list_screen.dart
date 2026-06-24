import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationListScreen extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;

  const NotificationListScreen({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
  });

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? list = prefs.getStringList('local_notifications');
      
      // If it's the very first time, seed welcome notifications
      if (list == null) {
        final List<Map<String, dynamic>> defaultNotifications = [
          {
            'id': 'welcome_1',
            'title': widget.languageCode == 'en' ? 'Welcome to Smart X Academy!' : 'እንኳን ወደ Smart X አካዳሚ በደህና መጡ!',
            'message': widget.languageCode == 'en' 
                ? 'Start your learning journey by exploring Grade 12 Mathematics.' 
                : 'የ12ኛ ክፍል ሂሳብን በመመርመር የትምህርት ጉዞዎን ይጀምሩ።',
            'time': widget.languageCode == 'en' ? '2 hours ago' : 'ከ2 ሰዓት በፊት',
            'is_read': false,
          },
          {
            'id': 'welcome_2',
            'title': widget.languageCode == 'en' ? 'Offline Mode Active' : 'ከመስመር ውጭ ሁነታ ንቁ ነው',
            'message': widget.languageCode == 'en' 
                ? 'You can download unit questions to practice quizzes offline anytime.' 
                : 'ከመስመር ውጭ በማንኛውም ጊዜ ጥያቄዎችን ለመለማመድ የክፍል ጥያቄዎችን ማውረድ ይችላሉ።',
            'time': widget.languageCode == 'en' ? '5 hours ago' : 'ከ5 ሰዓት በፊት',
            'is_read': false,
          }
        ];
        list = defaultNotifications.map((n) => jsonEncode(n)).toList();
        await prefs.setStringList('local_notifications', list);
      }
      
      final List<Map<String, dynamic>> parsedList = [];
      for (final item in list) {
        try {
          parsedList.add(Map<String, dynamic>.from(jsonDecode(item)));
        } catch (e) {
          debugPrint('Error parsing notification item: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          _notifications = parsedList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList('local_notifications') ?? [];
      final testNotification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': widget.languageCode == 'en' ? 'Smart Quiz Tip!' : 'የፈተና ምክር!',
        'message': widget.languageCode == 'en' 
            ? 'Practice makes perfect. Complete daily unit quizzes to master your courses.' 
            : 'መልመጃ ፍጹም ያደርጋል። ኮርሶችዎን ለማስተናገድ ዕለታዊ የክፍል ፈተናዎችን ያጠናቅቁ።',
        'time': widget.languageCode == 'en' ? 'Just now' : 'አሁን',
        'is_read': false,
      };
      list.insert(0, jsonEncode(testNotification));
      await prefs.setStringList('local_notifications', list);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.languageCode == 'en' ? 'Test notification added!' : 'የሙከራ ማሳወቂያ ታክሏል!'),
          ),
        );
      }
      
      await _loadNotifications();
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList('local_notifications') ?? [];
      final List<String> updatedList = [];
      for (final item in list) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(jsonDecode(item));
        if (map['id'].toString() == id) {
          map['is_read'] = true;
        }
        updatedList.add(jsonEncode(map));
      }
      await prefs.setStringList('local_notifications', updatedList);
      await _loadNotifications();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('local_notifications', []);
      await _loadNotifications();
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = !widget.isDarkMode;
    final backgroundColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final cardColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final titleColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final subtitleColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.languageCode == 'en' ? 'Notifications' : 'ማሳወቂያዎች',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
        foregroundColor: titleColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: widget.languageCode == 'en' ? 'Clear All' : 'ሁሉንም አጽዳ',
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(widget.languageCode == 'en' ? 'Clear All' : 'ሁሉንም አጽዳ'),
                    content: Text(widget.languageCode == 'en' 
                      ? 'Are you sure you want to clear all notifications?' 
                      : 'እርግጠኛ ነዎት ሁሉንም ማሳወቂያዎች ማጽዳት ይፈልጋሉ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(widget.languageCode == 'en' ? 'Cancel' : 'ይቅር'),
                      ),
                      TextButton(
                        onPressed: () {
                          _clearAllNotifications();
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          widget.languageCode == 'en' ? 'Clear' : 'አጽዳ',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                }
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendTestNotification,
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.add_alert_rounded, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 64, color: subtitleColor),
                      const SizedBox(height: 16),
                      Text(
                        widget.languageCode == 'en' ? 'No notifications yet' : 'ምንም ማሳወቂያዎች የሉም',
                        style: TextStyle(color: subtitleColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final bool isRead = notification['is_read'] ?? false;
                    final String time = notification['time'] ?? 'Just now';

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isLight ? 0.03 : 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: isRead
                              ? Colors.transparent
                              : const Color(0xFF3B82F6).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isRead 
                                ? Colors.grey.withOpacity(0.1)
                                : const Color(0xFF3B82F6).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded, 
                            color: isRead ? Colors.grey : const Color(0xFF3B82F6),
                          ),
                        ),
                        title: Text(
                          notification['title'] ?? 'Notification',
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.w900,
                            fontSize: 15,
                            color: titleColor,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              notification['message'] ?? '',
                              style: TextStyle(
                                color: isRead ? subtitleColor.withOpacity(0.7) : subtitleColor, 
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              time,
                              style: TextStyle(color: subtitleColor.withOpacity(0.5), fontSize: 11),
                            ),
                          ],
                        ),
                        onTap: () async {
                          if (!isRead) {
                            await _markAsRead(notification['id'].toString());
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
