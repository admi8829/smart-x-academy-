import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../models/question_model.dart';
import '../services/quiz_service.dart';
import '../services/offline_manager.dart';
import '../services/ad_helper.dart';
import '../main.dart';

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

class _QuizScreenState extends State<QuizScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isSubmittingScore = false;
  String? _errorMessage;
  List<QuestionModel> _questions = [];
  
  int _currentIndex = 0;
  final Map<int, int> _selectedAnswers = {};
  final Set<int> _submittedQuestions = {}; // Only for practice mode (already checked)
  bool _showAnswersAndExplanations = false; // Set to true after exam is finished/submitted
  bool _isSavingOffline = false;

  String _getUnitId() {
    if (widget.offlineUnitId != null && widget.offlineUnitId!.isNotEmpty) {
      return widget.offlineUnitId!;
    }
    String sub = (widget.subject ?? 'Physics').toLowerCase();
    String prefix = 'phys_u';
    if (sub.contains('math')) {
      prefix = 'math_u';
    } else if (sub.contains('biol')) {
      prefix = 'bio_u';
    } else if (sub.contains('phys')) {
      prefix = 'phys_u';
    } else if (sub.contains('chem')) {
      prefix = 'chem_u';
    } else if (sub.contains('geog')) {
      prefix = 'geo_u';
    } else if (sub.contains('hist')) {
      prefix = 'hist_u';
    } else if (sub.contains('civ')) {
      prefix = 'civ_u';
    } else if (sub.contains('agri')) {
      prefix = 'agri_u';
    }
    return '$prefix${widget.unit ?? 1}';
  }

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // Audio Feedbacks
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Timer fields
  Timer? _quizTimer;
  int _timeLeftSeconds = 0;
  int _selectedPracticeTimeLimit = 0; // in minutes (0 means no limit)
  bool _isPracticeSetupCompleted = true; // Bypassed for Practice Mode

  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _questionKeys = [];

  // Privacy Protection Mode
  bool _isPrivacyEnabled = false;
  bool _isBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRewardedAd();
    _loadBannerAd();
    _loadQuestions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rewardedAd?.dispose();
    _bannerAd?.dispose();
    _quizTimer?.cancel();
    _audioPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      setState(() {
        _isBackgrounded = true;
      });
    } else if (state == AppLifecycleState.resumed) {
      setState(() {
        _isBackgrounded = false;
      });
    }
  }

  Color _getSubjectThemeColor() {
    final sub = (widget.subject ?? '').toLowerCase();
    if (sub.contains('phys')) return const Color(0xFFF59E0B); // Amber
    if (sub.contains('chem')) return const Color(0xFF10B981); // Emerald
    if (sub.contains('bio')) return const Color(0xFFEC4899); // Pink
    if (sub.contains('math')) return const Color(0xFF3B82F6); // Blue
    return const Color(0xFF6366F1); // Indigo default
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;

    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = true;
            });
          } else {
            ad.dispose();
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('QuizScreen BannerAd failed to load: $err. Code: ${err.code}');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = false;
              _bannerAd = null;
            });
          }
        },
      ),
    );
    _bannerAd!.load();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
        },
        onAdFailedToLoad: (err) {
          debugPrint('Failed to load a rewarded ad: ${err.message}');
          _isRewardedAdLoaded = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadRewardedAd();
          _loadQuestions();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          _loadRewardedAd();
          _loadQuestions();
        },
      );
      _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        // User earned reward
      });
      _rewardedAd = null;
      _isRewardedAdLoaded = false;
    } else {
      _loadQuestions();
    }
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedAnswers.clear();
      _submittedQuestions.clear();
      _showAnswersAndExplanations = false;
      _currentIndex = 0;
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

      // Shuffle the list of questions so they appear in a random sequence every session
      final List<QuestionModel> randomizedQuestions = List<QuestionModel>.from(fetched)..shuffle();

      // For each question, dynamically shuffle its options list and update the corresponding index / value for correctAnswer
      final List<QuestionModel> processedQuestions = randomizedQuestions.map((q) {
        // Find the correct option text from the original options and correctAnswer
        String correctOptionText = '';
        for (int i = 0; i < q.options.length; i++) {
          final option = q.options[i];
          bool isOrigCorrect = false;
          if (option.trim().toLowerCase() == q.correctAnswer.trim().toLowerCase()) {
            isOrigCorrect = true;
          } else if (q.correctAnswer.trim() == i.toString()) {
            isOrigCorrect = true;
          } else {
            final Map<String, int> letterMap = {'a': 0, 'b': 1, 'c': 2, 'd': 3, 'e': 4};
            final String cleanCorrect = q.correctAnswer.trim().toLowerCase();
            if (letterMap.containsKey(cleanCorrect) && letterMap[cleanCorrect] == i) {
              isOrigCorrect = true;
            }
          }
          if (isOrigCorrect) {
            correctOptionText = option;
            break;
          }
        }

        // Fallback if not found
        if (correctOptionText.isEmpty) {
          correctOptionText = q.correctAnswer;
        }

        // Shuffle the options
        final shuffledOptions = List<String>.from(q.options)..shuffle();

        // Return a new QuestionModel with the shuffled options and exact correctOptionText
        return QuestionModel(
          id: q.id,
          grade: q.grade,
          subject: q.subject,
          unit: q.unit,
          questionText: q.questionText,
          options: shuffledOptions,
          correctAnswer: correctOptionText,
          explanation: q.explanation,
          createdAt: q.createdAt,
        );
      }).toList();

      setState(() {
        _questions = processedQuestions;
        _questionKeys = List.generate(processedQuestions.length, (_) => GlobalKey());
        _isLoading = false;
      });

      // Start exam mode countdown automatically
      if (widget.mode == QuizMode.exam) {
        _timeLeftSeconds = _questions.length * 60; // 1 minute per question
        _startTimer();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      debugPrint("Error loading questions: $e");
    }
  }

  void _startTimer() {
    _quizTimer?.cancel();
    _quizTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeLeftSeconds > 0) {
        setState(() {
          _timeLeftSeconds--;
        });
      } else {
        timer.cancel();
        _onTimeExpired();
      }
    });
  }

  void _onTimeExpired() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Time has expired! Submitting your quiz..."),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _showResults();
  }

  void _onOptionSelected(int optionIndex) {
    if (_questions.isEmpty || _currentIndex >= _questions.length || _currentIndex < 0) return;
    if (_showAnswersAndExplanations) return; // Prevent selection in post-exam review
    if (widget.mode == QuizMode.practice && _submittedQuestions.contains(_currentIndex)) return; // Already checked

    final q = _questions[_currentIndex];
    final isCorrect = _isOptionCorrect(q, q.options[optionIndex], optionIndex);

    setState(() {
      _selectedAnswers[_currentIndex] = optionIndex;
      if (widget.mode == QuizMode.practice) {
        _submittedQuestions.add(_currentIndex);
      }
    });

    _playFeedbackSound(isCorrect);

    if (widget.mode == QuizMode.practice) {
      _scrollToExplanation();
    } else if (widget.mode == QuizMode.exam) {
      _scrollToShiftExamQuestionUp();
    }
  }

  void _submitPracticeAnswer() {
    final selectedIdx = _selectedAnswers[_currentIndex];
    if (selectedIdx == null) return;
    
    final q = _questions[_currentIndex];
    final isCorrect = _isOptionCorrect(q, q.options[selectedIdx], selectedIdx);
    
    _playFeedbackSound(isCorrect);
    
    setState(() {
      _submittedQuestions.add(_currentIndex);
    });

    _scrollToExplanation();
  }

  Future<void> _playFeedbackSound(bool isCorrect) async {
    try {
      await _audioPlayer.stop();
      if (isCorrect) {
        await _audioPlayer.play(AssetSource('audio/correct.mp3'));
      } else {
        await _audioPlayer.play(AssetSource('audio/wrong.mp3'));
      }
    } catch (e) {
      debugPrint("Error playing audio feedback: $e");
    }
  }

  void _scrollToActiveQuestion() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_currentIndex < _questionKeys.length && _questionKeys[_currentIndex].currentContext != null) {
        Scrollable.ensureVisible(
          _questionKeys[_currentIndex].currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          alignment: 0.1, // Align near the top of the viewport
        );
      }
    });
  }

  void _scrollToExplanation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_currentIndex < _questionKeys.length && _questionKeys[_currentIndex].currentContext != null) {
        Scrollable.ensureVisible(
          _questionKeys[_currentIndex].currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          alignment: 1.0, // Align to bottom of viewport to reveal explanation block
        );
      }
    });
  }

  void _scrollToShiftExamQuestionUp() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_currentIndex < _questionKeys.length && _questionKeys[_currentIndex].currentContext != null) {
        Scrollable.ensureVisible(
          _questionKeys[_currentIndex].currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          alignment: 0.3, // Scroll slightly up so card and Next button are beautifully framed
        );
      }
    });
  }

  void _advanceToNext() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _scrollToActiveQuestion();
    } else {
      // Reached the end, navigate to submit screen/trigger submit results
      _showResults();
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
    final isExam = widget.mode == QuizMode.exam;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isLight ? Colors.white : const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isExam ? "Exit Exam?" : "Exit Quiz?",
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          isExam
              ? "Are you sure you want to quit this exam? Your progress will be lost and your score won't be saved."
              : "Are you sure you want to quit this practice session? Your progress will be lost.",
        ),
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
    _quizTimer?.cancel();
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

    setState(() => _isSubmittingScore = true);
    if (widget.mode == QuizMode.exam) {
      await _submitScoreToLeaderboard(score);
    }
    setState(() => _isSubmittingScore = false);

    if (!mounted) return;

    final percent = (score / _questions.length * 100).round();
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String scoreKey = 'best_score_${widget.grade}_${widget.subject ?? ""}_u${widget.unit ?? 1}';
      final int existingBest = prefs.getInt(scoreKey) ?? 0;
      if (percent > existingBest) {
        await prefs.setInt(scoreKey, percent);
      }
    } catch (_) {}

    // Play victory or completed sound
    _playFeedbackSound(percent >= 50);

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
                  setState(() {
                    _showAnswersAndExplanations = true;
                    _currentIndex = 0; // Return to first question for review
                  });
                  _scrollToActiveQuestion();
                } else {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getSubjectThemeColor(),
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
      ),
    );
  }

  Widget _buildMathText(String text, TextStyle baseStyle, {TextAlign align = TextAlign.center}) {
    if (!text.contains(r'$') && !text.contains(r'\(') && !text.contains(r'\[') && !text.contains(r'\\(') && !text.contains(r'\\[')) {
      return Text(
        text,
        style: baseStyle,
        textAlign: align,
      );
    }

    final List<Widget> spans = [];
    // Matches:
    // 1. $$...$$ (Block math)
    // 2. $...$ (Inline math)
    // 3. \[...\] or \\\[...\\\] (Block math)
    // 4. \(...\) or \\\(...\\\) (Inline math)
    final regex = RegExp(
      r'\$\$([\s\S]+?)\$\$|'
      r'\$([\s\S]+?)\$|'
      r'\\\[([\s\S]+?)\\\]|'
      r'\\\(([\s\S]+?)\\\)|'
      r'\\\\\[([\s\S]+?)\\\\\]|'
      r'\\\\\(([\s\S]+?)\\\\\)'
    );
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(Text(
          text.substring(lastIndex, match.start),
          style: baseStyle,
          textAlign: align,
        ));
      }

      final mathExpr = match.group(1) ??
          match.group(2) ??
          match.group(3) ??
          match.group(4) ??
          match.group(5) ??
          match.group(6) ??
          '';

      if (mathExpr.isNotEmpty) {
        spans.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: align == TextAlign.center ? Alignment.center : Alignment.centerLeft,
            child: Math.tex(
              mathExpr.trim(),
              textStyle: baseStyle.copyWith(
                fontSize: baseStyle.fontSize != null ? baseStyle.fontSize! + 1.5 : 17,
              ),
              onErrorFallback: (err) => Text(
                mathExpr,
                style: baseStyle.copyWith(fontFamily: 'monospace', color: Colors.amber),
              ),
            ),
          ),
        ));
      }
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(Text(
        text.substring(lastIndex),
        style: baseStyle,
        textAlign: align,
      ));
    }

    final wrapAlign = align == TextAlign.center
        ? WrapAlignment.center
        : (align == TextAlign.right ? WrapAlignment.end : WrapAlignment.start);

    final crossAlign = align == TextAlign.center
        ? WrapCrossAlignment.center
        : (align == TextAlign.right ? WrapCrossAlignment.end : WrapCrossAlignment.start);

    return Wrap(
      alignment: wrapAlign,
      crossAxisAlignment: crossAlign,
      spacing: 4,
      runSpacing: 4,
      children: spans,
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final backgroundColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final titleTextColor = isLight ? const Color(0xFF0F172A) : Colors.white;

    return PopScope(
      canPop: _showAnswersAndExplanations || (widget.mode == QuizMode.practice && !_isPracticeSetupCompleted) || _questions.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmationDialog();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            tooltip: "Exit",
            onPressed: () {
              if (_showAnswersAndExplanations || (widget.mode == QuizMode.practice && !_isPracticeSetupCompleted) || _questions.isEmpty) {
                Navigator.of(context).pop();
              } else {
                _showExitConfirmationDialog();
              }
            },
          ),
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
          actions: [
            IconButton(
              icon: Icon(_isPrivacyEnabled ? Icons.visibility_off_rounded : Icons.visibility_rounded),
              onPressed: () {
                setState(() {
                  _isPrivacyEnabled = !_isPrivacyEnabled;
                });
              },
              tooltip: "Privacy Shield",
            ),
          ],
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
            
            // Privacy Cover overlay
            if (_isPrivacyEnabled || _isBackgrounded)
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                    child: Container(
                      color: Colors.black.withOpacity(0.65),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: _getSubjectThemeColor().withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.security_rounded, 
                                size: 64, 
                                color: _getSubjectThemeColor()
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              "Content Hidden for Privacy",
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40.0),
                              child: Text(
                                _isBackgrounded 
                                    ? "Resume application to restore view" 
                                    : "Toggle the eye icon in the top right corner to unhide",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                              ),
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
        bottomNavigationBar: (_isBannerAdLoaded && _bannerAd != null)
            ? Container(
                color: backgroundColor,
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ),
              )
            : null,
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

    return _buildQuizActiveView();
  }

  Widget _buildCircularCheckbox({
    required bool isSelected,
    required bool showFeedback,
    required bool isCorrect,
    required Color subjectColor,
    required bool isLight,
  }) {
    Color borderCol;
    Color bgCol;
    Widget? icon;

    if (showFeedback) {
      if (isCorrect) {
        borderCol = const Color(0xFF10B981);
        bgCol = const Color(0xFF10B981);
        icon = const Icon(Icons.check, color: Colors.white, size: 12);
      } else if (isSelected) {
        borderCol = const Color(0xFFEF4444);
        bgCol = const Color(0xFFEF4444);
        icon = const Icon(Icons.close, color: Colors.white, size: 12);
      } else {
        borderCol = isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
        bgCol = Colors.transparent;
      }
    } else {
      borderCol = isSelected ? subjectColor : (isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569));
      bgCol = isSelected ? subjectColor : Colors.transparent;
      if (isSelected) {
        icon = const Icon(Icons.check, color: Colors.white, size: 12);
      }
    }

    return Container(
      width: 22.0,
      height: 22.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgCol,
        border: Border.all(
          color: borderCol,
          width: 2.0,
        ),
        boxShadow: isSelected && !showFeedback
            ? [
                BoxShadow(
                  color: subjectColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: icon != null ? Center(child: icon) : null,
    );
  }

  Widget _buildQuestionBlock(int index, bool isLight, Color cardColor, Color descColor, Color titleTextColor) {
    final q = _questions[index];
    final optionsData = q.options;
    final qText = q.questionText;

    final bool isActive = index == _currentIndex;
    final bool isExamReview = widget.mode == QuizMode.exam && _showAnswersAndExplanations;
    final bool isVisible = isActive || isExamReview;
    final showFeedback = _shouldShowExplanation(index);
    final isSubmitted = widget.mode == QuizMode.practice && _submittedQuestions.contains(index);
    final hasSelected = _selectedAnswers.containsKey(index);

    return Container(
      key: _questionKeys[index],
      margin: const EdgeInsets.only(bottom: 40.0), // beautiful gap between question blocks
      child: IgnorePointer(
        ignoring: isExamReview ? true : !isActive,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 350),
          opacity: isVisible ? 1.0 : 0.2,
          child: ClipRect(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: isVisible ? 0.0 : 5.0,
                sigmaY: isVisible ? 0.0 : 5.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question Header Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Question ${index + 1} of ${_questions.length}",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _getSubjectThemeColor(),
                        ),
                      ),
                      if (widget.mode == QuizMode.exam && isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_rounded, size: 14, color: Color(0xFFEF4444)),
                              const SizedBox(width: 6),
                              Text(
                                _formatTime(_timeLeftSeconds),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (index + 1) / _questions.length,
                      backgroundColor: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                      valueColor: AlwaysStoppedAnimation<Color>(_getSubjectThemeColor()),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Unified white card box containing both question text and options
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: isLight ? Colors.white : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isLight ? 0.04 : 0.16),
                          blurRadius: 16.0,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Question text (centered display math support)
                        _buildMathText(
                          qText,
                          TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            height: 1.45,
                            color: isLight ? const Color(0xFF0F172A) : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155),
                        ),
                        const SizedBox(height: 20),

                        // Options
                        if (optionsData.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              "No options available.",
                              style: TextStyle(color: descColor, fontStyle: FontStyle.italic),
                            ),
                          )
                        else
                          ...optionsData.asMap().entries.map((entry) {
                            final optIdx = entry.key;
                            final optText = entry.value;
                            final isOptSelected = _selectedAnswers[index] == optIdx;

                            Color borderCol;
                            Color bgCol;
                            Color txtCol;

                            if (showFeedback) {
                              final isCorrect = _isOptionCorrect(q, optText, optIdx);
                              if (isCorrect) {
                                borderCol = const Color(0xFF10B981);
                                bgCol = isLight ? const Color(0xFFD1FAE5) : const Color(0xFF064E3B).withOpacity(0.5);
                                txtCol = isLight ? const Color(0xFF065F46) : const Color(0xFFA7F3D0);
                              } else if (isOptSelected) {
                                borderCol = const Color(0xFFEF4444);
                                bgCol = isLight ? const Color(0xFFFEE2E2) : const Color(0xFF7F1D1D).withOpacity(0.5);
                                txtCol = isLight ? const Color(0xFF991B1B) : const Color(0xFFFECACA);
                              } else {
                                borderCol = isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155);
                                bgCol = Colors.transparent;
                                txtCol = descColor.withOpacity(0.6);
                              }
                            } else {
                              borderCol = isOptSelected
                                  ? _getSubjectThemeColor()
                                  : (isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155));
                              bgCol = isOptSelected
                                  ? _getSubjectThemeColor().withOpacity(isLight ? 0.08 : 0.15)
                                  : (isLight ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B));
                              txtCol = isOptSelected ? _getSubjectThemeColor() : (isLight ? const Color(0xFF0F172A) : Colors.white);
                            }

                            return GestureDetector(
                              onTap: () {
                                if (isActive && !showFeedback) {
                                  _onOptionSelected(optIdx);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(bottom: 12.0),
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                                decoration: BoxDecoration(
                                  color: bgCol,
                                  borderRadius: BorderRadius.circular(16.0),
                                  border: Border.all(
                                    color: borderCol,
                                    width: isOptSelected || (showFeedback && _isOptionCorrect(q, optText, optIdx)) ? 2.0 : 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Custom beautifully designed circular checkbox
                                    _buildCircularCheckbox(
                                      isSelected: isOptSelected,
                                      showFeedback: showFeedback,
                                      isCorrect: _isOptionCorrect(q, optText, optIdx),
                                      subjectColor: _getSubjectThemeColor(),
                                      isLight: isLight,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: _buildMathText(
                                        optText,
                                        TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: txtCol,
                                        ),
                                        align: TextAlign.left, // Left align inside rows for premium bento style
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),

                  // Practice Mode check answer button (rendered below the unified card)
                  if (widget.mode == QuizMode.practice && !isSubmitted && isActive) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: hasSelected ? _submitPracticeAnswer : null,
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: const Text(
                          "Check Answer",
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getSubjectThemeColor(),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                          disabledForegroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],

                  // Explanations Box
                  if (showFeedback && q.explanation != null && q.explanation!.trim().isNotEmpty && isActive) ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFF0F7FF) : const Color(0xFF1E293B).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border(
                          left: BorderSide(color: _getSubjectThemeColor(), width: 4.0),
                          top: BorderSide(color: isLight ? const Color(0xFFDBEAFE) : const Color(0xFF334155), width: 1.0),
                          right: BorderSide(color: isLight ? const Color(0xFFDBEAFE) : const Color(0xFF334155), width: 1.0),
                          bottom: BorderSide(color: isLight ? const Color(0xFFDBEAFE) : const Color(0xFF334155), width: 1.0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline_rounded, size: 18, color: _getSubjectThemeColor()),
                              const SizedBox(width: 8),
                              Text(
                                "Explanation",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: _getSubjectThemeColor(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildMathText(
                            q.explanation!.trim(),
                            TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                              color: isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                            align: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Next Question Button / Finish Quiz button
                  if (!isExamReview && isActive && ((widget.mode == QuizMode.practice && isSubmitted) || (widget.mode == QuizMode.exam && hasSelected) || _showAnswersAndExplanations)) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (index == _questions.length - 1) {
                            _showResults();
                          } else {
                            _advanceToNext();
                          }
                        },
                        icon: Icon(
                          index == _questions.length - 1
                              ? Icons.assignment_turned_in_rounded
                              : Icons.arrow_forward_rounded,
                          size: 16,
                        ),
                        label: Text(
                          index == _questions.length - 1
                              ? (_showAnswersAndExplanations ? "Finish Review" : "Finish Quiz")
                              : "Next Question",
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _getSubjectThemeColor(), width: 1.5),
                          foregroundColor: _getSubjectThemeColor(),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizActiveView() {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final cardColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final descColor = isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);
    final titleTextColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final bool isExamReview = widget.mode == QuizMode.exam && _showAnswersAndExplanations;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...List.generate(_questions.length, (index) {
                return _buildQuestionBlock(index, isLight, cardColor, descColor, titleTextColor);
              }),
              
              // End block when finished
              if (_currentIndex == _questions.length || isExamReview) ...[
                _buildFinishedSection(),
              ] else ...[
                // Generous vertical spacing at the bottom so we can center scroll the last question perfectly!
                const SizedBox(height: 500),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinishedSection() {
    if (_questions.isEmpty) return const SizedBox.shrink();
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final bool allAnswered = _selectedAnswers.length == _questions.length;
    
    if (_showAnswersAndExplanations) {
      final bool isExam = widget.mode == QuizMode.exam;
      final String languageCode = AppStateProvider.of(context).languageCode;
      final bool isDownloaded = OfflineManager.isDownloadedSync(_getUnitId());

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded, size: 64, color: Color(0xFF10B981)),
            const SizedBox(height: 16),
            Text(
              isExam
                  ? (languageCode == 'en' ? "Exam Review Complete" : "የፈተና ግምገማ ተጠናቋል")
                  : (languageCode == 'en' ? "Review Finished!" : "ግምገማው ተጠናቋል!"),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            if (isExam) ...[
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getSubjectThemeColor(),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                languageCode == 'en' ? "Go Back" : "ተመለስ",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
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
              backgroundColor: _getSubjectThemeColor(),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              disabledBackgroundColor: (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
            ),
            child: Text(
              widget.mode == QuizMode.exam ? "Submit Exam" : "View Results", 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
