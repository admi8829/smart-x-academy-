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

class _GamifiedQuizScreenState extends State<GamifiedQuizScreen> {
  List<QuestionModel> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _currentIndex = 0;
  int _lives = 3;
  int _score = 0;
  bool _gameOver = false;
  bool _victory = false;

  // Selected option index for the current question
  int? _selectedIdx;
  bool _isChecked = false;

  // Question Timer state
  Timer? _questionTimer;
  int _timeLeft = 25; // 25 seconds per question
  final int _maxTime = 25;

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
    setState(() {
      _isChecked = true;
      _lives--;
      if (_lives <= 0) {
        _gameOver = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Time is up! You lost 1 life ❤️"),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
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
    final cardBgColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final titleTextColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final descTextColor = isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF9000)))
          : _errorMessage != null
              ? _buildErrorWidget(isLight)
              : _questions.isEmpty
                  ? _buildEmptyWidget(descTextColor)
                  : _gameOver
                      ? _buildGameOverWidget(isLight, cardBgColor, titleTextColor)
                      : _victory
                          ? _buildVictoryWidget(isLight, cardBgColor, titleTextColor)
                          : _buildGameplayWidget(isLight, cardBgColor, titleTextColor, descTextColor),
    );
  }

  Widget _buildErrorWidget(bool isLight) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt_rounded, color: Color(0xFFFF9000), size: 56),
            const SizedBox(height: 16),
            const Text(
              "Challenge Interrupted",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? "",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadQuestions,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9000),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("Retry Load", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.explore_outlined, color: Colors.grey, size: 48),
          const SizedBox(height: 12),
          Text(
            "No queries found for this module.",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Go Back"),
          ),
        ],
      ),
    );
  }

  // GAME OVER SCREEN
  Widget _buildGameOverWidget(bool isLight, Color cardColor, Color textColor) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.heart_broken_rounded, size: 80, color: Colors.redAccent),
            ),
            const SizedBox(height: 28),
            Text(
              "Out of Lives!",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.8),
            ),
            const SizedBox(height: 12),
            const Text(
              "You ran out of hearts. Learn from the incorrect choices, recharge, and strive to conquer this module!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, color: Colors.grey, height: 1.45, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 36),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isLight ? 0.02 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn("Your Score", "$_score / ${_questions.length}", const Color(0xFFFF9000)),
                  _buildStatColumn("Progress Level", "${((_currentIndex / _questions.length) * 100).toStringAsFixed(0)}%", const Color(0xFF3B82F6)),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Exit Style", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.32),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _loadQuestions,
                        borderRadius: BorderRadius.circular(16),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              "Try Again",
                              style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 15),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // VICTORY SCREEN
  Widget _buildVictoryWidget(bool isLight, Color cardColor, Color textColor) {
    int ratingStars = 1;
    if (_lives == 3) ratingStars = 3;
    else if (_lives == 2) ratingStars = 2;

    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9000).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, size: 84, color: Color(0xFFFF9000)),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (idx) {
                final isFilled = idx < ratingStars;
                return Icon(
                  Icons.star_rounded,
                  size: 44,
                  color: isFilled ? const Color(0xFFFFB01F) : Colors.grey[400],
                );
              }),
            ),
            const SizedBox(height: 20),
            Text(
              "Victory Complete!",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.8),
            ),
            const SizedBox(height: 10),
            const Text(
              "Simply flawless! You successfully survived the dynamic countdown and finished the gamified challenge.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.45, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isLight ? 0.020 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn("Final Score", "$_score / ${_questions.length}", const Color(0xFF10B981)),
                  _buildStatColumn("Lives Left", "❤️ x $_lives", Colors.redAccent),
                ],
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9000), Color(0xFFFF7A00)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF9000).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        "Collect Points & Exit",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
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

  Widget _buildStatColumn(String heading, String content, Color contentColor) {
    return Column(
      children: [
        Text(heading, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        Text(content, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: contentColor)),
      ],
    );
  }

  // 1. TOP GAME PANEL: Standard Header, Countdown Timer block, Hearts list layout
  Widget _buildTopGamePanel(bool isLight) {
    final double timePercent = _timeLeft / _maxTime;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12.0, 10.0, 20.0, 10.0),
        child: Row(
          children: [
            // Close / back button
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                size: 28,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 4),
            // Middle visual countdown timer bar (animated)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(seconds: 1),
                  tween: Tween<double>(
                    begin: (_timeLeft == _maxTime) ? 1.0 : (_timeLeft + 1) / _maxTime,
                    end: timePercent,
                  ),
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                      color: value <= 0.32
                          ? Colors.redAccent
                          : (value <= 0.6 ? Colors.orangeAccent : const Color(0xFF10B981)),
                      minHeight: 12,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Right 3 Hearts representations
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (idx) {
                final isLit = idx < _lives;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Icon(
                    Icons.favorite,
                    color: isLit ? Colors.redAccent : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                    size: 24,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // CORE GAMEPLAY SCREEN
  Widget _buildGameplayWidget(bool isLight, Color cardColor, Color textColor, Color descColor) {
    final q = _questions[_currentIndex];

    return Column(
      children: [
        _buildTopGamePanel(isLight),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              children: [
                // 2. QUESTION BOX CARD: Clean floating layout with distinct rounded edges for questions and choices
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isLight ? 0.03 : 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle tracker info
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9000).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "QUESTION ${_currentIndex + 1} OF ${_questions.length}",
                          style: const TextStyle(
                            color: Color(0xFFFF9000),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Question body styled in high contrast crisp bold typography
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

                      // 3. OPTIONS: Tactile, 3D modern option list responding instantly to selections
                      ...q.options.asMap().entries.map((entry) {
                        final optIdx = entry.key;
                        final optionText = entry.value;

                        final isSelected = _selectedIdx == optIdx;
                        final isCorrect = _isOptionCorrect(q, optionText, optIdx);

                        // Layout styling variables
                        Color bgCol = Colors.transparent;
                        Color borderCol = isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155);
                        Color shadow3DCol = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
                        Color optionTxtCol = descColor;
                        Color labelBg = isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155);
                        Color labelTxt = descColor;

                        if (_isChecked) {
                          if (isCorrect) {
                            borderCol = const Color(0xFF10B981);
                            bgCol = const Color(0xFF10B981).withOpacity(isLight ? 0.08 : 0.15);
                            shadow3DCol = const Color(0xFF047857);
                            optionTxtCol = const Color(0xFF059669);
                            labelBg = const Color(0xFF10B981);
                            labelTxt = Colors.white;
                          } else if (isSelected) {
                            borderCol = const Color(0xFFEF4444);
                            bgCol = const Color(0xFFEF4444).withOpacity(isLight ? 0.08 : 0.15);
                            shadow3DCol = const Color(0xFFB91C1C);
                            optionTxtCol = const Color(0xFFDC2626);
                            labelBg = const Color(0xFFEF4444);
                            labelTxt = Colors.white;
                          }
                        } else if (isSelected) {
                          borderCol = const Color(0xFFFF9000);
                          bgCol = const Color(0xFFFF9000).withOpacity(isLight ? 0.06 : 0.12);
                          shadow3DCol = const Color(0xFFD97706);
                          optionTxtCol = const Color(0xFFFF9000);
                          labelBg = const Color(0xFFFF9000);
                          labelTxt = Colors.white;
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
                            duration: const Duration(milliseconds: 100),
                            margin: const EdgeInsets.only(bottom: 16.0),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                            decoration: BoxDecoration(
                              color: bgCol,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: borderCol,
                                width: isSelected || _isChecked ? 2.5 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: shadow3DCol,
                                  offset: (isSelected && !_isChecked) ? const Offset(0, 1.5) : const Offset(0, 4.0),
                                  blurRadius: 0, // Solid 3D look
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: labelBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + optIdx),
                                      style: TextStyle(
                                        color: labelTxt,
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
                                      color: optionTxtCol,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                      // Tutor Explanation block inside Question box card
                      if (_isChecked && q.explanation != null && q.explanation!.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9000).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFF9000).withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.lightbulb_rounded, size: 16, color: Color(0xFFFF9000)),
                                  SizedBox(width: 6),
                                  Text(
                                    "Tutor explanation",
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
                                  fontSize: 11.5,
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
                ),
              ],
            ),
          ),
        ),

        // 4. BOTTOM FOOTER: Energetic primary colored full width controller button
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 24.0),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: _isChecked
                ? Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _nextQuestion,
                        borderRadius: BorderRadius.circular(18),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentIndex == _questions.length - 1 ? "Finish Quest" : "Next Question",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: _selectedIdx == null
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFFFF9000), Color(0xFFFF6B00)],
                            ),
                      color: _selectedIdx == null
                          ? (isLight ? const Color(0xFFCBD5E1) : const Color(0xFF334155))
                          : null,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: _selectedIdx == null
                          ? []
                          : [
                              BoxShadow(
                                color: const Color(0xFFFF9000).withOpacity(0.30),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _selectedIdx == null ? null : _checkChoice,
                        borderRadius: BorderRadius.circular(18),
                        child: Center(
                          child: Text(
                            "Check Answer",
                            style: TextStyle(
                              color: _selectedIdx == null
                                  ? (isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                                  : Colors.white,
                              fontSize: 15.5,
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
    );
  }
}
