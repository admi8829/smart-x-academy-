import 'dart:async';
import 'package:flutter/material.dart';
import '../services/push_notification_service.dart';
import 'home_screen.dart';

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

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _loadingController;
  late AnimationController _pulseController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _titleSlide;
  late Animation<double> _contentOpacity;
  late Animation<double> _pulseGlow;

  double _loadingProgress = 0.0;
  String _currentLoadingText = "Starting academy engine...";

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation (Duration: 1.2s)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.backOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _titleSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.9, curve: Curves.easeIn),
      ),
    );

    // 2. Pulse background ring glow animation (loops continuously)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseGlow = Tween<double>(begin: 0.8, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // 3. Simulated curriculum load & custom progress counting (Duration: 3s)
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _loadingController.addListener(() {
      setState(() {
        _loadingProgress = _loadingController.value;
        if (_loadingProgress < 0.25) {
          _currentLoadingText = widget.languageCode == 'am' 
              ? 'የትምህርት ሞጁሎችን በማዘጋጀት ላይ...' 
              : 'Preparing learning modules...';
        } else if (_loadingProgress < 0.55) {
          _currentLoadingText = widget.languageCode == 'am' 
              ? 'የኢትዮጵያ ስርአተ ትምህርትን በመጫን ላይ...' 
              : 'Loading Ethiopian Syllabus...';
        } else if (_loadingProgress < 0.85) {
          _currentLoadingText = widget.languageCode == 'am' 
              ? 'እውቀት ሰጪ ጥያቄዎችን በማሰናዳት ላይ...' 
              : 'Synchronizing curriculum quizzes...';
        } else {
          _currentLoadingText = widget.languageCode == 'am' 
              ? 'ክፍሎችን በማጠናቀቅ ላይ...' 
              : 'Finalizing setup...';
        }
      });
    });

    _loadingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _completeInitialization();
      }
    });

    // Start everything!
    _entranceController.forward();
    _loadingController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _loadingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _completeInitialization() async {
    // 4. Request notifications permission *after* the loading screen is fully complete
    await PushNotificationService.requestNotificationPermission();

    // 5. Smooth page transition route
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
            const begin = Offset(0.0, 0.05);
            const end = Offset.zero;
            const curve = Curves.fastOutSlowIn;

            var slideTween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(slideTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 700),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDarkMode;

    // Define 60-30-10 color palette variables
    // 60% Dominant: Luxury dark slate or pristine soft ivory background
    final Color domBackground = isDark ? const Color(0xFF030712) : const Color(0xFFF8FAFC);
    // 30% Structural: Dark luxury text or fine slate borders, cards
    final Color structColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    // 10% Accent: Beautiful gradient matching physical country highlights and vibrant academic progress
    final List<Color> accentColors = isDark 
        ? [const Color(0xFF38BDF8), const Color(0xFF10B981)] 
        : [const Color(0xFF0D2353), const Color(0xFF1E88E5)];

    return Scaffold(
      backgroundColor: domBackground,
      body: Stack(
        children: [
          // Elegant subtle layout background pattern
          Positioned(
            top: -120,
            right: -120,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 320 * _pulseGlow.value,
                  height: 320 * _pulseGlow.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF10B981).withValues(alpha: isDark ? 0.05 : 0.03), 
                        const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.03 : 0.01),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 380 * _pulseGlow.value,
                  height: 380 * _pulseGlow.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFEF4444).withValues(alpha: isDark ? 0.04 : 0.02),
                        const Color(0xFF1E88E5).withValues(alpha: isDark ? 0.04 : 0.02),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Central Animated Brand Showcase
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 7),
                  // Animated Pulsing Halo Logo
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoOpacity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Concentric pulsing outer rings for premium quality tactile look
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 110 * _pulseGlow.value,
                                height: 110 * _pulseGlow.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (isDark ? Colors.white : const Color(0xFF0D2353))
                                      .withValues(alpha: 0.02 * _pulseGlow.value),
                                  border: Border.all(
                                    color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E88E5))
                                        .withValues(alpha: 0.07 * _pulseGlow.value),
                                    width: 1.5,
                                  ),
                                ),
                              );
                            },
                          ),
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 135 * _pulseGlow.value,
                                height: 135 * _pulseGlow.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent,
                                  border: Border.all(
                                    color: (isDark ? const Color(0xFF10B981) : Colors.amber)
                                        .withValues(alpha: 0.03 * _pulseGlow.value),
                                    width: 1,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Core logo box
                          Container(
                            height: 84,
                            width: 84,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: accentColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accentColors.first.withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              size: 42,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32.0),

                  // Brand name and subtitle alignment
                  AnimatedBuilder(
                    animation: _entranceController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _titleSlide.value),
                        child: child,
                      );
                    },
                    child: FadeTransition(
                      opacity: _contentOpacity,
                      child: Column(
                        children: [
                          // Main elegant brand name
                          Text(
                            "Smart X Academy",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32.0,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              color: isDark ? Colors.white : const Color(0xFF0D2353),
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          // Beautiful Ethiopian pill badge with color details
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF111827) : Colors.white,
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(
                                color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Mini Ethiopian mini gradient accent flag pill representation
                                Container(
                                  width: 14,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF009A44), // Green
                                        Color(0xFFFED100), // Yellow
                                        Color(0xFFEF4444), // Red
                                      ],
                                      stops: [0.33, 0.66, 1.0],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  "Ethiopian",
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 8),

                  // Customized loading progression
                  FadeTransition(
                    opacity: _contentOpacity,
                    child: Column(
                      children: [
                        // Live percentage ticker
                        Text(
                          "${(_loadingProgress * 100).toInt()}%",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E88E5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Soft loading context text
                        Text(
                          _currentLoadingText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Sleek Linear Progress loading line matching the 60-30-10 palette
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 6,
                            width: 180,
                            color: structColor,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: _loadingProgress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: accentColors,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
