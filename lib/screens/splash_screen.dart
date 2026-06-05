import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/push_notification_service.dart';
import 'home_screen.dart';

enum LaunchStep {
  welcome,       // Step 1: Welcome & App Launch
  syncing,       // Step 2: Data & Content Loading
  auth,          // Step 3: User Authentication
  selection,     // Step 4: Grade & Subject Selection
  ready,         // Step 5: Exam Ready & Dashboard
  completed,     // Completed processing
}

/// A dedicated State Manager to handle the App Launch Flow sequence smoothly.
class AppLaunchState extends ChangeNotifier {
  LaunchStep _currentStep = LaunchStep.welcome;
  double _step1Progress = 0.0;
  double _step2Progress = 0.0;
  String _authStatus = 'Checking account status...';
  String _selectionStatus = 'Selected: Grade 11 | Subject: Physics';
  double _step5Progress = 0.0;

  LaunchStep get currentStep => _currentStep;
  double get step1Progress => _step1Progress;
  double get step2Progress => _step2Progress;
  String get authStatus => _authStatus;
  String get selectionStatus => _selectionStatus;
  double get step5Progress => _step5Progress;

  Timer? _timer;

  void startSequence({
    required VoidCallback onComplete,
  }) {
    _currentStep = LaunchStep.welcome;
    _step1Progress = 0.0;
    _step2Progress = 0.0;
    _step5Progress = 0.0;
    _authStatus = 'Checking account status...';
    _selectionStatus = 'Syncing system configurations...';
    notifyListeners();

    // 1. WELCOME & APP LAUNCH
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) async {
      if (_currentStep == LaunchStep.welcome) {
        _step1Progress += 0.02;
        if (_step1Progress >= 1.0) {
          _step1Progress = 1.0;
          _currentStep = LaunchStep.syncing;
        }
        notifyListeners();
      } 
      // 2. DATA & CONTENT LOADING
      else if (_currentStep == LaunchStep.syncing) {
        _step2Progress += 0.025;
        if (_step2Progress >= 1.0) {
          _step2Progress = 1.0;
          _currentStep = LaunchStep.auth;
          _authStatus = 'Verifying secure backend credentials...';
        }
        notifyListeners();
      } 
      // 3. USER AUTHENTICATION
      else if (_currentStep == LaunchStep.auth) {
        timer.cancel(); // Transition to async lookup
        await Future.delayed(const Duration(milliseconds: 1000));
        
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            _authStatus = 'Logged in as: ${user.email ?? "User"}';
          } else {
            _authStatus = 'Guest Session Active (No sign-in required)';
          }
        } catch (e) {
          _authStatus = 'Offline sandbox session initialized';
        }
        
