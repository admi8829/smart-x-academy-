import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_helper.dart';

class NotesScreen extends StatefulWidget {
  final int grade;
  final String subjectId;
  final int unitNumber;
  final String unitTitle;
  final Color themeColor;
  final bool isDarkMode;
  final String languageCode;

  const NotesScreen({
    super.key,
    required this.grade,
    required this.subjectId,
    required this.unitNumber,
    required this.unitTitle,
    required this.themeColor,
    required this.isDarkMode,
    required this.languageCode,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  bool _isBookmarked = false;
  double _fontSizeMultiplier = 1.0;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
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
          debugPrint('NotesScreen BannerAd failed to load: $err. Code: ${err.code}');
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

  Future<void> _checkBookmarkStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = prefs.getStringList('bookmarked_notes') ?? [];
      final bookmarkId = '${widget.subjectId}_g${widget.grade}_u${widget.unitNumber}';
      setState(() {
        _isBookmarked = bookmarks.contains(bookmarkId);
      });
    } catch (_) {}
  }

  Future<void> _toggleBookmark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = prefs.getStringList('bookmarked_notes') ?? [];
      final bookmarkId = '${widget.subjectId}_g${widget.grade}_u${widget.unitNumber}';
      
      if (_isBookmarked) {
        bookmarks.remove(bookmarkId);
      } else {
        bookmarks.add(bookmarkId);
      }
      
