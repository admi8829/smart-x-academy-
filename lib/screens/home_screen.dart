import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    required this.onToggleTheme,
    required this.onToggleLanguage,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Translation dictionary to support "EN/አማ" localization selection
  final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Smart X Academy',
      'tutorial_desc': 'Watch tutorial: Getting started with the Smart X',
      'explore_title': 'Explore Your Learning Path',
      'explore_sub': 'Select your grade to access courses and resources.',
      'g9_title': 'Grade 9',
      'g9_sub': 'Start Your\nJourney!',
      'g10_title': 'Grade 10',
      'g10_sub': 'Expand your\nknowledge!',
      'g11_title': 'Grade 11',
      'g11_sub': 'Prepare for\nexcellence!',
      'g12_title': 'Grade 12',
      'g12_sub': 'Achieve your\ngoals!',
      'btn_start': 'Start Course',
      'coming_soon': 'Coming Soon',
      'subject_math': 'Math',
      'subject_physics': 'Physics',
      'subject_biology': 'Biology',
      'subject_history': 'History',
      'subject_chemistry': 'Chemistry',
      'nav_home': 'Home',
      'nav_courses': 'Courses',
      'nav_profile': 'Profile',
      'nav_settings': 'Settings',
    },
    'am': {
      'title': 'ስማርት ኤክስ አካዳሚ',
      'tutorial_desc': 'የመማሪያ መመሪያውን ይመልከቱ: በስማርት ኤክስ መጀመር',
      'explore_title': 'የመማር ጎዳናዎን ያስሱ',
      'explore_sub': 'ኮርሶችን እና ሀብቶችን ለማግኘት ክፍልዎን ይምረጡ።',
      'g9_title': 'ክፍል 9',
      'g9_sub': 'ጉዞዎን ይጀምሩ\nጉዞዎን ይጀምሩ!',
      'g10_title': 'ክፍል 10',
      'g10_sub': 'እውቀትዎን ያሳድጉ\nክፍልዎን ይቆጣጠሩ!',
      'g11_title': 'ክፍል 11',
      'g11_sub': 'ለላቀ ውጤት ይዘጋጁ\nፈተናዎችን ይጋፈጡ!',
      'g12_title': 'ክፍል 12',
      'g12_sub': 'ግብዎን ያሳኩ\nማዕረግ ያግኙ!',
      'btn_start': 'ኮርስ ይጀምሩ',
      'coming_soon': 'በቅርቡ የሚመጣ',
      'subject_math': 'ሒሳብ',
      'subject_physics': 'ፊዚክስ',
      'subject_biology': 'ባዮሎጂ',
      'subject_history': 'ታሪክ',
      'subject_chemistry': 'ኬሚስትሪ',
      'nav_home': 'መነሻ',
      'nav_courses': 'ኮርሶች',
      'nav_profile': 'መገለጫ',
      'nav_settings': 'ማስተካከያዎች',
    }
  };

  String _local(String key) {
    return _localizedValues[widget.languageCode]?[key] ?? key;
  }

  void _navigateToQuizScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QuizScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = !widget.isDarkMode;
    final Color scamPrimary = isLight ? const Color(0xFF0D2353) : Colors.white;

    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFF6F8FB) : const Color(0xFF0F172A),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: isLight ? const Color(0xFF0F172A) : Colors.white,
            size: 26,
          ),
          onPressed: () {},
        ),
        title: Text(
          _local('title'),
          style: GoogleFonts.poppins(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: isLight ? const Color(0xFF0D2353) : Colors.white,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          // Theme changer
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
              color: isLight ? const Color(0xFF0D2353) : const Color(0xFF38BDF8),
              size: 24,
            ),
            onPressed: widget.onToggleTheme,
          ),
          
          // Language selector
          GestureDetector(
            onTap: widget.onToggleLanguage,
            child: Container(
              margin: const EdgeInsets.only(right: 14, left: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.language_rounded,
                    size: 20,
                    color: isLight ? const Color(0xFF0D2353) : const Color(0xFF38BDF8),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    "EN/አማ",
                    style: GoogleFonts.poppins(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: isLight ? const Color(0xFF0D2353) : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // Background watermarks
          Positioned.fill(
            child: CustomPaint(
              painter: WatermarkBackgroundPainter(isDarkMode: widget.isDarkMode),
            ),
          ),
          
          // Interactive tab contents
          Positioned.fill(
            child: _buildCurrentTab(isLight),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
          selectedItemColor: const Color(0xFF1E88E5),
          unselectedItemColor: isLight ? const Color(0xFF90A4AE) : const Color(0xFF64748B),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          items: [
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 0 ? Icons.home_filled : Icons.home_outlined),
              label: _local('nav_home'),
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 1 ? Icons.book_rounded : Icons.book_outlined),
              label: _local('nav_courses'),
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 2 ? Icons.person : Icons.person_outline),
              label: _local('nav_profile'),
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 3 ? Icons.settings : Icons.settings_outlined),
              label: _local('nav_settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab(bool isLight) {
    switch (_currentIndex) {
      case 0:
        return _buildHomeScreenContent(isLight);
      case 1:
        return _buildCoursesScreen(isLight);
      case 2:
        return _buildProfileScreen(isLight);
      case 3:
        return _buildSettingsScreen(isLight);
      default:
        return _buildHomeScreenContent(isLight);
    }
  }

  Widget _buildHomeScreenContent(bool isLight) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. YouTube Tutorial video Banner in a rounded white card with shadow
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 6.0),
            decoration: BoxDecoration(
              color: isLight ? Colors.white : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: isLight ? Colors.black.withOpacity(0.04) : Colors.black.withOpacity(0.2),
                  blurRadius: 10.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // High Fidelity Thumbnail layout with mock overlay UI
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background design replicating video thumbnail
                        Container(
                          height: 190,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFE2EAF8), Color(0xFFF1F5FB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Decorative Left Text Block
                              Positioned(
                                left: 18,
                                top: 52,
                                bottom: 10,
                                right: 120,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Welcome to\nSmart X Academy!",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF0D2353),
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "How to Use\nthe App",
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0D2353),
                                        height: 1.2,
                                      ),
                                    ),
                                    const Spacer(),
                                    // Row with tiny logo matching screenshot
                                    Row(
                                      children: [
                                        _buildMiniCrossLogo(),
                                        const SizedBox(width: 5),
                                        Text(
                                          "Smart X\nAcademy",
                                          style: GoogleFonts.poppins(
                                            fontSize: 9.0,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF0D2353),
                                            height: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Decorative Right Illustration Stack (Giant books + smartphone + character shapes)
                              Positioned(
                                right: 12,
                                bottom: 10,
                                top: 40,
                                child: SizedBox(
                                  width: 110,
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      // Stack of books horizontally
                                      Positioned(
                                        bottom: 0,
                                        child: Column(
                                          children: [
                                            Container(width: 80, height: 6, decoration: BoxDecoration(color: const Color(0xFFFF5252), borderRadius: BorderRadius.circular(2))),
                                            Container(width: 84, height: 6, decoration: BoxDecoration(color: const Color(0xFFFFD54F), borderRadius: BorderRadius.circular(2))),
                                            Container(width: 88, height: 6, decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(2))),
                                            Container(width: 92, height: 6, decoration: BoxDecoration(color: const Color(0xFF1E88E5), borderRadius: BorderRadius.circular(2))),
                                          ],
                                        ),
                                      ),
                                      // Miniature Smart Phone sticking up
                                      Positioned(
                                        bottom: 12,
                                        right: 18,
                                        child: Container(
                                          width: 38,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0D2353),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.white, width: 1.5),
                                          ),
                                          padding: const EdgeInsets.all(2),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            alignment: Alignment.center,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                _buildMiniCrossLogo(size: 10),
                                                Text(
                                                  "Smart X\nAcademy",
                                                  style: GoogleFonts.poppins(fontSize: 4.5, fontWeight: FontWeight.w900, color: const Color(0xFF0D2353), height: 1.0),
                                                  textAlign: TextAlign.center,
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Tiny vector standing students shapes represent mockup
                                      Positioned(
                                        bottom: 14,
                                        left: 10,
                                        child: _buildMockStudent(Colors.amber),
                                      ),
                                      Positioned(
                                        bottom: 14,
                                        right: 2,
                                        child: _buildMockStudent(Colors.green),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Dark overlay tint
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.04),
                          ),
                        ),
                        // Top Video Bar Replicating YouTube UX
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black54, Colors.transparent],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.white,
                                  child: ClipOval(child: _buildMiniCrossLogo(size: 16)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Welcome to Smart X Acade...",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.more_vert, color: Colors.white, size: 18),
                              ],
                            ),
                          ),
                        ),
                        // Glowing Red YouTube Play Button (Center-Aligned)
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 58,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF0000), // YouTube red
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8.0,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Under tutorial card video description match
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text(
              _local('tutorial_desc'),
              style: GoogleFonts.poppins(
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                color: isLight ? const Color(0xFF4A5568) : Colors.grey[300],
              ),
            ),
          ),
          
          const SizedBox(height: 18.0),

          // Header path
          Text(
            _local('explore_title'),
            style: GoogleFonts.poppins(
              fontSize: 22.0,
              fontWeight: FontWeight.w800,
              color: isLight ? const Color(0xFF0D2353) : Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3.0),
          Text(
            _local('explore_sub'),
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: isLight ? const Color(0xFF718096) : const Color(0xFF94A3B8),
            ),
          ),
          
          const SizedBox(height: 16.0),
          
          // 2. Responsive 2x2 grid for Grade 9, 10, 11, and 12
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14.0,
            mainAxisSpacing: 14.0,
            childAspectRatio: 0.88,
            children: [
              // Grade 9
              _buildGradeCard(
                gradeNum: 9,
                title: _local('g9_title'),
                subtitle: _local('g9_sub'),
                cardBg: isLight ? const Color(0xFFE3F2FD) : const Color(0xFF1E3A8A).withOpacity(0.3),
                btnColor: const Color(0xFF0083FF),
                illustration: const Grade9Illustration(),
                isLight: isLight,
              ),
              // Grade 10
              _buildGradeCard(
                gradeNum: 10,
                title: _local('g10_title'),
                subtitle: _local('g10_sub'),
                cardBg: isLight ? const Color(0xFFE8F5E9) : const Color(0xFF065F46).withOpacity(0.3),
                btnColor: const Color(0xFF00C853),
                illustration: const Grade10Illustration(),
                isLight: isLight,
              ),
              // Grade 11
              _buildGradeCard(
                gradeNum: 11,
                title: _local('g11_title'),
                subtitle: _local('g11_sub'),
                cardBg: isLight ? const Color(0xFFFFF3E0) : const Color(0xFF92400E).withOpacity(0.3),
                btnColor: const Color(0xFFFF9100),
                illustration: const Grade11Illustration(),
                isLight: isLight,
              ),
              // Grade 12
              _buildGradeCard(
                gradeNum: 12,
                title: _local('g12_title'),
                subtitle: _local('g12_sub'),
                cardBg: isLight ? const Color(0xFFF3E5F5) : const Color(0xFF5B21B6).withOpacity(0.3),
                btnColor: const Color(0xFF9C27B0),
                illustration: const Grade12Illustration(),
                isLight: isLight,
              ),
            ],
          ),
          
          const SizedBox(height: 24.0),

          // 3. Horizontal Scroll of "Coming Soon" subjects
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildComingSoonSubject(
                  subjectName: _local('subject_math'),
                  circleColor: const Color(0xFF1E88E5),
                  isLight: isLight,
                  iconWidget: _buildMathSymbolsIcon(),
                ),
                _buildComingSoonSubject(
                  subjectName: _local('subject_physics'),
                  circleColor: const Color(0xFF9C27B0),
                  isLight: isLight,
                  iconWidget: const Icon(Icons.blur_circular_rounded, color: Colors.white, size: 30),
                ),
                _buildComingSoonSubject(
                  subjectName: _local('subject_biology'),
                  circleColor: const Color(0xFF4CAF50),
                  isLight: isLight,
                  iconWidget: const Icon(Icons.science_outlined, color: Colors.white, size: 30),
                ),
                _buildComingSoonSubject(
                  subjectName: _local('subject_history'),
                  circleColor: const Color(0xFFFFA726),
                  isLight: isLight,
                  iconWidget: const Icon(Icons.menu_book, color: Colors.white, size: 30),
                ),
                _buildComingSoonSubject(
                  subjectName: _local('subject_chemistry'),
                  circleColor: const Color(0xFFFF5252),
                  isLight: isLight,
                  iconWidget: const Icon(Icons.fireplace_outlined, color: Colors.white, size: 30),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Mini decorative chevron color logo helper
  Widget _buildMiniCrossLogo({double size = 18}) {
    return CustomPaint(
      size: Size(size, size),
      painter: CrossLogoPainter(),
    );
  }

  Widget _buildMockStudent(Color color) {
    return Container(
      width: 12,
      height: 24,
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
        ],
      ),
    );
  }

  // Individual Grade Card inside Grid
  Widget _buildGradeCard({
    required int gradeNum,
    required String title,
    required String subtitle,
    required Color cardBg,
    required Color btnColor,
    required Widget illustration,
    required bool isLight,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: isLight ? Colors.white.withOpacity(0.6) : Colors.white10,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      padding: const EdgeInsets.all(12.0),
      child: Stack(
        children: [
          // Layout
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top title & subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w850,
                      color: isLight ? const Color(0xFF0D2353) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isLight ? const Color(0xFF4A5568) : Colors.grey[300],
                      height: 1.25,
                    ),
                  ),
                ],
              ),
              
              // Bottom Action Start Course Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _navigateToQuizScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    _local('btn_start'),
                    style: GoogleFonts.poppins(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Floating high fidelity Illustration overlay top-right
          Positioned(
            right: -6,
            top: 2,
            child: illustration,
          ),
        ],
      ),
    );
  }

  // Math visual operator symbols (+ - x /) layout
  Widget _buildMathSymbolsIcon() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("+", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            SizedBox(width: 8),
            Text("/", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("×", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            SizedBox(width: 8),
            Text("÷", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  // Individual Subject with Coming Soon tag
  Widget _buildComingSoonSubject({
    required String subjectName,
    required Color circleColor,
    required Widget iconWidget,
    required bool isLight,
  }) {
    return Container(
      width: 76,
      margin: const EdgeInsets.only(right: 14.0),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Circular icon background
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: circleColor,
                  boxShadow: [
                    BoxShadow(
                      color: circleColor.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: iconWidget,
              ),
              
              // Centered dark gray capsule top badge
              Positioned(
                top: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A5568),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _local('coming_soon'),
                    style: GoogleFonts.poppins(
                      fontSize: 6.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            subjectName,
            style: GoogleFonts.poppins(
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              color: isLight ? const Color(0xFF0D2353) : Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- TAB PAGES PLACEHOLDERS OR CONTENT ---
  Widget _buildCoursesScreen(bool isLight) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("All Academy Courses", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: isLight ? const Color(0xFF0D2353) : Colors.white)),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: "Search courses...",
              hintStyle: GoogleFonts.poppins(fontSize: 14),
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: isLight ? Colors.white : const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          _buildPopularCourseItem("Mathematics Grade 12", "Calculus & Algebra", "4.8 ★ (120 reviews)", "48 Modules", const Color(0xFF9C27B0), isLight),
          _buildPopularCourseItem("Physics Grade 11", "Mechanics & Relativity", "4.9 ★ (95 reviews)", "40 Modules", const Color(0xFFFF9100), isLight),
          _buildPopularCourseItem("Biology Grade 10", "Ecosystems & Genetics", "4.7 ★ (80 reviews)", "30 Modules", const Color(0xFF4CAF50), isLight),
        ],
      ),
    );
  }

  Widget _buildPopularCourseItem(String title, String subtitle, String rating, String length, Color accent, bool isLight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            height: 48, width: 48,
            decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.menu_book, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: isLight ? const Color(0xFF0D2353) : Colors.white)),
                Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(rating, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
                    const SizedBox(width: 12),
                    Text(length, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProfileScreen(bool isLight) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          children: [
            const CircleAvatar(
              radius: 46,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
            ),
            const SizedBox(height: 12),
            Text("Abebe Bekele", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: isLight ? const Color(0xFF0D2353) : Colors.white)),
            Text("Grade 12 Student | Smart X Enthusiast", style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn("Streak", "15 days", Icons.local_fire_department, Colors.orange),
                _buildStatColumn("Completed", "18 lessons", Icons.check_circle_outline, Colors.green),
                _buildStatColumn("Avg Score", "94%", Icons.emoji_events_outlined, Colors.purple),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSettingsScreen(bool isLight) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ListTile(
          leading: const Icon(Icons.language),
          title: Text("Language Toggle", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          subtitle: Text(widget.languageCode == 'en' ? "Currently English" : "በአማርኛ", style: GoogleFonts.poppins(fontSize: 12)),
          trailing: Switch(
            value: widget.languageCode == 'am',
            onChanged: (val) => widget.onToggleLanguage(),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: Text("Dark Theme Mode", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          subtitle: Text(widget.isDarkMode ? "Enabled" : "Disabled", style: GoogleFonts.poppins(fontSize: 12)),
          trailing: Switch(
            value: widget.isDarkMode,
            onChanged: (val) => widget.onToggleTheme(),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text("App Version", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          trailing: const Text("1.0.0+1"),
        ),
      ],
    );
  }
}

// Custom Painter to draw back watermarks beautifully
class WatermarkBackgroundPainter extends CustomPainter {
  final bool isDarkMode;
  WatermarkBackgroundPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDarkMode ? Colors.white.withOpacity(0.015) : const Color(0xFF0D2353).withOpacity(0.018)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    _drawScroll(canvas, const Offset(60, 100), paint);
    _drawAtom(canvas, const Offset(310, 150), paint);
    _drawBeaker(canvas, const Offset(70, 360), paint);
    _drawGradCap(canvas, const Offset(330, 480), paint);
    _drawStar(canvas, const Offset(80, 580), paint);
    _drawGear(canvas, const Offset(310, 680), paint);
    _drawMath(canvas, const Offset(190, 420), paint);
  }

  void _drawScroll(Canvas canvas, Offset center, Paint paint) {
    final path = Path()
      ..moveTo(center.dx - 12, center.dy - 16)
      ..lineTo(center.dx + 12, center.dy - 16)
      ..quadraticBezierTo(center.dx + 16, center.dy - 8, center.dx + 12, center.dy)
      ..lineTo(center.dx - 12, center.dy)
      ..quadraticBezierTo(center.dx - 16, center.dy - 8, center.dx - 12, center.dy - 16);
    canvas.drawPath(path, paint);
  }

  void _drawAtom(Canvas canvas, Offset center, Paint paint) {
    canvas.drawOval(Rect.fromCenter(center: center, width: 26, height: 8), paint);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(1.1);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 26, height: 8), paint);
    canvas.restore();
    canvas.drawCircle(center, 1.5, paint);
  }

  void _drawBeaker(Canvas canvas, Offset center, Paint paint) {
    final path = Path()
      ..moveTo(center.dx - 8, center.dy - 12)
      ..lineTo(center.dx + 8, center.dy - 12)
      ..moveTo(center.dx - 4, center.dy - 12)
      ..lineTo(center.dx - 4, center.dy - 4)
      ..lineTo(center.dx - 14, center.dy + 12)
      ..lineTo(center.dx + 14, center.dy + 12)
      ..lineTo(center.dx + 4, center.dy - 4)
      ..lineTo(center.dx + 4, center.dy - 12);
    canvas.drawPath(path, paint);
  }

  void _drawGradCap(Canvas canvas, Offset center, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - 10)
      ..lineTo(center.dx + 18, center.dy)
      ..lineTo(center.dx, center.dy + 10)
      ..lineTo(center.dx - 18, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, Offset center, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      double angle = i * 4 * math.pi / 5;
      double dx = center.dx + 10 * math.cos(angle);
      double dy = center.dy + 10 * math.sin(angle);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawGear(Canvas canvas, Offset center, Paint paint) {
    canvas.drawCircle(center, 8, paint);
    canvas.drawCircle(center, 3, paint);
  }

  void _drawMath(Canvas canvas, Offset center, Paint paint) {
    canvas.drawLine(Offset(center.dx - 6, center.dy), Offset(center.dx + 6, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - 6), Offset(center.dx, center.dy + 6), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- CUSTOM DECORATIVE ILLUSTRATION WIDGETS ---

class Grade9Illustration extends StatelessWidget {
  const Grade9Illustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 2,
            top: 10,
            child: CustomPaint(
              size: const Size(44, 44),
              painter: RolledScrollPainter(),
            ),
          ),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100),
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
                ],
              ),
              child: Text(
                'A+',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RolledScrollPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = const Color(0xFFFBE9E7)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFBF360C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path()
      ..moveTo(8, 12)
      ..lineTo(38, 4)
      ..lineTo(34, 38)
      ..lineTo(4, 42)
      ..close();

    canvas.drawPath(path, bodyPaint);
    canvas.drawPath(path, borderPaint);

    canvas.drawCircle(const Offset(8, 12), 4, bodyPaint);
    canvas.drawCircle(const Offset(8, 12), 4, borderPaint);
    canvas.drawCircle(const Offset(38, 4), 4, bodyPaint);
    canvas.drawCircle(const Offset(38, 4), 4, borderPaint);
    canvas.drawCircle(const Offset(4, 42), 4, bodyPaint);
    canvas.drawCircle(const Offset(4, 42), 4, borderPaint);
    canvas.drawCircle(const Offset(34, 38), 4, bodyPaint);
    canvas.drawCircle(const Offset(34, 38), 4, borderPaint);

    canvas.drawLine(const Offset(12, 18), const Offset(32, 14), borderPaint..strokeWidth = 1.0);
    canvas.drawLine(const Offset(10, 26), const Offset(30, 22), borderPaint);
    canvas.drawLine(const Offset(8, 34), const Offset(28, 30), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Grade10Illustration extends StatelessWidget {
  const Grade10Illustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 2,
            top: 10,
            child: CustomPaint(
              size: const Size(42, 46),
              painter: ShieldPainter(),
            ),
          ),
          Positioned(
            right: -4,
            top: 14,
            child: CustomPaint(
              size: const Size(16, 40),
              painter: DNAPainter(),
            ),
          ),
          Positioned(
            left: 12,
            top: 20,
            child: Text(
              'A+',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [const Shadow(blurRadius: 2.0, color: Colors.black38, offset: Offset(0, 1))],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0D5257), Color(0xFF00796B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFB2DFDB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final width = size.width;
    final height = size.height;

    final path = Path()
      ..moveTo(width * 0.1, height * 0.05)
      ..lineTo(width * 0.9, height * 0.05)
      ..lineTo(width * 0.9, height * 0.4)
      ..quadraticBezierTo(width * 0.9, height * 0.75, width * 0.5, height * 0.98)
      ..quadraticBezierTo(width * 0.1, height * 0.75, width * 0.1, height * 0.4)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DNAPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wave1Paint = Paint()
      ..color = const Color(0xFF00C853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final wave2Paint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final height = size.height;
    const padding = 2.0;

    for (double y = padding; y < height - padding; y += 1.0) {
      double angle = (y / height) * 2.5 * math.pi;
      double x1 = 8 + 5 * math.sin(angle);
      double x2 = 8 - 5 * math.sin(angle);

      canvas.drawCircle(Offset(x1, y), 1.2, wave1Paint);
      canvas.drawCircle(Offset(x2, y), 1.2, wave2Paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Grade11Illustration extends StatelessWidget {
  const Grade11Illustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 14,
            child: CustomPaint(
              size: const Size(54, 40),
              painter: OrbitPainter(),
            ),
          ),
          Positioned(
            left: 12,
            top: 18,
            child: Container(
              height: 26,
              width: 26,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFFFFB74D), Color(0xFFE65100)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 2,
            top: 26,
            child: Container(
              width: 11,
              height: 9,
              decoration: BoxDecoration(color: const Color(0xFFB3E5FC), border: Border.all(color: const Color(0xFF0288D1)), borderRadius: BorderRadius.circular(2)),
              child: const CustomPaint(painter: GridWingPainter()),
            ),
          ),
          Positioned(
            left: 37,
            top: 26,
            child: Container(
              width: 11,
              height: 9,
              decoration: BoxDecoration(color: const Color(0xFFB3E5FC), border: Border.all(color: const Color(0xFF0288D1)), borderRadius: BorderRadius.circular(2)),
              child: const CustomPaint(painter: GridWingPainter()),
            ),
          ),
          Positioned(
            right: -2,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: const BoxDecoration(color: Color(0xFFFF5252), shape: BoxShape.circle),
              child: Text('A+', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class Grade12Illustration extends StatelessWidget {
  const Grade12Illustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 8,
            top: 16,
            child: Container(
              height: 38,
              width: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFF3F51B5), Color(0xFF9C27B0)]),
              ),
              child: ClipOval(child: CustomPaint(painter: GlobeLinesPainter())),
            ),
          ),
          Positioned(
            left: 1,
            top: -1,
            child: Transform.rotate(
              angle: -0.12,
              child: CustomPaint(size: const Size(48, 26), painter: MortarboardCapPainter()),
            ),
          ),
          Positioned(
            right: 0,
            top: 12,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(color: Color(0xFFFF9100), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 10),
            ),
          ),
          Positioned(
            left: 16,
            top: 25,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3)),
              child: Text('A+', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w950, color: const Color(0xFF0D2353))),
            ),
          ),
        ],
      ),
    );
  }
}

// Special Painter to draw a cross logo beautifully
class CrossLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Draw first diagonal block orange-gold
    final Paint orangePaint = Paint()
      ..color = const Color(0xFFFF9100)
      ..strokeWidth = w * 0.16
      ..strokeCap = StrokeCap.round;

    // Draw second diagonal block blue-cyan
    final Paint bluePaint = Paint()
      ..color = const Color(0xFF1E88E5)
      ..strokeWidth = w * 0.16
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.15, h * 0.15), Offset(w * 0.85, h * 0.85), orangePaint);
    canvas.drawLine(Offset(w * 0.15, h * 0.85), Offset(w * 0.85, h * 0.15), bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
