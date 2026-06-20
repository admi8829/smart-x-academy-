import 'package:flutter/material.dart';
import 'card_quiz_screen.dart';
import 'list_quiz_screen.dart';
import 'gamified_quiz_screen.dart';

class QuizStyleSelectionScreen extends StatefulWidget {
  final int grade;
  final String? subjectId;
  final int? unit;
  final Color themeColor;
  final bool isDarkMode;
  final String languageCode;

  const QuizStyleSelectionScreen({
    super.key,
    required this.grade,
    this.subjectId,
    this.unit,
    required this.themeColor,
    required this.isDarkMode,
    required this.languageCode,
  });

  @override
  State<QuizStyleSelectionScreen> createState() => _QuizStyleSelectionScreenState();
}

class _QuizStyleSelectionScreenState extends State<QuizStyleSelectionScreen> {
  int _selectedStyleIndex = 0; // Default to Card/Swipe Style

  String _local(String key) {
    final localized = {
      'en': {
        'title': 'Select Quiz Style',
        'subtitle': 'Pick how you would like to practice and master this unit',
        'start_button': "Let's Start",
        'style1_title': 'Card / Swipe Style',
        'style1_sub': 'Focus on one question at a time with smooth gesture card flips.',
        'style2_title': 'Traditional List',
        'style2_sub': 'Scroll through all questions in a standard vertical examination layout.',
        'style3_title': 'Gamified Mode',
        'style3_sub': 'Face a timed high-score challenge with restricted hearts / lives.',
      },
      'am': {
        'title': 'የፈተና ዘይቤ ይምረጡ',
        'subtitle': 'ይህንን ትምህርት እንዴት መለማመድ እና መቆጣጠር እንደሚፈልጉ ይምረጡ',
        'start_button': 'እንጀምር',
        'style1_title': 'የካርድ / የማሸብለል ዘዴ',
        'style1_sub': 'በአንድ ጊዜ በአንድ ጥያቄ ላይ ለስላሳ የካርድ እይታ በማተኮር ይለማመዱ።',
        'style2_title': 'ባህላዊ ዝርዝር',
        'style2_sub': 'ሁሉንም ጥያቄዎች በተለመደው የዝርዝር ቅርጸት ወደ ላይና ወደታች በመሸብለል ይስሩ።',
        'style3_title': 'የጨዋታ ሁነታ',
        'style3_sub': 'የጊዜ ገደብ እና የተወሰኑ ህይወቶችን በመጠቀም ፈታኝ ሙከራ ያድርጉ።',
      }
    };
    return localized[widget.languageCode]?[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = !widget.isDarkMode;
    final backgroundColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final cardColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final titleTextColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final descTextColor = isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);

    final List<Map<String, dynamic>> styles = [
      {
        'title': _local('style1_title'),
        'subtitle': _local('style1_sub'),
        'icon': Icons.layers_rounded,
        'color': const Color(0xFF0084FF),
      },
      {
        'title': _local('style2_title'),
        'subtitle': _local('style2_sub'),
        'icon': Icons.assignment_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'title': _local('style3_title'),
        'subtitle': _local('style3_sub'),
        'icon': Icons.sports_esports_rounded,
        'color': const Color(0xFFF59E0B),
      }
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Section - Stylish Minimal Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: cardColor,
                      shadowColor: Colors.black.withOpacity(0.04),
                      elevation: 4,
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: titleTextColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _local('title'),
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: titleTextColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Subtle decorative header description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _local('subtitle'),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: descTextColor,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Middle Section - Interactive Vertical Cards List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                itemCount: styles.length,
                itemBuilder: (context, index) {
                  final style = styles[index];
                  final bool isSelected = _selectedStyleIndex == index;
                  final Color styleColor = style['color'] as Color;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedStyleIndex = index;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? styleColor.withOpacity(isLight ? 0.05 : 0.08) 
                                : cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected 
                                  ? styleColor 
                                  : (isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155)),
                              width: isSelected ? 2.0 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? styleColor.withOpacity(isLight ? 0.12 : 0.2)
                                    : Colors.black.withOpacity(isLight ? 0.04 : 0.12),
                                blurRadius: isSelected ? 16 : 8,
                                offset: Offset(0, isSelected ? 6 : 3),
                              )
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon container
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? styleColor 
                                      : (isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155)),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  style['icon'] as IconData,
                                  color: isSelected ? Colors.white : descTextColor,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 18),
                              // Title and subtitle text fields
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      style['title'] as String,
                                      style: TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w900,
                                        color: isSelected && !isLight 
                                            ? Colors.white 
                                            : (isSelected ? styleColor : titleTextColor),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      style['subtitle'] as String,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        height: 1.45,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected && !isLight
                                            ? Colors.white.withOpacity(0.8)
                                            : descTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Radio style outer circle feedback
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 20,
                                  width: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? styleColor : descTextColor.withOpacity(0.5),
                                      width: isSelected ? 6 : 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Section - Let's Start Gradient Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.themeColor,
                      widget.themeColor.withOpacity(0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: widget.themeColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Widget targetScreen;
                      if (_selectedStyleIndex == 0) {
                        targetScreen = CardQuizScreen(
                          grade: widget.grade,
                          subject: widget.subjectId,
                          unit: widget.unit,
                        );
                      } else if (_selectedStyleIndex == 1) {
                        targetScreen = ListQuizScreen(
                          grade: widget.grade,
                          subject: widget.subjectId,
                          unit: widget.unit,
                        );
                      } else {
                        targetScreen = GamifiedQuizScreen(
                          grade: widget.grade,
                          subject: widget.subjectId,
                          unit: widget.unit,
                        );
                      }

                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => targetScreen,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _local('start_button'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
