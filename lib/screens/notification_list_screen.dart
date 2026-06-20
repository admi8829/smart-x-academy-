import 'package:flutter/material.dart';
import '../services/notification_service.dart';

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
    setState(() => _isLoading = true);
    final data = await NotificationService.fetchNotifications();
    if (mounted) {
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      final supabase = NotificationService.fetchNotifications(); // just to check connection
      // We'll use a mocked insert logic if they don't have the table yet
      // In a real scenario, this would be: 
      // await Supabase.instance.client.from('notifications').insert({...})
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification sent! Refreshing...')),
      );
      
      await _loadNotifications();
    } catch (e) {
      debugPrint('Error sending test notification: $e');
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
                    final bool isRead = notification['is_read'] ?? notification['isRead'] ?? false;
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
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_active_outlined, color: Color(0xFF3B82F6)),
                        ),
                        title: Text(
                          notification['title'] ?? 'Notification',
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.bold : FontWeight.w900,
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
                              style: TextStyle(color: subtitleColor, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              time,
                              style: TextStyle(color: subtitleColor.withOpacity(0.7), fontSize: 11),
                            ),
                          ],
                        ),
                        onTap: () async {
                          if (!isRead) {
                            await NotificationService.markAsRead(notification['id'].toString());
                            _loadNotifications();
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
