import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ad_helper.dart';
import '../services/offline_manager.dart';
import '../services/quiz_service.dart';
import '../main.dart';
import 'quiz_screen.dart';
import 'registration_overlay.dart';
import 'notes_screen.dart';

class UnitSelectionScreen extends StatefulWidget {
  final int grade;
  final String subjectId;
  final String enTitle;
  final String amTitle;
  final Color color;
  final Widget icon;
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;
  final bool isShortNotesMode;

  const UnitSelectionScreen({
    super.key,
    required this.grade,
    required this.subjectId,
    required this.enTitle,
    required this.amTitle,
    required this.color,
    required this.icon,
    required this.isDarkMode,
    required this.languageCode,
    required this.onToggleTheme,
    required this.onToggleLanguage,
    this.isShortNotesMode = false,
  });

  @override
  State<UnitSelectionScreen> createState() => _UnitSelectionScreenState();
}

class _UnitSelectionScreenState extends State<UnitSelectionScreen> {
  // Simple in-memory tracker for downloaded units & download progress states
  final Set<String> _downloadedUnits = {};
  final Map<String, double> _downloadProgress = {}; // unitId -> 0.0 to 1.0

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;

  bool _isRegistered = false;
  bool _notificationPermissionDenied = false;
  final Map<int, int> _unitBestScores = {};

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadRewardedAd();
    _loadInterstitialAd();
    _loadOfflineDownloads();
    _loadBestScores();
    _checkRegistrationStatus();
    _checkNotificationStatus();
  }

  void _checkNotificationStatus() async {
    try {
      final status = await Permission.notification.status;
      if (mounted) {
        setState(() {
          _notificationPermissionDenied = !status.isGranted;
        });
      }
    } catch (e) {
      debugPrint("Error checking notification status on load: $e");
    }
  }

  void _checkRegistrationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isRegistered = (prefs.getBool('has_registered') ?? false) ||
                        (prefs.getBool('is_authenticated') ?? false);
      });
    }
  }

  Future<void> _checkRegistrationAndProceed(int index, int activeUnitNum, {required VoidCallback onSuccess}) async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasRegistered = (prefs.getBool('has_registered') ?? false) ||
                               (prefs.getBool('is_authenticated') ?? false);

    if (activeUnitNum > 1 && !hasRegistered) {
      if (!mounted) return;
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => RegistrationOverlay(
            isDarkMode: widget.isDarkMode,
            languageCode: widget.languageCode,
            primaryColor: widget.color,
          ),
        ),
      );

      // Reload SharedPreferences state after overlay closes
      final updatedPrefs = await SharedPreferences.getInstance();
      final bool nowRegistered = (updatedPrefs.getBool('has_registered') ?? false) ||
                                 (updatedPrefs.getBool('is_authenticated') ?? false);
      setState(() {
        _isRegistered = nowRegistered;
      });

      if (nowRegistered) {
        onSuccess();
      } else {
        debugPrint("Registration is required for Unit $activeUnitNum. Navigation aborted.");
      }
    } else {
      onSuccess();
    }
  }

  void _showUnitOptionsSheet(BuildContext context, int unitNumber, String unitId, String unitTitle, bool isDownloaded) {
    final bool isLight = !widget.isDarkMode;
    final Color sheetBg = isLight ? Colors.white : const Color(0xFF0F172A);
    final Color headerColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color descColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.languageCode == 'en' ? "Unit Activities" : "የክፍሉ ተግባራት",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: headerColor,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.languageCode == 'en' 
                      ? "Choose how you want to study for Unit $unitNumber" 
                      : "ለክፍል $unitNumber የሚፈልጉትን ተግባር ይምረጡ",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: descColor,
                  ),
                ),
                const SizedBox(height: 24),
                


                // 2. Practice Mode Card
                InkWell(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _executeWithRewardedAd(() {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => QuizScreen(
                            grade: widget.grade,
                            subject: widget.subjectId,
                            unit: unitNumber,
                            mode: QuizMode.practice,
                            isOffline: isDownloaded,
                            offlineUnitId: isDownloaded ? unitId : null,
                          ),
                        ),
                      ).then((_) {
                        _loadBestScores();
                      });
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school_rounded, color: Color(0xFF3B82F6), size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.languageCode == 'en' ? "Practice Mode" : "የልምምድ ዓይነት",
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: headerColor),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.languageCode == 'en' 
                                    ? "Get instant answers, complete details & explanations" 
                                    : "ፈጣን መልሶችን እና ማብራሪያዎችን ያግኙ",
                                style: TextStyle(fontSize: 11.5, color: descColor, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: descColor, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // 3. Exam Mode Card
                InkWell(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _executeWithRewardedAd(() {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => QuizScreen(
                            grade: widget.grade,
                            subject: widget.subjectId,
                            unit: unitNumber,
                            mode: QuizMode.exam,
                            isOffline: isDownloaded,
                            offlineUnitId: isDownloaded ? unitId : null,
                          ),
                        ),
                      ).then((_) {
                        _loadBestScores();
                      });
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.timer_rounded, color: Color(0xFFEF4444), size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.languageCode == 'en' ? "Exam Mode" : "የፈተና ዓይነት",
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: headerColor),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.languageCode == 'en' 
                                    ? "Timed, scoreboard tracking, strict review on completion" 
                                    : "የውጤት ሰሌዳ እና ጥብቅ የልምምድ ክትትል",
                                style: TextStyle(fontSize: 11.5, color: descColor, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: descColor, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRegistrationDialog() {
    final bool isLight = !widget.isDarkMode;
    final Color headerTextColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color descColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    final _formKey = GlobalKey<FormState>();
    final _fullNameController = TextEditingController();
    final _phoneController = TextEditingController();
    final _emailController = TextEditingController();
    int _dialogSelectedGrade = widget.grade; // Default to current screen's grade
    String _dialogSelectedCountryCode = '+251'; // Default

    final List<Map<String, String>> countryCodes = [
      {'code': '+251', 'flag': '🇪🇹', 'name': 'Ethiopia'},
      {'code': '+1', 'flag': '🇺🇸', 'name': 'USA'},
      {'code': '+44', 'flag': '🇬🇧', 'name': 'UK'},
      {'code': '+254', 'flag': '🇰🇪', 'name': 'Kenya'},
      {'code': '+256', 'flag': '🇺🇬', 'name': 'Uganda'},
    ];

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while potentially registering
      builder: (BuildContext context) {
        bool _isLoading = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
              backgroundColor: isLight ? Colors.white : const Color(0xFF0F172A), // Premium deeper dark
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isLight ? Colors.transparent : const Color(0xFF1E293B),
                      width: 1.5,
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Section
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color: widget.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.verified_user_rounded, // Premium lock/security icon
                                    color: widget.color,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.languageCode == 'en' ? 'Unlock All Units' : 'ሁሉንም ክፍሎች ይክፈቱ',
                                        style: TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w900,
                                          color: headerTextColor,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        widget.languageCode == 'en' 
                                            ? 'Register to unlock premium prep content' 
                                            : 'ይዘቶችን ለማግኘት ይመዝገቡ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: descColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!_isLoading)
                                  IconButton(
                                    icon: Icon(Icons.close_rounded, color: descColor, size: 22),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Divider(height: 1, color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B), thickness: 1.5),
                            const SizedBox(height: 20),

                            // Full Name Field
                            _buildDialogLabel(
                              widget.languageCode == 'en' ? 'Full Name *' : 'ሙሉ ስም *',
                              isLight,
                            ),
                            _buildDialogFieldContainer(
                              isLight: isLight,
                              child: TextFormField(
                                controller: _fullNameController,
                                enabled: !_isLoading,
                                style: TextStyle(
                                  color: isLight ? const Color(0xFF0F172A) : Colors.white,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: widget.languageCode == 'en' ? 'e.g. Abebe Bekele' : 'ምሳሌ: አበበ በቀለ',
                                  hintStyle: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    color: widget.color,
                                    size: 18,
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return widget.languageCode == 'en' 
                                        ? 'Please enter your name' 
                                        : 'እባክዎን ስምዎን ያስገቡ';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Phone Number Field with Country Code
                            _buildDialogLabel(
                              widget.languageCode == 'en' ? 'Phone Number *' : 'ስልክ ቁጥር *',
                              isLight,
                            ),
                            _buildDialogFieldContainer(
                              isLight: isLight,
                              child: Row(
                                children: [
                                  // Country code selector dropdown with cohesive modern field wrapper
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                                        width: 1,
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _dialogSelectedCountryCode,
                                        dropdownColor: isLight ? Colors.white : const Color(0xFF1E293B),
                                        icon: const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
                                        style: TextStyle(
                                          color: isLight ? const Color(0xFF0F172A) : Colors.white,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        items: countryCodes.map((country) {
                                          return DropdownMenuItem<String>(
                                            value: country['code'],
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  country['flag']!,
                                                  style: const TextStyle(fontSize: 16),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  country['code']!,
                                                  style: const TextStyle(fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: _isLoading ? null : (val) {
                                          if (val != null) {
                                            setDialogState(() {
                                              _dialogSelectedCountryCode = val;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 1.2,
                                    height: 24,
                                    color: isLight ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _phoneController,
                                      enabled: !_isLoading,
                                      keyboardType: TextInputType.phone,
                                      style: TextStyle(
                                        color: isLight ? const Color(0xFF0F172A) : Colors.white,
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '911234567',
                                        hintStyle: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return widget.languageCode == 'en' 
                                              ? 'Please enter phone' 
                                              : 'እባክዎን ስልክ ቁጥር ያስገቡ';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Grade Level Dropdown
                            _buildDialogLabel(
                              widget.languageCode == 'en' ? 'Grade Level *' : 'የክፍል ደረጃ *',
                              isLight,
                            ),
                            _buildDialogFieldContainer(
                              isLight: isLight,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _dialogSelectedGrade,
                                  isExpanded: true,
                                  icon: Icon(Icons.arrow_drop_down, color: widget.color, size: 24),
                                  dropdownColor: isLight ? Colors.white : const Color(0xFF1E293B),
                                  style: TextStyle(
                                    color: isLight ? const Color(0xFF0F172A) : Colors.white,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  items: [9, 10, 11, 12].map((int val) {
                                    return DropdownMenuItem<int>(
                                      value: val,
                                      child: Text(
                                        widget.languageCode == 'en' ? 'Grade $val' : 'ክፍል $val',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _isLoading ? null : (val) {
                                    if (val != null) {
                                      setDialogState(() {
                                        _dialogSelectedGrade = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Optional Email Address
                            _buildDialogLabel(
                              widget.languageCode == 'en' ? 'Email Address (Optional)' : 'የኢሜል አድራሻ (አማራጭ)',
                              isLight,
                            ),
                            _buildDialogFieldContainer(
                              isLight: isLight,
                              child: TextFormField(
                                controller: _emailController,
                                enabled: !_isLoading,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  color: isLight ? const Color(0xFF0F172A) : Colors.white,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: widget.languageCode == 'en' ? 'e.g. abebe@smartx.com' : 'ምሳሌ: abebe@smartx.com',
                                  hintStyle: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: widget.color,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Action Buttons: Cancel & Register
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      side: BorderSide(
                                        color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: Text(
                                      widget.languageCode == 'en' ? 'Cancel' : 'ሰርዝ',
                                      style: TextStyle(
                                        color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () async {
                                            if (_formKey.currentState!.validate()) {
                                              setDialogState(() {
                                                _isLoading = true;
                                              });

                                              final String fullName = _fullNameController.text.trim();
                                              final String phone = _phoneController.text.trim();
                                              final String email = _emailController.text.trim();
                                              final String fullPhone = '$_dialogSelectedCountryCode $phone';

                                              try {
                                                final prefs = await SharedPreferences.getInstance();
                                                String? profileId = prefs.getString('user_id');
                                                if (profileId == null) {
                                                  profileId = 'user_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecondsSinceEpoch % 9000))}';
                                                  await prefs.setString('user_id', profileId);
                                                }
                                                final supabase = Supabase.instance.client;

                                                await supabase.from('student_profiles').upsert({
                                                  'id': profileId,
                                                  'full_name': fullName,
                                                  'phone_number': fullPhone,
                                                  'grade': _dialogSelectedGrade,
                                                  'email': email.isNotEmpty ? email : '$profileId@smartx-offline.com',
                                                });
                                                debugPrint("Successfully synced registration to Supabase student_profiles.");

                                                await prefs.setString('user_fullName', fullName);
                                                await prefs.setString('user_phoneNumber', fullPhone);
                                                await prefs.setString('user_grade', 'Grade $_dialogSelectedGrade');
                                                if (email.isNotEmpty) {
                                                  await prefs.setString('user_email', email);
                                                }
                                                await prefs.setBool('is_authenticated', true);

                                                // Update state
                                                if (this.mounted) {
                                                  this.setState(() {
                                                    _isRegistered = true;
                                                  });
                                                }

                                                // Close dialog
                                                if (context.mounted) {
                                                  Navigator.of(context).pop();
                                                }

                                                // Show success snackbar
                                                if (this.context.mounted) {
                                                  ScaffoldMessenger.of(this.context).clearSnackBars();
                                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                                    SnackBar(
                                                      content: Row(
                                                        children: [
                                                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                                          const SizedBox(width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              widget.languageCode == 'en' 
                                                                  ? 'Successfully registered! Premium content unlocked.' 
                                                                  : 'በስኬት ተመዝግበዋል! ሁሉም የትምህርት ክፍሎች ተከፍተዋል::',
                                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      backgroundColor: const Color(0xFF10B981),
                                                      behavior: SnackBarBehavior.floating,
                                                      duration: const Duration(seconds: 3),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                debugPrint("Failed to sync registration to Supabase: $e");
                                                
                                                setDialogState(() {
                                                  _isLoading = false;
                                                });

                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).clearSnackBars();
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Row(
                                                        children: [
                                                          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                                                          const SizedBox(width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              widget.languageCode == 'en'
                                                                  ? 'Registration failed. Please check your internet connection and try again.'
                                                                  : 'ምዝገባው አልተሳካም። እባክዎ የኢንተርኔት ግንኙነትዎን ያረጋግጡና እንደገና ይሞክሩ።',
                                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      backgroundColor: const Color(0xFFEF4444),
                                                      behavior: SnackBarBehavior.floating,
                                                      duration: const Duration(seconds: 4),
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: widget.color,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: widget.color.withOpacity(0.5),
                                      disabledForegroundColor: Colors.white.withOpacity(0.8),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      elevation: 2,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            widget.languageCode == 'en' ? 'Register' : 'ተመዝገብ',
                                            style: const TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogLabel(String text, bool isLight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2.0),
      child: Text(
        text,
        style: TextStyle(
          color: isLight ? const Color(0xFF0F172A) : Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildDialogFieldContainer({required Widget child, required bool isLight}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
          width: 1.2,
        ),
      ),
      child: child,
    );
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _loadRewardedAd();
            },
          );
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
        },
        onAdFailedToLoad: (err) {
          debugPrint('Failed to load a rewarded ad: ${err.message}');
          _isRewardedAdLoaded = false;
        },
      ),
    );
  }

  void _executeWithRewardedAd(VoidCallback action) {
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadRewardedAd();
          action();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          _loadRewardedAd();
          action();
        },
      );
      _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        // Reward earned. Action is called on dismiss.
      });
      _rewardedAd = null;
      _isRewardedAdLoaded = false;
    } else {
      action();
    }
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('Failed to load an interstitial ad: ${err.message}');
          _isInterstitialAdLoaded = false;
        },
      ),
    );
  }

  void _loadOfflineDownloads() async {
    final downloaded = await OfflineManager.getDownloadedUnitIds();
    if (mounted) {
      setState(() {
        _downloadedUnits.addAll(downloaded);
      });
    }
  }

  void _loadBestScores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allUnits = _getUnits();
      final Map<int, int> loadedScores = {};
      for (int i = 0; i < allUnits.length; i++) {
        final int unitNum = i + 1;
        final String scoreKey = 'best_score_${widget.grade}_${widget.subjectId}_u$unitNum';
        final int? score = prefs.getInt(scoreKey);
        if (score != null) {
          loadedScores[unitNum] = score;
        }
      }
      if (mounted) {
        setState(() {
          _unitBestScores.clear();
          _unitBestScores.addAll(loadedScores);
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

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
          debugPrint('UnitSelectionScreen BannerAd failed to load: $err. Code: ${err.code}');
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

  // Bilingual translation helper
  String _local(String key) {
    // Dynamic retrieval from AppStateProvider context
    final String languageCode = AppStateProvider.of(context).languageCode;
    final Map<String, Map<String, String>> localized = {
      'en': {
        'back': 'Back',
        'units_title': 'Unit Explorer',
        'download': 'Download Questions',
        'downloading': 'Downloading Questions...',
        'downloaded': 'Questions Saved',
        'start_quiz': 'Start Practice',
        'completed': 'Completed',
        'units_count': 'Units Available',
        'progress_label': 'My Learning Progress',
        'bytes_info': 'Size: ~100 KB • Complete offline questions database',
        'info_sheet': 'Unit Questions Package',
        'info_desc': 'Downloading saves unit-specific exam questions directly to your device for complete offline practice.',
      },
      'am': {
        'back': 'ተመለስ',
        'units_title': 'የትምህርት ክፍሎች',
        'download': 'ጥያቄዎችን አውርድ',
        'downloading': 'ጥያቄዎችን በማውረድ ላይ...',
        'downloaded': 'ጥያቄዎች ወርደዋል',
        'start_quiz': 'መጠይቅ ጀምር',
        'completed': 'የተጠናቀቀ',
        'units_count': 'ያሉ የትምህርት ክፍሎች',
        'progress_label': 'የእኔ የመማር ሂደት',
        'bytes_info': 'መጠን: ~100 KB • ሙሉ ከመስመር ውጪ ጥያቄዎች',
        'info_sheet': 'የክፍል ጥያቄዎች ጥቅል',
        'info_desc': 'ማውረድ ያለ በይነመረብ (ከመስመር ውጭ) የፈተና ጥያቄዎችን በቀጥታ በስልክዎ ላይ እንዲለማመዱ ያከማቻል።',
      }
    };
    return localized[languageCode]?[key] ?? key;
  }

  // Generate customized realistic units and descriptions for each subject + grade
  List<Map<String, dynamic>> _getUnits() {
    switch (widget.subjectId) {
      case 'Mathematics':
        return [
          {
            'id': 'math_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: The Number System',
            'amUnit': 'ክፍል 1: የቁጥር ስርዓት',
            'enDesc': 'Exploring rational & irrational numbers, operations, proofs, and sequence properties.',
            'amDesc': 'አሳማኝ እና አሳማኝ ያልሆኑ ቁጥሮች፣ ስሌቶች፣ ቀመሮች እና ቅደም ተከተሎችን ማሰስ።',
          },
          {
            'id': 'math_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: Equations & Inequalities',
            'amUnit': 'ክፍል 2: እኩልታዎች እና አለመساባዎች',
            'enDesc': 'Solving quadratic systems, absolute values, and application models in real contexts.',
            'amDesc': 'የሁለተኛ ዲግሪ እኩልታዎችን፣ ፍጹም እሴቶችን እና ተግባራዊ አተገባበር መፍታት።',
          },
          {
            'id': 'math_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Coordinates & Vector Spaces',
            'amUnit': 'ክፍል 3: መጋጠሚያዎች እና የቬክተር ክፍተቶች',
            'enDesc': 'Distance formulas, midpoint vectors, linear equations slope, and spatial points.',
            'amDesc': 'የነጥቦች ርቀቶች ቀመር፣ የመካከለኛ ነጥብ፣ የቁልቁለት እና የቬክተር አቀማመጦች።',
          },
          {
            'id': 'math_u4',
            'grade': widget.grade,
            'enUnit': 'Unit 4: Geometry & Trigonometry',
            'amUnit': 'ክፍል 4: ጂኦሜትሪ እና ትሪጎኖሜትሪ',
            'enDesc': 'Congruent shapes, sine & cosine rules, area theorems, and complex angle measures.',
            'amDesc': 'ተመሳሳይ ቅርጾች፣ ሳይን እና ኮሳይን ህግጋት፣ የቦታ ይዘት እና አንግሎች።',
          },
          {
            'id': 'math_u5',
            'grade': widget.grade,
            'enUnit': 'Unit 5: Statistics & Probability',
            'amUnit': 'ክፍል 5: ስታቲስቲክስ እና ፕሮባብሊቲ',
            'enDesc': 'Data variance indices, standard deviations, permutation and independent compound events.',
            'amDesc': 'የዳታ ልዩነቶች እና ስታንዳርድ ዴቪዬሽን፣ ፐርሙቴሽን እና የተለያዩ የዕድል ሁኔታዎች።',
          },
        ];

      case 'Biology':
        return [
          {
            'id': 'bio_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Introduction to Biology',
            'amUnit': 'ክፍል 1: ስለ ስነ-ህይወት መግቢያ',
            'enDesc': 'General scope of biological sciences, history, instruments, and microscopic observations.',
            'amDesc': 'የስነ-ህይወት ሳይንስ አጠቃላይ ድንጋጌዎች፣ ታሪክ፣ መሳሪያዎች እና የማይክሮስኮፕ አጠቃቀም።',
          },
          {
            'id': 'bio_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: Cellular Chemistry & Functions',
            'amUnit': 'ክፍል 2: የህዋስ ኬሚስትሪ እና ተግባራት',
            'enDesc': 'Primary organelles structure, cellular respiration pathway, and DNA replication mechanisms.',
            'amDesc': 'የኦርጋኔሎች መዋቅር፣ የህዋስ መተንፈስ ተግባር እና የዲኤንኤ ገለጻ መርሆዎች።',
          },
          {
            'id': 'bio_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Plant Structure and Physiology',
            'amUnit': 'ክፍል 3: የዕፅዋት መዋቅር እና ስነ-ተግባር',
            'enDesc': 'Photosynthesis processes, stomatal movements, transpiration forces and nutrient transport.',
            'amDesc': 'ፎቶሲንተሲስ፣ የስቶማታ እንቅስቃሴ፣ ትራንስፓይሬሽን እና የዕፅዋት ምግብ ዝውውር።',
          },
          {
            'id': 'bio_u4',
            'grade': widget.grade,
            'enUnit': 'Unit 4: Human Anatomy & Health Systems',
            'amUnit': 'ክፍል 4: የሰው አካል የአካል ክፍሎች እና ጤና',
            'enDesc': 'Nervous transmission pathways, endocrinal regulatory glands, and immune system response.',
            'amDesc': 'የነርቭ ዝውውር መቆጣጠሪያ፣ የሆርሞኖች እጢዎች እና የበሽታ መከላከያ ስርዓቶች።',
          },
          {
            'id': 'bio_u5',
            'grade': widget.grade,
            'enUnit': 'Unit 5: Ecology & Environmental Physics',
            'amUnit': 'ክፍል 5: ስነ-ምህዳር እና አካባቢ',
            'enDesc': 'Biosphere interactions, biogeochemical nutrient loops, and habitat preservation dynamics.',
            'amDesc': 'በባዮስፌር ውስጥ ያሉ ግንኙነቶች፣ አልሚ ንጥረ ነገሮች ኡደት እና አካባቢ ጥበቃ።',
          },
        ];

      case 'Physics':
        return [
          {
            'id': 'phys_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Physical Quantities & Vectors',
            'amUnit': 'ክፍል 1: ፊዚካዊ መጠኖች እና ቬክተሮች',
            'enDesc': 'Vector resolutions, scalar products, dimension analysis, and precision measurements.',
            'amDesc': 'የቬክተር ክፍፍሎች፣ መስቀለኛ እና ስካላር ብዜቶች፣ እና የልኬት ትክክለኛነት ሞዴሎች።',
          },
          {
            'id': 'phys_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: Kinematics & Mechanics',
            'amUnit': 'ክፍል 2: ኪነማቲክስ እና መካኒክስ',
            'enDesc': 'Two-dimensional motions, projectile trajectories, and Newton’s core acceleration laws.',
            'amDesc': 'ሁለት አቅጣጫዊ እንቅስቃሴዎች፣ ፕሮጀክታይል ሞሽን እና የኒውተን የጉልበት ህግጋት።',
          },
          {
            'id': 'phys_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Work, Energy & Power',
            'amUnit': 'ክፍል 3: ስራ፣ ጉልበት እና ሃይል',
            'enDesc': 'Conservation thresholds, potential fields, collision mechanics, and efficiency calculations.',
            'amDesc': 'የእምቅ ሃይል ክምችት፣ የመጋጨት መካኒክስ እና የውጤታማነት ስሌቶች።',
          },
          {
            'id': 'phys_u4',
            'grade': widget.grade,
            'enUnit': 'Unit 4: Rotational Motion & Gravity',
            'amUnit': 'ክፍል 4: ሽክርክሪት እንቅስቃሴ እና የስበት ኃይል',
            'enDesc': 'Angular pathways, torque balances, center of gravity, and moment of inertia formulas.',
            'amDesc': 'የማዕዘን ጉዞ፣ ቶርክ (ሽክርክሪት ኃይል) እና የመዞሪያ ግትርነት ስሌት።',
          },
          {
            'id': 'phys_u5',
            'grade': widget.grade,
            'enUnit': 'Unit 5: Thermodynamics & Heat Systems',
            'amUnit': 'ክፍል 5: ቴርሞዳይናሚክስ እና ሙቀት',
            'enDesc': 'Heat exchange equations, internal systems state energy, and thermodynamic efficiency.',
            'amDesc': 'የሙቀት ዝውውር መለኪያዎች፣ የውስጣዊ ሃይል መጠን እና የቴርሞዳይናሚክስ ህጎች።',
          },
        ];

      case 'Chemistry':
        return [
          {
            'id': 'chem_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Atomic Structure',
            'amUnit': 'ክፍል 1: የአቶም መዋቅር',
            'enDesc': 'Quantum numbers, orbital levels configuration, chemical properties trends on periodic tables.',
            'amDesc': 'የኳንተም ቁጥሮች፣ የኤሌክትሮን ምደባ መዋቅር እና የጊዜያዊ ሰንጠረዥ ባህሪያት።',
          },
          {
            'id': 'chem_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: Chemical Bonding',
            'amUnit': 'ክፍል 2: ኬሚካዊ ትስስር',
            'enDesc': 'Ionic lattices, covalent molecular geometries, molecular orbital systems, and electronegativity.',
            'amDesc': 'አዮኒክ እና ኮቫለንት ትስስሮች፣ የሞለኪውሎች ውቅር እና የኤሌክትሮኔጋቲቪቲ ልዩነቶች።',
          },
          {
            'id': 'chem_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Stoichiometry & Formula Mass',
            'amUnit': 'ክፍል 3: ስቶይኪዮሜትሪ',
            'enDesc': 'The mole concept, limiting reactant calculations, concentration equations and yield yields.',
            'amDesc': 'የሞል ጽንሰ-ሀሳብ፣ ወሳኝ አፀፋዊ ንጥረ ነገሮች እና የተመጣጠነ ኬሚካዊ ስሌቶች።',
          },
          {
            'id': 'chem_u4',
            'grade': widget.grade,
            'enUnit': 'Unit 4: Chemical Equilibria & Acids',
            'amUnit': 'ክፍል 4: ኬሚካዊ ሚዛን እና አሲዶች',
            'enDesc': 'Le Chatelier shifts, solubility product index, pH calculations, and neutralisations.',
            'amDesc': 'የለ ሻተሌየር መርህ፣ የፒኤች (pH) ስሌት እና የአሲድ-ቤዝ ገለልተኛ መሆን ሂደቶች።',
          },
          {
            'id': 'chem_u5',
            'grade': widget.grade,
            'enUnit': 'Unit 5: Introduction to Organic Chemistry',
            'amUnit': 'ክፍል 5: የኦርጋኒክ ኬሚስትሪ መግቢያ',
            'enDesc': 'IUPAC naming conventions of hydrocarbons, structural isomers, and alkanes properties.',
            'amDesc': 'የሃይድሮካርቦኖች የአሰያየም ሥርዓት (IUPAC)፣ አይሶመርስ እና አልኬን ባህሪዎች።',
          },
        ];

      case 'Geography':
        return [
          {
            'id': 'geo_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Map Reading and Interpretation',
            'amUnit': 'ክፍል 1: የካርታ ንባብ እና ትርጓሜ',
            'enDesc': 'Contour structures, scales comparison, grid symbols identification, and elevation slopes.',
            'amDesc': 'የኮንቱር መስመሮች፣ የካርታ ልኬቶች እና የከፍታዎች የቁልቁለት መጠን መመልከት።',
          },
          {
            'id': 'geo_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: Lithosphere and Landforms',
            'amUnit': 'ክፍል 2: ሊቶስፌር እና የመሬት ገጽታዎች',
            'enDesc': 'Plate tectonic dynamics, continental movements, weathering cycles and soil profiles.',
            'amDesc': 'የቴክቶኒክ ሳህኖች እንቅስቃሴ፣ የመሬት መንቀጥቀጥ እና የአፈር መሸርሸር ዑደቶች።',
          },
          {
            'id': 'geo_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Weather & Climate of Africa',
            'amUnit': 'ክፍል 3: የአፍሪካ የአየር ሁኔታ እና የአየር ንብረት',
            'enDesc': 'ITCZ air movements, climatic classifications, vegetation distribution, and drought factors.',
            'amDesc': 'የአየር ግፊት እና የአየር ንብረት ክልሎች፣ የአፍሪካ ደኖች ተደራሽነት እና ድርቅ።',
          },
          {
            'id': 'geo_u4',
            'grade': widget.grade,
            'enUnit': 'Unit 4: Human Demographics & Economic Growth',
            'amUnit': 'ክፍል 4: የህዝብ ስብጥር እና ኢኮኖሚያዊ ዕድገት',
            'enDesc': 'Fertility models, urban migrative patterns, and primary resource exploitation in Ethiopia.',
            'amDesc': 'የህዝብ ብዛት ተለዋዋጭነት፣ የከተማ ፍልሰት እና የኢትዮጵያ ኢኮኖሚ ሴክተሮች።',
          },
          {
            'id': 'geo_u5',
            'grade': widget.grade,
            'enUnit': 'Unit 5: GIS & Remote Sensing Principles',
            'amUnit': 'ክፍል 5: ጂአይኤስ (GIS) እና የርቀት ምርመራ',
            'enDesc': 'Vector vs Raster attributes, satellite photography data overlaying, mapping softwares info.',
            'amDesc': 'የቬክተር እና ራስተር ዳታ ሞዴሎች፣ የሳተላይት ምስሎች እና የካርታ አሰራር።',
          },
        ];

      case 'History':
        return [
          {
            'id': 'hist_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Human Beginnings inside East Africa',
            'amUnit': 'ክፍል 1: የሰዎች መገኛ በምስራቅ አፍሪካ',
            'enDesc': 'Palaeoanthropology discoveries, Australopithecus Afarensis (Lucy), stone-age tool developments.',
            'amDesc': 'የአርኪዮሎጂ ግኝቶች፣ ሉሲ (ድንቅነሽ) በአዋሽ ሸለቆ፣ የድንጋይ ዘመን መሳሪያዎች እድገት።',
          },
          {
            'id': 'hist_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: The Aksumite Kingdom & Maritime Trade',
            'amUnit': 'ክፍል 2: የአክሱም ስርወ-መንግስት እና የባህር ንግድ',
            'enDesc': 'Rise of Aksum state, stone obelisks engineering, coinage systems, and early Christian introduction.',
            'amDesc': 'የአክሱም ስልጣኔ መነሳት፣ የሀውልቶች ጥበብ፣ የሳንቲም ዝውውር እና ክርስትና መስፋፋት።',
          },
          {
            'id': 'hist_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Medieval Kingdoms and Camel Caravan Routes',
            'amUnit': 'ክፍል 3: የመካከለኛው ዘመን መንግስታት እና የንግድ መስመሮች',
            'enDesc': 'Lasta, Zagwe dynasty, Solomonic restoration, Gondar period, caravan trade routes.',
            'amDesc': 'ላስታ እና የዛግዌ ስርወ መንግስት፣ የሰለሞናዊያን ስርወ መንግስት መመለስ፣ የጎንደር ዘመን እና የነጋዴዎች መስመሮች።',
          },
        ];

      case 'Civics':
        return [
          {
            'id': 'civ_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Democratic & Constitutional Values',
            'amUnit': 'ክፍል 1: ዲሞክራሲያዊ እና ህገ-መንግስታዊ እሴቶች',
            'enDesc': 'Human rights concepts, citizens participation, rule of law, and democratic institutions.',
            'amDesc': 'የሰብአዊ መብቶች ጽንሰ-ሀሳብ፣ የተማሪዎች/ዜጎች ተሳትፎ፣ የህግ የበላይነት እና ዲሞክራሲያዊ ተቋማት።',
          },
          {
            'id': 'civ_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: Active Citizenship & Ethics',
            'amUnit': 'ክፍል 2: ንቁ ዜግነት እና ስነ-ምግባር',
            'enDesc': 'Social engagement, patriotic duties, volunteer activities, and civic responsibilities.',
            'amDesc': 'ማህበራዊ ተሳትፎ፣ የአገር ፍቅር ግዴታዎች፣ የበጎ ፈቃድ ስራዎች እና የዜግነት ኃላፊነቶች።',
          },
          {
            'id': 'civ_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Government and Legal Structures',
            'amUnit': 'ክፍል 3: የመንግስት እና የስነ-ህግ መዋቅሮች',
            'enDesc': 'Three branches of government, regional state formations, and national constitution pillars.',
            'amDesc': 'ሶስቱ የመንግስት አካላት፣ የክልል መንግስታት አመሰራረት እና የህገ-መንግስት መሰረቶች።',
          },
        ];

      case 'Agriculture':
        return [
          {
            'id': 'agri_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Principles of Crop and Livestock Management',
            'amUnit': 'ክፍል 1: የሰብል እና የእንስሳት እርባታ መሰረታዊ መርሆዎች',
            'enDesc': 'Sustainable animal breeding, agricultural tools safety, sowing timelines, crop rotation keys.',
            'amDesc': 'ዘላቂ የእንስሳት እርባታ፣ የግብርና ሰብል እንክብካቤ እና ዘላቂ የሰብል ዝውውር።',
          },
          {
            'id': 'agri_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: Soil Properties & Water Systems',
            'amUnit': 'ክፍል 2: የአፈር ባህሪያት እና የውሃ አጠቃቀም',
            'enDesc': 'Clay vs sand water holding indexes, organic manure, and primary drainage pathways.',
            'amDesc': 'የአሸዋማ እና ጭቃማ አፈር ባህሪዎች፣ የተፈጥሮ ማዳበሪያ እና መስኖ አጠቃቀም።',
          },
          {
            'id': 'agri_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Crop Parasites & Biological Control',
            'amUnit': 'ክፍል 3: የሰብል ተባዮች እና ባዮሎጂያዊ ቁጥጥር',
            'enDesc': 'Predator-prey insects implementations, rust fungus treatments, and non-chemical methods.',
            'amDesc': 'የተፈጥሮ ተባዮችን መከላከያ ነፍሳት፣ የቡና በሽታ መከላከያዎች እና የአካባቢ ጥበቃ።',
          },
          {
            'id': 'agri_u4',
            'grade': widget.grade,
            'enUnit': 'Unit 4: Agroforestry and Resource Conservation',
            'amUnit': 'ክፍል 4: አግሮ-ፎረስቴሪ እና የተፈጥሮ ሀብት ጥበቃ',
            'enDesc': 'Combining high-productive trees with cereal crops, windbreak buffers, and terracings.',
            'amDesc': 'ዛፎችን ከእርሻ ሰብሎች ጋር ማሳደግ፣ የእርከን ስራዎች እና የንፋስ መከላከያዎች።',
          },
          {
            'id': 'agri_u5',
            'grade': widget.grade,
            'enUnit': 'Unit 5: Advanced Smart Agriculture Systems',
            'amUnit': 'ክፍል 5: ዘመናዊ እና የተራቀቁ የግብርና ዘዴዎች',
            'enDesc': 'Hydroponics structures, drip-irrigation efficiency setups, and greenhouse automation theories.',
            'amDesc': 'ሀይድሮፖኒክስ (ያለ አፈር ማልማት)፣ የተንጠባጠብ መስኖ እና የሙቀት መቆጣጠሪያ ግሪንሃውስ።',
          },
        ];

      default:
        return [];
    }
  }

  int _selectedUnitIndex = 0;

  void _downloadUnitWithAd(String unitId) {
    if (_downloadedUnits.contains(unitId)) return;

    final String languageCode = AppStateProvider.of(context).languageCode;
    final allUnits = _getUnits();
    final unitIndex = allUnits.indexWhere((u) => u['id'] == unitId) + 1;
    final int activeUnitNum = unitIndex > 0 ? unitIndex : 1;

    void performDownload() async {
      setState(() {
        _downloadProgress[unitId] = 0.1;
      });

      try {
        setState(() {
          _downloadProgress[unitId] = 0.4;
        });

        final fetchedQuestions = await QuizService.fetchQuestions(
          grade: widget.grade,
          subject: widget.subjectId,
          unit: activeUnitNum,
        );

        setState(() {
          _downloadProgress[unitId] = 0.8;
        });

        if (fetchedQuestions.isEmpty) {
          throw Exception("No questions available on developer server.");
        }

        await OfflineManager.saveOfflineQuestions(unitId, fetchedQuestions);
        await OfflineManager.addDownload(unitId);

        setState(() {
          _downloadProgress.remove(unitId);
          _downloadedUnits.add(unitId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      languageCode == 'en'
                          ? 'Saved! ${fetchedQuestions.length} questions are available offline.'
                          : 'ተቀምጧል! ${fetchedQuestions.length} ጥያቄዎች ከመስመር ውጭ ዝግጁ ናቸው።',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _downloadProgress.remove(unitId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      languageCode == 'en'
                          ? 'Download failed. Check network connection.'
                          : 'ጥያቄዎችን ማውረድ አልተቻለም፡ በይነመረብዎን ያረጋግጡ።',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }

    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd();
          performDownload();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          _loadInterstitialAd();
          performDownload();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
      _isInterstitialAdLoaded = false;
    } else {
      performDownload();
    }
  }

  void _showInfoSheet() {
    final appConfig = AppStateProvider.of(context);
    final isLight = !appConfig.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.download_for_offline_rounded, color: widget.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _local('info_sheet'),
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
                _local('info_desc'),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _local('bytes_info'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Live query from AppStateProvider for absolute zero delay updates
    final appConfig = AppStateProvider.of(context);
    final bool isDarkMode = appConfig.isDarkMode;
    final String languageCode = appConfig.languageCode;
    final bool isLight = !isDarkMode;

    final Color bgColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color cardBgColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color headerTextColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color descColor = isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);

    final allUnits = _getUnits();
    final filteredUnits = allUnits;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: headerTextColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          languageCode == 'en' ? widget.enTitle : widget.amTitle,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w900,
            color: headerTextColor,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: headerTextColor, size: 20),
            onPressed: _showInfoSheet,
          ),
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round_outlined,
              color: headerTextColor,
              size: 20,
            ),
            onPressed: appConfig.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: (_isBannerAdLoaded && _bannerAd != null)
          ? SafeArea(
              child: Container(
                height: _bannerAd!.size.height.toDouble(),
                width: _bannerAd!.size.width.toDouble(),
                alignment: Alignment.center,
                color: Colors.transparent,
                child: AdWidget(ad: _bannerAd!),
              ),
            )
          : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          image: DecorationImage(
            image: const AssetImage('assets/images/education_bg_pattern.png'),
            repeat: ImageRepeat.repeat,
            opacity: isLight ? 0.09 : 0.03,
            colorFilter: isLight ? null : const ColorFilter.mode(Colors.white54, BlendMode.modulate),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Beautiful Hero section with Subject Card presentation
              Container(
                decoration: BoxDecoration(
                  color: isLight ? Colors.white : const Color(0xFF1E293B),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isLight
                          ? Colors.black.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dynamic scaled illustration in unique background box
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: widget.icon,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Titles and Grade
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: widget.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  languageCode == 'en'
                                      ? 'GRADE ${widget.grade}'
                                      : 'ክፍል ${widget.grade}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: widget.color,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                languageCode == 'en' ? widget.enTitle : widget.amTitle,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: headerTextColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                languageCode == 'en'
                                    ? 'High-quality comprehensive unit reviews'
                                    : 'ምርጥ ከመስመር ውጭ የትምህርት ክፍሎች',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: descColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 8),
                    // Progress metric section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _local('progress_label'),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: headerTextColor),
                        ),
                        Text(
                          languageCode == 'en'
                              ? '${_downloadedUnits.length} / ${allUnits.length} Offline'
                              : '${_downloadedUnits.length} / ${allUnits.length} ወርዷል',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: widget.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Custom layout ProgressBar
                    Stack(
                      children: [
                        Container(
                          height: 7,
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: 7,
                          width: MediaQuery.of(context).size.width * 
                              (allUnits.isEmpty ? 0 : (_downloadedUnits.length / allUnits.length)) * 0.85,
                          decoration: BoxDecoration(
                            color: widget.color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (_notificationPermissionDenied)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFFEF3C7) : const Color(0xFF78350F).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isLight ? const Color(0xFFFDE68A) : const Color(0xFF78350F).withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isLight ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              languageCode == 'en' ? 'Stay Updated!' : 'ወቅታዊ መረጃ ያግኙ!',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isLight ? const Color(0xFF92400E) : const Color(0xFFFDE68A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              languageCode == 'en'
                                  ? 'Enable notifications to get exam tips and reminders.'
                                  : 'የፈተና ምክሮችን እና ማሳሰቢያዎችን ለማግኘት ማሳወቂያዎችን ይፍቀዱ።',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isLight ? const Color(0xFFB45309) : const Color(0xFFFDE68A).withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          final status = await Permission.notification.request();
                          if (status.isGranted) {
                            if (mounted) {
                              setState(() {
                                _notificationPermissionDenied = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    languageCode == 'en'
                                        ? 'Notifications successfully enabled!'
                                        : 'ማሳወቂያዎች በተሳካ ሁኔታ ተፈቅደዋል!',
                                  ),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } else {
                            if (status.isPermanentlyDenied) {
                              await openAppSettings();
                            }
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          languageCode == 'en' ? 'Enable' : 'ፍቀድ',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8.0),

              // Filtered list of Units
              if (filteredUnits.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  child: Column(
                    children: [
                      Icon(Icons.layers_clear_rounded, color: descColor.withValues(alpha: 0.4), size: 48),
                      const SizedBox(height: 12),
                      Text(
                        languageCode == 'en' ? 'No units available yet.' : 'ምንም የትምህርት ክፍሎች አልተገኙም።',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: descColor, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  itemCount: filteredUnits.length,
                  itemBuilder: (context, index) {
                    final unit = filteredUnits[index];
                    final String unitId = unit['id'];
                    final bool isDownloaded = _downloadedUnits.contains(unitId);
                    final double? progress = _downloadProgress[unitId];

                    final String title = languageCode == 'en' ? unit['enUnit'] : unit['amUnit'];
                    final String desc = languageCode == 'en' ? unit['enDesc'] : unit['amDesc'];
                    final bool isSelected = _selectedUnitIndex == index;

                    final selectedUnit = filteredUnits[index];
                    final originalIndex = allUnits.indexOf(selectedUnit);
                    final int activeUnitNum = originalIndex >= 0 ? originalIndex + 1 : index + 1;

                    final indexFactor = index * 100;
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + indexFactor),
                      curve: Curves.easeOutCubic,
                      builder: (context, animValue, animChild) {
                        return Transform.translate(
                          offset: Offset(0.0, 30.0 * (1.1 - animValue)),
                          child: Opacity(
                            opacity: animValue,
                            child: animChild,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cardBgColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isLight ? 0.02 : 0.12),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: isSelected
                                        ? widget.color
                                        : (isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155)),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        _checkRegistrationAndProceed(index, activeUnitNum, onSuccess: () {
                                          setState(() {
                                            _selectedUnitIndex = index;
                                          });
                                          if (widget.isShortNotesMode) {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => NotesScreen(
                                                  grade: widget.grade,
                                                  subjectId: widget.subjectId,
                                                  unitNumber: activeUnitNum,
                                                  unitTitle: title,
                                                  themeColor: widget.color,
                                                  isDarkMode: widget.isDarkMode,
                                                  languageCode: widget.languageCode,
                                                ),
                                              ),
                                            );
                                          } else {
                                            _showUnitOptionsSheet(context, activeUnitNum, unitId, title, isDownloaded);
                                          }
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                                        child: Row(
                                          children: [
                                            // 1. UNIT NUMBER ON THE LEFT
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: (activeUnitNum > 1 && !_isRegistered)
                                                    ? Colors.grey.withValues(alpha: 0.08)
                                                    : widget.color.withValues(alpha: 0.08),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: (activeUnitNum > 1 && !_isRegistered)
                                                    ? Icon(
                                                        Icons.lock_outline_rounded,
                                                        color: const Color(0xFF94A3B8),
                                                        size: 18,
                                                      )
                                                    : Text(
                                                        "$activeUnitNum",
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.w900,
                                                          color: widget.color,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            // 2. UNIT TITLE IN THE MIDDLE (Wrapped in Expanded)
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    title,
                                                    style: TextStyle(
                                                      fontSize: 15.0,
                                                      fontWeight: FontWeight.w900,
                                                      color: (activeUnitNum > 1 && !_isRegistered)
                                                          ? headerTextColor.withValues(alpha: 0.7)
                                                          : headerTextColor,
                                                      height: 1.25,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    desc,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12.0,
                                                      fontWeight: FontWeight.w500,
                                                      color: (activeUnitNum > 1 && !_isRegistered)
                                                          ? descColor.withValues(alpha: 0.7)
                                                          : descColor,
                                                    ),
                                                  ),
                                                  if (_unitBestScores.containsKey(activeUnitNum)) ...[
                                                    const SizedBox(height: 5),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                                            borderRadius: BorderRadius.circular(6),
                                                            border: Border.all(
                                                              color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                                              width: 1.0,
                                                            ),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              const Icon(
                                                                Icons.emoji_events_rounded,
                                                                color: Colors.amber,
                                                                size: 13,
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                "${widget.enTitle == 'Mathematics' ? 'Maths' : widget.enTitle}: ${_unitBestScores[activeUnitNum]}%",
                                                                style: const TextStyle(
                                                                  fontSize: 11.0,
                                                                  fontWeight: FontWeight.w800,
                                                                  color: Color(0xFF10B981),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // 3. PLAY Action neatly on the right side
                                            SizedBox(
                                              width: 38,
                                              height: 38,
                                              child: IconButton(
                                                padding: EdgeInsets.zero,
                                                icon: Icon(
                                                  (activeUnitNum > 1 && !_isRegistered)
                                                      ? Icons.lock_outline_rounded
                                                      : Icons.play_circle_fill_rounded,
                                                  color: (activeUnitNum > 1 && !_isRegistered)
                                                      ? const Color(0xFF94A3B8)
                                                      : widget.color,
                                                  size: 28,
                                                ),
                                                onPressed: () {
                                                  _checkRegistrationAndProceed(index, activeUnitNum, onSuccess: () {
                                                    setState(() {
                                                      _selectedUnitIndex = index;
                                                    });
                                                    if (widget.isShortNotesMode) {
                                                      Navigator.of(context).push(
                                                        MaterialPageRoute(
                                                          builder: (context) => NotesScreen(
                                                            grade: widget.grade,
                                                            subjectId: widget.subjectId,
                                                            unitNumber: activeUnitNum,
                                                            unitTitle: title,
                                                            themeColor: widget.color,
                                                            isDarkMode: widget.isDarkMode,
                                                            languageCode: widget.languageCode,
                                                          ),
                                                        ),
                                                      );
                                                    } else {
                                                      _showUnitOptionsSheet(context, activeUnitNum, unitId, title, isDownloaded);
                                                    }
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Distinct Download icon button outside the unit selection box
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: isDownloaded 
                                    ? const Color(0xFF10B981).withValues(alpha: 0.1) 
                                    : widget.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDownloaded 
                                      ? const Color(0xFF10B981).withValues(alpha: 0.25) 
                                      : widget.color.withValues(alpha: 0.25),
                                  width: 1.5,
                                ),
                              ),
                              child: Tooltip(
                                message: languageCode == 'en' ? 'Download' : 'አውርድ',
                                child: progress != null
                                    ? Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            value: progress,
                                            strokeWidth: 2.5,
                                            color: widget.color,
                                          ),
                                        ),
                                      )
                                    : IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          isDownloaded
                                              ? Icons.cloud_done_rounded
                                              : Icons.file_download_rounded,
                                          color: isDownloaded
                                              ? const Color(0xFF10B981)
                                              : (activeUnitNum > 1 && !_isRegistered
                                                  ? const Color(0xFF94A3B8)
                                                  : widget.color),
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          _checkRegistrationAndProceed(index, activeUnitNum, onSuccess: () {
                                            _downloadUnitWithAd(unitId);
                                          });
                                        },
                                      ),
                              ),
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
        ),
      ),
    ),
  );
}
}

class InsetShadowPainter extends CustomPainter {
  final Color color;
  final double blurRadius;
  final double strokeWidth;
  final double borderRadius;

  InsetShadowPainter({
    required this.color,
    this.blurRadius = 6.0,
    this.strokeWidth = 3.0,
    this.borderRadius = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    
    canvas.clipRRect(rrect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant InsetShadowPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.blurRadius != blurRadius ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.borderRadius != borderRadius;
}
