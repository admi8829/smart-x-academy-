import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ad_helper.dart';
import '../main.dart';
import 'subject_selection_screen.dart';
import 'register_screen.dart';
import 'video_player_screen.dart';
import 'unit_selection_screen.dart';

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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _selectedUnitsGrade = 12; // Track selected grade filter for Units tab
  late AnimationController _fadeController;

  // Dynamic User Profile Fields loaded from SharedPreferences
  String _userName = "Abebe Bekele";
  String _userGradeStr = "Grade 12 Student";
  String _userSchoolName = "Yeka Secondary School";
  String _userPhoneNumber = "+251 911 234 567";
  String _userEmail = "abebe@smartx.com";
  bool _isPremiumUser = true;
  bool _profileImageRemoved = false;

  // --- AdMob Ads State ---
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

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
      'start_course_btn': 'Start Course',
      'featured_title': 'Today\'s Featured Lessons',
      'featured_sub': 'Select a lesson below to watch instantly in the player.',
      'pdf_preview_title': 'PDF Study Material Preview',
      'pdf_preview_sub': 'Interactive quick summary cheat cards. Switch pages below.',
      'pdf_prev_btn': 'Prev',
      'pdf_next_btn': 'Next',
      'pdf_download_btn': 'Download PDF',
      'pdf_page_label': 'Page',
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
      'start_course_btn': 'ኮርስ ጀምር',
      'featured_title': 'የዛሬው ልዩ ትምህርቶች',
      'featured_sub': 'በቀጥታ ለመመልከት ከታች ካሉት ቪዲዮዎች አንዱን ይምረጡ።',
      'pdf_preview_title': 'የፒዲኤፍ ማጠቃለያ ማሳያ',
      'pdf_preview_sub': 'በይነተገናኝ አጫጭር የጥናት ካርዶች። ገጾችን ከታች ይቀይሩ።',
      'pdf_prev_btn': 'ቀዳሚ',
      'pdf_next_btn': 'ቀጣይ',
      'pdf_download_btn': 'ማውረድ (PDF)',
      'pdf_page_label': 'ገጽ',
    }
  };

  // 4 Featured rich playlist videos matching the user screen layout perfectly
  final List<Map<String, String>> _featuredVideos = [
    {
      'title': 'Mathematics G12 - Unit 1: Sequence & Series Matric Prep',
      'duration': '1:15:30',
      'id': 'K_js8HXa8VM',
      'thumbnail': 'https://img.youtube.com/vi/K_js8HXa8VM/hqdefault.jpg',
    },
    {
      'title': 'Physics G11 - Unit 2: Two-Dimensional Motion Concept Mastery',
      'duration': '1:48:15',
      'id': 'bhpnLBUrk-4',
      'thumbnail': 'https://img.youtube.com/vi/bhpnLBUrk-4/hqdefault.jpg',
    },
    {
      'title': 'Chemistry G10 - Unit 3: Organic Hydrocarbons and Formulas',
      'duration': '1:02:40',
      'id': 'I5GdkvpY424',
      'thumbnail': 'https://img.youtube.com/vi/I5GdkvpY424/hqdefault.jpg',
    },
    {
      'title': 'Biology G9 - Unit 4: Cellular Structures & Daily Revision',
      'duration': '55:20',
      'id': 'AIinN1ezdoE',
      'thumbnail': 'https://img.youtube.com/vi/AIinN1ezdoE/hqdefault.jpg',
    },
  ];

  String _local(String key) {
    return _localizedValues[widget.languageCode]?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    // Replicating tutorial video with standard Youtube embedded controller
    _loadBannerAd();
    _fadeController.forward();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_fullName') ?? "Abebe Bekele";
      final gradeVal = prefs.getString('user_grade') ?? "Grade 12";
      _userGradeStr = gradeVal.endsWith("Student") ? gradeVal : "$gradeVal Student";
      _userSchoolName = prefs.getString('user_schoolName') ?? "Yeka Secondary School";
      _userPhoneNumber = prefs.getString('user_phoneNumber') ?? "+251 911 234 567";
      _userEmail = prefs.getString('user_email') ?? "abebe@smartx.com";
      _isPremiumUser = prefs.getBool('user_isPremium') ?? true;
      _profileImageRemoved = prefs.getBool('user_imageRemoved') ?? false;
    });
  }

  Future<void> _removeProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('user_imageRemoved', true);
    setState(() {
      _profileImageRemoved = true;
    });
  }

  Future<void> _restoreProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('user_imageRemoved', false);
    setState(() {
      _profileImageRemoved = false;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  /// Initialize AdMob and trigger async load for HomeScreen banner
  void _loadBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;

    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = true;
            });
          } else {
            ad.dispose();
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('HomeScreen BannerAd failed to load: $err. Code: ${err.code}');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = false;
              _bannerAd = null;
            });
          }
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final bool isDark = appState.isDarkMode;
    final bool isLight = !isDark;
    final String currentLang = appState.languageCode;

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
          _localizedValues[currentLang]?['title'] ?? 'Smart X Academy',
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
              isDark ? Icons.wb_sunny_rounded : Icons.nights_stay_outlined,
              color: isLight ? const Color(0xFF0D2353) : Colors.amberAccent,
              size: 24,
            ),
            onPressed: appState.onToggleTheme,
          ),
          
          // Compact, elegant language globe button matching design with EN/አማ
          GestureDetector(
            onTap: appState.onToggleLanguage,
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFF5F7FA) : const Color(0xFF111827),
          image: DecorationImage(
            image: const AssetImage('assets/images/education_bg_pattern.png'),
            repeat: ImageRepeat.repeat,
            opacity: isLight ? 0.09 : 0.03,
            colorFilter: isLight ? null : const ColorFilter.mode(Colors.white54, BlendMode.modulate),
          ),
        ),
        child: _buildCurrentTab(isLight, currentLang, appState),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(18.0, 0.0, 18.0, 24.0),
        child: Container(
          decoration: BoxDecoration(
            color: isLight ? Colors.white : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(38.0),
            border: Border.all(
              color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isLight 
                    ? const Color(0xFF0F1B2B).withValues(alpha: 0.08) 
                    : Colors.black.withValues(alpha: 0.45),
                blurRadius: 28.0,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(38.0),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              elevation: 0,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: const Color(0xFF1E88E5),
              unselectedItemColor: isLight ? const Color(0xFF2D3748) : const Color(0xFF94A3B8),
              selectedFontSize: 12.5,
              unselectedFontSize: 12.5,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E88E5),
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w700,
                color: isLight ? const Color(0xFF212529) : const Color(0xFFA0AEC0),
              ),
              items: [
                BottomNavigationBarItem(
                  icon: const Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Icon(
                      Icons.school_rounded,
                      size: 26,
                    ),
                  ),
                  label: currentLang == 'en' ? 'Courses' : 'ኮርሶች',
                ),
                BottomNavigationBarItem(
                  icon: const Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Icon(
                      Icons.collections_bookmark_rounded,
                      size: 25,
                    ),
                  ),
                  label: currentLang == 'en' ? 'Units' : 'ክፍሎች',
                ),
                BottomNavigationBarItem(
                  icon: const Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Icon(
                      Icons.account_circle_rounded,
                      size: 26,
                    ),
                  ),
                  label: currentLang == 'en' ? 'Account' : 'መገለጫ',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTab(bool isLight, String currentLang, AppStateProvider appState) {
    switch (_currentIndex) {
      case 0:
        return _buildHomeScreenContent(isLight);
      case 1:
        return _buildUnitsExplorerTab(isLight, currentLang, appState);
      case 2:
        return _buildProfileScreen(isLight);
      default:
        return _buildHomeScreenContent(isLight);
    }
  }

  Widget _animateItem({required Widget child, required int index}) {
    final curver = CurvedAnimation(
      parent: _fadeController,
      curve: Interval(
        (0.05 + (index * 0.12)).clamp(0.0, 1.0),
        (0.55 + (index * 0.12)).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.14),
          end: Offset.zero,
        ).animate(curver),
        child: child,
      ),
    );
  }

  Widget _buildHomeScreenContent(bool isLight) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index 3: Rich Dynamic Playlist Video Format (Horizontal scroll viewport containing > 3 videos)
          _animateItem(
            index: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E88E5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _local('featured_title'),
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w900,
                        color: isLight ? const Color(0xFF0D2353) : Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  _local('featured_sub'),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: isLight ? const Color(0xFF718096) : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  height: 195.0,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _featuredVideos.length,
                    itemBuilder: (context, index) {
                      final video = _featuredVideos[index];
                      return Container(
                        width: 220.0,
                        margin: const EdgeInsets.only(right: 16.0, bottom: 8),
                        decoration: BoxDecoration(
                          color: isLight ? Colors.white : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 12.0,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20.0),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerScreen(
                                  videoId: video['id']!,
                                  title: video['title']!,
                                  duration: video['duration']!,
                                  isDarkMode: !isLight,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Video Thumbnail with floating Duration tag & Play marker
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(19.0)),
                                child: Stack(
                                  children: [
                                    SizedBox(
                                      height: 80.0,
                                      width: double.infinity,
                                      child: Image.network(
                                        video['thumbnail']!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, e, s) => Container(
                                          color: const Color(0xFFCBD5E1),
                                          child: const Icon(Icons.video_library_rounded, color: Colors.white, size: 24),
                                        ),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black.withValues(alpha: 0.12),
                                      ),
                                    ),
                                    // Play icon ring in center
                                    Positioned.fill(
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.9),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.15),
                                                blurRadius: 4,
                                              )
                                            ]
                                          ),
                                          child: const Icon(
                                            Icons.play_arrow_rounded,
                                            size: 16,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Duration badge at the bottom-right corner of image matching screenshot
                                    Positioned(
                                      bottom: 4.0,
                                      right: 4.0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.75),
                                          borderRadius: BorderRadius.circular(4.0),
                                        ),
                                        child: Text(
                                          video['duration']!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9.0,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 8.0, bottom: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      video['title']!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: isLight ? const Color(0xFF0F172A) : Colors.white,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6.0),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Watch pill button matching screenshot "▶ Watch"
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0B3C5D), // Match gorgeous dark-blue pill
                                            borderRadius: BorderRadius.circular(50.0),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.play_arrow_rounded,
                                                color: Colors.white,
                                                size: 11,
                                              ),
                                              const SizedBox(width: 2.0),
                                              const Text(
                                                "Watch",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Companion badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            "Lesson",
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: isLight ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32.0),

          // Index 1: Free standing Explore Header (DECOUPLED AS REQUESTED!)
          _animateItem(
            index: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Explore section title matching image
                Text(
                  _local('explore_title'),
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.w900,
                    color: isLight ? const Color(0xFF0D2353) : Colors.white,
                    letterSpacing: -0.6,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  _local('explore_sub'),
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                    color: isLight ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18.0),

          // Index 2: Grid Layout of DECOUPLED INDEPENDENT GRADE CARDS with powerful shadows & gorgeous buttons
          _animateItem(
            index: 2,
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.98, // Adjusted height to make start buttons float beautifully below
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
          ),
          
          const SizedBox(height: 32.0),

          // --- Custom AdMob Banner Ad Area located visually at the very bottom end of home content ---
          if (_isBannerAdLoaded && _bannerAd != null) ...[
            Center(
              child: Container(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
          ],
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
          // Pure Colors.white background for light mode
          color: isLight ? Colors.white : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20.0,
              offset: const Offset(0, 10),
              spreadRadius: 1.0,
            )
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16.0, 18.0, 16.0, 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section containing header and illustration directly on the cream canvas
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 19.5,
                            fontWeight: FontWeight.w900,
                            color: isLight ? const Color(0xFF0F2537) : Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.0,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            color: isLight ? const Color(0xFF718096) : const Color(0xFFA0AEC0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 44,
                    width: 44,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: illustration,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10.0),
            // Premium Start Course floating button matching design and screenshot perfectly!
            Container(
              width: double.infinity,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isLight ? Colors.white : const Color(0xFF2D3748),
                borderRadius: BorderRadius.circular(20.0), // Rounded rectangular format matching screen with radius 20!
                border: Border.all(
                  color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF4A5568),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Text(
                _local('start_course_btn'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isLight ? const Color(0xFF4C6B94) : Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
              ),
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
                  color: Colors.black.withValues(alpha: 0.05),
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
            color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
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
            color: const Color(0xFF6A1B9A).withValues(alpha: 0.8),
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

  void _navigateToGradeScreen(int grade) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubjectSelectionScreen(
          grade: grade,
          isDarkMode: widget.isDarkMode,
          languageCode: widget.languageCode,
          onToggleTheme: widget.onToggleTheme,
          onToggleLanguage: widget.onToggleLanguage,
        ),
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
    final appState = AppStateProvider.of(context);
    final String currentLang = appState.languageCode;
    final bool isDark = appState.isDarkMode;

    // Generate lovely initials for the initials-fallback avatar
    String initials = "SU";
    if (_userName.trim().isNotEmpty) {
      final parts = _userName.trim().split(" ");
      if (parts.length > 1) {
        initials = (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
      } else if (_userName.trim().length > 1) {
        initials = _userName.trim().substring(0, 2).toUpperCase();
      } else {
        initials = _userName.trim()[0].toUpperCase();
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Center(
        child: Column(
          children: [
            // USER AVATAR WITH DIRECT REMOVAL PORTAL
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isPremiumUser 
                          ? [const Color(0xFFF59E0B), const Color(0xFFD97706)] // Gold halo
                          : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)], // Blue halo
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: isLight ? Colors.grey[200] : const Color(0xFF1E293B),
                    backgroundImage: _profileImageRemoved 
                        ? null 
                        : const NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
                    child: _profileImageRemoved 
                        ? Text(
                            initials,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: _isPremiumUser ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
                            ),
                          )
                        : null,
                  ),
                ),
                // Direct Remove Avatar Action
                if (!_profileImageRemoved)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () {
                        _removeProfileImage();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Profile image removed successfully!"),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        height: 28,
                        width: 28,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: isLight ? Colors.white : const Color(0xFF0F172A), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 15),
                      ),
                    ),
                  ),
                // Restore button icon if deleted
                if (_profileImageRemoved)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () {
                        _restoreProfileImage();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Profile image restored!"),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        height: 28,
                        width: 28,
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          shape: BoxShape.circle,
                          border: Border.all(color: isLight ? Colors.white : const Color(0xFF0F172A), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Dynamic user name and primary status label with PREMIUM STAR integration
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _userName,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: isLight ? const Color(0xFF0D2353) : Colors.white,
                  ),
                ),
                if (_isPremiumUser) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified_rounded, color: Color(0xFFF59E0B), size: 18),
                ],
              ],
            ),
            const SizedBox(height: 3),
            Text(
              "$_userGradeStr | $_userSchoolName",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 18),

            // STATS COLUMNS ROW OF SMART X
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn("Streak", "15 days", Icons.local_fire_department, Colors.orange),
                _buildStatColumn("Completed", "18 lessons", Icons.check_circle_outline, Colors.green),
                _buildStatColumn("Avg Score", "94%", Icons.emoji_events_outlined, Colors.purple),
              ],
            ),
            const SizedBox(height: 24),

            // STUNNING PREMIUM PRO MEMBER REWORK BANNER DISPLAY
            if (_isPremiumUser)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)], // Warm honey highlights
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded, color: Color(0xFFD97706), size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "ACTIVE PRO PREMIUM STUDENT",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFB45309),
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            currentLang == 'en'
                                ? "Full syllabus content and video portal unlocked with unlimited access."
                                : "የቪዲዮ ማብራሪያዎች እና ሙሉውን የ9-12ኛ ማጠቃለያዎች ተከፍተዋል።",
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF78350F),
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // DETAILS CONTAINER CARD FOR FULL CONTACT PROFILE DETAILS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(22.0),
                border: Border.all(
                  color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentLang == 'en' ? 'Academic Information' : 'የትምህርት መረጃ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isLight ? const Color(0xFF0D2353) : Colors.white,
                    ),
                  ),
                  const Divider(height: 20, thickness: 1),
                  
                  _buildProfileDetailRow(
                    label: currentLang == 'en' ? 'Full Name' : 'ሙሉ ስም',
                    value: _userName,
                    icon: Icons.person_rounded,
                    isLight: isLight,
                  ),
                  _buildProfileDetailRow(
                    label: currentLang == 'en' ? 'School / Academy' : 'ምንጮች / ትምህርት ቤት',
                    value: _userSchoolName,
                    icon: Icons.apartment_rounded,
                    isLight: isLight,
                  ),
                  _buildProfileDetailRow(
                    label: currentLang == 'en' ? 'Grade / Class' : 'ክፍል',
                    value: _userGradeStr,
                    icon: Icons.school_rounded,
                    isLight: isLight,
                  ),
                  _buildProfileDetailRow(
                    label: currentLang == 'en' ? 'Phone Number' : 'ስልክ ቁጥር',
                    value: _userPhoneNumber,
                    icon: Icons.phone_android_rounded,
                    isLight: isLight,
                  ),
                  _buildProfileDetailRow(
                    label: currentLang == 'en' ? 'Email Address' : 'ኢሜል አድራሻ',
                    value: _userEmail,
                    icon: Icons.mail_rounded,
                    isLight: isLight,
                  ),
                ],
              ),
            ),

            // REGISTER / EDIT PROFILE BUTTON BOX
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isLight ? 0.03 : 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.security_rounded,
                    color: isLight ? const Color(0xFF0D2353) : const Color(0xFF38BDF8),
                    size: 32,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.languageCode == 'en' ? 'Credential Sync & Updates' : 'ማመሳሰል እና ማስተካከያ',
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: isLight ? const Color(0xFF0D2353) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentLang == 'en' 
                        ? 'Update your details or link using safe, cloud-based synchronization.' 
                        : 'የትምህርት መረጃዎን ለማሻሻል ወይም ለመመዝገብ ከታች ያለውን መቆጣጠሪያ ይጫኑ።',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.4,
                      color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 18),
                      label: Text(
                        currentLang == 'en' ? 'Register / Profile Settings' : 'ይመዝገቡ / መገለጫ ያዋቅሩ',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterScreen(
                              isDarkMode: appState.isDarkMode,
                              languageCode: appState.languageCode,
                              onToggleTheme: appState.onToggleTheme,
                              onToggleLanguage: appState.onToggleLanguage,
                            ),
                          ),
                        ).then((_) {
                          // REFRESH dynamic details from SharedPreferences instantly when popped back!
                          _loadProfileData();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLight ? const Color(0xFF0D2353) : const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Integrated Settings & Choices Section to provide complete, instant updates
            Container(
              margin: const EdgeInsets.only(top: 20, bottom: 24),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isLight 
                        ? const Color(0xFF0F1B2B).withValues(alpha: 0.02) 
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
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
                        Icons.settings_suggest_rounded,
                        color: isLight ? const Color(0xFF0D2353) : const Color(0xFF38BDF8),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentLang == 'en' ? 'Settings & Choices' : 'ማስተካከያዎች እና አማራጮች',
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: isLight ? const Color(0xFF0D2353) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.language, color: isLight ? const Color(0xFF0D2353) : const Color(0xFF38BDF8)),
                    title: Text(
                      currentLang == 'en' ? "Language Toggle" : "ቋንቋ መቀያየሪያ", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: isLight ? const Color(0xFF0D2353) : Colors.white),
                    ),
                    subtitle: Text(
                      currentLang == 'en' ? "Currently English" : "በአማርኛ", 
                      style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                    trailing: Switch(
                      activeColor: const Color(0xFF1E88E5),
                      value: currentLang == 'am',
                      onChanged: (val) {
                        appState.onToggleLanguage();
                      },
                    ),
                  ),
                  const Divider(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.dark_mode_rounded, color: isLight ? const Color(0xFF0D2353) : const Color(0xFF38BDF8)),
                    title: Text(
                      currentLang == 'en' ? "Dark Theme Mode" : "ጨለማ ገጽታ", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: isLight ? const Color(0xFF0D2353) : Colors.white),
                    ),
                    subtitle: Text(
                      isDark ? (currentLang == 'en' ? "Enabled" : "በርቷል") : (currentLang == 'en' ? "Disabled" : "ጠፍቷል"), 
                      style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                    trailing: Switch(
                      activeColor: const Color(0xFF1E88E5),
                      value: isDark,
                      onChanged: (val) {
                        appState.onToggleTheme();
                      },
                    ),
                  ),
                  const Divider(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.info_outline_rounded, color: isLight ? const Color(0xFF0D2353) : const Color(0xFF38BDF8)),
                    title: Text(
                      currentLang == 'en' ? "App Version" : "የመተግበሪያው ስሪት", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: isLight ? const Color(0xFF0D2353) : Colors.white),
                    ),
                    trailing: const Text("1.0.0+1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitsExplorerTab(bool isLight, String currentLang, AppStateProvider appState) {
    // List representing subjects with localization support
    final List<Map<String, dynamic>> subjectsList = [
      {
        'id': 'Mathematics',
        'enTitle': 'Mathematics',
        'amTitle': 'ሂሳብ',
        'color': const Color(0xFF0084FF),
        'iconData': Icons.calculate_rounded,
      },
      {
        'id': 'Biology',
        'enTitle': 'Biology',
        'amTitle': 'ስነ-ህይወት',
        'color': const Color(0xFF2E7D32),
        'iconData': Icons.biotech_rounded,
      },
      {
        'id': 'Physics',
        'enTitle': 'Physics',
        'amTitle': 'ፊዚክስ',
        'color': const Color(0xFFE53935),
        'iconData': Icons.bolt_rounded,
      },
      {
        'id': 'Chemistry',
        'enTitle': 'Chemistry',
        'amTitle': 'ኬሚስትሪ',
        'color': const Color(0xFFEF6C00),
        'iconData': Icons.science_rounded,
      },
      {
        'id': 'Geography',
        'enTitle': 'Geography',
        'amTitle': 'ጂኦግራፊ',
        'color': const Color(0xFF8E24AA),
        'iconData': Icons.public_rounded,
      },
      {
        'id': 'History',
        'enTitle': 'History',
        'amTitle': 'ታሪክ',
        'color': const Color(0xFFF5B041),
        'iconData': Icons.museum_rounded,
      },
      {
        'id': 'Civics',
        'enTitle': 'Civics',
        'amTitle': 'ዜግነት',
        'color': const Color(0xFF1E88E5),
        'iconData': Icons.gavel_rounded,
      },
      {
        'id': 'Agriculture',
        'enTitle': 'Agriculture',
        'amTitle': 'ግብርና',
        'color': const Color(0xFF8D6E63),
        'iconData': Icons.agriculture_rounded,
      },
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant customized title header
          Text(
            currentLang == 'en' ? "Units Explorer" : "የትምህርት ክፍሎች ማውጫ",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isLight ? const Color(0xFF0D2353) : Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currentLang == 'en' 
                ? "Select a class grade and subject to explore curriculum units offline." 
                : "ከመስመር ውጭ ለመማር ክፍልዎን እና የትምህርት ዓይነትዎን ይምረጡ።",
            style: TextStyle(
              fontSize: 12.5,
              color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),

          // Grade Selection Buttons Selector with smooth physical scaling
          Row(
            children: [9, 10, 11, 12].map((gradeNum) {
              final isSelected = _selectedUnitsGrade == gradeNum;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedUnitsGrade = gradeNum;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected 
                            ? (isLight ? const Color(0xFF0D2353) : const Color(0xFF38BDF8))
                            : (isLight ? Colors.white : const Color(0xFF1E293B)),
                        foregroundColor: isSelected 
                            ? (isLight ? Colors.white : const Color(0xFF0F172A))
                            : (isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                        elevation: isSelected ? 3.0 : 0.0,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.0),
                          side: BorderSide(
                            color: isSelected 
                                ? Colors.transparent 
                                : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Text(
                        currentLang == 'en' ? "G-$gradeNum" : "ክፍል-$gradeNum",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Grid View of Subjects mapping standard designs
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subjectsList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14.0,
              mainAxisSpacing: 14.0,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, idx) {
              final sub = subjectsList[idx];
              final String title = currentLang == 'en' ? sub['enTitle']! : sub['amTitle']!;
              final Color color = sub['color'] as Color;
              final IconData iconData = sub['iconData'] as IconData;

              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UnitSelectionScreen(
                        grade: _selectedUnitsGrade,
                        subjectId: sub['id']!,
                        enTitle: sub['enTitle']!,
                        amTitle: sub['amTitle']!,
                        color: color,
                        icon: Icon(iconData, size: 36, color: color),
                        isDarkMode: appState.isDarkMode,
                        languageCode: appState.languageCode,
                        onToggleTheme: appState.onToggleTheme,
                        onToggleLanguage: appState.onToggleLanguage,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(22.0),
                child: Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: isLight ? Colors.white : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(22.0),
                    border: Border.all(
                      color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isLight 
                            ? const Color(0xFF0F1B2B).withValues(alpha: 0.02) 
                            : Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconData, color: color, size: 24),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: isLight ? const Color(0xFF0D2353) : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentLang == 'en' ? "View Units" : "ክፍሎችን እይ",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow({
    required String label,
    required String value,
    required IconData icon,
    required bool isLight,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 1.5),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isLight ? const Color(0xFF1E293B) : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
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
