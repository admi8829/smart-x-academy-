import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/question_model.dart';
import '../services/quiz_service.dart';

class MockExamScreen extends StatefulWidget {
  final int grade;
  final String? subject;
  final int? unit;

  const MockExamScreen({
    super.key,
    required this.grade,
    this.subject,
    this.unit,
  });

  @override
  State<MockExamScreen> createState() => _MockExamScreenState();
}

class _MockExamScreenState extends State<MockExamScreen> {
  List<QuestionModel> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Exam States
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {}; // Map of question index -> selected option index
  bool _isSubmitted = false;

  // State calculations
  int _score = 0;
  int _totalCorrect = 0;
  int _totalWrong = 0;
  int _totalUnanswered = 0;

  // Countdown timer logic
  Timer? _timer;
  int _timeLeftInSeconds = 0;
  int _initialTimeAllocated = 0;

  @override
  void initState() {
    super.initState();
    _loadExamQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadExamQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedAnswers.clear();
      _isSubmitted = false;
      _currentQuestionIndex = 0;
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
        
        // Allocate 1 minute (60s) per question. Minimum 5 minutes (300s).
        if (_questions.isNotEmpty) {
          _timeLeftInSeconds = _questions.length * 60;
          if (_timeLeftInSeconds < 300) _timeLeftInSeconds = 300;
          _initialTimeAllocated = _timeLeftInSeconds;
          _startCountdownTimer();
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startCountdownTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      setState(() {
        if (_timeLeftInSeconds > 0) {
          _timeLeftInSeconds--;
        } else {
          _timer?.cancel();
          _autoSubmitDueToTimeOut();
        }
      });
    });
  }

  String _formatDuration(int totalSecs) {
    final int minutes = totalSecs ~/ 60;
    final int seconds = totalSecs % 60;
    final String minStr = minutes < 10 ? '0$minutes' : '$minutes';
    final String secStr = seconds < 10 ? '0$seconds' : '$seconds';
    return '$minStr:$secStr';
  }

  void _autoSubmitDueToTimeOut() {
    setState(() {
      _isSubmitted = true;
    });
    _calculateFinalExamResults();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.hourglass_disabled_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text(
                "Time limit reached!",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          content: const Text(
            "The exam duration has expired. Your answers have been automatically collected and processed.",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("View Results Page", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _promptFinalSubmitConfirm() {
    final int answeredCount = _selectedAnswers.length;
    final int remainingCount = _questions.length - answeredCount;

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Submit Dashboard",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                "Confirm physical dispatch of exam papers.",
                style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Are you sure you would like to end the examination session? You cannot revise your answers after submitting.",
                style: TextStyle(fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.indigo, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 13),
                          children: [
                            TextSpan(text: "$answeredCount ", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.indigo)),
                            const TextSpan(text: "questions completed, "),
                            TextSpan(text: "$remainingCount ", style: TextStyle(fontWeight: FontWeight.w900, color: remainingCount > 0 ? Colors.orange : Colors.grey)),
                            const TextSpan(text: "unanswered."),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Re-edit Answers", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _processFinalSubmit();
              },
              child: const Text("Final Submit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
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

  void _processFinalSubmit() {
    _timer?.cancel();
    setState(() {
      _isSubmitted = true;
    });
    _calculateFinalExamResults();
  }

  void _calculateFinalExamResults() {
    int totalC = 0;
    int totalW = 0;
    int totalUn = 0;

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (!_selectedAnswers.containsKey(i)) {
        totalUn++;
      } else {
        final int selIdx = _selectedAnswers[i]!;
        if (_isOptionCorrect(q, q.options[selIdx], selIdx)) {
          totalC++;
        } else {
          totalW++;
        }
      }
    }

    setState(() {
      _totalCorrect = totalC;
      _totalWrong = totalW;
      _totalUnanswered = totalUn;
      _score = totalC;
    });
  }

  // Telegram error launcher
  Future<void> _launchTelegramReport(String textMessage) async {
    final telegramUrl = Uri.parse("https://t.me/SmartXAcademySupport?text=${Uri.encodeComponent(textMessage)}");
    try {
      if (await canLaunchUrl(telegramUrl)) {
        await launchUrl(telegramUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Telegram app not detected on this client. Ready for manual copy-paste."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Unable to trigger Telegram: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _triggerFullExamReport() {
    final double pct = _questions.isEmpty ? 0.0 : (_totalCorrect / _questions.length) * 100;
    final int durationSpent = _initialTimeAllocated - _timeLeftInSeconds;
    final int minSpent = durationSpent ~/ 60;
    final int secSpent = durationSpent % 60;

    final String message = "📊 SMART X ACADEMY • MOCK EXAM SCORECARD\n\n"
        "• Grade: ${widget.grade}\n"
        "• Course / Subject: ${widget.subject?.toUpperCase() ?? 'GENERAL'}\n"
        "• Unit / Segment: ${widget.unit ?? 'General'}\n"
        "• Overall score: $_totalCorrect / ${_questions.length} (${pct.toStringAsFixed(1)}%)\n"
        "• Correct: $_totalCorrect ✅\n"
        "• Wrong answers: $_totalWrong ❌\n"
        "• Left Unanswered: $_totalUnanswered ⚠️\n"
        "• Duration elapsed: $minSpent min $secSpent sec\n\n"
        "Authenticated via Smart X Student Space.";

    _launchTelegramReport(message);
  }

  void _triggerQuestionIssueReport(QuestionModel q, int index) {
    final String message = "⚠️ SMART X ACADEMY • QUESTION DISCREPANCY DETECTED\n\n"
        "• Mock Exam Grade: ${widget.grade}\n"
        "• Subject: ${widget.subject?.toUpperCase() ?? 'GENERAL'}\n"
        "• Unit ID: ${widget.unit ?? 'General'}\n"
        "• Outlier Question [#${index + 1}]: \"${q.questionText}\"\n\n"
        "• Candidate mistake description: [Provide detailed notes here regarding corrections]";

    _launchTelegramReport(message);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color titleTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          _isSubmitted ? "Mock Exam scorecard" : "Smart X Mock Center",
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: titleTextColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          onPressed: () {
            if (!_isSubmitted && _questions.isNotEmpty) {
              // Ask confirmation before exit during active mock
              showDialog(
                context: context,
                builder: (BuildContext ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  title: const Text("Abandon Mock Exam?", style: TextStyle(fontWeight: FontWeight.w900)),
                  content: const Text("Your ongoing mock answers will be discarded without checking or storing the grades. Do you wish to proceed?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Pick up where I left", style: TextStyle(color: Colors.indigo))),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text("Abandon Exam", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorPlaceholder(isDark)
              : _questions.isEmpty
                  ? _buildEmptyQuestionsWidget(subtitleColor)
                  : _isSubmitted
                      ? _buildResultScreen(isDark, cardColor, titleTextColor, subtitleColor)
                      : _buildActiveExamScreen(isDark, cardColor, titleTextColor, subtitleColor),
    );
  }

  Widget _buildErrorPlaceholder(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.indigo, size: 48),
            const SizedBox(height: 16),
            const Text(
              "Connection Interrupted",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? "",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loadExamQuestions,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
              child: const Text("Retry Connection", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQuestionsWidget(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.rule_folder_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            "There are currently no mock exam models registered under this Unit.",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- 1. ACTIVE EXAM SCREEN ---
  Widget _buildActiveExamScreen(bool isDark, Color cardColor, Color titleColor, Color bodyColor) {
    final totalQ = _questions.length;
    final int answeredCount = _selectedAnswers.length;
    final double completionPercent = totalQ > 0 ? (answeredCount / totalQ) : 0.0;
    
    final QuestionModel activeQuestion = _questions[_currentQuestionIndex];

    return Column(
      children: [
        // Countdown timer bar & Final Submit at the top
        _buildTimerAndControlsHeader(isDark, cardColor),

        // Linear overall status progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                     "Completed $answeredCount of $totalQ questions",
                     style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: bodyColor),
                   ),
                   Text(
                     "${(completionPercent * 100).toStringAsFixed(0)}% ready",
                     style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF6366F1)),
                   ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: completionPercent,
                  backgroundColor: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                  color: const Color(0xFF6366F1),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),

        // Main Question Sheet Card
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(22.0),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "QUESTION ${_currentQuestionIndex + 1} OF $totalQ",
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF6366F1),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          // Individual specific question flag
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.outlined_flag_rounded, color: Colors.orangeAccent, size: 18),
                            onPressed: () => _triggerQuestionIssueReport(activeQuestion, _currentQuestionIndex),
                            tooltip: "Flag & report this question structure",
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Question Statement text block
                      Text(
                        activeQuestion.questionText,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: titleColor,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Academic standard Choice list
                      ...activeQuestion.options.asMap().entries.map((entry) {
                        final int oIdx = entry.key;
                        final String optionText = entry.value;

                        final bool isChosen = _selectedAnswers[_currentQuestionIndex] == oIdx;

                        Color boundaryColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF1F5F9);
                        Color fillBg = Colors.transparent;
                        Color textPaintColor = bodyColor;

                        if (isChosen) {
                          boundaryColor = const Color(0xFF6366F1);
                          fillBg = const Color(0xFF6366F1).withOpacity(isDark ? 0.08 : 0.06);
                          textPaintColor = const Color(0xFF6366F1);
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedAnswers[_currentQuestionIndex] = oIdx;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: fillBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: boundaryColor,
                                  width: isChosen ? 2.5 : 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: isChosen
                                          ? const Color(0xFF6366F1)
                                          : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isChosen
                                            ? Colors.transparent
                                            : (isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFCBD5E1)),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + oIdx), // A, B, C, D...
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w900,
                                          color: isChosen ? Colors.white : bodyColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      optionText,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: textPaintColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Question Navigation Grid Heading & Segment
                Row(
                  children: [
                    const Icon(Icons.grid_view_rounded, size: 14, color: Color(0xFF6366F1)),
                    const SizedBox(width: 6),
                    Text(
                      "QUESTION NAVIGATION MATRIX",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: bodyColor.withOpacity(0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Navigation Grid Layout itself
                _buildQuestionNavigationGrid(isDark, cardColor, bodyColor),

                const SizedBox(height: 60), // Space for floating button offsets
              ],
            ),
          ),
        ),

        // Navigation controls at very bottom (Previous / Next)
        _buildBottomNavigationBar(isDark, cardColor),
      ],
    );
  }

  Widget _buildTimerAndControlsHeader(bool isDark, Color cardColor) {
    final double pctRemaining = _timeLeftInSeconds / _initialTimeAllocated;
    Color timerAccent = const Color(0xFF10B981);
    if (_timeLeftInSeconds <= 60) {
      timerAccent = const Color(0xFFEF4444); // Red panic timer
    } else if (_timeLeftInSeconds <= 180) {
      timerAccent = Colors.orange;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.08 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Countdown clock chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: timerAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: timerAccent.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, color: timerAccent, size: 16),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(_timeLeftInSeconds),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: timerAccent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),

          // Final Submit action button
          ElevatedButton.icon(
            onPressed: _promptFinalSubmitConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            icon: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 16),
            label: const Text(
              "Final Submit",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionNavigationGrid(bool isDark, Color cardColor, Color bodyColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.start,
        children: List.generate(_questions.length, (idx) {
          final bool isActive = _currentQuestionIndex == idx;
          final bool isAnswered = _selectedAnswers.containsKey(idx);

          Color cellBg = Colors.transparent;
          Color cellBorder = isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1);
          Color digitColor = bodyColor;

          if (isActive) {
            cellBg = const Color(0xFF6366F1).withOpacity(0.1);
            cellBorder = const Color(0xFF6366F1);
            digitColor = const Color(0xFF6366F1);
          } else if (isAnswered) {
            cellBg = const Color(0xFF6366F1);
            cellBorder = const Color(0xFF6366F1);
            digitColor = Colors.white;
          }

          return InkWell(
            onTap: () {
              setState(() {
                _currentQuestionIndex = idx;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: cellBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cellBorder,
                  width: isActive ? 2.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  "${idx + 1}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: digitColor,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomNavigationBar(bool isDark, Color cardColor) {
    final bool isFirst = _currentQuestionIndex == 0;
    final bool isLast = _currentQuestionIndex == _questions.length - 1;

    return Container(
      color: cardColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Row(
        children: [
          // Previous button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isFirst
                  ? null
                  : () {
                      setState(() {
                        _currentQuestionIndex--;
                      });
                    },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFCBD5E1),
                ),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text(
                "Previous",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Next / Finished button
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (isLast) {
                  _promptFinalSubmitConfirm();
                } else {
                  setState(() {
                    _currentQuestionIndex++;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLast ? "Review Submit" : "Next Question",
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isLast ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. THE RESULT SCREEN ---
  Widget _buildResultScreen(bool isDark, Color cardColor, Color titleColor, Color bodyColor) {
    final int totalQ = _questions.length;
    final double successPercentage = totalQ > 0 ? (_score / totalQ) * 100 : 0.0;
    final double fractionDecimal = totalQ > 0 ? (_score / totalQ) : 0.0;

    // Filter questions that were answered incorrectly or skipped altogether
    final List<Map<String, dynamic>> wrongQuestionList = [];
    for (int i = 0; i < totalQ; i++) {
      final q = _questions[i];
      final selectedOpt = _selectedAnswers[i];
      
      final bool isCorrect = selectedOpt != null && _isOptionCorrect(q, q.options[selectedOpt], selectedOpt);
      if (!isCorrect) {
        wrongQuestionList.add({
          'index': i,
          'question': q,
          'selected': selectedOpt,
        });
      }
    }

    // Set feedback title based on the result
    String bannerFeedback = "Excellent performance!";
    IconData bannerIcon = Icons.emoji_events_rounded;
    Color scoreColor = const Color(0xFF10B981); // Green

    if (successPercentage < 50) {
      bannerFeedback = "Keep practicing!";
      bannerIcon = Icons.auto_stories_rounded;
      scoreColor = const Color(0xFFEF4444); // Red
    } else if (successPercentage < 80) {
      bannerFeedback = "Good milestone reached!";
      bannerIcon = Icons.thumb_up_rounded;
      scoreColor = const Color(0xFFF59E0B); // Amber
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Column(
        children: [
          
          // Performance overview card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(bannerIcon, size: 40, color: scoreColor),
                const SizedBox(height: 12),
                Text(
                  bannerFeedback,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: titleColor, letterSpacing: -0.3),
                ),
                Text(
                  "Mock examination summary statistics",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: bodyColor),
                ),
                const SizedBox(height: 24),

                // Circular Progress indicator
                CircularPercentIndicator(
                  radius: 75.0,
                  lineWidth: 12.0,
                  percent: fractionDecimal.clamp(0.0, 1.0),
                  animation: true,
                  animationDuration: 1000,
                  circularStrokeCap: CircularStrokeCap.round,
                  backgroundColor: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                  linearGradient: LinearGradient(
                    colors: [scoreColor, scoreColor.withOpacity(0.5)],
                  ),
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${successPercentage.toStringAsFixed(0)}%",
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: titleColor),
                      ),
                      Text(
                        "$_score / $totalQ Correct",
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: bodyColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick statistics chips grid
                Row(
                  children: [
                    _buildMetricsCard(isDark, const Color(0xFF10B981), "Correct", "$_totalCorrect", Icons.check_circle_rounded),
                    const SizedBox(width: 10),
                    _buildMetricsCard(isDark, const Color(0xFFEF4444), "Incorrect", "$_totalWrong", Icons.cancel_rounded),
                    const SizedBox(width: 10),
                    _buildMetricsCard(isDark, Colors.orangeAccent, "Unanswered", "$_totalUnanswered", Icons.warning_rounded),
                  ],
                ),

                const SizedBox(height: 24),

                // Premium action button: screenshot-ready Telegram export
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0088CC), // Telegram blue
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _triggerFullExamReport,
                    icon: const Icon(Icons.telegram_rounded, color: Colors.white, size: 21),
                    label: const Text(
                      "Share Score to Telegram Support",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Header for "List of Failed Questions"
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(Icons.report_gmailerrorred_rounded, size: 18, color: scoreColor),
                const SizedBox(width: 8),
                Text(
                  wrongQuestionList.isEmpty ? "No Failed Challenges!" : "Review Exam Mistakes (${wrongQuestionList.length})",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // List of wrong/failed answers with explanations
          if (wrongQuestionList.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.15)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.celebration_rounded, color: Color(0xFF10B981), size: 32),
                  const SizedBox(height: 10),
                  const Text(
                    "Flawless Academic Victory!",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "You achieved 100% on this unit model mock test.",
                    style: TextStyle(fontSize: 11, color: bodyColor, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: wrongQuestionList.length,
              itemBuilder: (context, mapIndex) {
                final map = wrongQuestionList[mapIndex];
                final int originalIdx = map['index'];
                final QuestionModel q = map['question'];
                final int? selOptIdx = map['selected'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "CHALLENGE #${originalIdx + 1}",
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          
                          // Question reporting link 
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.outlined_flag, color: Color(0xFFEF4444), size: 16),
                            onPressed: () => _triggerQuestionIssueReport(q, originalIdx),
                            tooltip: "Send correction details for this challenge",
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Question Body
                      Text(
                        q.questionText,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // User choice VS correct answer
                      _buildMistakeRow(
                        label: "Your Response",
                        value: selOptIdx != null ? q.options[selOptIdx] : "Unanswered (No Selection)",
                        color: const Color(0xFFEF4444),
                        icon: Icons.cancel_rounded,
                      ),
                      const SizedBox(height: 8),
                      _buildMistakeRow(
                        label: "Solution Correct Key",
                        value: q.correctAnswer,
                        color: const Color(0xFF10B981),
                        icon: Icons.check_circle_rounded,
                      ),

                      // Rationale
                      if (q.explanation != null && q.explanation!.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.lightbulb_rounded, size: 14, color: Color(0xFFF59E0B)),
                                  SizedBox(width: 4),
                                  Text(
                                    "Rationale & Rationale Breakdown:",
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFD97706)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                q.explanation!,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 24),

          // Actions to restart or exit
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loadExamQuestions,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1)),
                  ),
                  child: const Text("Reset Session", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Exit Statistics", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMetricsCard(bool isDark, Color baseColor, String title, String val, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: baseColor, size: 16),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: baseColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildMistakeRow({required String label, required String value, required Color color, required IconData icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              children: [
                TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: value, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
