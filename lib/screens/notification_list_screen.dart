import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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
      List<String>? list = prefs.getStringList('local_notifications');
      
      // Seed curated notifications for testing if none exist
      if (list == null) {
        final List<Map<String, dynamic>> defaultNotifications = [
          {
            'id': 'social_yt_1',
            'title': widget.languageCode == 'en' ? 'New Trigonometry Video Lesson!' : 'አዲስ የትሪጎኖሜትሪ ቪዲዮ ትምህርት!',
            'message': widget.languageCode == 'en' 
                ? 'Watch our premium, step-by-step masterclass on Grade 12 Advanced Trigonometry. We solve challenging entrance exam questions! Join us on YouTube: https://www.youtube.com/watch?v=dQw4w9WgXcQ'
                : 'የ12ኛ ክፍል የላቀ ትሪጎኖሜትሪ ፕሪሚየም የቪዲዮ ትምህርታችንን ይመልከቱ። አስቸጋሪ የመግቢያ ፈተና ጥያቄዎችን ደረጃ በደረጃ እንፈታለን! ዩቲዩብ ላይ ይከታተሉን፡ https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            'time': widget.languageCode == 'en' ? '1 hour ago' : 'ከ1 ሰዓት በፊት',
            'is_read': false,
          },
          {
            'id': 'social_tg_1',
            'title': widget.languageCode == 'en' ? 'Official Telegram Channel' : 'ይፋዊ የቴሌግራም ቻናል',
            'message': widget.languageCode == 'en' 
                ? 'Get access to daily exam preparation worksheets, PDF study notes, and direct teacher consultations. Join the Smart X student community: https://t.me/smartxacademy'
                : 'ዕለታዊ የፈተና ማዘጋጃ ወረቀቶችን፣ የፒዲኤፍ የጥናት ማስታወሻዎችን እና የቀጥታ የመምህራን ምክክር ያግኙ። የስማርት ኤክስ ማህበረሰብን ይቀላቀሉ፡ https://t.me/smartxacademy',
            'time': widget.languageCode == 'en' ? '5 hours ago' : 'ከ5 ሰዓት በፊት',
            'is_read': false,
          },
          {
            'id': 'registration_info_1',
            'title': widget.languageCode == 'en' ? 'National Entrance Exam Registration Guidelines' : 'ብሔራዊ የመግቢያ ፈተና ምዝገባ መመሪያዎች',
            'message': widget.languageCode == 'en' 
                ? 'Attention candidates: The Ministry of Education has officially announced that the registration portal is open. To complete registration, ensure you have your school transcripts, valid school identification cards, and two clear digital photographs. Verification must be approved by high school administrators before the absolute cutoff on July 15th. Late registration requests will be rejected by the system under any circumstances.'
                : 'ለተማሪዎች በሙሉ፡ የዚህ አመት የመግቢያ ፈተና ምዝገባ በይፋ ተከፍቷል። የክፍል ማስረጃዎችዎን፣ የሁለተኛ ደረጃ ትምህርት ምስክር ወረቀትን እና ፎቶዎን ማቅረብዎን ያረጋግጡ። ጊዜ ካለፈ በኋላ የሚመጣ ምዝገባ በሚኒስቴሩ ተቀባይነት አይኖረውም። ሁሉንም ምዝገባዎች እስከ ሐምሌ 15 ድረስ ያጠናቅቁ።',
            'time': widget.languageCode == 'en' ? '1 day ago' : 'ከትናንት በፊት',
            'is_read': false,
          },
        ];
        list = defaultNotifications.map((n) => jsonEncode(n)).toList();
        await prefs.setStringList('local_notifications', list);
      }
      
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

  Future<void> _sendTestNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList('local_notifications') ?? [];
      
      final bool useYoutube = DateTime.now().second % 2 == 0;
      final Map<String, dynamic> testNotification;
      
      if (useYoutube) {
        testNotification = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': widget.languageCode == 'en' ? 'New Chemistry Lab Video!' : 'አዲስ የኬሚስትሪ የላብራቶሪ ቪዲዮ!',
          'message': widget.languageCode == 'en' 
              ? 'Learn complete acid-base reactions under 5 minutes with vivid experiments. Watch now: https://www.youtube.com/watch?v=dQw4w9WgXcQ' 
              : 'ከአሲድ-ቤዝ ምላሾች ጋር የተያያዙ ሙከራዎችን ከ 5 ደቂቃ በታች ይመልከቱ። አሁን ይመልከቱ፡ https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          'time': widget.languageCode == 'en' ? 'Just now' : 'አሁን',
          'is_read': false,
        };
      } else {
        testNotification = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': widget.languageCode == 'en' ? 'Join Physics Chat Group' : 'የፊዚክስ ውይይት ቡድንን ይቀላቀሉ',
          'message': widget.languageCode == 'en' 
              ? 'Join our community group to ask questions and study together with friends. Click here: https://t.me/smartxacademy' 
              : 'አብረው ለማጥናት እና ጥያቄዎችን ለመጠየቅ የማህበረሰባችንን ውይይት ይቀላቀሉ። እዚህ ይጫኑ፡ https://t.me/smartxacademy',
          'time': widget.languageCode == 'en' ? 'Just now' : 'አሁን',
          'is_read': false,
        };
      }
      
      list.insert(0, jsonEncode(testNotification));
      await prefs.setStringList('local_notifications', list);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.languageCode == 'en' ? 'Test notification added!' : 'የሙከራ ማሳወቂያ ታክሏል!'),
            behavior: SnackBarBehavior.floating,
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

  Future<void> _updateFeedback(String notificationId, String feedback) async {
    try {
      setState(() {
        _userFeedbacks[notificationId] = feedback;
      });

      await NotificationService.saveFeedback(notificationId, feedback);

      if (mounted) {
        final isEn = widget.languageCode == 'en';
        final message = feedback == 'Interested'
            ? (isEn ? 'Marked as Interested' : 'ፍላጎት አለኝ ተብሏል')
            : (isEn ? 'Marked as Not Interested' : 'ፍላጎት የለኝም ተብሏል');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating feedback: $e');
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

  Widget _buildFeedbackRow(String notificationId, bool isLight, Color subtitleColor) {
    final currentFeedback = _userFeedbacks[notificationId];
    final isEn = widget.languageCode == 'en';

    final bool isInterestedSelected = currentFeedback == 'Interested';
    final bool isNotInterestedSelected = currentFeedback == 'Not Interested';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Divider(
          height: 1,
          thickness: 1,
          color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _updateFeedback(notificationId, 'Interested'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isInterestedSelected
                        ? const Color(0xFF10B981)
                        : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                    width: isInterestedSelected ? 1.5 : 1,
                  ),
                  backgroundColor: isInterestedSelected
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : Colors.transparent,
                  foregroundColor: isInterestedSelected
                      ? const Color(0xFF10B981)
                      : (isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: Icon(
                  isInterestedSelected ? Icons.thumb_up_rounded : Icons.thumb_up_alt_outlined,
                  size: 14,
                ),
                label: Text(
                  isEn ? 'Interested' : 'ፍላጎት አለኝ',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _updateFeedback(notificationId, 'Not Interested'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isNotInterestedSelected
                        ? const Color(0xFFEF4444)
                        : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                    width: isNotInterestedSelected ? 1.5 : 1,
                  ),
                  backgroundColor: isNotInterestedSelected
                      ? const Color(0xFFEF4444).withOpacity(0.1)
                      : Colors.transparent,
                  foregroundColor: isNotInterestedSelected
                      ? const Color(0xFFEF4444)
                      : (isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: Icon(
                  isNotInterestedSelected ? Icons.thumb_down_rounded : Icons.thumb_down_alt_outlined,
                  size: 14,
                ),
                label: Text(
                  isEn ? 'Not Interested' : 'ፍላጎት የለኝም',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
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
                              if (youtubeId != null) ...[
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.network(
                                        'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg',
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 120,
                                            color: isLight ? Colors.grey.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                                            alignment: Alignment.center,
                                            child: const Icon(Icons.video_library_rounded, size: 40, color: Colors.grey),
                                          );
                                        },
                                      ),
                                      Positioned.fill(
                                        child: Container(
                                          color: Colors.black.withOpacity(0.15),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (detectedUrl != null) ...[
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => _launchURL(detectedUrl),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _getSocialColor(detectedUrl),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 38),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: Icon(_getSocialIcon(detectedUrl), size: 16),
                                  label: Text(
                                    _getSocialButtonLabel(detectedUrl),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                  ),
                                ),
                              ],
                              _buildFeedbackRow(id, isLight, subtitleColor),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
