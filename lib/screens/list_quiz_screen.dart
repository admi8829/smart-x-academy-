import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedAnswers.clear();
      _isSubmitted = false;
      _score = 0;
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
    });
  }

  void _resetQuiz() {
    setState(() {
      _selectedAnswers.clear();
      _isSubmitted = false;
      _score = 0;
    });
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
              ? "${widget.subject!.toUpperCase()} - List Exam"
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

  // EXAMS GRAPHICAL CONTENT SCROLLER
  Widget _buildExamContent(bool isLight, Color cardColor, Color titleColor, Color bodyColor) {
    // Elegant details calculated
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: totalQuestions + 1, // Additional index for beautiful result overview/submit action at button
            itemBuilder: (context, index) {
              if (index == totalQuestions) {
                // Return submission summary dashboard card or trigger action button
                return _buildBottomSummaryWidget(isLight, cardColor, titleColor, bodyColor);
              }

              final q = _questions[index];
              final qNum = (index + 1) < 10 ? '0${index + 1}' : '${index + 1}';

              return Container(
                margin: const EdgeInsets.only(bottom: 20.0),
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
                    // Heading tracking bubble with stylish index layout
                    Row(
                      children: [
                        Text(
                          "$qNum.",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w950,
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
                        if (_isSubmitted)
                          _buildQuestionStatusIndicator(q, index),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Academic question body representation in crisp bold typeface
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

                    // Display choices vertically in spacious format
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
                              // Pure custom alphabet bubbles
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

                    // Sleek professional tutor tips & translation reference overlay block
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
            },
          ),
        ),
      ],
    );
  }

  // Render question correct/failed layout check indicator badge
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

  // BOTTOM CARD SUMMARY OR ACTION gradButton FORM
  Widget _buildBottomSummaryWidget(bool isLight, Color cardColor, Color titleColor, Color bodyColor) {
    final int totalQuestions = _questions.length;
    final int totalAnswered = _selectedAnswers.length;

    if (_isSubmitted) {
      // Review details dashboard metric evaluation
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
              color: Colors.black.withOpacity(isLight ? 0.03 : 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
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
                Icons.assignment_turned_in_rounded,
                size: 40,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Exam Result Summary",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w950, letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (idx) {
                final isLit = idx < masterStars;
                return Icon(
                  Icons.star_rounded,
                  size: 30,
                  color: isLit ? const Color(0xFFF59E0B) : Colors.grey[300],
                );
              }),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF334155).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Correct Answers",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$_score / $totalQuestions",
                          style: const TextStyle(
                            fontSize: 16,
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
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF334155).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Academy Grade",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${scorePercentage.toStringAsFixed(0)}%",
                          style: const TextStyle(
                            fontSize: 16,
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
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _resetQuiz,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      // Large Centered solid gradient submit actions button
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
                          fontWeight: FontWeight.w950,
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
