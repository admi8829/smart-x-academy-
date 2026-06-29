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
  bool _isPracticeSetupCompleted = false;

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

      setState(() {
        _questions = fetched;
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

  void _advanceToNext() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isLight ? Colors.white : const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Exit Exam?", style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text("Are you sure you want to quit? Your progress in this session will be lost."),
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

    if (widget.mode == QuizMode.exam) {
      setState(() => _isSubmittingScore = true);
      await _submitScoreToLeaderboard(score);
      setState(() => _isSubmittingScore = false);
    }

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
                  setState(() {
                    _showAnswersAndExplanations = true;
                    _currentIndex = 0; // Return to first question for review
                  });
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

  Widget _buildMathText(String text, TextStyle baseStyle) {
    if (!text.contains(r'$') && !text.contains(r'\(') && !text.contains(r'\[')) {
      return Text(
        text,
        style: baseStyle,
        textAlign: TextAlign.center,
      );
    }

    final List<Widget> spans = [];
    final regex = RegExp(r'\$\$([\s\S]+?)\$\$|\$([\s\S]+?)\$');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(Text(
          text.substring(lastIndex, match.start),
          style: baseStyle,
          textAlign: TextAlign.center,
        ));
      }

      final mathExpr = match.group(1) ?? match.group(2) ?? '';
      if (mathExpr.isNotEmpty) {
        spans.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
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
        textAlign: TextAlign.center,
      ));
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
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

    // Show Practice Setup Screen if in practice mode and not completed setup
    if (widget.mode == QuizMode.practice && !_isPracticeSetupCompleted) {
      return _buildPracticeSetupView();
    }

    return _buildQuizActiveView();
  }

  Widget _buildPracticeSetupView() {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final cardColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final titleColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final descColor = isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);

    final List<int> limits = [0, 3, 5, 10, 15, 20];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isLight ? 0.04 : 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getSubjectThemeColor().withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.settings_suggest_rounded, 
                  color: _getSubjectThemeColor(), 
                  size: 36
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Practice Mode Setup",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: titleColor),
              ),
              const SizedBox(height: 8),
              Text(
                "Select a custom time limit for your practice session. Choose 'No limit' for relaxed learning.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.4, color: descColor),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: limits.map((limit) {
                  final isSelected = _selectedPracticeTimeLimit == limit;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPracticeTimeLimit = limit;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? _getSubjectThemeColor().withOpacity(0.1) 
                            : (isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? _getSubjectThemeColor() : Colors.transparent,
                          width: 1.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            limit == 0 ? Icons.timer_off_rounded : Icons.timer_outlined,
                            size: 16,
                            color: isSelected ? _getSubjectThemeColor() : descColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            limit == 0 ? "No limit" : "$limit Mins",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? _getSubjectThemeColor() : titleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_selectedPracticeTimeLimit > 0) {
                    _timeLeftSeconds = _selectedPracticeTimeLimit * 60;
                    _startTimer();
                  }
                  setState(() {
                    _isPracticeSetupCompleted = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getSubjectThemeColor(),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text(
                  "Start Practice Session",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
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

    final totalQ = _questions.length;
    final progress = (_currentIndex + 1) / totalQ;

    // Show finished state if currentIndex has reached questions list length
    if (_currentIndex == _questions.length) {
      return SingleChildScrollView(
        child: _buildFinishedSection(),
      );
    }

    final q = _questions[_currentIndex];
    final optionsData = q.options;
    final qText = q.questionText;

    final showFeedback = _shouldShowExplanation(_currentIndex);
    final isSubmitted = widget.mode == QuizMode.practice && _submittedQuestions.contains(_currentIndex);
    final hasSelected = _selectedAnswers.containsKey(_currentIndex);

    final showTimer = (widget.mode == QuizMode.exam) || (widget.mode == QuizMode.practice && _selectedPracticeTimeLimit > 0);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          // Upper progress and info block
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Question ${_currentIndex + 1} of $totalQ",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _getSubjectThemeColor(),
                ),
              ),
              if (showTimer)
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
              value: progress,
              backgroundColor: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              valueColor: AlwaysStoppedAnimation<Color>(_getSubjectThemeColor()),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 24),

          // Question container: reduced height, center-aligned, cohesive themed border
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22.0),
            decoration: BoxDecoration(
              color: cardColor,
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
              children: [
                _buildMathText(
                  qText,
                  TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    height: 1.45,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Center-aligned, reduced-height options list
          if (optionsData.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "No options available.",
                style: TextStyle(color: descColor, fontStyle: FontStyle.italic),
              ),
            ),
          
          ...optionsData.asMap().entries.map((entry) {
            final optIdx = entry.key;
            final optText = entry.value;
            final isSelected = _selectedAnswers[_currentIndex] == optIdx;

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
                trailingIcon = const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16);
              } else if (isSelected) {
                borderCol = const Color(0xFFEF4444);
                bgCol = isLight ? const Color(0xFFFEE2E2) : const Color(0xFF7F1D1D).withOpacity(0.5);
                txtCol = isLight ? const Color(0xFF991B1B) : const Color(0xFFFECACA);
                trailingIcon = const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 16);
              } else {
                borderCol = isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155);
                bgCol = Colors.transparent;
                txtCol = descColor.withOpacity(0.6);
              }
            } else {
              borderCol = isSelected
                  ? _getSubjectThemeColor()
                  : (isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155));
              bgCol = isSelected
                  ? _getSubjectThemeColor().withOpacity(isLight ? 0.08 : 0.15)
                  : cardColor;
              txtCol = isSelected ? _getSubjectThemeColor() : titleTextColor;
            }

            return GestureDetector(
              onTap: () => _onOptionSelected(optIdx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 11.0),
                decoration: BoxDecoration(
                  color: bgCol,
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: borderCol,
                    width: isSelected || (showFeedback && _isOptionCorrect(q, optText, optIdx)) ? 2.0 : 1.5,
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
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: showFeedback && _isOptionCorrect(q, optText, optIdx)
                              ? const Color(0xFF10B981)
                              : (isSelected ? _getSubjectThemeColor() : descColor.withOpacity(0.2)),
                          child: Text(
                            String.fromCharCode(65 + optIdx),
                            style: TextStyle(
                              color: isSelected || (showFeedback && _isOptionCorrect(q, optText, optIdx)) ? Colors.white : titleTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (trailingIcon != null) ...[
                          const SizedBox(width: 6),
                          trailingIcon,
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildMathText(
                      optText,
                      TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: txtCol,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Check answer button (only practice mode and not submitted)
          if (widget.mode == QuizMode.practice && !isSubmitted) ...[
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
                  disabledBackgroundColor: (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                  disabledForegroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],

          // Explanations Box
          if (showFeedback && q.explanation != null && q.explanation!.trim().isNotEmpty) ...[
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
                  Text(
                    q.explanation!.trim(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                      color: isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Next Question Navigation Logic
          if ((widget.mode == QuizMode.practice && isSubmitted) || (widget.mode == QuizMode.exam && hasSelected) || _showAnswersAndExplanations) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _advanceToNext,
                icon: Icon(
                  _currentIndex == totalQ - 1 
                      ? Icons.assignment_turned_in_rounded 
                      : Icons.arrow_forward_rounded, 
                  size: 16
                ),
                label: Text(
                  _currentIndex == totalQ - 1 
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
    );
  }

  Widget _buildFinishedSection() {
    if (_questions.isEmpty) return const SizedBox.shrink();
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final bool allAnswered = _selectedAnswers.length == _questions.length;
    
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
                backgroundColor: _getSubjectThemeColor(),
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