      await prefs.setStringList('bookmarked_notes', bookmarks);
      setState(() {
        _isBookmarked = !_isBookmarked;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isBookmarked
                  ? (widget.languageCode == 'en' ? 'Notes bookmarked!' : 'ማስታወሻው ተቀምጧል!')
                  : (widget.languageCode == 'en' ? 'Bookmark removed' : 'ማስታወሻው ከምርጫዎች ተሰርዟል'),
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  List<Map<String, String>> _getNotesSections() {
    final sub = widget.subjectId.toLowerCase();
    
    if (sub.contains('math')) {
      switch (widget.unitNumber) {
        case 1:
          return [
            {
              'title': widget.languageCode == 'en' ? '1. Rational and Irrational Numbers' : '1. አሳማኝ እና አሳማኝ ያልሆኑ ቁጥሮች',
              'content': widget.languageCode == 'en'
                  ? 'A rational number is any number that can be expressed as the quotient p/q of two integers, with a non-zero denominator q.\nIrrational numbers cannot be written as simple fractions. Examples include √2, √3, and π.'
                  : 'አሳማኝ ቁጥር ማለት በሁለት ሙሉ ቁጥሮች p/q አካፋይ ሊገለጽ የሚችል ማንኛውም ቁጥር ነው።\nአሳማኝ ያልሆኑ ቁጥሮች በቀላል ክፍልፋይ ሊጻፉ አይችሉም። ምሳሌዎች √2፣ √3 እና π ያካትታሉ።',
              'math': 'r \\in \\mathbb{Q} \\iff r = \\frac{p}{q} \\quad (q \\neq 0)'
            },
            {
              'title': widget.languageCode == 'en' ? '2. Proof of Irrationality of √2' : '2. √2 አሳማኝ አለመሆኑ ማረጋገጫ',
              'content': widget.languageCode == 'en'
                  ? 'Assume √2 is rational, so √2 = p/q in lowest terms. Then 2 = p²/q², so p² = 2q². Since p² is even, p must be even (p = 2k). Substituting gives 4k² = 2q², so q² = 2k², meaning q is also even. This contradicts that p/q was in lowest terms. Thus, √2 is irrational.'
                  : '√2 አሳማኝ ነው ብለን እናስብ፣ ስለዚህ √2 = p/q በትንሹ ቃላት። ከዚያ 2 = p²/q²፣ ስለዚህ p² = 2q²። p² ተጋማሽ ስለሆነ p ተጋማሽ መሆን አለበት (p = 2k)። ይህንን ስንተካ 4k² = 2q²፣ ስለዚህ q² = 2k²፣ ይህም ማለት q ደግሞ ተጋማሽ ነው። ይህ p/q በትንሹ ቃላት ነው ከሚለው ጋር ይጋጫል። ስለዚህ √2 አሳማኝ አይደለም።',
            },
            {
              'title': widget.languageCode == 'en' ? '3. Properties of Absolute Value' : '3. የፍጹም እሴት ባህሪያት',
              'content': widget.languageCode == 'en'
                  ? 'The absolute value of a real number x, denoted |x|, is the non-negative value of x without regard to its sign. Key properties include the Triangle Inequality.'
                  : 'የእውነተኛ ቁጥር x ፍጹም እሴት፣ በ |x| የሚገለጸው፣ ያለ ምልክቱ የ x አዎንታዊ እሴት ነው። ዋና ዋና ባህሪያት የሶስት ማዕዘን አለመመጣጠንን ያካትታሉ።',
              'math': '|a + b| \\le |a| + |b|'
            }
          ];
        case 2:
          return [
            {
              'title': widget.languageCode == 'en' ? '1. Quadratic Equations' : '1. የሁለተኛ ዲግሪ እኩልታዎች',
              'content': widget.languageCode == 'en'
                  ? 'A quadratic equation is a second-order polynomial equation in a single variable. The standard form is ax² + bx + c = 0, where a ≠ 0.'
                  : 'የሁለተኛ ዲግሪ እኩልታ በነጠላ ተለዋዋጭ ውስጥ ያለ የሁለተኛ ደረጃ ፖሊኖሚአል እኩልታ ነው። መደበኛ ፎርሙ ax² + bx + c = 0 ነው፣ እዚህ a ≠ 0።',
              'math': 'x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}'
            },
            {
              'title': widget.languageCode == 'en' ? '2. The Discriminant (D)' : '2. ዲክሪሚናንት (D)',
              'content': widget.languageCode == 'en'
                  ? 'The discriminant D = b² - 4ac determines the nature of the roots:\n• If D > 0, there are two distinct real roots.\n• If D = 0, there is exactly one real root (double root).\n• If D < 0, there are no real roots (two complex roots).'
                  : 'ዲክሪሚናንት D = b² - 4ac የስሮቹን ባህሪ ይወስናል፡\n• D > 0 ከሆነ፣ ሁለት የተለያዩ እውነተኛ ስሮች አሉ።\n• D = 0 ከሆነ፣ በትክክል አንድ እውነተኛ ስር አለ።\n• D < 0 ከሆነ፣ ምንም እውነተኛ ስሮች የሉም።',
              'math': 'D = b^2 - 4ac'
            }
          ];
        default:
          return [
            {
              'title': widget.languageCode == 'en' ? '1. Core Mathematical Foundations' : '1. መሰረታዊ የሂሳብ መርሆዎች',
              'content': widget.languageCode == 'en'
                  ? 'This unit covers core analytical steps, proving theorems systematically, and working through sequence convergence and functions.'
                  : 'ይህ ክፍል መሰረታዊ የትንታኔ ደረጃዎችን፣ ቲዎረሞችን በስርዓት ማረጋገጥ እና የተከታታይ ውህደትን እና ተግባራትን መተግበርን ያጠቃልላል።',
              'math': 'f(x) = \\lim_{h \\to 0} \\frac{f(x+h) - f(x)}{h}'
            }
          ];
      }
    } else if (sub.contains('bio')) {
      return [
        {
          'title': widget.languageCode == 'en' ? '1. Cell Theory and Foundations' : '1. የሴል ቲዎሪ እና መሰረቶች',
          'content': widget.languageCode == 'en'
              ? 'All living organisms are composed of one or more cells. The cell is the basic unit of structure and organization in organisms. Cells arise from pre-existing cells.'
              : 'ሁሉም ህይወት ያላቸው ፍጥረታት ከአንድ ወይም ከዚያ በላይ ከሆኑ ሴሎች የተገነቡ ናቸው። ሴል በፍጥረታት ውስጥ የስነ-ቅርጽ እና የአደረጃጀት መሰረታዊ ክፍል ነው። ሴሎች ከቀደምት ሴሎች ይፈጠራሉ።',
        },
        {
          'title': widget.languageCode == 'en' ? '2. Eukaryotic vs Prokaryotic Cells' : '2. ዩካርዮቲክ እና ፕሮካርዮቲክ ሴሎች',
          'content': widget.languageCode == 'en'
              ? 'Prokaryotes lack a defined nucleus and membrane-bound organelles (e.g., bacteria). Eukaryotes contain a true nucleus and complex organelles like mitochondria and endoplasmic reticulum.'
              : 'ፕሮካርዮቶች የተወሰነ ኒውክሊየስ እና በሽፋን የተከበቡ አካላት የሏቸውም (ለምሳሌ ባክቴሪያ)። ዩካርዮቶች እውነተኛ ኒውክሊየስ እና እንደ ሚቶኮንድሪያ ያሉ ውስብስብ ሴል አካላትን ይይዛሉ።',
        }
      ];
    } else if (sub.contains('phys')) {
      return [
        {
          'title': widget.languageCode == 'en' ? '1. Newton’s Laws of Motion' : '1. የኒውተን የእንቅስቃሴ ህግጋት',
          'content': widget.languageCode == 'en'
              ? '1. Law of Inertia: An object remains at rest or in uniform motion unless acted on by an external force.\n2. F = ma: Force equals mass times acceleration.\n3. Action-Reaction: For every action, there is an equal and opposite reaction.'
              : '1. የኢነርሺያ ህግ፡ ማንኛውም ነገር በውጫዊ ኃይል ካልተገደደ በስተቀር ባለበት ይቆያል ወይም በቀጥታ መስመር ይጓዛል።\n2. F = ma: ጉልበት ከክብደት እና ፍጥነት መጨመር ብዜት ጋር እኩል ነው።\n3. የተቃራኒ ስራ ህግ፡ ለእያንዳንዱ ድርጊት እኩል እና ተቃራኒ የሆነ አጸፋዊ ምላሽ አለ።',
          'math': '\\vec{F} = m \\vec{a}'
        }
      ];
    } else {
      return [
        {
          'title': widget.languageCode == 'en' ? '1. Unit Introduction and Summary' : '1. የክፍሉ መግቢያ እና ማጠቃለያ',
          'content': widget.languageCode == 'en'
              ? 'This unit introduces essential vocabulary, historical timelines, structures, and key summary frameworks.'
              : 'ይህ ክፍል አስፈላጊ የሆኑ ቃላትን፣ ታሪካዊ ሂደቶችን፣ መዋቅሮችን እና ዋና ዋና ማጠቃለያዎችን ያስተዋውቃል።',
        }
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = !widget.isDarkMode;
    final Color bgColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color cardColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color titleColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color contentColor = isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    final sections = _getNotesSections();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          widget.languageCode == 'en' ? 'Short Notes' : 'አጫጭር ማስታወሻዎች',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Font Size Controls
          IconButton(
            icon: const Icon(Icons.format_size_rounded),
            onPressed: () {
              setState(() {
                if (_fontSizeMultiplier >= 1.4) {
                  _fontSizeMultiplier = 0.85;
                } else {
                  _fontSizeMultiplier += 0.15;
                }
              });
            },
          ),
          // Bookmark Action
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isBookmarked ? Colors.amberAccent : Colors.white,
            ),
            onPressed: _toggleBookmark,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject & Unit Info Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: widget.themeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: widget.themeColor.withOpacity(0.2), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.themeColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${widget.languageCode == 'en' ? 'Grade' : 'ክፍል'} ${widget.grade}",
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.subjectId,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: widget.themeColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.unitTitle,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Notes Content List
            ...sections.map((section) {
              final mathExp = section['math'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isLight ? 0.03 : 0.12),
                        blurRadius: 12.0,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section['title'] ?? '',
                        style: TextStyle(
                          fontSize: 16.0 * _fontSizeMultiplier,
                          fontWeight: FontWeight.w900,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        section['content'] ?? '',
                        style: TextStyle(
                          fontSize: 13.5 * _fontSizeMultiplier,
                          fontWeight: FontWeight.w500,
                          height: 1.55,
                          color: contentColor,
                        ),
                      ),
                      if (mathExp != null) ...[
                        const SizedBox(height: 16.0),
                        Center(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Math.tex(
                                mathExp,
                                textStyle: TextStyle(
                                  fontSize: 16 * _fontSizeMultiplier,
                                  color: widget.themeColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20.0),

            // Bottom CTA: Start Quizzes
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // Back to unit selection sheet
                },
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(
                  widget.languageCode == 'en' ? 'Back to Unit Options' : 'ወደ አማራጮች ይመለሱ',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 40.0),
          ],
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
