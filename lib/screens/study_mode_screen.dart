import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../models/question_model.dart';
import '../services/quiz_service.dart';

class StudyModeScreen extends StatefulWidget {
  final int grade;
  final String? subject;
  final int? unit;

  const StudyModeScreen({
    super.key,
    required this.grade,
    this.subject,
    this.unit,
  });

  @override
  State<StudyModeScreen> createState() => _StudyModeScreenState();
}

class _StudyModeScreenState extends State<StudyModeScreen> {
  List<QuestionModel> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Track the user state
  final Map<int, int> _selectedAnswers = {}; // records option index for each question
  final Set<int> _showExplanations = {}; // records which cards have explanation toggle switched on
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadQuestions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedAnswers.clear();
      _showExplanations.clear();
      _currentPage = 0;
    });

    try {
      final fetched = await QuizService.fetchQuestions(
        grade: widget.grade,
        subject: widget.subject,
        unit: widget.unit,
      );

      setState(() {
        _questions = fetched;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  bool _isOptionCorrect(QuestionModel q, String option, int index) {
    if (option.trim().toLowerCase() == q.correctAnswer.trim().toLowerCase()) {
      return true;
    }
    if (q.correctAnswer.trim() == index.toString()) {
      return true;
    }
    final Map<String, int> letterMap = {'a': 0, 'b': 1, 'c': 2, 'd': 3, 'e': 4};
    final String cleanCorrect = q.correctAnswer.trim().toLowerCase();
    if (letterMap.containsKey(cleanCorrect) && letterMap[cleanCorrect] == index) {
      return true;
    }
    return false;
  }

  void _shareQuestion(QuestionModel q, int index) {
    final String label = "Challenge #${index + 1}";
    final String subjectLabel = widget.subject?.toUpperCase() ?? "GENERAL";
    final String shareMessage = "📚 Smart X Academy — Study Mode 📚\n\n"
        "$label (Grade ${widget.grade} • $subjectLabel • Unit ${widget.unit ?? 1})\n\n"
        "❓ Question: ${q.questionText}\n\n"
        "Can you solve this or find more study assets? Learn and practice with offline support on Smart X Academy!\n"
        "Join and learn: https://t.me/SmartXAcademySupport";

    Share.share(shareMessage);
  }

  Future<void> _launchTelegramSupport() async {
    final telegramUrl = Uri.parse("https://t.me/SmartXAcademySupport");
    try {
      if (await canLaunchUrl(telegramUrl)) {
        await launchUrl(telegramUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Could not deep link into Telegram. Redirecting to external web instead..."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error launching support link: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchReportError(QuestionModel q, int index) async {
    final String subjectName = widget.subject ?? "General";
    final String message = "⚠️ Smart X Academy • Question Error Report\n\n"
        "• Grade: ${widget.grade}\n"
        "• Subject: $subjectName\n"
        "• Unit: ${widget.unit ?? 'General'}\n"
        "• Question #${index + 1}: \"${q.questionText}\"\n\n"
        "• Description of mistake: [Type error detail here]";

    final telegramReportUrl = Uri.parse("https://t.me/SmartXAcademySupport?text=${Uri.encodeComponent(message)}");

    try {
      if (await canLaunchUrl(telegramReportUrl)) {
        await launchUrl(telegramReportUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Unable to open Telegram. Please ensure Telegram is installed."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to trigger support: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final bgGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1E38), Color(0xFF090D1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0), Color(0xFFEEF2F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Stylish glassmorphic top header
              _buildTopHeader(isDark, titleColor, subtitleColor),

              // Horizontal swiping cards with page_view
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? _buildErrorWidget(isDark)
                        : _questions.isEmpty
                            ? _buildEmptyStateWidget(titleColor)
                            : PageView.builder(
                                controller: _pageController,
                                itemCount: _questions.length,
                                onPageChanged: (page) {
                                  setState(() {
                                    _currentPage = page;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final q = _questions[index];
                                  return _buildStudyCard(q, index, isDark);
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
      // Glassy FAB floating action support button redirecting to Telegram username
      floatingActionButton: _isLoading || _questions.isEmpty || _errorMessage != null
          ? null
          : AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: 1.0,
              child: FloatingActionButton.extended(
                onPressed: _launchTelegramSupport,
                elevation: 4,
                backgroundColor: const Color(0xFF0088CC), // Telegram Blue
                icon: const Icon(
                  Icons.report_problem_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  "Support",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTopHeader(bool isDark, Color titleColor, Color subtitleColor) {
    final double completionPercent = _questions.isEmpty
        ? 0.0
        : (_currentPage + 1) / _questions.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: titleColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.subject != null
                          ? "${widget.subject!.toUpperCase()} • Study Mode"
                          : "Study Mode",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: titleColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      "Swipe horizontally to study cards",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (_questions.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.indigo.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                     "${_currentPage + 1}/${_questions.length}",
                     style: const TextStyle(
                       fontSize: 12,
                       fontWeight: FontWeight.w900,
                       color: Color(0xFF6366F1),
                     ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Beautiful interactive progress bar utilizing percent_indicator which user emphasized
          if (_questions.isNotEmpty) _buildPercentProgressIndicator(completionPercent, isDark),
        ],
      ),
    );
  }

  Widget _buildPercentProgressIndicator(double completionPercent, bool isDark) {
    return LinearPercentIndicator(
      percent: completionPercent.clamp(0.0, 1.0),
      lineHeight: 6.0,
      animation: true,
      animateFromLastPercent: true,
      animationDuration: 300,
      barRadius: const Radius.circular(8),
      backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.4),
      linearGradient: const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFFA5B4FC)],
      ),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildErrorWidget(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sentiment_dissatisfied_rounded, color: Color(0xFF6366F1), size: 48),
            const SizedBox(height: 16),
            const Text(
              "Challenge Cards Offline",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? "",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQuestions,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Retry Connection", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget(Color titleColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_rounded, size: 48, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 14),
          Text(
            "This Unit hasn't uploaded flashcards yet.",
            style: TextStyle(color: titleColor.withOpacity(0.6), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyCard(QuestionModel q, int index, bool isDark) {
    final titleTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textThemeColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    final bool hasSelectedAnswer = _selectedAnswers.containsKey(index);
    final int? selectedOptionIndex = _selectedAnswers[index];
    final bool isExplanationShowing = _showExplanations.contains(index);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: GlassmorphicWidget(
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top card label, report and share actions
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "CARD #${index + 1}",
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF6366F1),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Telegram error reporting button
                  IconButton(
                    onPressed: () => _launchReportError(q, index),
                    tooltip: "Report mistake to admin",
                    icon: const Icon(
                      Icons.flag_outlined,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                  // Share Question button on each card
                  IconButton(
                    onPressed: () => _shareQuestion(q, index),
                    tooltip: "Share to Telegram",
                    icon: const Icon(
                      Icons.share_rounded,
                      color: Color(0xFF0088CC),
                      size: 19,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Question body representation
              Text(
                q.questionText,
                style: TextStyle(
                  fontSize: 17.0,
                  fontWeight: FontWeight.w900,
                  color: titleTextColor,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),

              // Option list
              ...q.options.asMap().entries.map((entry) {
                final oIndex = entry.key;
                final oVal = entry.value;

                final bool isThisSelected = selectedOptionIndex == oIndex;
                final bool isThisCorrect = _isOptionCorrect(q, oVal, oIndex);

                Color itemBorderColor = isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0);
                Color itemBgColor = Colors.transparent;
                Color itemTextColor = textThemeColor;

                // Color overrides with instant feedback
                if (hasSelectedAnswer) {
                  if (isThisCorrect) {
                    itemBorderColor = const Color(0xFF10B981);
                    itemBgColor = const Color(0xFF10B981).withOpacity(isDark ? 0.08 : 0.12);
                    itemTextColor = const Color(0xFF10B981);
                  } else if (isThisSelected) {
                    itemBorderColor = const Color(0xFFEF4444);
                    itemBgColor = const Color(0xFFEF4444).withOpacity(isDark ? 0.08 : 0.12);
                    itemTextColor = const Color(0xFFEF4444);
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: hasSelectedAnswer
                        ? null // Lock answer selection once tapped
                        : () {
                            setState(() {
                              _selectedAnswers[index] = oIndex;
                              // Auto reveal explanation when answered correctly/wrongly as an aid
                              _showExplanations.add(index);
                            });
                          },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      decoration: BoxDecoration(
                        color: itemBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: itemBorderColor,
                          width: (isThisSelected || (hasSelectedAnswer && isThisCorrect)) ? 2.5 : 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isThisSelected
                                  ? (isThisCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                  : (hasSelectedAnswer && isThisCorrect
                                      ? const Color(0xFF10B981)
                                      : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9))),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: (isThisSelected || (hasSelectedAnswer && isThisCorrect))
                                    ? Colors.transparent
                                    : (isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFCBD5E1)),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + oIndex), // A, B, C, D...
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: (isThisSelected || (hasSelectedAnswer && isThisCorrect))
                                      ? Colors.white
                                      : textThemeColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              oVal,
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w700,
                                color: itemTextColor,
                              ),
                            ),
                          ),
                          if (hasSelectedAnswer) ...[
                            if (isThisCorrect) ...[
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20)
                            ] else if (isThisSelected) ...[
                              const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 20)
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),

              // Instant explanatory helper toggle panel
              if (hasSelectedAnswer) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Divider(color: Colors.white24, height: 1.0),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _showExplanations.contains(index) ? "Hide Study Explanation" : "Reveal Study Explanation",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: subtitleColor,
                      ),
                    ),
                    Switch.adaptive(
                      value: isExplanationShowing,
                      activeColor: const Color(0xFF6366F1),
                      onChanged: (val) {
                        setState(() {
                          if (val) {
                            _showExplanations.add(index);
                          } else {
                            _showExplanations.remove(index);
                          }
                        });
                      },
                    ),
                  ],
                ),
                // Smoothly animated size toggle explanation container
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFFF59E0B)),
                            SizedBox(width: 6),
                            Text(
                              "Flashcard Solution & Rationale",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (q.explanation != null && q.explanation!.trim().isNotEmpty)
                              ? q.explanation!
                              : "The correct option is: ${q.correctAnswer}.",
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: isExplanationShowing ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Glassmorphism wrapper using BackdropFilter and clean gradient border
class GlassmorphicWidget extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const GlassmorphicWidget({
    super.key,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14.0, sigmaY: 14.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
