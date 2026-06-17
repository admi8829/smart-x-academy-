import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../services/quiz_service.dart';

class CardQuizScreen extends StatefulWidget {
  final int grade;
  final String? subject;
  final int? unit;

  const CardQuizScreen({
    super.key,
    required this.grade,
    this.subject,
    this.unit,
  });

  @override
  State<CardQuizScreen> createState() => _CardQuizScreenState();
}

class _CardQuizScreenState extends State<CardQuizScreen> {
  List<QuestionModel> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _currentIndex = 0;
  int? _selectedOptIdx;
  int _score = 0;
  bool _quizFinished = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentIndex = 0;
      _selectedOptIdx = null;
      _score = 0;
      _quizFinished = false;
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

  void _onOptionSelected(int idx) {
    setState(() {
      _selectedOptIdx = idx;
    });
  }

  void _nextQuestion() {
    if (_selectedOptIdx == null) return;

    // Score answer
    final q = _questions[_currentIndex];
    final isCorrect = _isOptionCorrect(q, q.options[_selectedOptIdx!], _selectedOptIdx!);
    if (isCorrect) {
      _score++;
    }

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptIdx = null;
      });
    } else {
      setState(() {
        _quizFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final backgroundColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final cardColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final titleTextColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final descTextColor = isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.subject != null
              ? "${widget.subject!.toUpperCase()} - Card Style"
              : "Card Practice",
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
                  ? _buildEmptyWidget(descTextColor)
                  : _quizFinished
                      ? _buildFinishedWidget(isLight, cardColor, titleTextColor)
                      : _buildQuizContentWidget(isLight, cardColor, titleTextColor, descTextColor),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
              child: const Text("Retry Quest", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(Color textColor) {
    return Center(
      child: Text(
        "No challenges exist inside this Unit.",
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildQuizContentWidget(bool isLight, Color cardColor, Color textColor, Color descColor) {
    final q = _questions[_currentIndex];
    final double progress = (_currentIndex + 1) / _questions.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // 1. Top Bar Tracker text and linear Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Question ${_currentIndex + 1} of ${_questions.length}",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: descColor,
                ),
              ),
              Text(
                "${(progress * 100).toStringAsFixed(0)}% Done",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              color: const Color(0xFF3B82F6),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 24),

          // 2. Main Body: Center a large white/dark Card with elegant rounded corners (borderRadius: 24) and soft shadow
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isLight ? 0.04 : 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic Subject unit bubble banner tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.subject != null ? widget.subject!.toUpperCase() : "QUIZ CARD",
                        style: const TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Question Text representation in crisp, bold display design
                    Text(
                      q.questionText,
                      style: TextStyle(
                        fontSize: 17.0,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Multi-choice vertical spacious options buttons
                    ...q.options.asMap().entries.map((entry) {
                      final optIdx = entry.key;
                      final optionText = entry.value;

                      final isSelected = _selectedOptIdx == optIdx;

                      final Color borderCol = isSelected
                          ? const Color(0xFF3B82F6)
                          : (isLight ? const Color(0xFFEDF2F7) : const Color(0xFF475569));
                      final Color bgCol = isSelected
                          ? const Color(0xFF3B82F6).withOpacity(isLight ? 0.06 : 0.1)
                          : Colors.transparent;
                      final Color txtCol = isSelected ? const Color(0xFF3B82F6) : descColor;

                      return GestureDetector(
                        onTap: () => _onOptionSelected(optIdx),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12.0),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                          decoration: BoxDecoration(
                            color: bgCol,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: borderCol,
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
                                      ? const Color(0xFF3B82F6)
                                      : (isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155)),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + optIdx),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : descColor,
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: txtCol,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),

          // 3. Action controller trigger: Sleek modern Next button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  gradient: _selectedOptIdx == null
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        ),
                  color: _selectedOptIdx == null
                      ? (isLight ? const Color(0xFFCBD5E1) : const Color(0xFF334155))
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _selectedOptIdx == null
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _selectedOptIdx == null ? null : _nextQuestion,
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: Text(
                        "Next Question ->",
                        style: TextStyle(
                          color: _selectedOptIdx == null
                              ? (isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                              : Colors.white,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // QUIZ FINISHED CELEBRATION WIDGET
  Widget _buildFinishedWidget(bool isLight, Color cardColor, Color textColor) {
    int earnedStars = 1;
    if (_score == _questions.length) earnedStars = 3;
    else if (_score >= _questions.length / 2) earnedStars = 2;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars_rounded, size: 72, color: Color(0xFF3B82F6)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (idx) {
                  final isLit = idx < earnedStars;
                  return Icon(
                    Icons.star_rounded,
                    size: 40,
                    color: isLit ? const Color(0xFFF59E0B) : Colors.grey[400],
                  );
                }),
              ),
              const SizedBox(height: 20),
              Text(
                "Challenge Completed!",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              const Text(
                "Awesome job polishing your memory with this quiz! Proceed with other styles or try again to attain a master class perfection.",
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCompletedCol("Score achieved", "$_score / ${_questions.length}", const Color(0xFF10B981)),
                    _buildCompletedCol("Mastery Level", "${((_score / _questions.length) * 100).toStringAsFixed(0)}%", const Color(0xFF3B82F6)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loadQuestions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: const Text("Practise Again", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: BorderSide(color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Exit Style", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedCol(String title, String val, Color highlight) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: highlight)),
      ],
    );
  }
}