        _currentStep = LaunchStep.selection;
        _selectionStatus = 'Reading school grade preferences...';
        notifyListeners();
        _resumeSequence(onComplete);
      }
    });
  }

  void _resumeSequence(VoidCallback onComplete) {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) async {
      // 4. GRADE & SUBJECT SELECTION
      if (_currentStep == LaunchStep.selection) {
        timer.cancel();
        await Future.delayed(const Duration(milliseconds: 1000));
        
        try {
          final prefs = await SharedPreferences.getInstance();
          int savedGrade = prefs.getInt('selected_grade') ?? 11;
          String savedSubject = prefs.getString('selected_subject') ?? 'Physics';
          _selectionStatus = 'Selected: Grade $savedGrade | Subject: $savedSubject';
        } catch (e) {
          _selectionStatus = 'Selected: Grade 11 | Subject: Physics';
        }
        
        _currentStep = LaunchStep.ready;
        notifyListeners();
        _resumeSequence(onComplete);
      } 
      // 5. EXAM READY & DASHBOARD
      else if (_currentStep == LaunchStep.ready) {
        _step5Progress += 0.04;
        if (_step5Progress >= 1.0) {
          _step5Progress = 1.0;
          _currentStep = LaunchStep.completed;
          timer.cancel();
          notifyListeners();
          
          Future.delayed(const Duration(milliseconds: 600), () {
            onComplete();
          });
        }
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

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

class _SplashScreenState extends State<SplashScreen> {
  late AppLaunchState _launchState;

  @override
  void initState() {
    super.initState();
    _launchState = AppLaunchState();
    
    // Start tracking opening workflow
    _launchState.startSequence(
      onComplete: _finishLaunchTransition,
    );
  }

  @override
  void dispose() {
    _launchState.dispose();
    super.dispose();
  }

  Future<void> _finishLaunchTransition() async {
    // Request push notifications permission as part of safe finalization
    try {
      await PushNotificationService.requestNotificationPermission();
    } catch (e) {
      debugPrint("Notification permissions bypass: $e");
    }

    if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDarkMode;
    final Color primaryColor = const Color(0xFF0F4C81); // Elegant royal blue brand accent
    final Color backgroundColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0D2353);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                
                // Centered dynamic branding Star Logo with student in center
                CustomPaint(
                  size: const Size(80, 80),
                  painter: SmartXStarPainter(color: primaryColor),
                ),
                const SizedBox(height: 12),
                
                Text(
                  "SMART X",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                Text(
                  "ETHIOPIA",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4.0,
                  ),
                ),
                const SizedBox(height: 10),
                
                Text(
                  "APPLICATION PROCESS FLOW",
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 32),

                // THE VERTICAL CONNECTED FLOW TIMELINE LIST
                AnimatedBuilder(
                  animation: _launchState,
                  builder: (context, child) {
                    final step = _launchState.currentStep;
                    
                    return Column(
                      children: [
                        _buildTimelineStep(
                          index: 1,
                          title: "WELCOME & APP LAUNCH",
                          desc: "Smart X Ethiopian is loading...\n(Visualizing startup)",
                          icon: Icons.shield_outlined,
                          progress: _launchState.step1Progress,
                          isActive: step == LaunchStep.welcome,
                          isCompleted: step.index > LaunchStep.welcome.index,
                          primaryColor: primaryColor,
                          isDark: isDark,
                        ),
                        _buildTimelineStep(
                          index: 2,
                          title: "DATA & CONTENT LOADING",
                          desc: "Syncing content for Grades 9, 10, 11, 12...\n(Checking updates)",
                          icon: Icons.cloud_download_outlined,
                          progress: _launchState.step2Progress,
                          isActive: step == LaunchStep.syncing,
                          isCompleted: step.index > LaunchStep.syncing.index,
                          primaryColor: primaryColor,
                          isDark: isDark,
                        ),
                        _buildTimelineStep(
                          index: 3,
                          title: "USER AUTHENTICATION",
                          desc: _launchState.authStatus,
                          icon: Icons.lock_outline_rounded,
                          progress: step == LaunchStep.auth ? 0.5 : 0.0,
                          isActive: step == LaunchStep.auth,
                          isCompleted: step.index > LaunchStep.auth.index,
                          primaryColor: primaryColor,
                          isDark: isDark,
                        ),
                        _buildTimelineStep(
                          index: 4,
                          title: "GRADE & SUBJECT SELECTION",
                          desc: _launchState.selectionStatus,
                          icon: Icons.calendar_today_outlined,
                          progress: step == LaunchStep.selection ? 0.5 : 0.0,
                          isActive: step == LaunchStep.selection,
                          isCompleted: step.index > LaunchStep.selection.index,
                          primaryColor: primaryColor,
                          isDark: isDark,
                        ),
                        _buildTimelineStep(
                          index: 5,
                          title: "EXAM READY & DASHBOARD",
                          desc: "Start practicing! | Access:\nPractice Exams, Quizzes, Progress...",
                          icon: Icons.rocket_launch_outlined,
                          progress: _launchState.step5Progress,
                          isActive: step == LaunchStep.ready,
                          isCompleted: step == LaunchStep.completed,
                          primaryColor: primaryColor,
                          isDark: isDark,
                        ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 36),

                // BOTTOM BADGE BAR
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // YouTube branding widget
                    _buildYouTubeBadge(primaryColor, isDark),
                    
                    // Gear customization icon
                    IconButton(
                      icon: Icon(
                        Icons.settings_outlined,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                        size: 24,
                      ),
                      onPressed: () {
                        // Quick toggle modal or settings menu
                        _showLocalSettingsModal(context, isDark);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required int index,
    required String title,
    required String desc,
    required IconData icon,
    required double progress,
    required bool isActive,
    required bool isCompleted,
    required Color primaryColor,
    required bool isDark,
  }) {
    final Color borderColors = isCompleted 
        ? primaryColor 
        : (isActive ? primaryColor.withOpacity(0.8) : Colors.grey[300]!);
    final Color iconColors = isCompleted || isActive ? primaryColor : Colors.grey[400]!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical timeline left path column
          Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: Border.all(
                        color: borderColors,
                        width: isCompleted || isActive ? 2.5 : 1.5,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.15),
                                blurRadius: 10,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: Icon(
                      icon,
                      color: iconColors,
                      size: 22,
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1E88E5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        index.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (index < 5)
                Expanded(
                  child: Container(
                    width: 2.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted ? primaryColor : Colors.grey[200]!,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 18),
          
          // Step metadata column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isCompleted || isActive 
                        ? (isDark ? Colors.white : const Color(0xFF122C4B)) 
                        : Colors.grey[400]!,
                  ),
                ),
                const SizedBox(height: 6),
                
                // Custom horizontal loading progress bar as in reference mockup screenshot
                if (isActive && progress >= 0.0 && progress <= 1.0 && (index == 1 || index == 2 || index == 5)) ...[
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : Colors.grey[150] ?? const Color(0xFFEEF2F6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F4C81), Color(0xFF1E88E5)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ] else if (isCompleted && (index == 1 || index == 2 || index == 5)) ...[
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isCompleted || isActive 
                        ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)) 
                        : Colors.grey[400]!,
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYouTubeBadge(Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow, color: Colors.white, size: 12),
                SizedBox(width: 1),
                Text(
                  "You",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  "Tube",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "2.3K+",
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  height: 1.1,
                ),
              ),
              const Text(
                "SUBSCRIBERS",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 7.5,
                  letterSpacing: 0.5,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLocalSettingsModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Launch Customization",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xFF0F4C81),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: const Color(0xFF1E88E5),
                ),
                title: Text(
                  isDark ? "Switch to Light Mode" : "Switch to Dark Mode",
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onToggleTheme();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.translate_rounded,
                  color: Color(0xFF10B981),
                ),
                title: Text(
                  widget.languageCode == 'en' ? " አማርኛ መተግበሪያ (Amharic)" : " English Language",
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onToggleLanguage();
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4C81),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Close"),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A Custom Painter to render a sharp 8-pointed star with a student emblem in center.
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

    // Draw an 8-pointed star shape
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

    // Draw additional concentric detailing lines
    canvas.drawCircle(
      Offset(cx, cy),
      R * 0.82,
      Paint()
        ..color = color.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Draw stylized student child/figure inside the star
    final studentPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    // Head circle represent student
    canvas.drawCircle(Offset(cx, cy - 8), 4.5, Paint()..color = color..style = PaintingStyle.fill);

    // Embracing / open welcoming arms
    final armPath = Path()
      ..moveTo(cx - 15, cy + 3)
      ..quadraticBezierTo(cx, cy - 2, cx + 15, cy + 3);
    canvas.drawPath(armPath, studentPaint);

    // Body & legs structure
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
