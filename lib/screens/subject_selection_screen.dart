import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_helper.dart';
import '../main.dart';
import 'unit_selection_screen.dart';
import '../widgets/subject_vector_widgets.dart';
import '../widgets/interactive_subject_card.dart';

class SubjectSelectionScreen extends StatefulWidget {
  final int grade;
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;

  const SubjectSelectionScreen({
    super.key,
    required this.grade,
    required this.isDarkMode,
    required this.languageCode,
    required this.onToggleTheme,
    required this.onToggleLanguage,
  });

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
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
          debugPrint('SubjectSelectionScreen BannerAd failed to load: $err. Code: ${err.code}');
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

  // Translate title helper dynamically retrieving the language code
  String _local(String key, String languageCode) {
    final Map<String, Map<String, String>> localized = {
      'en': {
        'title': 'GRADE ${widget.grade}: SUBJECTS',
        'subtitle': 'Select your subject to access courses and resources.',
        'btn_start': 'START',
      },
      'am': {
        'title': 'ክፍል ${widget.grade}: የትምህርት ምድቦች',
        'subtitle': 'የትምህርት ዓይነቶችዎን ለመምረጥ ከዚህ በታች ይጫኑ።',
        'btn_start': 'ጀምር',
      }
    };
    return localized[languageCode]?[key] ?? key;
  }

  // Define subjects with Amharic & English representation plus custom coloring/drawing style
  List<Map<String, dynamic>> _getSubjects() {
    return [
      {
        'id': 'Mathematics',
        'amTitle': 'ሂሳብ',
        'enTitle': 'Mathematics',
        'color': const Color(0xFF0084FF),
        'illustration': const DraftingGeometryWidget(),
      },
      {
        'id': 'Biology',
        'amTitle': 'ስነ-ህይወት',
        'enTitle': 'Biology',
        'color': const Color(0xFF2E7D32),
        'illustration': const CellBiologyWidget(),
      },
      {
        'id': 'Physics',
        'amTitle': 'ፊዚክስ',
        'enTitle': 'Physics',
        'color': const Color(0xFFE53935),
        'illustration': const AtomPhysicsWidget(),
      },
      {
        'id': 'Chemistry',
        'amTitle': 'ኬሚስትሪ',
        'enTitle': 'Chemistry',
        'color': const Color(0xFFEF6C00),
        'illustration': const ChemistryFlaskWidget(),
      },
      {
        'id': 'Geography',
        'amTitle': 'ጂኦግራፊ',
        'enTitle': 'Geography',
        'color': const Color(0xFF8E24AA),
        'illustration': const WorldMapGeographyWidget(),
      },
      {
        'id': 'History',
        'amTitle': 'ታሪክ',
        'enTitle': 'History',
        'color': const Color(0xFFF5B041),
        'illustration': const AksumObeliskWidget(),
      },
      {
        'id': 'Civics',
        'amTitle': 'ዜግነት',
        'enTitle': 'Civics',
        'color': const Color(0xFF1E88E5),
        'illustration': const CivicsGavelWidget(),
      },
      {
        'id': 'Agriculture',
        'amTitle': 'ግብርና',
        'enTitle': 'Agriculture',
        'color': const Color(0xFF8D6E63),
        'illustration': const AgricultureSproutWidget(),
      },
    ];
  }

  void _navigateToUnitSelectionScreen(Map<String, dynamic> subject, AppStateProvider appState) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UnitSelectionScreen(
          grade: widget.grade,
          subjectId: subject['id'],
          enTitle: subject['enTitle'],
          amTitle: subject['amTitle'],
          color: subject['color'],
          icon: subject['illustration'],
          isDarkMode: appState.isDarkMode,
          languageCode: appState.languageCode,
          onToggleTheme: appState.onToggleTheme,
          onToggleLanguage: appState.onToggleLanguage,
        ),
      ),
    );
  }

  Color _getGradeColor() {
    switch (widget.grade) {
      case 9:
        return const Color(0xFF0084FF); // Blue
      case 10:
        return const Color(0xFF10B981); // Emerald Green
      case 11:
        return const Color(0xFFF59E0B); // Amber
      case 12:
        return const Color(0xFF8B5CF6); // Purple
      default:
        return const Color(0xFF0084FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically retrieve the latest real-time application values to bypass stale attributes
    final appState = AppStateProvider.of(context);
    final bool isDark = appState.isDarkMode;
    final bool isLight = !isDark;
    final String currentLang = appState.languageCode;
    final subjects = _getSubjects();
    final Color gradeColor = _getGradeColor();

    // Matching responsive top UI alignment and clean off-white platform canvas background
    final Color bgColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color headerTextColor = isLight ? const Color(0xFF0F172A) : Colors.white;

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
          _local('title', currentLang),
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w900,
            color: headerTextColor,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          // Elegant theme mode toggles
          IconButton(
            icon: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round_outlined,
              color: headerTextColor,
              size: 20,
            ),
            onPressed: appState.onToggleTheme,
          ),
          const SizedBox(width: 12),
        ],
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Redesigned 2-column GridView subject selector matching request of 100% high-fidelity bento design
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    return InteractiveSubjectCard(
                      amTitle: subject['amTitle'],
                      enTitle: subject['enTitle'],
                      color: subject['color'],
                      illustration: subject['illustration'],
                      isLight: isLight,
                      gradeColor: gradeColor,
                      languageCode: currentLang,
                      grade: widget.grade,
                      btnText: _local('btn_start', currentLang),
                      onTap: () => _navigateToUnitSelectionScreen(subject, appState),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: (_isBannerAdLoaded && _bannerAd != null)
          ? Container(
              color: bgColor,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
            )
          : null,
    );
  }
}
