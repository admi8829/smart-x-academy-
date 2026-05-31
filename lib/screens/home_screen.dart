import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../services/gms_and_ads_service.dart';

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
      'tutorial_desc': 'Watch tutorial: Getting started with the Smart X Academy App.',
      'explore_title': 'Explore Your Grade',
      'explore_sub': 'Select your grade to view courses.',
      'g9_title': 'Grade 9',
      'g9_sub': 'Begin your journey!',
      'g10_title': 'Grade 10',
      'g10_sub': 'Expand your knowledge!',
      'g11_title': 'Grade 11',
      'g11_sub': 'Prepare for excellence!',
      'g12_title': 'Grade 12',
      'g12_sub': 'Achieve your goals!',
      'nav_home': 'Home',
      'nav_courses': 'Courses',
      'nav_profile': 'Profile',
      'nav_settings': 'Settings',
    },
    'am': {
      'title': 'ስማርት ኤክስ አካዳሚ',
      'tutorial_desc': 'የመማሪያ መመሪያውን ይመልከቱ: በስማርት ኤክስ አካዳሚ መተግበሪያ እንዴት እንደሚጀመር።',
      'explore_title': 'ደረጃዎን ይመልከቱ',
      'explore_sub': 'ኮርሶችን ለማየት ክፍልዎን ይምረጡ።',
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
      initialVideoId: 'FRjnr4UAhNk', // Replace with Smart X Academy tutorial ID
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
              widget.isDarkMode ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
              color: isLight ? const Color(0xFF0D2353) : const Color(0xFF7A97FF),
              size: 24,
            ),
            onPressed: widget.onToggleTheme,
          ),
          
          // Compact, elegant language button
          GestureDetector(
            onTap: widget.onToggleLanguage,
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16, left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFF5F7FA) : const Color(0xFF374151),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.public, // elegant globe icon
                      size: 14,
                      color: isLight ? const Color(0xFF0D2353) : const Color(0xFF7A97FF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.languageCode.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isLight ? const Color(0xFF0D2353) : Colors.white,
                      ),
                    ),
                  ],
                ),
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
              color: Colors.black.withValues(alpha: 0.05),
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
                  color: isLight ? Colors.black.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.2),
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
                                      'https://img.youtube.com/vi/FRjnr4UAhNk/maxresdefault.jpg',
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
                                      color: Colors.black.withValues(alpha: 0.25),
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
                                                color: Colors.black.withValues(alpha: 0.15),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                              BoxShadow(
                                                color: const Color(0xFF1E88E5).withValues(alpha: 0.3),
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
          
          const SizedBox(height: 16.0),
          
          // GMS-Safe Sponsor/AdMob Banner Container
          const SmartXAdsBannerWidget(),
          
          const SizedBox(height: 16.0),
          
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
            childAspectRatio: 1.12,
            children: [
              // Grade 9
              _buildGradeCard(
                title: _local('g9_title'),
                subtitle: _local('g9_sub'),
                icon: Icons.auto_stories,
                iconColor: Colors.white,
                circleBg: const Color(0xFF1E88E5), // Soft Blue
                isLight: isLight,
                onTap: () => _navigateToGradeScreen(9),
              ),
              // Grade 10
              _buildGradeCard(
                title: _local('g10_title'),
                subtitle: _local('g10_sub'),
                icon: Icons.science_outlined,
                iconColor: Colors.white,
                circleBg: const Color(0xFF4CAF50), // Soft Green
                isLight: isLight,
                onTap: () => _navigateToGradeScreen(10),
              ),
              // Grade 11
              _buildGradeCard(
                title: _local('g11_title'),
                subtitle: _local('g11_sub'),
                icon: Icons.calculate_outlined,
                iconColor: Colors.white,
                circleBg: const Color(0xFFFFA726), // Soft Orange
                isLight: isLight,
                onTap: () => _navigateToGradeScreen(11),
              ),
              // Grade 12
              _buildGradeCard(
                title: _local('g12_title'),
                subtitle: _local('g12_sub'),
                icon: Icons.school_outlined,
                iconColor: Colors.white,
                circleBg: const Color(0xFF9C27B0), // Soft Purple
                isLight: isLight,
                onTap: () => _navigateToGradeScreen(12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color circleBg,
    required bool isLight,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
              color: isLight ? Colors.black.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.25),
              blurRadius: 16.0,
              offset: const Offset(0, 8),
            )
          ],
        ),
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon visual exactly styled to scale
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: circleBg,
                borderRadius: BorderRadius.circular(14.0),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 25,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17.0,
                    fontWeight: FontWeight.bold,
                    color: isLight ? const Color(0xFF111827) : Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                    color: isLight ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _navigateToGradeScreen(int grade) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GradeCoursesPage(grade: grade, isDarkMode: widget.isDarkMode),
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
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
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
      padding: const EdgeInsets.all(18.0),
      children: [
        // Premium Theme & Language Settings Card
        Container(
          decoration: BoxDecoration(
            color: isLight ? Colors.white : const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isLight ? Colors.black.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.language, color: isLight ? const Color(0xFF0D2353) : const Color(0xFF7A97FF)),
                title: const Text("Language Toggle", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(widget.languageCode == 'en' ? "Currently English" : "በአማርኛ"),
                trailing: Switch(
                  value: widget.languageCode == 'am',
                  onChanged: (val) => widget.onToggleLanguage(),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.dark_mode, color: isLight ? const Color(0xFF0D2353) : const Color(0xFF7A97FF)),
                title: const Text("Dark Theme Mode", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(widget.isDarkMode ? "Enabled" : "Disabled"),
                trailing: Switch(
                  value: widget.isDarkMode,
                  onChanged: (val) => widget.onToggleTheme(),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Dynamic Services & Integrations Card
        Text(
          "GMS & Notifications Integration",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isLight ? const Color(0xFF0D2353) : Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isLight ? Colors.white : const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isLight ? Colors.black.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Icon(
                    GmsAndAdsService.isGmsAvailable ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                    color: GmsAndAdsService.isGmsAvailable ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      GmsAndAdsService.isGmsAvailable ? "Google Play Services [GMS] Detected" : "Non-GMS Device Clean Safe Mode",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatusLine("GMS Verified", GmsAndAdsService.isGmsAvailable ? "YES" : "NO", isLight),
              _buildStatusLine("Firebase Messaging (FCM)", GmsAndAdsService.isFirebaseInitialized ? "Initialized" : "Skipped (Offline Mode)", isLight),
              _buildStatusLine("AdMob Ads Status", GmsAndAdsService.isAdMobInitialized ? "Active & Safe" : "Disabled (Clean Mode)", isLight),
              if (GmsAndAdsService.fcmToken != null) ...[
                const SizedBox(height: 12),
                Text(
                  "FCM Push Token:",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isLight ? const Color(0xFF0D2353) : Colors.white),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFF5F7FA) : const Color(0xFF374151),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    GmsAndAdsService.fcmToken!,
                    style: const TextStyle(fontSize: 10.5, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        Container(
          decoration: BoxDecoration(
            color: isLight ? Colors.white : const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isLight ? Colors.black.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("App Version", style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text("1.0.0+1", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusLine(String label, String value, bool isLight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: value.contains("YES") || value.contains("Active") || value.contains("Initialized")
                  ? Colors.green
                  : const Color(0xFFE53935),
            ),
          ),
        ],
      ),
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
              color: isLight ? Colors.black.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.2),
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
