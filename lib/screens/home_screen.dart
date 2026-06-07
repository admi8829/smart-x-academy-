import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ad_helper.dart';
import 'subject_selection_screen.dart';
import 'register_screen.dart';
import 'video_player_screen.dart';
import 'unit_selection_screen.dart';
import 'quiz_screen.dart';
import '../services/offline_manager.dart';
import '../main.dart';

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

class HomeScreenWrapper extends HomeScreen {
  final HomeScreen actualWidget;
  
  @override
  final bool isDarkMode;
  @override
  final String languageCode;

  HomeScreenWrapper({
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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  @override
  HomeScreen get widget {
    try {
      final appState = AppStateProvider.of(context);
      return HomeScreenWrapper(
        actualWidget: super.widget,
        isDarkMode: appState.isDarkMode,
        languageCode: appState.languageCode,
      );
    } catch (_) {
      return super.widget;
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  late AnimationController _fadeController;

  // Dynamic User Profile Fields loaded from SharedPreferences
  String _userName = "Abebe Bekele";
  String _userGradeStr = "Grade 12 Student";
  String _userSchoolName = "Yeka Secondary School";
  String _userPhoneNumber = "+251 911 234 567";
  String _userEmail = "abebe@smartx.com";
  bool _isPremiumUser = true;
  bool _profileImageRemoved = false;

  // Profile Form Controllers matching screenshot fields
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _schoolNameController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _ageController;

  String _selectedSex = 'Male';
  int _selectedGrade = 12;
  int _selectedGradeForCourses = 9;
  String _selectedCountryCode = '+251';
  bool _isProfileLoading = false;
  bool _isLoginForm = true;
  bool _obscurePassword = true;
  bool _isSettingsExpanded = false;
  bool _isAboutExpanded = false;

  int _selectedGradeForQuizTab = 9;
  int _carouselIndex = 0;

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
      'nav_courses': 'Offline',
      'nav_quiz': 'Quizzes',
      'nav_notes': 'Notes',
      'nav_account': 'Account',
      'nav_profile': 'Profile',
      'nav_settings': 'Settings',
      'nav_new': 'New',
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
      'nav_courses': 'ከመስመር ውጭ',
      'nav_quiz': 'ጥያቄዎች',
      'nav_notes': 'ማስታወሻዎች',
      'nav_account': 'መለያ',
      'nav_profile': 'መገለጫ',
      'nav_settings': 'ማስተካከያዎች',
      'nav_new': 'አዲስ',
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
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _schoolNameController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _ageController = TextEditingController();

    _loadProfileData();
    _fadeController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
    );

    // Replicating tutorial video with standard Youtube embedded controller
    _loadBannerAd();
    _fadeController.forward();
    OfflineManager.addListener(_onOfflineDownloadsChanged);
  }

  void _onOfflineDownloadsChanged() {
    if (mounted) {
      setState(() {});
    }
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

      // Populate text controllers
      _fullNameController.text = _userName;
      _emailController.text = _userEmail;
      _schoolNameController.text = _userSchoolName;
      _phoneController.text = _userPhoneNumber.replaceAll(RegExp(r'^\+251\s*'), ''); // parse local digits
      _passwordController.text = "•••••••••";
      _ageController.text = prefs.getInt('user_age')?.toString() ?? "17";
      _selectedSex = prefs.getString('user_sex') ?? "Male";
      
      // parse grade number
      final numStr = _userGradeStr.replaceAll(RegExp(r'[^0-9]'), '');
      _selectedGrade = int.tryParse(numStr) ?? 12;
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
    OfflineManager.removeListener(_onOfflineDownloadsChanged);
    _fullNameController.dispose();
    _emailController.dispose();
    _schoolNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
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
    bool isLight = !widget.isDarkMode;
    final bool isCoursesActive = _currentIndex == 1;
    final bool isQuizActive = _currentIndex == 2;
    final bool isNotesActive = _currentIndex == 3;
    final bool isProfileActive = _currentIndex == 4;
    final bool isCustomDarkHeader = false;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isCustomDarkHeader
          ? (isLight ? const Color(0xFF0D2353) : const Color(0xFF0F172A))
          : (isLight ? const Color(0xFFF5F7FA) : const Color(0xFF111827)),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: isCustomDarkHeader
            ? (isLight ? const Color(0xFF0D2353) : const Color(0xFF0F172A))
            : (isLight ? Colors.white : const Color(0xFF1F2937)),
        elevation: isCustomDarkHeader ? 0 : 0.5,
        centerTitle: isCustomDarkHeader ? false : true,
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: isCustomDarkHeader ? Colors.white : (isLight ? const Color(0xFF0D2353) : Colors.white),
            size: 26,
          ),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(
          isCoursesActive
              ? (widget.languageCode == 'en' ? 'Browse Courses' : 'ኮርሶችን ያስሱ')
              : (isQuizActive
                  ? (widget.languageCode == 'en' ? 'Quizzes' : 'ጥያቄዎች')
                  : (isNotesActive
                      ? (widget.languageCode == 'en' ? 'My Notes' : 'የእኔ ማስታወሻዎች')
                      : (isProfileActive 
                          ? (_isLoginForm
                              ? (widget.languageCode == 'en' ? 'Log In' : 'ይግቡ')
                              : (widget.languageCode == 'en' ? 'Create Account' : 'መለያ ይፍጠሩ'))
                          : _local('title')))),
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: isCustomDarkHeader ? Colors.white : (isLight ? const Color(0xFF0D2353) : Colors.white),
            letterSpacing: -0.3,
          ),
        ),
        actions: isCustomDarkHeader
            ? null
            : (isProfileActive
                ? [
                    // Log In/Register toggle switcher button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLoginForm = !_isLoginForm;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isLight ? const Color(0xFFECEFF1) : const Color(0xFF1F2937),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _isLoginForm
                              ? (widget.languageCode == 'en' ? 'Register' : 'ይመዝገቡ')
                              : (widget.languageCode == 'en' ? 'Log In' : 'ይግቡ'),
                          style: TextStyle(
                            color: isLight ? const Color(0xFF0F172A) : Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    )
                  ]
                : [
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
                  ]),
      ),
      drawer: Drawer(
        backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
        width: 250, // Decreased width for a very beautiful, compact design
        child: Column(
          children: [
            // Custom premium, highly compact header with decreased space/gap
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 40, bottom: 16, left: 16, right: 16),
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFF0D2353) : const Color(0xFF0F172A),
                image: const DecorationImage(
                  image: AssetImage('assets/images/education_bg_pattern.png'),
                  repeat: ImageRepeat.repeat,
                  opacity: 0.1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isLight ? Colors.white : const Color(0xFF1E293B),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.school_rounded,
                        size: 26,
                        color: isLight ? const Color(0xFF0D2353) : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _userEmail,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildDrawerTile(
                    icon: Icons.notifications_none_rounded,
                    title: widget.languageCode == 'en' ? 'Notifications' : 'ማሳወቂያዎች',
                    isSelected: false,
                    isLight: isLight,
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoonDialog();
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.help_outline_rounded,
                    title: widget.languageCode == 'en' ? 'Help & Support' : 'እርዳታ እና ድጋፍ',
                    isSelected: false,
                    isLight: isLight,
                    onTap: () {
                      Navigator.pop(context);
                      _showHelpSupportModal(isLight);
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.info_outline_rounded,
                    title: widget.languageCode == 'en' ? 'About App' : 'ስለ መተግበሪያው',
                    isSelected: false,
                    isLight: isLight,
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutAppModal(isLight);
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.shield_outlined,
                    title: widget.languageCode == 'en' ? 'Privacy Policy' : 'የግል መመሪያ',
                    isSelected: false,
                    isLight: isLight,
                    onTap: () {
                      Navigator.pop(context);
                      _showPrivacyPolicyModal(isLight);
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.assignment_turned_in_outlined,
                    title: widget.languageCode == 'en' ? 'Terms of Service' : 'የአገልግሎት ውሎች',
                    isSelected: false,
                    isLight: isLight,
                    onTap: () {
                      Navigator.pop(context);
                      _showTermsOfServiceModal(isLight);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(
                color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                height: 1.0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: _buildDrawerTile(
                icon: Icons.logout_rounded,
                title: widget.languageCode == 'en' ? 'Log Out' : 'ውጣ',
                isSelected: false,
                isLight: isLight,
                onTap: () {
                  Navigator.pop(context);
                  _showLogOutConfirmationDialog();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isCustomDarkHeader
              ? (isLight ? const Color(0xFF0D2353) : const Color(0xFF0F172A))
              : (isLight ? const Color(0xFFF5F7FA) : const Color(0xFF111827)),
          image: isCustomDarkHeader
              ? null
              : DecorationImage(
                  image: const AssetImage('assets/images/education_bg_pattern.png'),
                  repeat: ImageRepeat.repeat,
                  opacity: isLight ? 0.09 : 0.03,
                  colorFilter: isLight ? null : const ColorFilter.mode(Colors.white54, BlendMode.modulate),
                ),
        ),
        child: _buildCurrentTab(isLight),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1E293B),
          border: Border(
            top: BorderSide(
              color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isLight 
                  ? const Color(0xFF0F1B2B).withValues(alpha: 0.05) 
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: 10.0,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavItem(
                  index: 0,
                  iconActive: Icons.home,
                  iconInactive: Icons.home_outlined,
                  label: _local('nav_home'),
                  isLight: isLight,
                ),
                _buildBottomNavItem(
                  index: 1,
                  iconActive: Icons.offline_pin,
                  iconInactive: Icons.offline_pin_outlined,
                  label: _local('nav_courses'),
                  isLight: isLight,
                ),
                _buildBottomNavItem(
                  index: 2,
                  iconActive: Icons.fact_check,
                  iconInactive: Icons.fact_check_outlined,
                  label: _local('nav_quiz'),
                  isLight: isLight,
                ),
                _buildBottomNavItem(
                  index: 3,
                  iconActive: Icons.article,
                  iconInactive: Icons.article_outlined,
                  label: _local('nav_notes'),
                  isLight: isLight,
                ),
                _buildBottomNavItem(
                  index: 4,
                  iconActive: Icons.person,
                  iconInactive: Icons.person_outline,
                  label: _local('nav_account'),
                  isLight: isLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTab(bool isLight) {
    switch (_currentIndex) {
      case 0:
        return _buildHomeScreenContent(isLight);
      case 1:
        return _buildOfflineScreen(isLight);
      case 2:
        return _buildQuizScreenTab(isLight); // Quiz
      case 3:
        return _buildNotesScreenPlaceholder(isLight); // Notes
      case 4:
        return _buildProfileScreen(isLight); // Account
      default:
        return _buildHomeScreenContent(isLight);
    }
  }

  Widget _buildQuizScreenPlaceholder(bool isLight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_box_outlined, size: 80, color: isLight ? const Color(0xFF0F4C81).withValues(alpha: 0.3) : Colors.white30),
          const SizedBox(height: 16),
          Text(
            widget.languageCode == 'en' ? 'Quiz feature coming soon!' : 'የጥያቄዎች አገልግሎት በቅርቡ ይመጣል!',
            style: TextStyle(fontSize: 16, color: isLight ? const Color(0xFF475569) : Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesScreenPlaceholder(bool isLight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 80, color: isLight ? const Color(0xFF0F4C81).withValues(alpha: 0.3) : Colors.white30),
          const SizedBox(height: 16),
          Text(
            widget.languageCode == 'en' ? 'Notes feature coming soon!' : 'የማስታወሻ አገልግሎት በቅርቡ ይመጣል!',
            style: TextStyle(fontSize: 16, color: isLight ? const Color(0xFF475569) : Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required bool isSelected,
    required bool isLight,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 1.0),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? (isLight ? const Color(0xFFDBEAFE) : const Color(0xFF334155))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
          leading: Icon(
            icon,
            color: isSelected
                ? const Color(0xFF1E88E5)
                : (isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
            size: 20,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF1E88E5)
                  : (isLight ? const Color(0xFF0F172A) : Colors.white),
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w750,
              fontSize: 13.0,
            ),
          ),
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
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

  List<Map<String, dynamic>> _getCoursesData(int grade) {
    if (grade == 9) {
      return [
        {
          'subjectId': 'Biology',
          'enTitle': 'Biology',
          'amTitle': 'ስነ-ህይወት',
          'title': 'Biology',
          'icon': Icons.biotech_rounded,
          'color': const Color(0xFF2E7D32),
          'videosCount': '30+ Videos',
          'notesText': 'Chapter 1-12\nNotes',
          'quizzesCount': '15\nQuizzes',
          'useThumbnail': false,
          'thumbnailUrl': '',
          'playlist': [
            {'title': 'Biology Grade 9 - Unit 1: Introduction to Biology', 'duration': '45:15', 'id': 'coH023k00D8'},
            {'title': 'Biology Grade 9 - Unit 2: Cell Structure & Theory', 'duration': '1:12:40', 'id': '8IlzKkJbWRQ'},
            {'title': 'Biology Grade 9 - Unit 3: Human Anatomy & Tissues', 'duration': '58:20', 'id': 'VSc_v-SUp7c'},
          ],
        },
        {
          'subjectId': 'Biology',
          'enTitle': 'Biology',
          'amTitle': 'ስነ-ህይወት',
          'title': 'Biology',
          'icon': Icons.science_rounded,
          'color': const Color(0xFF2E7D32),
          'videosCount': '30+ Videos',
          'notesText': 'Chapter 1-12\nNotes',
          'quizzesCount': '15\nQuizzes',
          'useThumbnail': true,
          'thumbnailUrl': 'https://images.unsplash.com/photo-1530026405186-ed1ea0ac7a63?w=80',
          'playlist': [
            {'title': 'Biology Grade 9 - Unit 4: Ecosystems & Biomes', 'duration': '48:30', 'id': 'coH023k00D8'},
            {'title': 'Biology Grade 9 - Unit 5: Classification of Plants', 'duration': '1:02:15', 'id': '8IlzKkJbWRQ'},
          ],
        },
        {
          'subjectId': 'Physics',
          'enTitle': 'Physics',
          'amTitle': 'ፊዚክስ',
          'title': 'Physics',
          'icon': Icons.bolt_rounded,
          'color': const Color(0xFFE53935),
          'videosCount': '30+ Videos',
          'notesText': 'Chapter 1-12\nNotes',
          'quizzesCount': '15\nQuizzes',
          'useThumbnail': true,
          'thumbnailUrl': 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=80',
          'playlist': [
            {'title': 'Physics Grade 9 - Unit 1: Vectors & Kinematics', 'duration': '52:10', 'id': 'n_58_qM4zR0'},
            {'title': 'Physics Grade 9 - Unit 2: Two-Dimensional Dynamics', 'duration': '1:18:45', 'id': 'bB71nFpXGic'},
          ],
        },
        {
          'subjectId': 'Mathematics',
          'enTitle': 'Mathematics',
          'amTitle': 'ሂሳብ',
          'title': 'Mathematics',
          'icon': Icons.functions_rounded,
          'color': const Color(0xFF0084FF),
          'videosCount': '30+ Videos',
          'notesText': 'Chapter 1-12\nNotes',
          'quizzesCount': '15\nQuizzes',
          'useThumbnail': true,
          'thumbnailUrl': 'https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?w=80',
          'playlist': [
            {'title': 'Math Grade 9 - Unit 1: Sequence & Series', 'duration': '1:05:30', 'id': '5s2Lcs0Bq78'},
            {'title': 'Math Grade 9 - Unit 2: Quadratic Equations', 'duration': '1:24:12', 'id': 'ySXe7f6G4_g'},
          ],
        }
      ];
    } else if (grade == 10) {
      return [
        {
          'subjectId': 'Biology',
          'enTitle': 'Biology',
          'amTitle': 'ስነ-ህይወት',
          'title': 'Biology',
          'icon': Icons.biotech_rounded,
          'color': const Color(0xFF2E7D32),
          'videosCount': '25+ Videos',
          'notesText': 'Chapter 1-10\nNotes',
          'quizzesCount': '10\nQuizzes',
          'useThumbnail': false,
          'thumbnailUrl': '',
          'playlist': [
            {'title': 'Biology Grade 10 - Unit 1: Genetics & DNA replication', 'duration': '58:15', 'id': 'coH023k00D8'},
          ],
        },
        {
          'subjectId': 'Physics',
          'enTitle': 'Physics',
          'amTitle': 'ፊዚክስ',
          'title': 'Physics',
          'icon': Icons.bolt_rounded,
          'color': const Color(0xFFE53935),
          'videosCount': '28+ Videos',
          'notesText': 'Chapter 1-10\nNotes',
          'quizzesCount': '12\nQuizzes',
          'useThumbnail': true,
          'thumbnailUrl': 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=80',
          'playlist': [
            {'title': 'Physics Grade 10 - Unit 1: Heat & Thermodynamics', 'duration': '48:30', 'id': 'n_58_qM4zR0'},
          ],
        },
        {
          'subjectId': 'Mathematics',
          'enTitle': 'Mathematics',
          'amTitle': 'ሂሳብ',
          'title': 'Mathematics',
          'icon': Icons.functions_rounded,
          'color': const Color(0xFF0084FF),
          'videosCount': '35+ Videos',
          'notesText': 'Chapter 1-12\nNotes',
          'quizzesCount': '18\nQuizzes',
          'useThumbnail': true,
          'thumbnailUrl': 'https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?w=80',
          'playlist': [
            {'title': 'Math Grade 10 - Unit 1: Polynomial Functions', 'duration': '1:10:00', 'id': '5s2Lcs0Bq78'},
          ],
        },
      ];
    } else if (grade == 11) {
      return [
        {
          'subjectId': 'Biology',
          'enTitle': 'Biology',
          'amTitle': 'ስነ-ህይወት',
          'title': 'Biology',
          'icon': Icons.biotech_rounded,
          'color': const Color(0xFF2E7D32),
          'videosCount': '35+ Videos',
          'notesText': 'Chapter 1-12\nNotes',
          'quizzesCount': '18\nQuizzes',
          'useThumbnail': false,
          'thumbnailUrl': '',
          'playlist': [
            {'title': 'Biology Grade 11 - Unit 1: Chemistry of Life', 'duration': '1:15:00', 'id': 'coH023k00D8'},
          ],
        },
        {
          'subjectId': 'Physics',
          'enTitle': 'Physics',
          'amTitle': 'ፊዚክስ',
          'title': 'Physics',
          'icon': Icons.bolt_rounded,
          'color': const Color(0xFFE53935),
          'videosCount': '32+ Videos',
          'notesText': 'Chapter 1-12\nNotes',
          'quizzesCount': '15\nQuizzes',
          'useThumbnail': true,
          'thumbnailUrl': 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=80',
          'playlist': [
            {'title': 'Physics Grade 11 - Unit 1: Vectors & Equilibrium', 'duration': '1:02:10', 'id': 'n_58_qM4zR0'},
          ],
        },
        {
          'subjectId': 'Mathematics',
          'enTitle': 'Mathematics',
          'amTitle': 'ሂሳብ',
          'title': 'Mathematics',
          'icon': Icons.functions_rounded,
          'color': const Color(0xFF0084FF),
          'videosCount': '40+ Videos',
          'notesText': 'Chapter 1-12\nNotes',
          'quizzesCount': '20\nQuizzes',
          'useThumbnail': true,
          'thumbnailUrl': 'https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?w=80',
          'playlist': [
            {'title': 'Math Grade 11 - Unit 1: Relations & Functions', 'duration': '1:04:30', 'id': '5s2Lcs0Bq78'},
          ],
        },
      ];
    } else {
      return [
        {
          'subjectId': 'Biology',
          'enTitle': 'Biology',
          'amTitle': 'ስነ-ህይወት',
          'title': 'Biology',
          'icon': Icons.biotech_rounded,
          'color': const Color(0xFF2E7D32),
          'videosCount': '48+ Videos',
          'notesText': 'Chapter 1-12\nNotes',
          'quizzesCount': '20\nQuizzes',
          'useThumbnail': false,
          'thumbnailUrl': '',
          'playlist': [
            {'title': 'Biology Grade 12 - Unit 1: Microorganisms', 'duration': '1:10:45', 'id': 'coH023k00D8'},
          ],
        },
        {
          'subjectId': 'Physics',
          'enTitle': 'Physics',
          'amTitle': 'ፊዚክስ',
          'title': 'Physics',
          'icon': Icons.bolt_rounded,
          'color': const Color(0xFFE53935),
          'videosCount': '50+ Videos',
          'notesText': 'Chapter 1-12\nNotes',
          'quizzesCount': '20\nQuizzes',
          'useThumbnail': true,
          'thumbnailUrl': 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=80',
          'playlist': [
            {'title': 'Physics Grade 12 - Unit 1: Electromagnetism', 'duration': '1:15:20', 'id': 'n_58_qM4zR0'},
          ],
        },
        {
          'subjectId': 'Mathematics',
          'enTitle': 'Mathematics',
          'amTitle': 'ሂሳብ',
          'title': 'Mathematics',
          'icon': Icons.functions_rounded,
          'color': const Color(0xFF0084FF),
          'videosCount': '55+ Videos',
          'notesText': 'Chapter 1-12\nNotes',
          'quizzesCount': '25\nQuizzes',
          'useThumbnail': true,
          'thumbnailUrl': 'https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?w=80',
          'playlist': [
            {'title': 'Math Grade 12 - Unit 1: Sequences & Series Matric Prep', 'duration': '1:15:30', 'id': 'K_js8HXa8VM'},
          ],
        },
      ];
    }
  }

  void _showVideoPlaylistModal(String courseTitle, List<dynamic> playlist, bool isLight) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$courseTitle Video Lessons',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isLight ? const Color(0xFF0D2353) : Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: playlist.length,
                  itemBuilder: (context, index) {
                    final item = playlist[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D2353),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                        ),
                        title: Text(
                          item['title']!,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isLight ? const Color(0xFF0F172A) : Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          item['duration']!,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isLight ? Colors.black54 : Colors.white70,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerScreen(
                                videoId: item['id']!,
                                title: item['title']!,
                                duration: item['duration']!,
                                isDarkMode: !isLight,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToCourseUnitNotes(Map<String, dynamic> course, bool isLight) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UnitSelectionScreen(
          grade: _selectedGradeForCourses,
          subjectId: course['subjectId'],
          enTitle: course['enTitle'],
          amTitle: course['amTitle'],
          color: course['color'],
          icon: Icon(course['icon'], size: 48, color: Colors.white),
          isDarkMode: !isLight,
          languageCode: widget.languageCode,
          onToggleTheme: widget.onToggleTheme,
          onToggleLanguage: widget.onToggleLanguage,
        ),
      ),
    );
  }

  void _navigateToCourseQuiz(Map<String, dynamic> course) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          grade: _selectedGradeForCourses,
          subject: course['subjectId'].toString().toLowerCase(),
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    return Container(
      width: 28,
      height: 19,
      margin: const EdgeInsets.only(right: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2353),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
        size: 13,
      ),
    );
  }

  Widget _buildThumbnailButton(String imageUrl) {
    return Container(
      width: 28,
      height: 19,
      margin: const EdgeInsets.only(right: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2353),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 13,
            );
          },
        ),
      ),
    );
  }

  Widget _buildOfflineScreen(bool isLight) {
    return FutureBuilder<Set<String>>(
      future: OfflineManager.getDownloadedUnitIds(),
      builder: (context, snapshot) {
        final downloadedIds = snapshot.data ?? {};
        
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 26.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Title
              Text(
                widget.languageCode == 'en' ? 'Offline Study Hub' : 'ከመስመር ውጭ የጥናት ማህደር',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isLight ? const Color(0xFF0F172A) : Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.languageCode == 'en'
                    ? 'Your downloaded lessons, short notes, and practice quizzes are available 100% offline.'
                    : 'ያወረዷቸው አጫጭር ማስታወሻዎች እና ፈተናዎች ያለ በይነመረብ (Offline) እዚህ ይሰራሉ።',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
              
              if (downloadedIds.isEmpty) ...[
                // Beautiful guide card on how to download if empty
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(
                      color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_download_outlined,
                          size: 32,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.languageCode == 'en' ? 'No downloads yet' : 'እስካሁን የወረደ ፋይል የለም',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w950,
                          color: isLight ? const Color(0xFF0F172A) : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.languageCode == 'en'
                            ? 'To access lessons offline, select any Grade on the Home Screen, browse your courses/subjects, open any Unit Explorer, and tap the "Download" button to save files instantly.'
                            : 'የትምህርት ክፍሎችን ያለ በይነመረብ ለማግኘት መነሻ ገጽ ላይ ክፍልዎን ይምረጡ፣ የሚፈልጉትን ትምህርት ከገቡ በኋላ "ያውርዱ" የሚለውን ቁልፍ ይጫኑ።',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // List of downloaded units
                ...downloadedIds.map((id) {
                  final unitInfo = _lookupUnitInfo(id);
                  final String title = widget.languageCode == 'en' ? unitInfo['enUnit'] : unitInfo['amUnit'];
                  final String subject = unitInfo['subject'];
                  final IconData icon = unitInfo['icon'];
                  final Color color = unitInfo['color'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isLight ? Colors.white : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
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
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                icon,
                                color: color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        subject,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w900,
                                          color: color,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF10B981)),
                                            const SizedBox(width: 4),
                                            Text(
                                              widget.languageCode == 'en' ? 'Offline' : 'ከመስመር ውጭ',
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF10B981),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w900,
                                      color: isLight ? const Color(0xFF0F172A) : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () => _showOfflineShortNotesSheet(title, subject, id, isLight),
                                icon: const Icon(Icons.description_rounded, size: 14),
                                label: Text(
                                  widget.languageCode == 'en' ? 'Short Note' : 'ማስታወሻ',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: color,
                                  backgroundColor: color.withOpacity(0.08),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => QuizScreen(grade: 9, subject: subject),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.help_rounded, size: 14),
                                label: Text(
                                  widget.languageCode == 'en' ? 'Take Quiz' : 'ፈተና',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: color,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _confirmDeleteDownload(id, title),
                              icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF4444)),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444).withOpacity(0.08),
                                padding: const EdgeInsets.all(10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showOfflineShortNotesSheet(String unitTitle, String subject, String id, bool isLight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isLight ? Colors.white : const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.languageCode == 'en' ? 'SMART SHORT NOTE' : 'አጭር የጥናት ማስታወሻ',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Text(
                    unitTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isLight ? const Color(0xFF0F172A) : Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    subject,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Container(
                    height: 1,
                    color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    children: [
                      Text(
                        _getShortNotesForUnit(id, subject),
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.6,
                          fontWeight: FontWeight.w600,
                          color: isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteDownload(String id, String unitTitle) {
    showDialog(
      context: context,
      builder: (context) {
        final isLight = !widget.isDarkMode;
        return AlertDialog(
          backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
          title: Text(
            widget.languageCode == 'en' ? 'Delete offline package?' : 'ፓኬጁን ያጥፉ?',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          content: Text(
            widget.languageCode == 'en'
                ? 'Are you sure you want to remove "$unitTitle" from your offline study packages?'
                : '"$unitTitle" የሚለውን አጭር ማስታወሻ እና ፈተና ማጥፋት ይፈልጋሉ?',
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                widget.languageCode == 'en' ? 'Cancel' : 'አይ',
                style: TextStyle(color: isLight ? const Color(0xFF475569) : Colors.white60, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () {
                OfflineManager.removeDownload(id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.languageCode == 'en'
                          ? 'Offline package removed'
                          : 'ከመስመር ውጭ የነበረው ማህደር ተሰርዟል',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(
                widget.languageCode == 'en' ? 'Delete' : 'አጥፋ',
                style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic> _lookupUnitInfo(String id) {
    final Map<String, Map<String, dynamic>> unitsDb = {
      'math_u1': {
        'enUnit': 'Unit 1: The Number System',
        'amUnit': 'ክፍል 1: የቁጥር ስርዓት',
        'subject': 'Mathematics',
        'icon': Icons.functions_rounded,
        'color': const Color(0xFF0084FF),
      },
      'bio_u1': {
        'enUnit': 'Unit 1: Introduction to Biology',
        'amUnit': 'ክፍል 1: ስለ ስነ-ህይወት መግቢያ',
        'subject': 'Biology',
        'icon': Icons.biotech_rounded,
        'color': const Color(0xFF2E7D32),
      },
    };

    if (unitsDb.containsKey(id)) {
      return unitsDb[id]!;
    }

    String subject = "General";
    IconData icon = Icons.offline_pin_rounded;
    Color color = const Color(0xFF8B5CF6);

    if (id.startsWith('math')) {
      subject = "Mathematics";
      icon = Icons.functions_rounded;
      color = const Color(0xFF0084FF);
    } else if (id.startsWith('bio')) {
      subject = "Biology";
      icon = Icons.biotech_rounded;
      color = const Color(0xFF2E7D32);
    } else if (id.startsWith('phys')) {
      subject = "Physics";
      icon = Icons.bolt_rounded;
      color = const Color(0xFFE53935);
    } else if (id.startsWith('chem')) {
      subject = "Chemistry";
      icon = Icons.science_rounded;
      color = const Color(0xFFD81B60);
    } else if (id.startsWith('geo')) {
      subject = "Geography";
      icon = Icons.public_rounded;
      color = const Color(0xFF0F766E);
    } else if (id.startsWith('hist')) {
      subject = "History";
      icon = Icons.account_balance_rounded;
      color = const Color(0xFFCA8A04);
    } else if (id.startsWith('civ')) {
      subject = "Civics";
      icon = Icons.gavel_rounded;
      color = const Color(0xFF475569);
    } else if (id.startsWith('agri')) {
      subject = "Agriculture";
      icon = Icons.agriculture_rounded;
      color = const Color(0xFF15803D);
    }

    String unitNum = "1";
    final match = RegExp(r'u(\d+)').firstMatch(id);
    if (match != null) {
      unitNum = match.group(1) ?? "1";
    }

    return {
      'enUnit': 'Unit $unitNum: Complete Package',
      'amUnit': 'ክፍል $unitNum: አጠቃላይ ፓኬጅ',
      'subject': subject,
      'icon': icon,
      'color': color,
    };
  }

  String _getShortNotesForUnit(String id, String subject) {
    if (id.startsWith('math')) {
      return "• Rational Numbers: Any number that can be expressed as the quotient or fraction p/q of two integers, a numerator p and a non-zero denominator q.\n\n"
          "• Irrational Numbers: Real numbers that cannot be written as simple fractions. E.g., √2, π (pi), and e. They have non-terminating, non-periodic decimal expansions.\n\n"
          "• Arithmetic Progression (AP): A sequence of numbers such that the difference of any two successive members is a constant d. Formula: a_n = a_1 + (n-1)d.\n\n"
          "• Geometric Progression (GP): A sequence where each term after the first is found by multiplying the previous term by a non-zero number called the common ratio r. Formula: a_n = a_1 * r^(n-1).\n\n"
          "• High-Yield Exam Tip: Arithmetic Mean AM = (a+b)/2, Geometric Mean GM = √(ab). AM is always greater than or equal to GM.";
    } else if (id.startsWith('bio')) {
      return "• Biology is the scientific study of life. It covers molecular structures, microscopic cell biology, genetics, anatomy, and global environmental ecology.\n\n"
          "• Microscope Technology: Cellular biology began after Robert Hooke described plant cork cells in 1665 using an early compound microscope.\n\n"
          "• Cell Theory Principles:\n"
          "  1. All living organisms are composed of one or more cells.\n"
          "  2. The cell is the basic structural and functional unit of life.\n"
          "  3. All cells arise from pre-existing cells.\n\n"
          "• Organelles Key Functions:\n"
          "  - Mitochondria: Powerhouse of the cell, generates ATP via cellular respiration.\n"
          "  - Nucleus: Site of genetic information storage (DNA).\n"
          "  - Chloroplasts: Solar panels of plant cells, coordinates photosynthesis processes.\n\n"
          "• Scientific Inquiry: Formulate Hypothesis -> Operational Experiment -> Empirical Data Collection -> Peer-Reviewed Conclusion.";
    } else if (id.startsWith('chem')) {
      return "• Atomic Structure & Quantum Theory: Atoms consist of a heavy, positively charged nucleus surrounded by tiny, negatively charged electrons.\n\n"
          "• Quantum Numbers:\n"
          "  1. Principle (n): Specifies the shell energy level.\n"
          "  2. Angular (l): Codes subshell shape (s, p, d, f).\n"
          "  3. Magnetic (m): Identifies orbital spatial alignment.\n"
          "  4. Spin (s): Defines electron self-rotation (+1/2 or -1/2).\n\n"
          "• Key Atomic Building Rules:\n"
          "  - Aufbau Principle: Orbitals must be filled in order of ascending energy.\n"
          "  - Pauli Exclusion: Two electrons cannot share identical quantum indices.\n"
          "  - Hund's Rule: Orbitals are singly filled before doubling up to minimize Coulombic repulsion.";
    } else if (id.startsWith('phys')) {
      return "• Physical Quantities & Vectors:\n"
          "  - Scalar: Quantity with magnitude only (e.g., speed, mass, energy).\n"
          "  - Vector: Quantity with both magnitude and direction (e.g., velocity, acceleration, force).\n\n"
          "• Vector Addition Methods:\n"
          "  1. Graphical: Head-to-Tail alignment.\n"
          "  2. Analytical Components: Projecting onto Cartesian coordinates (A_x = A*cos(θ), A_y = A*sin(θ)). Sum components to find resultant magnitude R = √(R_x² + R_y²).\n\n"
          "• Units System (SI): 7 base units form the blueprint of all derived physical measurements on Earth.";
    } else {
      return "• General Summary Notes:\n\n"
          "This offline module has been successfully compiled and fully saved directly to your local partition. It contains cheat cards, diagrams index, matric-aligned questions, and high-yield notes.\n\n"
          "• Study Tips:\n"
          "  - Review this page regularly before trying the offline quiz\n"
          "  - Tap 'Quiz' on your offline dashboard to test your knowledge retention\n"
          "  - Active recall and spaced repetition are highly effective for national exams prep.";
    }
  }

  Widget _buildQuizScreenTab(bool isLight) {
    final quizSlides = _getQuizSlidesForGrade(_selectedGradeForQuizTab);
    final currentSlide = quizSlides[_carouselIndex % quizSlides.length];
    final String questionText = currentSlide['question'];
    final List<String> options = currentSlide['options'];
    final int correctIndex = currentSlide['correctIndex'];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 26.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.languageCode == 'en' ? 'National Exam Quizzes' : 'ብሄራዊ የፈተና ጥያቄዎች',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isLight ? const Color(0xFF0F172A) : Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.languageCode == 'en'
                ? 'Select a high school grade below to start official matric-level mock exams.'
                : 'ብሄራዊ የልምምድ ፈተና መፈተን ለመጀመር ከታች የአንዱን ክፍል ካርድ ይጫኑ።',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),

          // Beautiful grade grid cards matching home page design conceptually
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: 1.55,
            children: [
              _buildGradeQuizSelectorCard(9, widget.languageCode == 'en' ? 'Grade 9' : 'ክፍል 9', widget.languageCode == 'en' ? 'Start Journey!' : 'ጉዞዎን ይጀምሩ!', const Color(0xFF0084FF), isLight),
              _buildGradeQuizSelectorCard(10, widget.languageCode == 'en' ? 'Grade 10' : 'ክፍል 10', widget.languageCode == 'en' ? 'Expand knowledge!' : 'እውቀትዎን ያሳድጉ!', const Color(0xFF10B981), isLight),
              _buildGradeQuizSelectorCard(11, widget.languageCode == 'en' ? 'Grade 11' : 'ክፍል 11', widget.languageCode == 'en' ? 'Prepare for excellence!' : 'ለላቀ ውጤት ይዘጋጁ!', const Color(0xFFF59E0B), isLight),
              _buildGradeQuizSelectorCard(12, widget.languageCode == 'en' ? 'Grade 12' : 'ክፍል 12', widget.languageCode == 'en' ? 'Achieve goals!' : 'ግብዎን ያሳኩ!', const Color(0xFF8B5CF6), isLight),
            ],
          ),

          const SizedBox(height: 32),

          // PREVIEW MODE section styled exactly like reference image
          Row(
            children: [
              Icon(Icons.style_rounded, size: 18, color: isLight ? const Color(0xFF0F172A) : Colors.white),
              const SizedBox(width: 8),
              Text(
                widget.languageCode == 'en' ? 'Interactive Preview' : 'በይነተገናኝ ማሳያ',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                  color: isLight ? const Color(0xFF0F172A) : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Inner Card mimicking exactly the user's reference image
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                  decoration: BoxDecoration(
                    color: isLight ? Colors.white : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header PREVIEW MODE + Glowing Green Dot
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PREVIEW MODE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.8,
                            ),
                          ),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Question text
                      Text(
                        questionText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 1.3,
                          color: isLight ? const Color(0xFF0F172A) : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Options list with Addis Ababa / correct green check highlight
                      ...List.generate(options.length, (idx) {
                        final bool isCorrectHighlight = idx == correctIndex;
                        final String optionValue = options[idx];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isCorrectHighlight
                                ? (isLight ? const Color(0xFFEFF6FF) : const Color(0xFF1E3A8A).withOpacity(0.3))
                                : (isLight ? Colors.white : const Color(0xFF1E293B)),
                            border: Border.all(
                              color: isCorrectHighlight
                                  ? const Color(0xFF1E88E5)
                                  : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                              width: isCorrectHighlight ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                optionValue,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: isCorrectHighlight
                                      ? const Color(0xFF1E88E5)
                                      : (isLight ? const Color(0xFF475569) : Colors.white70),
                                ),
                              ),
                              if (isCorrectHighlight)
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 11,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Slideshow Carousel controls (Next, Prev)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _carouselIndex = (_carouselIndex - 1 + quizSlides.length) % quizSlides.length;
                        });
                      },
                      icon: Icon(Icons.arrow_back_rounded, color: isLight ? const Color(0xFF475569) : Colors.white70),
                      style: IconButton.styleFrom(
                        backgroundColor: isLight ? Colors.white : const Color(0xFF0F172A),
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Row(
                      children: List.generate(quizSlides.length, (dotIdx) {
                        final bool isCurrent = dotIdx == (_carouselIndex % quizSlides.length);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isCurrent ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isCurrent ? const Color(0xFF1E88E5) : const Color(0xFF94A3B8).withOpacity(0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 14),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _carouselIndex = (_carouselIndex + 1) % quizSlides.length;
                        });
                      },
                      icon: Icon(Icons.arrow_forward_rounded, color: isLight ? const Color(0xFF475569) : Colors.white70),
                      style: IconButton.styleFrom(
                        backgroundColor: isLight ? Colors.white : const Color(0xFF0F172A),
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          // Giant action button to trigger comprehensive exam screen
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizScreen(
                      grade: _selectedGradeForQuizTab,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_circle_filled_rounded, size: 18),
              label: Text(
                widget.languageCode == 'en'
                    ? 'Start Grade $_selectedGradeForQuizTab Practice Exam'
                    : 'የክፍል $_selectedGradeForQuizTab የልምምድ ፈተና ጀምር',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w955),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _selectedGradeForQuizTab == 9
                    ? const Color(0xFF0084FF)
                    : (_selectedGradeForQuizTab == 10
                        ? const Color(0xFF10B981)
                        : (_selectedGradeForQuizTab == 11
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF8B5CF6))),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeQuizSelectorCard(int gradeNum, String title, String subtitle, Color btnColor, bool isLight) {
    bool isSelected = _selectedGradeForQuizTab == gradeNum;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGradeForQuizTab = gradeNum;
          _carouselIndex = 0;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isSelected ? btnColor : (isLight ? Colors.white : const Color(0xFF1E293B)),
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(
            color: isSelected ? btnColor : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? btnColor.withOpacity(0.2) : Colors.black.withOpacity(0.01),
              blurRadius: 8.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school,
                  size: 16,
                  color: isSelected ? Colors.white : btnColor,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w950,
                    color: isSelected ? Colors.white : (isLight ? const Color(0xFF0F172A) : Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white.withOpacity(0.8) : (isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getQuizSlidesForGrade(int grade) {
    if (grade == 9) {
      return [
        {
          'question': 'What is the capital city of Ethiopia?',
          'options': ['A) Nairobi', 'B) Addis Ababa', 'C) Asmara'],
          'correctIndex': 1,
        },
        {
          'question': 'Which branch of Biology studies the feedback cycles of organisms and biosphere?',
          'options': ['A) Genetics', 'B) Zoology', 'C) Ecology'],
          'correctIndex': 2,
        },
        {
          'question': 'Calculate the slope value of y = 3x + 12.',
          'options': ['A) m = 1', 'B) m = 3', 'C) m = 12'],
          'correctIndex': 1,
        },
      ];
    } else if (grade == 10) {
      return [
        {
          'question': 'Which biological macromolecule builds plant cell walls?',
          'options': ['A) Cellulose', 'B) Glycogen', 'C) Peptide-glycans'],
          'correctIndex': 0,
        },
        {
          'question': 'Find the root solution set of x² - 16 = 0.',
          'options': ['A) {4}', 'B) {-4, 4}', 'C) {16}'],
          'correctIndex': 1,
        },
      ];
    } else if (grade == 11) {
      return [
        {
          'question': 'What is the magnitude of a vector with components (6, 8)?',
          'options': ['A) 10 units', 'B) 14 units', 'C) 100 units'],
          'correctIndex': 0,
        },
        {
          'question': 'Which model proposed electrons travel in stationary quantic orbits?',
          'options': ['A) Bohr Model', 'B) Dalton Model', 'C) Rutherford Model'],
          'correctIndex': 0,
        },
      ];
    } else {
      return [
        {
          'question': 'What is the limit of (3x² - 2x) / x as x approaches 0?',
          'options': ['A) 0', 'B) -2', 'C) ∞'],
          'correctIndex': 1,
        },
        {
          'question': 'In which historic year did the victory of Battle of Adwa transpire?',
          'options': ['A) 1889', 'B) 1896', 'C) 1935'],
          'correctIndex': 1,
        },
      ];
    }
  }

  Widget _buildCoursesScreen(bool isLight) {
    final List<Map<String, dynamic>> courses = _getCoursesData(_selectedGradeForCourses);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 26.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.languageCode == 'en' ? 'Grade' : 'ክፍል',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isLight ? const Color(0xFF0F172A) : Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [9, 10, 11, 12].map((int gradeNum) {
                final bool isSelected = _selectedGradeForCourses == gradeNum;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGradeForCourses = gradeNum;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1E88E5)
                          : (isLight ? Colors.white : const Color(0xFF1E293B)),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              width: 1.2,
                            ),
                    ),
                        child: Text(
                          widget.languageCode == 'en' ? 'Grade $gradeNum' : 'ክፍል $gradeNum',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isLight ? const Color(0xFF0F172A) : Colors.white),
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24.0),
              ...courses.map((course) {
                final List<Widget> placeholders = [
                  _buildPlayButton(),
                  _buildPlayButton(),
                  course['useThumbnail'] == true
                      ? _buildThumbnailButton(course['thumbnailUrl'])
                      : _buildPlayButton(),
                ];

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  decoration: BoxDecoration(
                    color: isLight ? Colors.white : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(
                      color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isLight ? const Color(0xFFDBEAFE) : const Color(0xFF1E3A8A),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              course['icon'],
                              color: isLight ? const Color(0xFF1E3A8A) : Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            course['title'],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isLight ? const Color(0xFF0F172A) : Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        child: Container(
                          height: 0.8,
                          color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                        ),
                      ),
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: InkWell(
                                onTap: () => _showVideoPlaylistModal(course['title'], course['playlist'], isLight),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.languageCode == 'en' ? 'Video Lessons' : 'የቪዲዮ ትምህርት',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: placeholders,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      course['videosCount'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isLight ? const Color(0xFF0D2353) : const Color(0xFF38BDF8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: 0.8,
                              color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                            Expanded(
                              flex: 3,
                              child: InkWell(
                                onTap: () => _navigateToCourseUnitNotes(course, isLight),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.languageCode == 'en' ? 'Short Notes' : 'አጫጭር ማስታወሻ',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.description_rounded,
                                          color: isLight ? const Color(0xFF0D2353) : const Color(0xFF38BDF8),
                                          size: 22,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            course['notesText'],
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              color: isLight ? const Color(0xFF1E293B) : Colors.white,
                                              height: 1.15,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: 0.8,
                              color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                            Expanded(
                              flex: 3,
                              child: InkWell(
                                onTap: () => _navigateToCourseQuiz(course),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.languageCode == 'en' ? 'Quiz' : 'ፈተና',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.help_rounded,
                                          color: isLight ? const Color(0xFF0D2353) : const Color(0xFF38BDF8),
                                          size: 22,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            course['quizzesCount'],
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              color: isLight ? const Color(0xFF1E293B) : Colors.white,
                                              height: 1.15,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
              }).toList(),
            ],
          ),
        );
  }

  Future<void> _handleProfileFormSave() async {
    setState(() {
      _isProfileLoading = true;
    });

    final String fullName = _fullNameController.text.trim();
    final String email = _emailController.text.trim();
    final String schoolName = _schoolNameController.text.trim();
    final String phone = _phoneController.text.trim();
    final String password = _passwordController.text.trim();
    final int ageVal = int.tryParse(_ageController.text.trim()) ?? 17;
    final String fullPhoneWithCountry = '$_selectedCountryCode $phone';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_fullName', fullName);
    await prefs.setString('user_email', email);
    await prefs.setString('user_phoneNumber', fullPhoneWithCountry);
    await prefs.setString('user_schoolName', schoolName);
    await prefs.setString('user_grade', 'Grade $_selectedGrade');
    await prefs.setString('user_sex', _selectedSex);
    await prefs.setInt('user_age', ageVal);
    await prefs.setString('user_password', password);

    setState(() {
      _userName = fullName;
      _userGradeStr = "Grade $_selectedGrade Student";
      _userSchoolName = schoolName;
      _userPhoneNumber = fullPhoneWithCountry;
      _userEmail = email;
      _isProfileLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.languageCode == 'en'
                ? "Profile details updated successfully! Welcome to Smart X!"
                : "የመገለጫ መረጃዎ በስኬት ተስተካክሏል! ወደ ስማርት ኤክስ እንኳን ደህና መጡ!",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF0D2353),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _buildFieldContainer({required Widget child, required bool isDark}) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 2.0, bottom: 4.0, top: 4.0),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0B1E40),
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(bool isLight) {
    final bool isDark = !isLight;
    final TextEditingController emailResetController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
          backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDBEAFE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.key_rounded,
                        color: Color(0xFF1E88E5),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.languageCode == 'en' ? 'Reset Password' : 'የይለፍ ቃል መቀየር',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isLight ? const Color(0xFF0F172A) : Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.languageCode == 'en'
                      ? 'Enter your registered email address or phone number to receive a secure recovery code.'
                      : 'የይለፍ ቃልዎን መልሰው ለማግኘት የተመዘገቡበትን ኢሜል ወይም ስልክ ቁጥር ያስገቡ።',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: isLight ? const Color(0xFF475569) : Colors.white70,
                  ),
                ),
                const SizedBox(height: 18),
                _buildLabel(widget.languageCode == 'en' ? 'Email or Phone Number' : 'ኢሜል ወይም ስልክ ቁጥር', isDark),
                _buildFieldContainer(
                  isDark: isDark,
                  child: TextFormField(
                    controller: emailResetController,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: widget.languageCode == 'en' ? 'e.g. email@domain.com' : 'ምሳሌ፡ email@domain.com',
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14.0,
                        fontWeight: FontWeight.normal,
                      ),
                      prefixIcon: Icon(
                        Icons.email,
                        color: isDark ? Colors.white70 : const Color(0xFF0D2353),
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        widget.languageCode == 'en' ? 'Cancel' : 'አትርሳ',
                        style: TextStyle(
                          color: isLight ? const Color(0xFF64748B) : Colors.white60,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final input = emailResetController.text.trim();
                        if (input.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                widget.languageCode == 'en' ? 'Please enter your email or phone!' : 'እባክዎን ኢሜል ወይም ስልክ ያስገቡ!',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              widget.languageCode == 'en'
                                  ? 'Recovery instructions sent successfully to $input!'
                                  : 'የይለፍ ቃል ማግኛ መመሪያ ወደ $input በስኬት ተልኳል!',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: const Color(0xFF1E88E5),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        widget.languageCode == 'en' ? 'Send Code' : 'ኮድ ላክ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLoginSave() async {
    setState(() {
      _isProfileLoading = true;
    });

    final String userInput = _emailController.text.trim();
    final String passwordInput = _passwordController.text.trim();

    // Small delay to simulate authenticating
    await Future.delayed(const Duration(milliseconds: 1000));

    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('user_email') ?? "abebe@smartx.com";
    final savedPhone = prefs.getString('user_phoneNumber') ?? "+251 911 234 567";
    final savedPassword = prefs.getString('user_password') ?? "password";

    bool loginSuccess = false;
    if (userInput.isNotEmpty && passwordInput.isNotEmpty) {
      if ((userInput.toLowerCase() == savedEmail.toLowerCase() || 
           userInput == savedPhone || 
           userInput.replaceAll(' ', '') == savedPhone.replaceAll(' ', '') ||
           userInput == '0911234567' ||
           userInput == '911234567') && 
          (passwordInput == savedPassword || passwordInput == 'password')) {
        loginSuccess = true;
      } else {
        // Fallback or developers master bypass
        if (passwordInput == 'password' || passwordInput == savedPassword) {
          loginSuccess = true;
        }
      }
    }

    setState(() {
      _isProfileLoading = false;
    });

    if (loginSuccess) {
      await _loadProfileData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.languageCode == 'en'
                  ? "Logged in successfully! Welcome back, $_userName!"
                  : "በስኬት ገብተዋል! እንኳን ደህና መጡ $_userName!",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF1E88E5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() {
          _currentIndex = 0; // Go back to Home screen
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.languageCode == 'en'
                  ? "Invalid email/phone or password. (Hint: Use abebe@smartx.com and password)"
                  : "የተሳሳተ ኢሜል/ስልክ ወይም የይለፍ ቃል ያስገቡ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Widget _buildLoginForm(bool isLight, bool isDark, Color navyColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFDBEAFE) : const Color(0xFF1E293B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  size: 36,
                  color: Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.languageCode == 'en' ? 'Welcome Back!' : 'እንኳን በደህና መጡ!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isLight ? const Color(0xFF0F172A) : Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.languageCode == 'en'
                    ? 'Log in to continue your learning journey'
                    : 'ለመቀጠል እባክዎን መለያዎን ያስገቡ',
                style: TextStyle(
                  fontSize: 12,
                  color: isLight ? const Color(0xFF64748B) : Colors.white70,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Email or Phone input
        _buildLabel(widget.languageCode == 'en' ? 'Email Address or Phone Number' : 'የኢሜል አድራሻ ወይም ስልክ ቁጥር', isDark),
        _buildFieldContainer(
          isDark: isDark,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              setState(() {});
            },
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.languageCode == 'en' ? 'e.g. abebe@smartx.com or phone' : 'ምሳሌ: abebe@smartx.com ወይም ስልክ ቁጥር',
              hintStyle: const TextStyle(
                color: Colors.grey,
                fontSize: 14.0,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Icon(
                Icons.person_outline,
                color: isDark ? Colors.white70 : navyColor,
                size: 20,
              ),
              suffixIcon: _emailController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _emailController.clear();
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Password input row with Forgot Password Link
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel(widget.languageCode == 'en' ? 'Password' : 'የይለፍ ቃል', isDark),
            GestureDetector(
              onTap: () => _showForgotPasswordDialog(isLight),
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0, right: 2.0),
                child: Text(
                  widget.languageCode == 'en' ? 'Forgot Password?' : 'የይለፍ ቃል ጠፋብዎት?',
                  style: const TextStyle(
                    color: Color(0xFF1E88E5),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
        _buildFieldContainer(
          isDark: isDark,
          child: TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: (value) {
              setState(() {});
            },
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.languageCode == 'en' ? 'Enter security password' : 'የይለፍ ቃልዎን ያስገቡ',
              hintStyle: const TextStyle(
                color: Colors.grey,
                fontSize: 14.0,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: isDark ? Colors.white70 : navyColor,
                size: 20,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_passwordController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _passwordController.clear();
                        });
                      },
                    ),
                  IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Log In submit Button
        _isProfileLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0D2353),
                ),
              )
            : Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E88E5).withOpacity(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: _handleLoginSave,
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    widget.languageCode == 'en' ? 'Log In' : 'ይግቡ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 12),

        // Sign Up Switcher Footer
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isLoginForm = false;
              });
            },
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: widget.languageCode == 'en' ? "Don't have an account? " : 'መለያ የለዎትም? ',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: widget.languageCode == 'en' ? 'Register Now' : 'አሁን ይመዝገቡ',
                    style: const TextStyle(
                      color: Color(0xFF1E88E5),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm(bool isLight, bool isDark, Color navyColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFDBEAFE) : const Color(0xFF1E293B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 36,
                  color: Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.languageCode == 'en' ? 'Create Account' : 'መለያ ይፍጠሩ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isLight ? const Color(0xFF0F172A) : Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.languageCode == 'en'
                    ? 'Join Smart X Academy and boost your grades'
                    : 'ስማርት ኤክስ አካዳሚ በመቀላቀል ውጤትዎን ያሻሽሉ',
                style: TextStyle(
                  fontSize: 12,
                  color: isLight ? const Color(0xFF64748B) : Colors.white70,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 1. Full Name
        _buildLabel(widget.languageCode == 'en' ? 'Full Name' : 'ሙሉ ስም', isDark),
        _buildFieldContainer(
          isDark: isDark,
          child: TextFormField(
            controller: _fullNameController,
            onChanged: (value) {
              setState(() {});
            },
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.languageCode == 'en' ? 'e.g. Abebe Bekele' : 'ምሳሌ: አበበ በቀለ',
              hintStyle: const TextStyle(
                color: Colors.grey,
                fontSize: 14.0,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Icon(
                Icons.person_outline,
                color: isDark ? Colors.white70 : navyColor,
                size: 20,
              ),
              suffixIcon: _fullNameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _fullNameController.clear();
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 4),

        // 2. Email Address
        _buildLabel(widget.languageCode == 'en' ? 'Email Address' : 'የኢሜል አድራሻ', isDark),
        _buildFieldContainer(
          isDark: isDark,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              setState(() {});
            },
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.languageCode == 'en' ? 'e.g. abebe@smartx.com' : 'ምሳሌ: abebe@smartx.com',
              hintStyle: const TextStyle(
                color: Colors.grey,
                fontSize: 14.0,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: isDark ? Colors.white70 : navyColor,
                size: 20,
              ),
              suffixIcon: _emailController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _emailController.clear();
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 4),

        // 3. Grade Level dropdown selector
        _buildLabel(widget.languageCode == 'en' ? 'Grade Level' : 'የክፍል ደረጃ', isDark),
        _buildFieldContainer(
          isDark: isDark,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedGrade,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white70 : navyColor, size: 28),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
              ),
              items: [9, 10, 11, 12, 13].map((int val) {
                return DropdownMenuItem<int>(
                  value: val == 13 ? 12 : val,
                  child: Text(
                    val == 13 
                        ? (widget.languageCode == 'en' ? 'Select Grade' : 'ክፍል ይምረጡ') 
                        : (widget.languageCode == 'en' ? 'Grade $val' : 'ክፍል $val'),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedGrade = val;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 4),

        // 4. School Name
        _buildLabel(widget.languageCode == 'en' ? 'School Name' : 'የትምህርት ቤት ስም', isDark),
        _buildFieldContainer(
          isDark: isDark,
          child: TextFormField(
            controller: _schoolNameController,
            onChanged: (value) {
              setState(() {});
            },
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.languageCode == 'en' ? 'e.g. Yeka Secondary School' : 'ምሳሌ: የካ ማናቸውም ሁለተኛ ደረጃ ትምህርት ቤት',
              hintStyle: const TextStyle(
                color: Colors.grey,
                fontSize: 14.0,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Icon(
                Icons.apartment_outlined,
                color: isDark ? Colors.white70 : navyColor,
                size: 20,
              ),
              suffixIcon: _schoolNameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _schoolNameController.clear();
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 4),

        // 5. Age input with icons on both sides
        _buildLabel(widget.languageCode == 'en' ? 'Age' : 'እድሜ', isDark),
        _buildFieldContainer(
          isDark: isDark,
          child: Row(
            children: [
              Icon(Icons.calendar_month_outlined, color: isDark ? Colors.white70 : navyColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {});
                  },
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: widget.languageCode == 'en' ? 'Enter age (e.g. 17)' : 'እድሜዎን ያስገቡ (ለምሳሌ 17)',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14.0,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
              if (_ageController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _ageController.clear();
                    });
                  },
                ),
              Icon(Icons.calendar_month, color: isDark ? Colors.white70 : navyColor, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // 6. Sex (Gender) selector row
        Row(
          children: [
            Text(
              widget.languageCode == 'en' ? 'Sex (Gender)' : 'ጾታ',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0B1E40),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            // Male selector
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSex = 'Male';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedSex == 'Male'
                      ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedSex == 'Male'
                        ? (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E2))
                        : Colors.transparent,
                    width: _selectedSex == 'Male' ? 1.2 : 0,
                  ),
                  boxShadow: _selectedSex == 'Male'
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedSex == 'Male' ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isDark ? Colors.white70 : navyColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.languageCode == 'en' ? 'Male' : 'ወንድ',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Female selector
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSex = 'Female';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedSex == 'Female'
                      ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedSex == 'Female'
                        ? (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E2))
                        : Colors.transparent,
                    width: _selectedSex == 'Female' ? 1.2 : 0,
                  ),
                  boxShadow: _selectedSex == 'Female'
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedSex == 'Female' ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isDark ? Colors.white70 : navyColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.languageCode == 'en' ? 'Female' : 'ሴት',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // 7. Phone Number Input with Ethiopian Country Selector representation
        _buildLabel(widget.languageCode == 'en' ? 'Phone Number' : 'ስልክ ቁጥር', isDark),
        _buildFieldContainer(
          isDark: isDark,
          child: Row(
            children: [
              const Text(
                '🇪🇹',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 6),
              Text(
                'Et...',
                style: TextStyle(
                  color: isDark ? Colors.white70 : navyColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: isDark ? Colors.white70 : navyColor,
              ),
              const SizedBox(width: 6),
              Container(
                width: 1.2,
                height: 22,
                color: Colors.grey[300],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  onChanged: (value) {
                    setState(() {});
                  },
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: widget.languageCode == 'en' ? 'e.g. 911234567' : 'ምሳሌ: 911234567',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14.0,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
              if (_phoneController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _phoneController.clear();
                    });
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // 8. Password Input
        _buildLabel(widget.languageCode == 'en' ? 'Password' : 'የይለፍ ቃል', isDark),
        _buildFieldContainer(
          isDark: isDark,
          child: TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: (value) {
              setState(() {});
            },
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.languageCode == 'en' ? 'Create security password' : 'ደህንነቱ የተጠበቀ የይለፍ ቃል ያስገቡ',
              hintStyle: const TextStyle(
                color: Colors.grey,
                fontSize: 14.0,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: isDark ? Colors.white70 : navyColor,
                size: 20,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_passwordController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _passwordController.clear();
                        });
                      },
                    ),
                  IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 9. Register submit Button
        _isProfileLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0D2353),
                ),
              )
            : Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E88E5).withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: _handleProfileFormSave,
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    widget.languageCode == 'en' ? 'Register' : 'ይመዝገቡ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 18),

        // Footer Switch Button
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isLoginForm = true;
              });
            },
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: widget.languageCode == 'en' ? 'Already have an account? ' : 'ቀድሞውኑ መለያ አለዎት? ',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: widget.languageCode == 'en' ? 'Log In' : 'ይግቡ',
                    style: const TextStyle(
                      color: Color(0xFF1E88E5),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Terms of Service indicator
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: widget.languageCode == 'en' ? 'By registering, you agree to our ' : 'በመመዝገብዎ፣ በሚከተሉት ደንቦች ይስማማሉ ',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: widget.languageCode == 'en' ? 'Terms of Service' : 'ግልጋሎት ደንቦች',
                  style: const TextStyle(
                    color: Color(0xFF1E88E5),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileScreen(bool isLight) {
    final bool isDark = !isLight;
    final Color navyColor = const Color(0xFF0D2353);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Form(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: isLight ? Colors.white.withOpacity(0.92) : const Color(0xFF1E293B).withOpacity(0.95),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _isLoginForm
              ? _buildLoginForm(isLight, isDark, navyColor)
              : _buildRegisterForm(isLight, isDark, navyColor),
        ),
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
    bool isDark = !isLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFE0F2FE) : const Color(0xFF0F172A),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.celebration_rounded,
                size: 72,
                color: isLight ? const Color(0xFF0284C7) : const Color(0xFF38BDF8),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              widget.languageCode == 'en' ? 'What\'s New' : 'አዳዲስ ነገሮች',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: isLight ? const Color(0xFF0F172A) : Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.languageCode == 'en' 
                  ? 'Check back soon for new features, upcoming lessons, and exciting announcements!'
                  : 'ለአዳዲስ አገልግሎቶች፣ ለሚቀጥሉት ትምህርቶች እና ለሚያስደስቱ ማስታወቂያዎች በቅርቡ ተመልሰው ይምጡ!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isLight ? const Color(0xFF475569) : Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentIndex = 0; // Go to home
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Text(
                widget.languageCode == 'en' ? 'Go to Home' : 'ወደ መነሻ ተመለስ',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreItem({
    required IconData leadingIcon,
    required String title,
    required bool isLight,
    bool isDestructive = false,
    bool showChevron = true,
    Widget? expandedContent,
    VoidCallback? onTap,
  }) {
    final Color textColor = isDestructive
        ? const Color(0xFF991B1B)
        : (isLight ? const Color(0xFF0F172A) : Colors.white);

    final Color iconColor = isDestructive
        ? const Color(0xFF991B1B)
        : (isLight ? const Color(0xFF0D2353) : const Color(0xFF0284C7));

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 4.0),
            child: Row(
              children: [
                Icon(
                  leadingIcon,
                  color: iconColor,
                  size: 24,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
                if (showChevron)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isLight ? const Color(0xFF0D2353) : const Color(0xFF64748B),
                    size: 26,
                  ),
              ],
            ),
          ),
        ),
        if (expandedContent != null) expandedContent,
        Divider(
          height: 1,
          thickness: 1,
          color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
        ),
      ],
    );
  }

  void _showSavedLessonsModal(bool isLight) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bookmark_border_rounded, size: 52, color: isLight ? const Color(0xFF0D2353) : Colors.white),
              const SizedBox(height: 14),
              Text(
                widget.languageCode == 'en' ? 'Saved Lessons' : 'የተቀመጡ ትምህርቶች',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isLight ? const Color(0xFF0D2353) : Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                widget.languageCode == 'en'
                    ? 'No bookmarks are saved yet. You can bookmark any lesson while practicing or watching lectures to find them instantly here!'
                    : 'ምንም የተቀመጡ ትምህርቶች የሉም። ዋና ክፍሎች ላይ በሚለማመዱበት ወይም ቪዲዮዎችን በሚያዩበት ጊዜ ትምህርቶችን እዚህ ማስቀመጥ ይችላሉ!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, height: 1.4, color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showStudyProgressModal(bool isLight) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flash_on, size: 48, color: Colors.amber[700]),
              const SizedBox(height: 12),
              Text(
                widget.languageCode == 'en' ? 'Your Study Progress' : 'የጥናት ማሻሻያ መረጃዎ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isLight ? const Color(0xFF0D2353) : Colors.white),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildProgressItem("Streak", "15 Days", Icons.local_fire_department, Colors.orange),
                  _buildProgressItem("Completed", "18 Lessons", Icons.check_circle, Colors.green),
                  _buildProgressItem("Avg Score", "94%", Icons.leaderboard, Colors.purple),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 36),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showSubscriptionModal(bool isLight) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Icon(Icons.stars, size: 48, color: Colors.amber[700]),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: Text(
                  widget.languageCode == 'en' ? 'Subscription & Billing' : 'ምዝገባ እና ክፍያ መረጃ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isLight ? const Color(0xFF0D2353) : Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("ACTIVE SMART X PRO VIP STUDENT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF78350F))),
                    const SizedBox(height: 4),
                    Text(
                      widget.languageCode == 'en' 
                          ? "Full syllabus courses, cheat cards, explanations and unlimited mock national matric exam portal unlocked entirely."
                          : "ሙሉ የቪዲዮ ኮርሶች፣ ማጠቃለያዎች፣ የአጭር ጊዜ የጥናት መረጃዎች ሙሉ በሙሉ ተከፍተዋል።",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationsModal(bool isLight) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none_rounded, size: 48, color: isLight ? const Color(0xFF0D2353) : Colors.white),
              const SizedBox(height: 12),
              Text(
                widget.languageCode == 'en' ? 'Notifications' : 'ማሳወቂያዎች',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isLight ? const Color(0xFF0D2353) : Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                widget.languageCode == 'en'
                    ? 'No new announcements are available at this time. Stay tuned for class reminders and updates!'
                    : 'በአሁኑ ጊዜ ምንም አዳዲስ ማሳወቂያዎች የሉም። ለተጨማሪ መረጃዎች ተከታተሉ!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showHelpSupportModal(bool isLight) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.contact_support_outlined, size: 48, color: isLight ? const Color(0xFF0D2353) : Colors.white),
              const SizedBox(height: 12),
              Text(
                widget.languageCode == 'en' ? 'Help & Support' : 'የእርዳታ መስመር እና ድጋፍ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isLight ? const Color(0xFF0D2353) : Colors.white),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.phone_iphone_rounded, color: Colors.green),
                title: const Text("WhatsApp Helpline", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("+251 911 234 567", style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.telegram_rounded, color: Colors.blue),
                title: const Text("Telegram Support", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("@smartx_support", style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.mail_outline_rounded, color: Colors.red),
                title: const Text("Support Email", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("support@smartxacademy.com", style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {},
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData iconActive,
    required IconData iconInactive,
    required String label,
    required bool isLight,
  }) {
    final bool isSelected = _currentIndex == index;
    final Color activeColor = const Color(0xFF0C4673); // Dark navy blue as in reference
    final Color inactiveColor = isLight ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF); // Gray color
    
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Container(
          color: Colors.transparent,
          height: 64.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 3.0,
                width: 44.0,
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : Colors.transparent,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(3),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? iconActive : iconInactive,
                      color: isSelected ? activeColor : inactiveColor,
                      size: 26,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? activeColor : inactiveColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4), // small bottom padding
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isLight = !widget.isDarkMode;
        return AlertDialog(
          backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            widget.languageCode == 'en' ? 'Coming Soon' : 'በቅርቡ የሚመጣ',
            style: TextStyle(
              color: isLight ? const Color(0xFF0F172A) : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            widget.languageCode == 'en'
                ? 'This feature is currently under development.'
                : 'ይህ አገልግሎት በአሁኑ ጊዜ በልማት ላይ ነው።',
            style: TextStyle(
              color: isLight ? const Color(0xFF475569) : Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                widget.languageCode == 'en' ? 'Close' : 'ዝጋ',
                style: const TextStyle(
                  color: Color(0xFF1E88E5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAboutAppModal(bool isLight) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline_rounded, size: 48, color: isLight ? const Color(0xFF0D2353) : Colors.white),
              const SizedBox(height: 12),
              Text(
                'Smart X Academy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isLight ? const Color(0xFF0D2353) : Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.languageCode == 'en'
                    ? 'Version: 1.0.0+1 (Stable Build)\n\nAn advanced e-learning platform specifically crafted for Grade 9 to 12 Ethiopian high school students to access summaries, matric practice exams, interactive digital cheat-cards, and video walkthrough lessons.'
                    : 'ስሪት: 1.0.0+1 (የተረጋጋ)\n\nለ9-12ኛ ክፍል ኢትዮጵያዊያን ተማሪዎች የተዘጋጀ የቪዲዮ ትምህርቶች፣ ማጠቃለያዎች፣ የአጭር ጊዜ የጥናት መረጃዎች ሙሉ በሙሉ ተከፍተዋል።',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                  color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showTermsOfServiceModal(bool isLight) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_turned_in_outlined, size: 48, color: isLight ? const Color(0xFF0D2353) : Colors.white),
              const SizedBox(height: 12),
              Text(
                widget.languageCode == 'en' ? 'Terms of Service' : 'የአገልግሎት ውሎች',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isLight ? const Color(0xFF0D2353) : Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                widget.languageCode == 'en'
                    ? 'By using the Smart X Academy app, you agree to access our educational content for personal learning purposes only. Content cloning, commercial redistribution, or reproduction of summaries, matric cheat cards, and video content is strictly prohibited.'
                    : 'ስማርት ኤክስ አካዳሚ መተግበሪያን ሲጠቀሙ፤ የተዘጋጁ የትምህርት ማጠቃለያዎችን፣ የፈተና ጥያቄዎችን እና የቪዲዮ ማስረዳቶችን ለግል ዕውቀትዎ ብቻ ለመጠቀም ይስማማሉ። ይዘቶችን ማባዛት ወይም ለሌላ ማስተላለፍ በጥብቅ የተከለከለ ነው።',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, height: 1.4, color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showPrivacyPolicyModal(bool isLight) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.security, size: 48, color: isLight ? const Color(0xFF0D2353) : Colors.white),
              const SizedBox(height: 12),
              Text(
                widget.languageCode == 'en' ? 'User Privacy Policy' : 'የተጠቃሚ የግል መረጃ አጠባበቅ ህግ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isLight ? const Color(0xFF0D2353) : Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                widget.languageCode == 'en'
                    ? 'Smart X Academy values your data privacy. All lesson progress, test scores, bookmarks, and user profile credentials remain securely saved on your device local cache database storage (SharedPreferences) and are never shared with external advertisers.'
                    : 'ስማርት ኤክስ አካዳሚ የእርስዎን ደህንነት እና የግል መረጃዎች ይጠብቃል። ሁሉም የጥናት ሂደቶችዎ፣ መለያዎና ያገኟቸው ውጤቶች በመሳሪያዎ ላይ ብቻ ደህንነቱ በተጠበቀ ሁኔታ ይቀመጣሉ።',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, height: 1.4, color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showLogOutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final bool isLight = Theme.of(context).brightness == Brightness.light;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
          title: Text(
            widget.languageCode == 'en' ? 'Log Out' : 'መለያ ውጣ',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            widget.languageCode == 'en' 
                ? 'Are you sure you want to log out of your Smart X Academy student profile? Your local study stats will remain saved.'
                : 'ከስማርት ኤክስ መለያዎ መውጣት እርግጠኛ ነዎት? የዚህ መሣሪያ የጥናት ሂደትዎ አይጠፋም።',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                widget.languageCode == 'en' ? 'Cancel' : 'ሰርዝ',
                style: TextStyle(fontWeight: FontWeight.bold, color: isLight ? Colors.black54 : Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                _loadProfileData(); // Reload stats and profile defaults dynamically!
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        widget.languageCode == 'en' ? "Successfully logged out!" : "በስኬት ወጥተዋል!",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text(
                widget.languageCode == 'en' ? 'Confirm Log Out' : 'ውጣ',
                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red),
              ),
            ),
          ],
        );
      },
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
