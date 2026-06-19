import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/question_model.dart';
import '../services/quiz_service.dart';

class ListQuizScreen extends StatefulWidget {
  final int grade;
  final String? subject;
  final int? unit;

  const ListQuizScreen({
    super.key,
    required this.grade,
    this.subject,
    this.unit,
  });

  @override
  State<ListQuizScreen> createState() => _ListQuizScreenState();
}

class _ListQuizScreenState extends State<ListQuizScreen> {
  List<QuestionModel> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Track user selections: Map<QuestionIndex, SelectedOptionIndex>
  final Map<int, int> _selectedAnswers = {};
  bool _isSubmitted = false;
  int _score = 0;
  int _unlockedCount = 1; // Default to revealing Question 1 only initially
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadQuestions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedAnswers.clear();
      _isSubmitted = false;
      _score = 0;
      _unlockedCount = 1;
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

  void _submitQuiz() {
    int finalScore = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers.containsKey(i)) {
        final q = _questions[i];
        final selectedIdx = _selectedAnswers[i]!;
        if (_isOptionCorrect(q, q.options[selectedIdx], selectedIdx)) {
          finalScore++;
        }
      }
    }

    setState(() {
      _score = finalScore;
      _isSubmitted = true;
      _unlockedCount = _questions.length; // Unlock all upon submission for review
    });

    // Scroll smoothly to bottom results summary
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _resetQuiz() {
    setState(() {
      _selectedAnswers.clear();
      _isSubmitted = false;
      _score = 0;
      _unlockedCount = 1;
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  // Pre-filled Telegram report module
  Future<void> _reportQuestion(int index, QuestionModel q) async {
    final String subjectName = widget.subject ?? "General";
    final String message = "⚠️ Smart X Academy • Question Report\n\n"
        "• Grade: ${widget.grade}\n"
        "• Subject: $subjectName\n"
        "• Unit: ${widget.unit ?? 'General'}\n"
        "• Question #${index + 1}: \"${q.questionText}\"\n\n"
        "• Issue description: [Please type details here]";

    final telegramUrl = Uri.parse("https://t.me/SmartXAcademySupport?text=${Uri.encodeComponent(message)}");

    try {
      if (await canLaunchUrl(telegramUrl)) {
        await launchUrl(telegramUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Unable to launch Telegram. Please make sure the Telegram app is installed on your device."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error launching report: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // PDF Report generation using pdf and printing packages
  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();

    try {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainpw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "Smart X Academy",
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo900,
                      ),
                    ),
                    pw.Text(
                      "QUIZ EXAM REPORT",
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),

              // Metrics Dashboard
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo50,
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: PdfColors.indigo100, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Performance Metrics",
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo900,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainpw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Grade Level: Grade ${widget.grade}", style: pw.TextStyle(fontSize: 10)),
                        pw.Text("Subject Name: ${widget.subject?.toUpperCase() ?? 'GENERAL'}", style: pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainpw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Unit / Chapter: ${widget.unit ?? 'General'}", style: pw.TextStyle(fontSize: 10)),
                        pw.Text(
                          "Score achieved: $_score / ${_questions.length} (${((_score / _questions.length) * 100).toStringAsFixed(0)}%)",
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: _score >= _questions.length / 2 ? PdfColors.green900 : PdfColors.red900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              pw.Text(
                "Detailed Performance Review",
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900,
                ),
              ),
              pw.Divider(color: PdfColors.indigo400, thickness: 1),
              pw.SizedBox(height: 10),

              // Question results list
              ...List.generate(_questions.length, (idx) {
                final q = _questions[idx];
                final selectedOpt = _selectedAnswers[idx];
                final isCorrect = selectedOpt != null && _isOptionCorrect(q, q.options[selectedOpt], selectedOpt);

                final String userAns = selectedOpt != null ? q.options[selectedOpt] : "No Answer";
                final String correctAns = q.correctAnswer;

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: isCorrect ? PdfColors.green50 : PdfColors.red50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(
                      color: isCorrect ? PdfColors.green100 : PdfColors.red100,
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainpw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            "Question ${idx + 1}",
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 11,
                              color: PdfColors.blueGrey800,
                            ),
                          ),
                          pw.Text(
                            isCorrect ? "CORRECT" : "INCORRECT",
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                              color: isCorrect ? PdfColors.green800 : PdfColors.red800,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(q.questionText, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.Text("Your Response: ", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                          pw.Text(userAns, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: isCorrect ? PdfColors.green900 : PdfColors.red900)),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        children: [
                          pw.Text("Correct Response: ", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                          pw.Text(correctAns, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                        ],
                      ),
                      if (q.explanation != null && q.explanation!.trim().isNotEmpty) ...[
                        pw.SizedBox(height: 6),
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.amber50,
                            border: pw.Border.all(color: PdfColors.amber100),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                "RATIONALE / EXPLANATION:",
                                style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(q.explanation!, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: "SmartX_Report_Grade${widget.grade}_${widget.subject ?? 'General'}.pdf",
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error creating PDF document: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final backgroundColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final cardColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final titleTextColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final bodyTextColor = isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.subject != null
              ? "${widget.subject!.toUpperCase()} - Quiz List"
              : "Traditional Exam",
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
        ),
        elevation: 0,
        backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
        foregroundColor: titleTextColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
               ? _buildErrorWidget(isLight)
               : _questions.isEmpty
                   ? _buildEmptyQuestionsWidget(bodyTextColor)
                   : _buildExamContent(isLight, cardColor, titleTextColor, bodyTextColor),
    );
  }

  Widget _buildErrorWidget(bool isLight) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.indigo, size: 48),
            const SizedBox(height: 16),
            const Text(
              "Offline Quiz Load Helper",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
              child: const Text("Retry Load", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQuestionsWidget(Color textColor) {
    return Center(
      child: Text(
        "No challenges exist inside this Unit.",
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildExamContent(bool isLight, Color cardColor, Color titleColor, Color bodyColor) {
    final int totalQuestions = _questions.length;
    final int totalAnswered = _selectedAnswers.length;
    final double completionPercent = totalQuestions > 0 ? (totalAnswered / totalQuestions) : 0.0;

    return Column(
      children: [
        // Sleek Linear Progress tracker banner at top
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isLight ? Colors.white : const Color(0xFF1E293B),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isLight ? 0.02 : 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isSubmitted ? "Exam Completed" : "Academic Progress",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isLight ? const Color(0xFF1E293B) : Colors.white,
                    ),
                  ),
                  Text(
                    _isSubmitted
                        ? "Score: $_score / $totalQuestions"
                        : "Answered: $totalAnswered of $totalQuestions",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _isSubmitted
                          ? (_score >= totalQuestions / 2 ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                          : const Color(0xFF4F46E5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _isSubmitted ? 1.0 : completionPercent,
                  backgroundColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
                  color: _isSubmitted
                      ? (_score >= totalQuestions / 2 ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                      : const Color(0xFF4F46E5),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),

        // Scrollable list displaying all standard academic challenge cards
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: totalQuestions + 1, // Additional index for results dashboard
            itemBuilder: (context, index) {
              if (index == totalQuestions) {
                return _buildBottomSummaryWidget(isLight, cardColor, titleColor, bodyColor);
              }

              final q = _questions[index];
              final qNum = (index + 1) < 10 ? '0${index + 1}' : '${index + 1}';

              // Reveal condition: Lock questions after current unlocked pointer
              final bool isLocked = !_isSubmitted && (index >= _unlockedCount);

              final cardChild = Container(
                padding: const EdgeInsets.all(22.0),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isLight ? 0.025 : 0.1),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "$qNum.",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF4F46E5),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "QUESTION",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: bodyColor.withOpacity(0.8),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const Spacer(),
                        // Telegram Report flags button
                        TextButton.icon(
                          onPressed: () => _reportQuestion(index, q),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFE2E8F0),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.outlined_flag_rounded, size: 14, color: Color(0xFFE11D48)),
                          label: const Text(
                            "Report",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE11D48),
                            ),
                          ),
                        ),
                        if (_isSubmitted) ...[
                          const SizedBox(width: 8),
                          _buildQuestionStatusIndicator(q, index),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Question body representation in responsive typography
                    Text(
                      q.questionText,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // List choice options
                    ...q.options.asMap().entries.map((entry) {
                      final optIdx = entry.key;
                      final optionText = entry.value;
                      final String charLabel = String.fromCharCode(65 + optIdx); // A, B, C, D

                      final isSelected = _selectedAnswers[index] == optIdx;
                      final isCorrect = _isOptionCorrect(q, optionText, optIdx);

                      Color optionBorderColor = isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155);
                      Color optionBgColor = Colors.transparent;
                      Color optionTextColor = bodyColor;

                      if (_isSubmitted) {
                        if (isCorrect) {
                          optionBorderColor = const Color(0xFF10B981);
                          optionBgColor = const Color(0xFF10B981).withOpacity(isLight ? 0.08 : 0.15);
                          optionTextColor = const Color(0xFF10B981);
                        } else if (isSelected) {
                          optionBorderColor = const Color(0xFFEF4444);
                          optionBgColor = const Color(0xFFEF4444).withOpacity(isLight ? 0.08 : 0.15);
                          optionTextColor = const Color(0xFFEF4444);
                        }
                      } else if (isSelected) {
                        optionBorderColor = const Color(0xFF4F46E5);
                        optionBgColor = const Color(0xFF4F46E5).withOpacity(isLight ? 0.06 : 0.1);
                        optionTextColor = const Color(0xFF4F46E5);
                      }

                      return GestureDetector(
                        onTap: _isSubmitted
                            ? null
                            : () {
                                setState(() {
                                  _selectedAnswers[index] = optIdx;
                                  // Reveal next question with slide-down transition
                                  if (index + 1 >= _unlockedCount && index + 1 < _questions.length) {
                                    _unlockedCount = index + 2;
                                    Future.delayed(const Duration(milliseconds: 600), () {
                                      if (_scrollController.hasClients) {
                                        _scrollController.animateTo(
                                          _scrollController.offset + 220,
                                          duration: const Duration(milliseconds: 600),
                                          curve: Curves.easeOutCubic,
                                        );
                                      }
                                    });
                                  }
                                });
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12.0),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                          decoration: BoxDecoration(
                            color: optionBgColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: optionBorderColor,
                              width: isSelected ? 2.5 : 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (_isSubmitted
                                          ? (isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                          : const Color(0xFF4F46E5))
                                      : (isLight ? const Color(0xFFF8FAFC) : const Color(0xFF334155)),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF475569)),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    charLabel,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : bodyColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
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
                                    color: optionTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),

                    if (_isSubmitted && q.explanation != null && q.explanation!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lightbulb_rounded, size: 16, color: Color(0xFFF59E0B)),
                                SizedBox(width: 6),
                                Text(
                                  "Answer Rationale",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              q.explanation!,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.45,
                                color: isLight ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );

              return _QuestionCardWrapper(
                index: index,
                isLocked: isLocked,
                unlockedChild: cardChild,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionStatusIndicator(QuestionModel q, int index) {
    final selected = _selectedAnswers[index];
    final bool isCorrect = selected != null && _isOptionCorrect(q, q.options[selected], selected);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFF10B981).withOpacity(0.12) : const Color(0xFFEF4444).withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCorrect ? Icons.check_rounded : Icons.close_rounded,
            color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            isCorrect ? "Correct" : "Incorrect",
            style: TextStyle(
              color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // BOTTOM RESULTS DASHBOARD & SCORE CHECKLIST
  Widget _buildBottomSummaryWidget(bool isLight, Color cardColor, Color titleColor, Color bodyColor) {
    final int totalQuestions = _questions.length;
    final int totalAnswered = _selectedAnswers.length;

    if (_isSubmitted) {
      final double scorePercentage = totalQuestions > 0 ? (_score / totalQuestions) * 100 : 0.0;
      int masterStars = 1;
      if (_score == totalQuestions) masterStars = 3;
      else if (_score >= totalQuestions / 2) masterStars = 2;

      return Container(
        margin: const EdgeInsets.only(top: 8.0, bottom: 20.0),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isLight ? 0.04 : 0.15),
              blurRadius: 18,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 44,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Results Dashboard",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            const Text(
              "Here is an overview of your quiz performance",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (idx) {
                final isLit = idx < masterStars;
                return Icon(
                  Icons.star_rounded,
                  size: 34,
                  color: isLit ? const Color(0xFFF59E0B) : Colors.grey[300],
                );
              }),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF334155).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Total Score",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$_score / $totalQuestions",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF334155).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Success Rate",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${scorePercentage.toStringAsFixed(0)}%",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Correct/Wrong List and Explanations Review
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.analytics_outlined, color: Color(0xFF4F46E5), size: 18),
                const SizedBox(width: 8),
                Text(
                  "Explanations Checklist",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalQuestions,
              itemBuilder: (context, idx) {
                final q = _questions[idx];
                final selectedOpt = _selectedAnswers[idx];
                final isCorrect = selectedOpt != null && _isOptionCorrect(q, q.options[selectedOpt], selectedOpt);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: isLight
                        ? (isCorrect ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE))
                        : (isCorrect ? const Color(0xFF1B5E20).withOpacity(0.15) : const Color(0xFFB71C1C).withOpacity(0.15)),
                    border: Border.all(
                      color: isCorrect ? const Color(0xFF81C784) : const Color(0xFFE57373),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Challenge #${idx + 1} • ${isCorrect ? 'Correct' : 'Incorrect'}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        q.questionText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Rich details
                      RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 11.5, color: bodyColor),
                          children: [
                            const TextSpan(text: "Your Answer: ", style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(
                              text: selectedOpt != null ? q.options[selectedOpt] : "Unanswered",
                              style: TextStyle(
                                color: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 11.5, color: bodyColor),
                          children: [
                            const TextSpan(text: "Correct Solution: ", style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(
                              text: q.correctAnswer,
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (q.explanation != null && q.explanation!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Rationale details:",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                q.explanation!,
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.35,
                                  color: bodyColor,
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

            const SizedBox(height: 24),
            // Premium PDF Download Report button
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE11D48), Color(0xFFBE123C)], // Royal Red PDF Gradient scheme
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE11D48).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _generatePdfReport,
                  borderRadius: BorderRadius.circular(16),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Download Results PDF",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _resetQuiz,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                      ),
                      child: const Text(
                        "Retry Exam",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        "Exit Review",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      final bool hasUnanswered = totalAnswered < totalQuestions;

      return Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: totalAnswered == 0
                    ? [Colors.grey.shade400, Colors.grey.shade500]
                    : [const Color(0xFF4F46E5), const Color(0xFF3730A3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: totalAnswered == 0
                  ? []
                  : [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      )
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: totalAnswered == 0 ? null : _submitQuiz,
                borderRadius: BorderRadius.circular(18),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hasUnanswered
                            ? "Submit Exam ($totalAnswered of $totalQuestions)"
                            : "Submit Exam",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (hasUnanswered && totalAnswered > 0) ...[
            const SizedBox(height: 8),
            Text(
              "Note: You have left ${totalQuestions - totalAnswered} questions unanswered.",
              style: const TextStyle(
                fontSize: 11.5,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      );
    }
  }
}

// PREMIUM REVEAL AND LIFT ANIMATION WRAPPER FOR INDIVIDUAL CARD
class _QuestionCardWrapper extends StatefulWidget {
  final int index;
  final Widget unlockedChild;
  final bool isLocked;

  const _QuestionCardWrapper({
    super.key,
    required this.index,
    required this.unlockedChild,
    required this.isLocked,
  });

  @override
  State<_QuestionCardWrapper> createState() => _QuestionCardWrapperState();
}

class _QuestionCardWrapperState extends State<_QuestionCardWrapper> with TickerProviderStateMixin {
  late AnimationController _revealController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _wasLocked = true;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeIn,
    );

    _wasLocked = widget.isLocked;
    if (!widget.isLocked) {
      _revealController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_QuestionCardWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLocked && !widget.isLocked) {
      _revealController.value = 0.0;
      _revealController.forward();
      _wasLocked = false;
    } else if (!oldWidget.isLocked && widget.isLocked) {
      _revealController.value = 0.0;
      _wasLocked = true;
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLocked) {
      return _buildLockedPlaceholder();
    }

    if (_revealController.isAnimating || _revealController.value < 1.0) {
      return SizeTransition(
        sizeFactor: _slideAnimation,
        axisAlignment: -1.0,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: widget.unlockedChild,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: widget.unlockedChild,
    );
  }

  Widget _buildLockedPlaceholder() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBgColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final descColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBgColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLight ? const Color(0xFFEDF2F7).withOpacity(0.6) : const Color(0xFF334155).withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isLight ? 0.02 : 0.08),
            blurRadius: 10,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(22.0),
              child: Opacity(
                opacity: 0.12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 12,
                      width: 70,
                      decoration: BoxDecoration(
                        color: isLight ? Colors.black38 : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isLight ? Colors.black38 : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(3, (i) => Container(
                      height: 44,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isLight ? Colors.black12 : Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    )),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.35), width: 1.2),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF4F46E5),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Challenge #${widget.index + 1} Locked",
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: isLight ? const Color(0xFF334155) : Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Solve the previous challenge to unlock.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: descColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
