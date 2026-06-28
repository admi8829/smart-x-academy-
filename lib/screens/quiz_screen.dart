import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question_model.dart';
import '../services/quiz_service.dart';
import '../services/offline_manager.dart';

enum QuizMode {
  practice,
  exam,
}

class QuizScreen extends StatefulWidget {
  final int grade;
  final String? subject;
  final int? unit;
  final bool isOffline;
  final String? offlineUnitId;
  final QuizMode mode;

  const QuizScreen({
    super.key,
    required this.grade,
    this.subject,
    this.unit,
    this.isOffline = false,
    this.offlineUnitId,
    this.mode = QuizMode.practice,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _isLoading = true;
  bool _isSubmittingScore = false;
  String? _errorMessage;
  List<QuestionModel> _questions = [];
  
  int _currentIndex = 0;
  final Map<int, int> _selectedAnswers = {};
  final Set<int> _submittedQuestions = {}; // Only for practice mode
  bool _showAnswersAndExplanations = false; // Set to true after exam is finished and submitted

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};

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
      _submittedQuestions.clear();
      _showAnswersAndExplanations = false;
      _currentIndex = 0;
      _itemKeys.clear();
    });

    try {
      final List<QuestionModel> fetched;
      if (widget.isOffline && widget.offlineUnitId != null) {
        fetched = await OfflineManager.getOfflineQuestions(widget.offlineUnitId!);
      } else {
        fetched = await QuizService.fetchQuestions(
          grade: widget.grade,
          subject: widget.subject,
          unit: widget.unit,
        );
      }

      if (fetched.isEmpty) {
        setState(() {
          _questions = [];
          _isLoading = false;
          _errorMessage = "No questions available.";
        });
        return;
      }

      for (var i = 0; i < fetched.length; i++) {
        _itemKeys[i] = GlobalKey();
      }

      setState(() {
        _questions = fetched;
        _isLoading = false;
      });
      
      if (_questions.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToIndex(0);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      debugPrint("Error loading questions: $e");
    }
  }

  void _onOptionSelected(int qIndex, int optionIndex) {
    if (_questions.isEmpty || qIndex >= _questions.length || qIndex < 0) return;
    
    // In exam mode, prevent changing past answers once passed.
    if (widget.mode == QuizMode.exam && qIndex != _currentIndex) return;
    if (_showAnswersAndExplanations) return; // Prevent change during post-exam review
    if (widget.mode == QuizMode.practice && _submittedQuestions.contains(qIndex)) return; // Prevent change after submit

    setState(() {
      _selectedAnswers[qIndex] = optionIndex;
    });
  }

  void _advanceToNext(int index) {
    if (index < _questions.length - 1) {
      setState(() => _currentIndex = index + 1);
      _scrollToIndex(index + 1);
    } else {
      // Reached the end
      setState(() => _currentIndex = index + 1);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void _makeActive(int index) {
    if (_currentIndex != index) {
      if (widget.mode == QuizMode.exam && !_showAnswersAndExplanations) {
        // Block navigation backward / forward manually in live exam mode
        return;
      }
      setState(() => _currentIndex = index);
      _scrollToIndex(index);
    }
  }

  void _scrollToIndex(int index) {
    if (_questions.isEmpty || index >= _questions.length || index < 0) return;
    if (!_itemKeys.containsKey(index)) return;
    final context = _itemKeys[index]!.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        alignment: 0.3, // Scroll so item is in upper third
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  bool _shouldShowExplanation(int index) {
    if (widget.mode == QuizMode.practice) {
      return _submittedQuestions.contains(index);
    } else {
      return _showAnswersAndExplanations;
    }
  }

  Future<void> _submitScoreToLeaderboard(int score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String fullName = prefs.getString('user_fullName') ?? 'Student';
      final String phoneNumber = prefs.getString('user_phoneNumber') ?? 'N/A';

      final String subjectId = widget.subject ?? 'unknown';
      final int unitId = widget.unit ?? 1;

      await QuizService.submitLeaderboardScore(
        fullName: fullName,
        phoneNumber: phoneNumber,
        subjectId: subjectId,
        unitId: unitId,
        score: score,
        totalQuestions: _questions.length,
      );
    } on PostgrestException catch (e) {
      debugPrint("PostgrestException submitting score: $e");
      _showDescriptiveSnackBar();
    } catch (e) {
      debugPrint("Failed to submit score to leaderboard: $e");
      _showDescriptiveSnackBar();
    }
  }

  void _showDescriptiveSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                "Could not sync your score to the leaderboard. Please check your internet connection.",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showExitConfirmationDialog() {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isLight ? Colors.white : const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Exit Exam?", style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text("Are you sure you want to quit? Your progress in this exam will be lost."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text("Exit", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _showResults() async {
    if (_questions.isEmpty) return;
    int score = 0;
    
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (_selectedAnswers.containsKey(i)) {
        final selectedIdx = _selectedAnswers[i]!;
        if (selectedIdx < q.options.length) {
          final isCorrect = _isOptionCorrect(q, q.options[selectedIdx], selectedIdx);
          if (isCorrect) score++;
        }
      }
    }

    if (widget.mode == QuizMode.exam) {
      setState(() => _isSubmittingScore = true);
      await _submitScoreToLeaderboard(score);
      setState(() => _isSubmittingScore = false);
    }

    if (!mounted) return;

    final percent = (score / _questions.length * 100).round();
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        elevation: 12,
        backgroundColor: isLight ? Colors.white : const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFBBF24), size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              widget.mode == QuizMode.exam ? "Exam Finished!" : "Quiz Finished!",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: isLight ? const Color(0xFF0F172A) : Colors.white,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Here is your performance summary",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text("SCORE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Text(
                        "$score / ${_questions.length}",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isLight ? const Color(0xFF0F172A) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(width: 1.5, height: 36, color: Colors.grey.withOpacity(0.2)),
                  Column(
                    children: [
                      const Text("ACCURACY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Text(
                        "$percent%",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: percent >= 70 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (widget.mode == QuizMode.exam)
              Text(
                "Your score has been successfully posted to the leaderboard. You can now review all questions and explanations.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                ),
              ),
          ],
        ),
        actions: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (widget.mode == QuizMode.exam) {
                  // Unlock review mode
                  setState(() {
                    _showAnswersAndExplanations = true;
                    _currentIndex = 0; // Return to first question so they can review easily
                  });
                  _scrollToIndex(0);
                } else {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: Text(
                widget.mode == QuizMode.exam ? "Review Answers" : "Done",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final backgroundColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final titleTextColor = isLight ? const Color(0xFF0F172A) : Colors.white;

    return PopScope(
      canPop: _showAnswersAndExplanations || widget.mode == QuizMode.practice || _questions.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmationDialog();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.subject != null ? "${widget.subject!.toUpperCase()} QUIZ" : "QUIZ",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
                decoration: BoxDecoration(
                  color: _showAnswersAndExplanations 
                      ? const Color(0xFF10B981).withOpacity(0.12)
                      : (widget.mode == QuizMode.exam 
                          ? const Color(0xFFEF4444).withOpacity(0.12) 
                          : const Color(0xFF3B82F6).withOpacity(0.12)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _showAnswersAndExplanations 
                      ? "REVIEW MODE" 
                      : (widget.mode == QuizMode.exam ? "EXAM MODE" : "PRACTICE MODE"),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: _showAnswersAndExplanations 
                        ? const Color(0xFF10B981)
                        : (widget.mode == QuizMode.exam 
                            ? const Color(0xFFEF4444) 
                            : const Color(0xFF3B82F6)),
                  ),
                ),
              ),
            ],
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: titleTextColor,
          centerTitle: true,
        ),
        body: Stack(
          children: [
            _buildBody(),
            if (_isSubmittingScore)
              Container(
                color: Colors.black.withOpacity(0.6),
                child: const Center(
                  child: Card(
                    color: Colors.white,
                    elevation: 12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(strokeWidth: 4),
                          SizedBox(height: 20),
                          Text(
                            "Syncing Leaderboard...",
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Please do not close this screen",
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: Colors.grey),
                          ),
                        ],
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.blueAccent),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadQuestions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }
    if (_questions.isEmpty) {
      return const Center(
        child: Text(
          "No questions found.",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 200, top: 10),
      itemCount: _questions.length + 1,
      itemBuilder: (context, index) {
        if (index == _questions.length) {
          return _buildFinishedSection();
        }
        return _buildQuestionCard(index, _questions[index]);
      },
    );
  }

  Widget _buildQuestionCard(int index, QuestionModel q) {
    final isActive = index == _currentIndex;
    final opacity = (isActive || _showAnswersAndExplanations) ? 1.0 : 0.4;
    
    final optionsData = q.options;
    final qText = q.questionText;

    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final cardColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final descColor = isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);

    final showFeedback = _shouldShowExplanation(index);
    final isSubmitted = widget.mode == QuizMode.practice && _submittedQuestions.contains(index);

    return GestureDetector(
      key: _itemKeys[index],
      onTap: () => _makeActive(index),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: opacity,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(isLight ? 0.06 : 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ]
                : [],
            border: Border.all(
              color: isActive ? const Color(0xFF3B82F6).withOpacity(0.3) : Colors.transparent,
              width: isActive ? 2 : 0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Question ${index + 1}",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                qText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.4,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 24),
              if (optionsData.isEmpty)
                Text(
                  "No options available.",
                  style: TextStyle(color: descColor, fontStyle: FontStyle.italic),
                ),
              ...optionsData.asMap().entries.map((entry) {
                final optIdx = entry.key;
                final optText = entry.value;
                
                final isSelected = _selectedAnswers[index] == optIdx;

                Color borderCol;
                Color bgCol;
                Color txtCol;
                Widget? trailingIcon;

                if (showFeedback) {
                  final isCorrect = _isOptionCorrect(q, optText, optIdx);
                  if (isCorrect) {
                    borderCol = const Color(0xFF10B981);
                    bgCol = isLight ? const Color(0xFFD1FAE5) : const Color(0xFF064E3B).withOpacity(0.5);
                    txtCol = isLight ? const Color(0xFF065F46) : const Color(0xFFA7F3D0);
                    trailingIcon = const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20);
                  } else if (isSelected) {
                    borderCol = const Color(0xFFEF4444);
                    bgCol = isLight ? const Color(0xFFFEE2E2) : const Color(0xFF7F1D1D).withOpacity(0.5);
                    txtCol = isLight ? const Color(0xFF991B1B) : const Color(0xFFFECACA);
                    trailingIcon = const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 20);
                  } else {
                    borderCol = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
                    bgCol = Colors.transparent;
                    txtCol = descColor.withOpacity(0.6);
                  }
                } else {
                  borderCol = isSelected
                      ? const Color(0xFF3B82F6)
                      : (isLight ? const Color(0xFFEDF2F7) : const Color(0xFF475569));
                  bgCol = isSelected
                      ? const Color(0xFF3B82F6).withOpacity(isLight ? 0.08 : 0.15)
                      : Colors.transparent;
                  txtCol = isSelected ? const Color(0xFF3B82F6) : descColor;
                }

                return GestureDetector(
                  onTap: () => _onOptionSelected(index, optIdx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12.0),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      color: bgCol,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: borderCol,
                        width: isSelected || (showFeedback && _isOptionCorrect(q, optText, optIdx)) ? 2.0 : 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: showFeedback && _isOptionCorrect(q, optText, optIdx)
                                ? const Color(0xFF10B981)
                                : (isSelected
                                    ? const Color(0xFF3B82F6)
                                    : (isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155))),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + optIdx),
                              style: TextStyle(
                                color: isSelected || (showFeedback && _isOptionCorrect(q, optText, optIdx)) ? Colors.white : descColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            optText,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: txtCol,
                            ),
                          ),
                        ),
                        if (trailingIcon != null) ...[
                          const SizedBox(width: 8),
                          trailingIcon,
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
              
              if (widget.mode == QuizMode.practice && !isSubmitted) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _selectedAnswers.containsKey(index)
                        ? () {
                            setState(() {
                              _submittedQuestions.add(index);
                            });
                          }
                        : null,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: const Text(
                      "Check Answer",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                      disabledForegroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],

              if (showFeedback && q.explanation != null && q.explanation!.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFF0F7FF) : const Color(0xFF1E293B).withOpacity(0.8),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    border: Border(
                      left: const BorderSide(color: Color(0xFF3B82F6), width: 4.0),
                      top: BorderSide(color: isLight ? const Color(0xFFDBEAFE) : const Color(0xFF334155), width: 1.0),
                      right: BorderSide(color: isLight ? const Color(0xFFDBEAFE) : const Color(0xFF334155), width: 1.0),
                      bottom: BorderSide(color: isLight ? const Color(0xFFDBEAFE) : const Color(0xFF334155), width: 1.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isLight ? 0.02 : 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded, size: 18, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 8),
                          Text(
                            "Explanation",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: isLight ? const Color(0xFF2563EB) : const Color(0xFF60A5FA),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        q.explanation!.trim(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          color: isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (isActive && index < _questions.length - 1) ...[
                if ((widget.mode == QuizMode.practice && isSubmitted) || 
                    (widget.mode == QuizMode.exam && _selectedAnswers.containsKey(index))) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _advanceToNext(index),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text(
                        "Next Question",
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                        foregroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinishedSection() {
    if (_questions.isEmpty) return const SizedBox.shrink();
    
    final bool allAnswered = _selectedAnswers.isNotEmpty && _selectedAnswers.length == _questions.length;
    
    // In review mode, we can just hide this section or show a finished checkmark
    if (_showAnswersAndExplanations) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded, size: 64, color: Color(0xFF10B981)),
            const SizedBox(height: 16),
            const Text(
              "Review Finished!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Go Back", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: allAnswered ? 1.0 : 0.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 64, color: Color(0xFF10B981)),
            const SizedBox(height: 16),
            const Text(
              "You've completed all questions!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: allAnswered ? _showResults : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                widget.mode == QuizMode.exam ? "Submit Exam" : "View Results", 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
