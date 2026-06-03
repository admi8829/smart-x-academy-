import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
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
  late YoutubePlayerController _ytController;
  bool _isPlaying = false;

  // Dictionary for dynamic translation matching 'EN/አማርኛ'
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
      'nav_home': 'Home',
      'nav_courses': 'Courses',
      'nav_profile': 'Profile',
      'nav_settings': 'Settings',
    },
    'am': {
      'title': 'ስማርት ኤክስ አካዳሚ',
      'tutorial_desc': 'የማጠናከሪያ ቪዲዮ: በስማርት ኤክስ አካዳሚ መተግበሪያ እንዴት እንደሚጀመር።',
      'explore_title': 'የመማር መንገድዎን ያስሱ',
      'explore_sub': 'ኮርሶችን እና ሀብቶችን ለማግኘት ክፍልዎን ይምረጡ።',
      'g9_title': 'ክፍል 9',
      'g9_sub': 'ጉዞዎን ይጀምሩ!',
      'g10_title': 'ክፍል 10',
      'g10_sub': 'እውቀትዎን ያሳድጉ!',
      'g11_title': 'ክፍል 11',
      'g11_sub': 'ለላቀ ውጤት ይዘጋጁ!',
      'g12_title': 'ክፍል 12',
      'g12_sub': 'ግብዎን ያሳኩ!',
      'nav_home': 'መነሻ',
      'nav_courses': 'ኮርሶች',
      'nav_profile': 'መገለጫ',
      'nav_settings': 'ማስተካከያዎች',
    }
  };

  String _local(String key) {
    return _localizedValues[widget.languageCode]?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    // Replicating tutorial video with standard Youtube embedded controller
    _ytController = YoutubePlayerController(
      initialVideoId: 'K_js8HXa8VM', // Smart X Academy tutorial Video ID requested by user
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        disableDragSeek: false,
      ),
    );
  }

  @override
  void dispose() {
    _ytController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isLight = !widget.isDarkMode;

    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFF5F7FA) : const Color(0xFF111827),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: isLight ? Colors.white : const Color(0xFF1F2937),
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: isLight ? const Color(0xFF0D2353) : Colors.white,
            size: 26,
          ),
          onPressed: () {},
        ),
        title: Text(
          _local('title'),
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: isLight ? const Color(0xFF0D2353) : Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          // Light/Dark Theme Switcher (Represents custom dark mode icon)
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.wb_sunny_rounded : Icons.nights_stay_outlined,
              color: isLight ? const Color(0xFF0D2353) : Colors.amberAccent,
              size: 24,
            ),
            onPressed: widget.onToggleTheme,
          ),
          
          // Compact, elegant language globe button matching design with EN/አማ
          GestureDetector(
            onTap: widget.onToggleLanguage,
            child: Container(
              margin: const EdgeInsets.only(right: 16, left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF374151),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.public_outlined,
                    size: 18,
                    color: isLight ? const Color(0xFF0D2353) : const Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "EN/አማ",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isLight ? const Color(0xFF0D2353) : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      body: _buildCurrentTab(isLight),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
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
          backgroundColor: isLight ? Colors.white : const Color(0xFF1F2937),
          selectedItemColor: const Color(0xFF1E88E5),
          unselectedItemColor: isLight ? const Color(0xFF90A4AE) : const Color(0xFF64748B),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_filled),
              label: _local('nav_home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.book_outlined),
              label: _local('nav_courses'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              label: _local('nav_profile'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
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
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant Video / Tutorial Showcase Card (image_2.png top box)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isLight ? Colors.white : const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: [
                BoxShadow(
                  color: isLight ? Colors.black.withOpacity(0.04) : Colors.black.withOpacity(0.2),
                  blurRadius: 12.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // YouTube simulated video viewport
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _isPlaying
                            ? YoutubePlayer(
                                controller: _ytController,
                                showVideoProgressIndicator: true,
                              )
                            : Stack(
                                children: [
                                  // Video Thumbnail Placeholder
                                  Container(
                                    height: 190,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                                    ),
                                    child: Image.network(
                                      'https://img.youtube.com/vi/K_js8HXa8VM/maxresdefault.jpg',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.network(
                                          'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=600&auto=format&fit=crop&q=80',
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    ),
                                  ),
                                  // Dark overlay tint for visual contrast
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black.withOpacity(0.25),
                                    ),
                                  ),
                                  // Elegant Play Button (Center-aligned)
                                  Positioned.fill(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isPlaying = true;
                                          });
                                          _ytController.play();
                                        },
                                        child: Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E88E5), // Educational blue play button
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.15),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                              BoxShadow(
                                                color: const Color(0xFF1E88E5).withOpacity(0.3),
                                                blurRadius: 16,
                                                spreadRadius: 2,
                                              )
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 38,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Top Title overlay (looks premium like floating UI)
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.black54, Colors.transparent],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                      child: const Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.white,
                                            child: Icon(Icons.school, size: 12, color: Color(0xFF1E88E5)),
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "Welcome to Smart X Academy...",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  // Bottom caption matching image
                  Text(
                    _local('tutorial_desc'),
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: isLight ? const Color(0xFF42526E) : Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24.0),

          // --- Premium Smart X Quiz Arena CTA Banner ---
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLight 
                    ? [const Color(0xFF0F172A), const Color(0xFF1E293B)] 
                    : [const Color(0xFF1E1E38), const Color(0xFF0D2353)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E88E5).withOpacity(0.12),
                  blurRadius: 18.0,
                  spreadRadius: 2.0,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF0EA5E9).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "POPULAR FEATURE",
                                style: TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.flash_on, color: Colors.amber, size: 14),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Smart X Quiz Arena",
                          style: TextStyle(
                            fontSize: 18.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Test your syllabus skills, earn grades, watch rewarded test videos for hints, and prepare for exams!",
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey[300],
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const QuizScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: const Color(0xFF0D2353),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      elevation: 3,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, size: 22, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24.0),
          
          // Explore section title matching image
          Text(
            _local('explore_title'),
            style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.w800,
              color: isLight ? const Color(0xFF0D2353) : Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            _local('explore_sub'),
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: isLight ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
            ),
          ),
          
          const SizedBox(height: 20.0),
          
          // 2x2 Clean Grid Layout matching exact cards in image
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.88, // Custom aspect ratio optimized to hold title, sub text and pill button
            children: [
              // Grade 9
              _buildGradeCard(
                title: _local('g9_title'),
                subtitle: _local('g9_sub'),
                illustration: _buildScrollIllustration(),
                btnColor: const Color(0xFF0084FF),
                isLight: isLight,
                onTap: () => _navigateToGradeScreen(9),
              ),
              // Grade 10
              _buildGradeCard(
                title: _local('g10_title'),
                subtitle: _local('g10_sub'),
                illustration: _buildShieldIllustration(),
                btnColor: const Color(0xFF10B981),
                isLight: isLight,
                onTap: () => _navigateToGradeScreen(10),
              ),
              // Grade 11
              _buildGradeCard(
                title: _local('g11_title'),
                subtitle: _local('g11_sub'),
                illustration: _buildOrbitIllustration(),
                btnColor: const Color(0xFFF59E0B),
                isLight: isLight,
                onTap: () => _navigateToGradeScreen(11),
              ),
              // Grade 12
              _buildGradeCard(
                title: _local('g12_title'),
                subtitle: _local('g12_sub'),
                illustration: _buildGraduateIllustration(),
                btnColor: const Color(0xFF8B5CF6),
                isLight: isLight,
                onTap: () => _navigateToGradeScreen(12),
              ),
            ],
          ),
          
          // Bottom Coming Soon Horizontal Subjects Row
          _buildComingSoonSubjectsSection(isLight),
        ],
      ),
    );
  }

  Widget _buildGradeCard({
    required String title,
    required String subtitle,
    required Widget illustration,
    required Color btnColor,
    required bool isLight,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF374151),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isLight ? Colors.black.withOpacity(0.04) : Colors.black.withOpacity(0.25),
              blurRadius: 16.0,
              offset: const Offset(0, 8),
            )
          ],
        ),
        padding: const EdgeInsets.all(18.0),
        child: Stack(
          children: [
            // Right Corner Custom Vector Illustration
            Positioned(
              right: 0,
              top: 0,
              child: illustration,
            ),
            // Title, description and CTA Button Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w800,
                        color: isLight ? const Color(0xFF0D2353) : Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.0,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: isLight ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                // Premium colored Start Course button at the bottom left of card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: btnColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: btnColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: const Text(
                    "Start Course",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Beautiful Custom stacked vector illustrations matching image ---
  Widget _buildScrollIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: -0.15,
          child: Container(
            height: 48,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(1, 2),
                )
              ]
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (i) => Container(height: 1.8, width: 22, color: const Color(0xFFFFD54F))),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(3.5),
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
              shape: BoxShape.circle,
            ),
            child: const Text("A+", style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildShieldIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(
          Icons.shield_outlined,
          color: Color(0xFF2E7D32),
          size: 46,
        ),
        Positioned(
          child: Icon(
            Icons.nature_people_outlined,
            color: const Color(0xFF2E7D32).withOpacity(0.4),
            size: 20,
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(3.5),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
            child: const Text("A+", style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  Widget _buildOrbitIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(
          Icons.analytics_outlined,
          color: Color(0xFFEF6C00),
          size: 46,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(3.5),
            decoration: const BoxDecoration(
              color: Color(0xFFEF6C00),
              shape: BoxShape.circle,
            ),
            child: const Text("A+", style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildGraduateIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(
          Icons.public_outlined,
          color: Color(0xFF6A1B9A),
          size: 46,
        ),
        Positioned(
          top: 0,
          child: Icon(
            Icons.school_outlined,
            color: const Color(0xFF6A1B9A).withOpacity(0.8),
            size: 18,
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(3.5),
            decoration: const BoxDecoration(
              color: Color(0xFF6A1B9A),
              shape: BoxShape.circle,
            ),
            child: const Text("A+", style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // Horizontal Scrolling Subjects Row with elegant "Coming Soon" badges
  Widget _buildComingSoonSubjectsSection(bool isLight) {
    final subjectItems = [
      _SubjectItem(name: "Math", icon: Icons.calculate_outlined, color: const Color(0xFF0084FF)),
      _SubjectItem(name: "Physics", icon: Icons.science_outlined, color: const Color(0xFF8B5CF6)),
      _SubjectItem(name: "Biology", icon: Icons.biotech_outlined, color: const Color(0xFF10B981)),
      _SubjectItem(name: "History", icon: Icons.class_outlined, color: const Color(0xFFF59E0B)),
      _SubjectItem(name: "Chemistry", icon: Icons.opacity, color: const Color(0xFF06B6D4)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28.0),
        Row(
          children: [
            Text(
              "Explore Subjects",
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w800,
                color: isLight ? const Color(0xFF0D2353) : Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Syllabus",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isLight ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14.0),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: subjectItems.length,
            itemBuilder: (context, index) {
              final item = subjectItems[index];
              return Container(
                width: 95,
                margin: const EdgeInsets.only(right: 14),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // Class body container
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      top: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isLight ? Colors.white : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             const SizedBox(height: 12),
                             Container(
                               padding: const EdgeInsets.all(8),
                               decoration: BoxDecoration(
                                 color: item.color.withOpacity(0.12),
                                 shape: BoxShape.circle,
                               ),
                               child: Icon(
                                 item.icon,
                                 color: item.color,
                                 size: 22,
                               ),
                             ),
                             const SizedBox(height: 8),
                             Text(
                               item.name,
                               style: TextStyle(
                                 fontSize: 12,
                                 fontWeight: FontWeight.bold,
                                 color: isLight ? const Color(0xFF0D2353) : Colors.white,
                               ),
                             ),
                          ],
                        ),
                      ),
                    ),
                    // Elegant "Coming Soon" Badge over Subject
                    Positioned(
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isLight ? const Color(0xFF334155) : const Color(0xFF475569),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: const Text(
                          "Coming Soon",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  void _navigateToGradeScreen(int grade) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizScreen(grade: grade),
      ),
    );
  }

  // Placeholder screen structures for secondary tabs
  Widget _buildCoursesScreen(bool isLight) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("All Academy Courses", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isLight ? const Color(0xFF0D2353) : Colors.white)),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: "Search courses...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: isLight ? Colors.white : const Color(0xFF1F2937),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          _buildPopularCourseItem("Mathematics Grade 12", "Calculus & Algebra", "4.8 ★ (120 reviews)", "48 Modules", const Color(0xFF9C27B0), isLight),
          _buildPopularCourseItem("Physics Grade 11", "Mechanics & Relativity", "4.9 ★ (95 reviews)", "40 Modules", const Color(0xFFFFA726), isLight),
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
        color: isLight ? Colors.white : const Color(0xFF1F2937),
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
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isLight ? const Color(0xFF0D2353) : Colors.white)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(rating, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
                    const SizedBox(width: 12),
                    Text(length, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
            Text("Abebe Bekele", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isLight ? const Color(0xFF0D2353) : Colors.white)),
            const Text("Grade 12 Student | Smart X Enthusiast", style: TextStyle(fontSize: 13, color: Colors.grey)),
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
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSettingsScreen(bool isLight) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text("Language Toggle"),
          subtitle: Text(widget.languageCode == 'en' ? "Currently English" : "በአማርኛ"),
          trailing: Switch(
            value: widget.languageCode == 'am',
            onChanged: (val) => widget.onToggleLanguage(),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: const Text("Dark Theme Mode"),
          subtitle: Text(widget.isDarkMode ? "Enabled" : "Disabled"),
          trailing: Switch(
            value: widget.isDarkMode,
            onChanged: (val) => widget.onToggleTheme(),
          ),
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text("App Version"),
          trailing: Text("1.0.0+1"),
        ),
      ],
    );
  }
}

// Separate Page shown when a user taps a Grade selection card
class GradeCoursesPage extends StatelessWidget {
  final int grade;
  final bool isDarkMode;
  const GradeCoursesPage({super.key, required this.grade, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    bool isLight = !isDarkMode;
    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFF5F7FA) : const Color(0xFF111827),
      appBar: AppBar(
        iconTheme: IconThemeData(color: isLight ? const Color(0xFF0D2353) : Colors.white),
        backgroundColor: isLight ? Colors.white : const Color(0xFF1F2937),
        elevation: 0.5,
        title: Text(
          'Grade $grade Syllabus',
          style: TextStyle(fontWeight: FontWeight.bold, color: isLight ? const Color(0xFF0D2353) : Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        children: [
          _buildItem(context, "Lesson 1: Introduction to Calculus & Function Analysis", "Duration: 45m", isLight),
          _buildItem(context, "Lesson 2: Modern Physics Principles and Vectors", "Duration: 55m", isLight),
          _buildItem(context, "Lesson 3: Advanced Chemical Synthesis & Equilibrium", "Duration: 1h 10m", isLight),
          _buildItem(context, "Lesson 4: Structure of Cells and Metabolism pathways", "Duration: 38m", isLight),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, String title, String duration, bool isLight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isLight ? Colors.black.withOpacity(0.04) : Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.5,
              height: 1.3,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, size: 14, color: isLight ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Text(
                  duration,
                  style: TextStyle(
                    color: isLight ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.play_circle_fill, color: Color(0xFF1E88E5), size: 32),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Launching video lesson player...")));
            },
          ),
        ),
      ),
    );
  }
}

class _SubjectItem {
  final String name;
  final IconData icon;
  final Color color;

  const _SubjectItem({
    required this.name,
    required this.icon,
    required this.color,
  });
}
