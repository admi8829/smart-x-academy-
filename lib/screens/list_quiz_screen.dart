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
    final bodyTextColor = isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.subject != null
              ? "${widget.subject!.toUpperCase()} - Traditional List"
              : "Traditional Quiz",
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
                  : _buildQuizContent(isLight, cardColor, titleTextColor, bodyTextColor),
    );
  }

  Widget _buildErrorWidget(bool isLight) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              "Oops, could not fetch unit questions",
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              child: const Text("Retry Connection", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQuestionsWidget(Color textColor) {
    return Center(
      child: Text(
        "No questions found for this unit.",
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildQuizContent(bool isLight, Color cardColor, Color titleColor, Color bodyColor) {
    return Column(
      children: [
        // Subtitle header summary showing questions list and progress
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: isLight ? Colors.white : const Color(0xFF1E293B).withOpacity(0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Questions: ${_questions.length}",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: bodyColor),
              ),
              Text(
                _isSubmitted 
                    ? "Result: $_score / ${_questions.length} (${((_score / _questions.length) * 100).toStringAsFixed(0)}%)"
                    : "Answered: ${_selectedAnswers.length} / ${_questions.length}",
                style: TextStyle(
                  fontSize: 13, 
                  fontWeight: FontWeight.w900, 
                  color: _isSubmitted 
                      ? (_score >= _questions.length / 2 ? Colors.green : Colors.red)
                      : const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),

        // Questions scrollable item list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _questions.length,
            itemBuilder: (context, qIndex) {
              final q = _questions[qIndex];
              return Container(
                margin: const EdgeInsets.only(bottom: 20.0),
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isSubmitted
                        ? (_selectedAnswers[qIndex] == null
                            ? Colors.amber.withOpacity(0.5)
                            : (_isOptionCorrect(q, q.options[_selectedAnswers[qIndex]!], _selectedAnswers[qIndex]!)
                                ? Colors.green.withOpacity(0.5)
                                : Colors.red.withOpacity(0.5)))
                        : (isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155)),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isLight ? 0.03 : 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question index tracking badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Question ${qIndex + 1}",
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (_isSubmitted)
                          Icon(
                            _selectedAnswers[qIndex] != null &&
                                    _isOptionCorrect(q, q.options[_selectedAnswers[qIndex]!], _selectedAnswers[qIndex]!)
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: _selectedAnswers[qIndex] != null &&
                                    _isOptionCorrect(q, q.options[_selectedAnswers[qIndex]!], _selectedAnswers[qIndex]!)
                                ? Colors.green
                                : Colors.red,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Question text representation
                    Text(
                      q.questionText,
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w900,
                        color: titleColor,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Option list elements
                    ...q.options.asMap().entries.map((entry) {
                      final optIdx = entry.key;
                      final optionText = entry.value;
                      final charLabel = String.fromCharCode(65 + optIdx); // A, B, C, D...
                      
                      final isSelected = _selectedAnswers[qIndex] == optIdx;
                      final isCorrect = _isOptionCorrect(q, optionText, optIdx);

                      Color optionBorderColor = isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155);
                      Color optionBgColor = Colors.transparent;
                      Color optionTextColor = bodyColor;

                      if (_isSubmitted) {
                        if (isCorrect) {
                          // Highlight actual correct answer always upon submit
                          optionBorderColor = Colors.green;
                          optionBgColor = Colors.green.withOpacity(isLight ? 0.08 : 0.15);
                          optionTextColor = Colors.green;
                        } else if (isSelected) {
                          // Highlight incorrect selection
                          optionBorderColor = Colors.red;
                          optionBgColor = Colors.red.withOpacity(isLight ? 0.08 : 0.15);
                          optionTextColor = Colors.red;
                        }
                      } else if (isSelected) {
                        optionBorderColor = const Color(0xFF10B981);
                        optionBgColor = const Color(0xFF10B981).withOpacity(isLight ? 0.05 : 0.1);
                        optionTextColor = const Color(0xFF10B981);
                      }

                      return GestureDetector(
                        onTap: _isSubmitted
                            ? null
                            : () {
                                setState(() {
                                  _selectedAnswers[qIndex] = optIdx;
                                });
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 10.0),
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                          decoration: BoxDecoration(
                            color: optionBgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: optionBorderColor, width: isSelected ? 2.0 : 1.2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (_isSubmitted
                                          ? (isCorrect ? Colors.green : Colors.red)
                                          : const Color(0xFF10B981))
                                      : (isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155)),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    charLabel,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : bodyColor,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  optionText,
                                  style: TextStyle(
                                    fontSize: 13,
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

                    // Show solution explanation once submitted
                    if (_isSubmitted && q.explanation != null && q.explanation!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lightbulb_rounded, size: 16, color: Color(0xFFF59E0B)),
                                SizedBox(width: 6),
                                Text(
                                  "Explanation / Tutor Tips",
                                  style: TextStyle(
                                    fontSize: 11.5,
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
                                fontSize: 11.5,
                                height: 1.4,
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

        // Bottom Submission Card control bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_isSubmitted)
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _resetQuiz,
                      borderRadius: BorderRadius.circular(20),
                      child: const Center(
                        child: Text(
                          "Retry / Reset Quiz",
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 15.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _selectedAnswers.isEmpty ? null : _submitQuiz,
                      borderRadius: BorderRadius.circular(20),
                      child: Center(
                        child: Text(
                          _selectedAnswers.length < _questions.length
                              ? "Submit Answered (${_selectedAnswers.length}/${_questions.length})"
                              : "Submit Quiz",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
