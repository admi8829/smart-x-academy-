import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/push_notification_service.dart';
import 'home_screen.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;

  const SplashScreen({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    required this.onToggleTheme,
    required this.onToggleLanguage,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class SplashScreenWrapper extends SplashScreen {
  final SplashScreen actualWidget;
  
  @override
  final bool isDarkMode;
  @override
  final String languageCode;

  SplashScreenWrapper({
    required this.actualWidget,
    required this.isDarkMode,
    required this.languageCode,
  }) : super(
          isDarkMode: isDarkMode,
          languageCode: languageCode,
          onToggleTheme: actualWidget.onToggleTheme,
          onToggleLanguage: actualWidget.onToggleLanguage,
          key: actualWidget.key,
        );
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  @override
  SplashScreen get widget {
    try {
      final appState = AppStateProvider.of(context);
      return SplashScreenWrapper(
        actualWidget: super.widget,
        isDarkMode: appState.isDarkMode,
        languageCode: appState.languageCode,
      );
    } catch (_) {
      return super.widget;
    }
  }

  // --- Onboarding & Interactive Progress Flow ---
  int _currentStep = 0; // 0 = Terms & Conditions, 1 = Push Notifications Permission
  bool _agreeToTerms = false;
  
  // Custom Swing and Pulse Animations
  late AnimationController _bellSwingController;
  late AnimationController _pulseController;
  late Animation<double> _bellRotation;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();

    // 1. Swing animation for notification bell
    _bellSwingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _bellRotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.12), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: -0.12), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.08), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: -0.08), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.0), weight: 15),
    ]).animate(CurvedAnimation(
      parent: _bellSwingController,
      curve: Curves.easeInOut,
    ));

    // 2. Pulse waves for notification permissions background
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseScale = Tween<double>(begin: 0.8, end: 2.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.outBack)
    );

    _pulseOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut)
    );

    // Repeat animations continuously
    _bellSwingController.repeat(reverse: true);
    _pulseController.repeat();
  }

  @override
  void dispose() {
    _bellSwingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleAcceptTerms() async {
    if (!_agreeToTerms) return;
    
    // Smooth transition from Terms Step (0) to Notification Step (1)
    setState(() {
      _currentStep = 1;
    });
  }

  Future<void> _handleNotificationPermission(bool authorized) async {
    if (authorized) {
      try {
        await PushNotificationService.requestNotificationPermission();
      } catch (e) {
        debugPrint("Error with notifications setup: $e");
      }
    }
    
    _navigateToDashboard();
  }

  void _navigateToDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(
          isDarkMode: widget.isDarkMode,
          languageCode: widget.languageCode,
          onToggleTheme: widget.onToggleTheme,
          onToggleLanguage: widget.onToggleLanguage,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.fastOutSlowIn;
          var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDarkMode;
    final Color backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              ),
            );
          },
          child: _currentStep == 0 
              ? _buildTermsAndConditionsView(isDark) 
              : _buildNotificationPermissionsView(isDark),
        ),
      ),
    );
  }

  // Phase 1: Interactive Terms & Core Academic policies
  Widget _buildTermsAndConditionsView(bool isDark) {
    final Color primaryColor = const Color(0xFF1E88E5);
    final Color cardBackground = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    final String titleText = widget.languageCode == 'en' 
        ? "Terms & Study Policies" 
        : "የአጠቃቀም ስምምነቶች እና ፖሊሲዎች";

    final String subtitleText = widget.languageCode == 'en'
        ? "Welcome to Smart X Ethiopia! Please read and accept our general academic agreements below to continue."
        : "እንኳን ወደ Smart X ኢትዮጵያ በሰላም መጡ! ለመቀጠል እባክዎ የአጠቃቀም ደንቦችን እና ፖሊሲዎችን ያንብቡ እና ይቀበሉ።";

    // Detailed 5 Terms & Policies list
    final List<Map<String, dynamic>> termsList = [
      {
        'index': '1',
        'icon': Icons.assignment_turned_in_outlined,
        'color': const Color(0xFF10B981),
        'titleEn': 'Academic Honesty & Integrity',
        'titleAm': 'አካዳሚያዊ ታማኝነት እና ቅንነት',
        'descEn': 'Build authentic mock study habits. Use our offline exam modules, practice quizzes, and sample questions strictly for personal skill diagnostics.',
        'descAm': 'በራስ መተማመንን ለማሳደግ እና ትክክለኛ የትምህርት ዝግጁነትን ለማጠናከር የመለማመጃ ፈተናዎችን በቅንነት እና በታማኝነት በመጠቀም መለማመድ።',
      },
      {
        'index': '2',
        'icon': Icons.menu_book_outlined,
        'color': primaryColor,
        'titleEn': 'Educational Materials Licensing',
        'titleAm': 'የይዘቶች የግል አጠቃቀም ፈቃድ',
        'descEn': 'The provided revision cheatsheets, lesson syllabus indices, and matric revision guides are licensed exclusively for individual offline student study.',
        'descAm': 'በመተግበሪያው ውስጥ የሚቀርቡት አጫጭር የክፍል ማስታወሻዎች፣ የጥናት መመሪያዎች እና የፈተና ጥያቄዎች ለተማሪው የግል ጥናት ብቻ የተዘጋጁ ናቸው።',
      },
      {
        'index': '3',
        'icon': Icons.lock_outline_rounded,
        'color': const Color(0xFFF59E0B),
        'titleEn': 'Local Progress Data Privacy',
        'titleAm': 'የውጤቶች እና የምርጫዎች ሚስጥራዊነት',
        'descEn': 'Your chosen school grades, test logs, quiz scores, and study revision paths remain entirely saved on your local device with no cloud snooping.',
        'descAm': 'የሚመርጡት የክፍል ደረጃ፣ የሚሰሯቸው ፈተናዎች እና ያስመዘገቧቸው ውጤቶች በስልክዎ ላይ ብቻ በጥብቅ ሚስጥራዊነት የሚቀመጡ ይሆናል።',
      },
      {
        'index': '4',
        'icon': Icons.offline_bolt_outlined,
        'color': const Color(0xFF8B5CF6),
        'titleEn': 'Offline Access & Data Limits',
        'titleAm': 'ከመስመር ውጭ አጠቃቀም ሁኔታ',
        'descEn': 'Subject unit packages download minimal payloads directly onto your phone to keep storage footprint light and preserve cellular internet data.',
        'descAm': 'ትምህርቶች 100% ያለ ኢንተርኔት ከመስመር ውጭ እንዲሰሩ የሚወርዱ መረጃዎች የተንቀሳቃሽ ስልክዎን የመያዣ ቦታ እና የሞባይል ዳታ ለመቆጠብ የተዘጋጁ ናቸው።',
      },
      {
        'index': '5',
        'icon': Icons.verified_outlined,
        'color': const Color(0xFF0F766E),
        'titleEn': 'Assessment Accuracy Disclaimer',
        'titleAm': 'የምዘና እና የልምምድ ሁኔታዎች',
        'descEn': 'Mock programs and review cards are custom educational simulators prepared by professional tutors strictly matching official matric exam specs.',
        'descAm': 'የልምምድ ጥያቄዎቹ የብሄራዊ ፈተናዎችን ይዘት ለመለማመድ እንዲረዱ በአስተማሪዎች በጥንቃቄ የተዘጋጁ ግብዓቶች እንጂ ኦፊሴላዊ ፈተናዎች አይደሉም።',
      },
    ];

    return KeyedSubtree(
      key: const ValueKey('terms_view'),
      child: Column(
        children: [
          // Elegant Header Actions (Theme, Language togglers and Star Emblem)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CustomPaint(
                        size: const Size(28, 28),
                        painter: SmartXStarPainter(color: primaryColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "SMART X ETHIOPIA",
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  ],
                ),
                // Custom quick setting controls
                Row(
                  children: [
                    // Language Switcher
                    IconButton(
                      icon: const Icon(Icons.g_translate_rounded, size: 20),
                      onPressed: widget.onToggleLanguage,
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        foregroundColor: isDark ? Colors.white : const Color(0xFF0D47A1),
                        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Theme Switcher
                    IconButton(
                      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 20),
                      onPressed: widget.onToggleTheme,
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        foregroundColor: isDark ? Colors.white : const Color(0xFF0D47A1),
                        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable list of Terms
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleText,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w950,
                      color: titleColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitleText,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Building 5 distinct terms cards
                  ...termsList.map((term) {
                    final String termTitle = widget.languageCode == 'en' ? term['titleEn'] : term['titleAm'];
                    final String termDesc = widget.languageCode == 'en' ? term['descEn'] : term['descAm'];
                    final Color iconCol = term['color'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.015),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Number Indicator in Colored Circle Side-Badge
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: iconCol.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              term['index'],
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w950,
                                color: iconCol,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  termTitle,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  termDesc,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                    color: subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Accept agreement section at the foot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: cardBackground,
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF2E3B4E) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Custom Tactile Agreement Checkbox Card
                InkWell(
                  onTap: () {
                    setState(() {
                      _agreeToTerms = !_agreeToTerms;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _agreeToTerms ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _agreeToTerms ? primaryColor : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                              width: 1.8,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: _agreeToTerms 
                              ? const Icon(Icons.check, size: 14, color: Colors.white) 
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.languageCode == 'en'
                                ? "I read and accept all 5 educational terms & policies."
                                : "ሁሉንም የትምህርት አጠቃቀም ደንቦችን እና ፖሊሲዎችን ተስማምቻለሁ።",
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: titleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Proceed Action Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _agreeToTerms ? _handleAcceptTerms : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      disabledForegroundColor: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                      elevation: _agreeToTerms ? 4 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.languageCode == 'en' ? "Accept & Continue" : "ተስማምቻለሁ፤ ቀጥል",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w955,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Phase 2: Beautiful custom Notification permission interface with swinging bell & wave pulse
  Widget _buildNotificationPermissionsView(bool isDark) {
    final Color primaryColor = const Color(0xFF1D4ED8);
    final Color cardBackground = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    final String titleText = widget.languageCode == 'en'
        ? "Never Miss Study Alerts!"
        : "የፈተናና ጥናት ማሳሰቢያዎችን ያግኙ";

    final String italicHelpText = widget.languageCode == 'en'
        ? "Receive alerts on weekly revision cheatsheets, smart matric challenge cards, and customized grade content countdown timers."
        : "በየሳምንቱ የሚወጡ አዳዲስ ፈተናዎችን፣ ጠቃሚ የክፍል አጫጭር ማስታወሻዎችን እና የጥናት ማሳሰቢያዎችን በቀጥታ በስልክዎ ላይ ያግኙ።";

    return KeyedSubtree(
      key: const ValueKey('notifications_view'),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Dynamic Swinging Interactive Bell Animation
              SizedBox(
                height: 180,
                width: 180,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // radiating ambient wave
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 80 * _pulseScale.value,
                          height: 80 * _pulseScale.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF3B82F6).withOpacity(_pulseOpacity.value),
                          ),
                        );
                      },
                    ),
                    
                    // Core solid rounded circular pedestal
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.15),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),

                    // Physically rotating metal bell custom painter
                    AnimatedBuilder(
                      animation: _bellRotation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _bellRotation.value,
                          alignment: const Alignment(0.0, -0.6),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            size: 46,
                            color: Color(0xFFF59E0B),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              Text(
                titleText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w950,
                  height: 1.25,
                  color: titleColor,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 12),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  italicHelpText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // "Allow & Continue" Main Action Badge
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _handleNotificationPermission(true),
                  icon: const Icon(Icons.notifications_active_outlined, size: 18),
                  label: Text(
                    widget.languageCode == 'en' 
                        ? "Allow Notifications" 
                        : "ማሳወቂያዎችን ፍቀድ",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w955,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Skip action option
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => _handleNotificationPermission(false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                    foregroundColor: subtitleColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    widget.languageCode == 'en' ? "Maybe Later" : "ቆይቶ ይሁን / እለፍ",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SmartXStarPainter extends CustomPainter {
  final Color color;
  SmartXStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double R = size.width / 2;
    final double r = size.width * 0.42;

    final path = Path();
    for (int i = 0; i < 16; i++) {
      double angle = i * pi / 8 - pi / 2;
      double radius = (i % 2 == 0) ? R : r;
      double x = cx + radius * cos(angle);
      double y = cy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    canvas.drawCircle(
      Offset(cx, cy),
      R * 0.82,
      Paint()
        ..color = color.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final studentPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy - 8), 4.5, Paint()..color = color..style = PaintingStyle.fill);

    final armPath = Path()
      ..moveTo(cx - 15, cy + 3)
      ..quadraticBezierTo(cx, cy - 2, cx + 15, cy + 3);
    canvas.drawPath(armPath, studentPaint);

    final bodyPath = Path()
      ..moveTo(cx, cy - 3)
      ..lineTo(cx, cy + 12)
      ..moveTo(cx, cy + 12)
      ..lineTo(cx - 8, cy + 22)
      ..moveTo(cx, cy + 12)
      ..lineTo(cx + 8, cy + 22);
    canvas.drawPath(bodyPath, studentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
