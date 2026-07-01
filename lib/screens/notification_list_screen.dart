import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'notes_screen.dart';
import 'quiz_screen.dart';

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
  final Set<String> _expandedIds = {};
  final Map<String, String> _userFeedbacks = {};

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
      final List<String> list = prefs.getStringList('local_notifications') ?? [];
      
      final List<Map<String, dynamic>> parsedList = [];
      _userFeedbacks.clear();
      
      for (final item in list) {
        try {
          final map = Map<String, dynamic>.from(jsonDecode(item));
          parsedList.add(map);
          
          final String id = map['id'].toString();
          final String? savedFeedback = prefs.getString('feedback_$id');
          if (savedFeedback != null) {
            _userFeedbacks[id] = savedFeedback;
          }
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

  Future<void> _launchURL(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch url: $urlString');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  String? _parseLink(String message) {
    final RegExp urlRegExp = RegExp(
      r'https?:\/\/[^\s]+',
      caseSensitive: false,
    );
    final Match? match = urlRegExp.firstMatch(message);
    return match?.group(0);
  }

  String? _getYouTubeId(String url) {
    final RegExp regExp = RegExp(
      r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/|youtube\.com\/shorts\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    final Match? match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }

  Color _getSocialColor(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
      return const Color(0xFFFF0000);
    } else if (lower.contains('t.me') || lower.contains('telegram.org')) {
      return const Color(0xFF229ED9);
    } else if (lower.contains('facebook.com') || lower.contains('fb.com')) {
      return const Color(0xFF1877F2);
    }
    return const Color(0xFF4F46E5);
  }

  IconData _getSocialIcon(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
      return Icons.play_circle_fill_rounded;
    } else if (lower.contains('t.me') || lower.contains('telegram.org')) {
      return Icons.telegram_rounded;
    } else if (lower.contains('facebook.com') || lower.contains('fb.com')) {
      return Icons.facebook_rounded;
    }
    return Icons.link_rounded;
  }

  String _getSocialButtonLabel(String url) {
    final lower = url.toLowerCase();
    final isEn = widget.languageCode == 'en';
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
      return isEn ? 'Watch on YouTube' : 'ዩቲዩብ ላይ ይመልከቱ';
    } else if (lower.contains('t.me') || lower.contains('telegram.org')) {
      return isEn ? 'Join Telegram' : 'ቴሌግራም ይቀላቀሉ';
    } else if (lower.contains('facebook.com') || lower.contains('fb.com')) {
      return isEn ? 'Visit Facebook' : 'ፌስቡክ ይጎብኙ';
    }
    return isEn ? 'Open Link' : 'ሊንክ ይክፈቱ';
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
                    final String id = notification['id'].toString();
                    final bool isRead = notification['is_read'] ?? false;
                    final String time = notification['time'] ?? 'Just now';
                    final String message = notification['message'] ?? '';
                    final String title = notification['title'] ?? 'Notification';

                    final String? detectedUrl = notification['url'] ?? _parseLink(message);
                    final String? youtubeId = detectedUrl != null ? _getYouTubeId(detectedUrl) : null;
                    
                    final bool isLongMessage = message.length > 120;
                    final bool isExpanded = _expandedIds.contains(id);

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
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          if (!isRead) {
                            await _markAsRead(id);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isRead 
                                          ? Colors.grey.withOpacity(0.1)
                                          : const Color(0xFF3B82F6).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded, 
                                      color: isRead ? Colors.grey : const Color(0xFF3B82F6),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: TextStyle(
                                            fontWeight: isRead ? FontWeight.normal : FontWeight.w900,
                                            fontSize: 15,
                                            color: titleColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          time,
                                          style: TextStyle(color: subtitleColor.withOpacity(0.5), fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF3B82F6),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                message,
                                maxLines: isExpanded ? null : 3,
                                overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isRead ? subtitleColor.withOpacity(0.7) : subtitleColor, 
                                  fontSize: 13.5,
                                  height: 1.4,
                                ),
                              ),
                              if (isLongMessage) ...[
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isExpanded) {
                                        _expandedIds.remove(id);
                                      } else {
                                        _expandedIds.add(id);
                                      }
                                    });
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isExpanded 
                                            ? (widget.languageCode == 'en' ? 'Show less' : 'በትንሹ አሳይ')
                                            : (widget.languageCode == 'en' ? 'Read more' : 'ተጨማሪ ያንብቡ'),
                                        style: const TextStyle(
                                          color: Color(0xFF3B82F6),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Icon(
                                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                        color: const Color(0xFF3B82F6),
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (notification['actions'] != null) ...[
                                const SizedBox(height: 12),
                                _buildNotificationActionButtons(context, notification),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildNotificationActionButtons(BuildContext context, Map<String, dynamic> notification) {
    try {
      final actionsField = notification['actions'];
      List<dynamic> actions = [];
      if (actionsField is String) {
        actions = jsonDecode(actionsField);
      } else if (actionsField is List) {
        actions = actionsField;
      }
      
      if (actions.isEmpty) return const SizedBox.shrink();
      
      return Row(
        children: actions.map<Widget>((act) {
          if (act is! Map) return const SizedBox.shrink();
          final String actionId = act['id']?.toString() ?? '';
          final String actionTitle = act['title']?.toString() ?? '';
          if (actionId.isEmpty || actionTitle.isEmpty) return const SizedBox.shrink();
          
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: () async {
                final String id = notification['id'].toString();
                if (!(notification['is_read'] ?? false)) {
                  await _markAsRead(id);
                }
                _handleUIAction(context, actionId, notification);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                foregroundColor: const Color(0xFF3B82F6),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                actionTitle,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  void _handleUIAction(BuildContext context, String actionId, Map<String, dynamic> notification) {
    try {
      final grade = int.tryParse(notification['grade']?.toString() ?? '') ?? 12;
      final subjectId = notification['subjectId']?.toString() ?? 'physics';
      final unitNumber = int.tryParse(notification['unitNumber']?.toString() ?? '') ?? 1;
      final unitTitle = notification['unitTitle']?.toString() ?? 'Unit $unitNumber';
      final themeColor = _parseThemeColor(notification['themeColor']?.toString());
      
      if (actionId == 'read' || actionId == 'አንብብ') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => NotesScreen(
              grade: grade,
              subjectId: subjectId,
              unitNumber: unitNumber,
              unitTitle: unitTitle,
              themeColor: themeColor,
              isDarkMode: widget.isDarkMode,
              languageCode: widget.languageCode,
            ),
          ),
        );
      } else if (actionId == 'quiz' || actionId == 'ፈተና ጀምር') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => QuizScreen(
              mode: QuizMode.exam,
              grade: grade,
              subjectId: subjectId,
              unitNumber: unitNumber,
              isDarkMode: widget.isDarkMode,
              languageCode: widget.languageCode,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error handling UI action: $e');
    }
  }

  Color _parseThemeColor(String? colorStr) {
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
}
