import 'dart:async';
import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../services/quiz_service.dart';

class GamifiedQuizScreen extends StatefulWidget {
  final int grade;
  final String? subject;
  final int? unit;

  const GamifiedQuizScreen({
    super.key,
    required this.grade,
    this.subject,
    this.unit,
  });

  @override
  State<GamifiedQuizScreen> createState() => _GamifiedQuizScreenState();
}

class _GamifiedQuizScreenState extends State<GamifiedQuizScreen> with SingleTickerProviderStateMixin {
  List<QuestionModel> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _currentIndex = 0;
  int _lives = 3;
  int _score = 0;
  bool _gameOver = false;
  bool _victory = false;

  // Selected option index for contemporary question
  int? _selectedIdx;
  bool _isChecked = false;

  // Question Timer state
  Timer? _questionTimer;
  int _timeLeft = 30; // 30 seconds per question
  final int _maxTime = 30;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  void _startTimer() {
    _cancelTimer();
    setState(() {
      _timeLeft = _maxTime;
    });

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_gameOver || _victory) {
        _cancelTimer();
        return;
      }

      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _cancelTimer();
          _handleTimeOut();
        }
      });
    });
  }

  void _cancelTimer() {
    _questionTimer?.cancel();
    _questionTimer = null;
  }

  void _handleTimeOut() {
    // Force answer checking as wrong
    setState(() {
      _isChecked = true;
      _lives--;
      if (_lives <= 0) {
        _gameOver = true;
      }
    });

    // Notify student about expiration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Time's up! You lost 1 life ❤️"),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _gameOver = false;
      _victory = false;
      _lives = 3;
      _score = 0;
      _currentIndex = 0;
      _selectedIdx = null;
      _isChecked = false;
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

      if (fetched.isNotEmpty) {
        _startTimer();
      }
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

  void _checkChoice() {
    if (_selectedIdx == null || _isChecked) return;
    _cancelTimer();

    final q = _questions[_currentIndex];
    final bool isCorrect = _isOptionCorrect(q, q.options[_selectedIdx!], _selectedIdx!);

    setState(() {
      _isChecked = true;
      if (isCorrect) {
        _score++;
      } else {
        _lives--;
        if (_lives <= 0) {
          _gameOver = true;
        }
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedIdx = null;
        _isChecked = false;
      });
      _startTimer();
    } else {
      setState(() {
        _victory = true;
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
              ? "${widget.subject!.toUpperCase()} - Gamified Mode"
              : "Gamified Quiz",
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
                  : _gameOver
                      ? _buildGameOverWidget(isLight, cardColor, titleTextColor)
                      : _victory
                          ? _buildVictoryWidget(isLight, cardColor, titleTextColor)
                          : _buildGameplayWidget(isLight, cardColor, titleTextColor, descTextColor),
    );
  }

  Widget _buildErrorWidget(bool isLight) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.amber, size: 48),
            const SizedBox(height: 16),
            const Text("Offline Setup Check", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? "", style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQuestions,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
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
        "No challenges exist for this unit.",
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  // GAME OVER SCREEN WIDGET
  Widget _buildGameOverWidget(bool isLight, Color cardColor, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.heart_broken_rounded, size: 72, color: Colors.red),
          ),
          const SizedBox(height: 24),
          Text(
            "Game Over!",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          const Text(
            "You ran out of hearts. Learn from solutions and try again to master this subject!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5, color: Colors.grey, height: 1.45, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(0.32)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn("Your Score", "$_score / ${_questions.length}", Colors.amber),
                _buildStatColumn("Progress", "${((_currentIndex / _questions.length) * 100).toStringAsFixed(0)}%", Colors.blue),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Exit Style", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _loadQuestions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: const Text("Try Again", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // VICTORY SCREEN WIDGET
  Widget _buildVictoryWidget(bool isLight, Color cardColor, Color textColor) {
    // Calculation of stars earned
    int ratingStars = 1;
    if (_lives == 3) ratingStars = 3;
    else if (_lives == 2) ratingStars = 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded, size: 72, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (idx) {
              final isFilled = idx < ratingStars;
              return Icon(
                Icons.star_rounded,
                size: 40,
                color: isFilled ? const Color(0xFFF59E0B) : Colors.grey[400],
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            "Victory!",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          const Text(
            "Sensational work! You successfully survived the dynamic gamified challenge.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.32)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn("Final Score", "$_score / ${_questions.length}", Colors.green),
                _buildStatColumn("Bonus Lives Left", "❤️ x $_lives", Colors.redAccent),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: const Text("Finish & Collect Points", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String heading, String content, Color contentColor) {
    return Column(
      children: [
        Text(heading, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        Text(content, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: contentColor)),
      ],
    );
  }

  // CORE GAMEPLAY CONTAINER
  Widget _buildGameplayWidget(bool isLight, Color cardColor, Color textColor, Color descColor) {
    final q = _questions[_currentIndex];
    final double timePercent = _timeLeft / _maxTime;

    return Column(
      children: [
        // 1. Timer indicator bar directly under the header
        Column(
          children: [
            LinearProgressIndicator(
              value: timePercent,
              backgroundColor: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              color: _timeLeft <= 8 ? Colors.red : const Color(0xFFF59E0B),
              minHeight: 6,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        "$_timeLeft s",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFF59E0B)),
                      ),
                    ],
                  ),
                  Row(
                    children: List.generate(3, (idx) {
                      final bool isHeartFilled = idx < _lives;
                      return Icon(
                        isHeartFilled ? Icons.favorite : Icons.favorite_border,
                        color: Colors.redAccent,
                        size: 20,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Questions single frame panel
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isLight ? 0.03 : 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Question ${_currentIndex + 1} of ${_questions.length}",
                          style: const TextStyle(
                            color: Color(0xFFD97706),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    q.questionText,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...q.options.asMap().entries.map((entry) {
                    final optIdx = entry.key;
                    final optionText = entry.value;

                    final isSelected = _selectedIdx == optIdx;
                    final isCorrect = _isOptionCorrect(q, optionText, optIdx);

                    Color optBorder = isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155);
                    Color optBg = Colors.transparent;
                    Color optTextColor = descColor;

                    if (_isChecked) {
                      if (isCorrect) {
                        optBorder = Colors.green;
                        optBg = Colors.green.withOpacity(isLight ? 0.08 : 0.15);
                        optTextColor = Colors.green;
                      } else if (isSelected) {
                        optBorder = Colors.red;
                        optBg = Colors.red.withOpacity(isLight ? 0.08 : 0.15);
                        optTextColor = Colors.red;
                      }
                    } else if (isSelected) {
                      optBorder = const Color(0xFFF59E0B);
                      optBg = const Color(0xFFF59E0B).withOpacity(isLight ? 0.05 : 0.1);
                      optTextColor = const Color(0xFFF59E0B);
                    }

                    return GestureDetector(
                      onTap: _isChecked
                          ? null
                          : () {
                              setState(() {
                                _selectedIdx = optIdx;
                              });
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12.0),
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: optBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: optBorder, width: isSelected ? 2.0 : 1.2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (_isChecked
                                        ? (isCorrect ? Colors.green : Colors.red)
                                        : const Color(0xFFF59E0B))
                                    : (isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155)),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + optIdx),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : descColor,
                                    fontSize: 12,
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
                                  color: optTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                  // Detailed answers solution feedback panel
                  if (_isChecked && q.explanation != null && q.explanation!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF10B981)),
                              SizedBox(width: 6),
                              Text(
                                "Tutor Insight",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            q.explanation!,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.4,
                              color: isLight ? const Color(0xFF0F5132) : const Color(0xFFD1E7DD),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Action controls bar bottom section of gameplay
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: _isChecked
                ? ElevatedButton.icon(
                    onPressed: _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text(
                      _currentIndex == _questions.length - 1 ? "Finish Quest" : "Next Question",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _selectedIdx == null ? null : _checkChoice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: _selectedIdx == null ? 0 : 3,
                    ),
                    child: const Text(
                      "Check Answer",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
