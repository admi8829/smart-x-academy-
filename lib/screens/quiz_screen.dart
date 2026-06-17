import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_helper.dart';
import '../models/question_model.dart';
import '../services/quiz_service.dart';
import '../services/offline_manager.dart';

class QuizScreen extends StatefulWidget {
  final int grade;
  final String? subject;
  final int? unit;

  const QuizScreen({
    super.key,
    this.grade = 9,
    this.subject,
    this.unit,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  // --- Quiz & Supabase State ---
  List<QuestionModel> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _currentQuestionIndex = 0;
  
  // Track selected answer per question (index of option)
  final Map<int, int> _selectedAnswers = {};
  
  // Track whether the answer for the question has been "checked/submitted"
  final Map<int, bool> _checkedQuestions = {};
  
  int _score = 0;
  bool _quizFinished = false;

  // --- AdMob Ads State ---
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  // --- Animation State ---
  late final AnimationController _transitionController;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadQuestions();
    _initAdMob();
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  // --- Fetch from Supabase ---
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
      // Fire entrance animation
      _transitionController.forward(from: 0.0);
    } catch (e) {
      try {
        String prefix = (widget.subject ?? '').toLowerCase().trim();
        if (prefix.contains('math')) {
          prefix = 'math';
        } else if (prefix.contains('biol')) {
          prefix = 'bio';
        } else if (prefix.contains('phys')) {
          prefix = 'phys';
        } else if (prefix.contains('chem')) {
          prefix = 'chem';
        } else if (prefix.contains('geog')) {
          prefix = 'geo';
        } else if (prefix.contains('hist')) {
          prefix = 'hist';
        } else if (prefix.contains('civ')) {
          prefix = 'civ';
        } else if (prefix.contains('agri')) {
          prefix = 'agri';
        } else if (prefix.length > 4) {
          prefix = prefix.substring(0, 4);
        }
        final String unitId = "${prefix}_u${widget.unit ?? 1}";
        final localQuestions = await OfflineManager.getOfflineQuestions(unitId);
        if (localQuestions.isNotEmpty) {
          setState(() {
            _questions = localQuestions;
            _isLoading = false;
          });
          _transitionController.forward(from: 0.0);
          return;
        }
      } catch (err) {
        debugPrint("Local offline fallback fetch failed: $err");
      }

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // --- Check if option is correct inside QuestionModel ---
  bool _isOptionCorrect(QuestionModel q, String option, int index) {
    // 1. Direct option text match
    if (option.trim().toLowerCase() == q.correctAnswer.trim().toLowerCase()) {
      return true;
    }
    // 2. Index match
    if (q.correctAnswer.trim() == index.toString()) {
      return true;
    }
    // 3. Mapping of A, B, C, D to index
    final Map<String, int> letterMap = {'a': 0, 'b': 1, 'c': 2, 'd': 3, 'e': 4};
    final String cleanCorrect = q.correctAnswer.trim().toLowerCase();
    if (letterMap.containsKey(cleanCorrect) && letterMap[cleanCorrect] == index) {
      return true;
    }
    return false;
  }

  // --- AdMob Initialization ---
  void _initAdMob() {
    // Banner
    BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdMob Banner failed: $error');
          ad.dispose();
        },
      ),
    ).load();

    // Interstitial
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdMob Interstitial failed: $error');
        },
      ),
    );

    // Rewarded
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdMob Rewarded failed: $error');
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          _showHintDialog();
        },
      );
      _isRewardedAdLoaded = false;
      _rewardedAd = null;
      // Pre-load again
      _initAdMob();
    } else {
      _showHintDialog(isFallback: true);
    }
  }

  void _showHintDialog({bool isFallback = false}) {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) return;
    final q = _questions[_currentQuestionIndex];
    final String hintText = q.explanation ?? 'Analyze options closely to determine matching solution pattern.';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.white : const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.lightbulb_rounded, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              Text(
                "Study Tip / Explanation",
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light ? const Color(0xFF0F172A) : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isFallback) ...[
                Text(
                  "Rewarded challenge loaded offline. Here is your study tip:",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                hintText,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.light ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Got it",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Submission & Nav Operations ---
  void _checkAnswer() {
    final int questionIdx = _currentQuestionIndex;
    if (!_selectedAnswers.containsKey(questionIdx)) return;

    setState(() {
      _checkedQuestions[questionIdx] = true;
      
      // Calculate score if correct
      final q = _questions[questionIdx];
      final selIdx = _selectedAnswers[questionIdx]!;
      if (_isOptionCorrect(q, q.options[selIdx], selIdx)) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _transitionController.forward(from: 0.0);
    } else {
      _finishQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      _transitionController.forward(from: 0.0);
    }
  }

  void _finishQuiz() {
    setState(() {
      _quizFinished = true;
    });

    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd!.show();
      _isInterstitialAdLoaded = false;
      _interstitialAd = null;
    }
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswers.clear();
      _checkedQuestions.clear();
      _score = 0;
      _quizFinished = false;
    });
    _transitionController.forward(from: 0.0);
  }

  // --- Widget Builders ---
  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final Color backgroundColor = isLight ? const Color(0xFF0F172A) : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          widget.subject != null
              ? "${widget.subject!.toUpperCase()} - Grade ${widget.grade}"
              : "Smart X Exam Challenge",
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
        foregroundColor: isLight ? const Color(0xFF0F172A) : Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Challenge Specs"),
                  content: const Text(
                    "• Questions loaded from official Smart X database.\n"
                    "• Review option solutions offline.\n"
                    "• Use tips to reveal expert tutor insights.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Dismiss"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
          image: DecorationImage(
            image: const AssetImage('assets/images/education_bg_pattern.png'),
            repeat: ImageRepeat.repeat,
            opacity: isLight ? 0.08 : 0.02,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _buildMainContent(isLight),
              ),
              _buildBottomBanner(isLight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isLight) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              "Retrieving questions from Supabase...",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red[400], size: 48),
              const SizedBox(height: 16),
              Text(
                "Offline Setup / Network Error",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isLight ? const Color(0xFF0F172A) : Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadQuestions,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text("Retry Connection"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_late_outlined, size: 54, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                "No Exam Questions Available",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isLight ? const Color(0xFF0F172A) : Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "There are no questions posted for Grade ${widget.grade} ${widget.subject ?? ''} yet. Our tutors are creating new packages weekly.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.45),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1E88E5)),
                ),
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    if (_quizFinished) {
      return _buildResultsView(isLight);
    }

    return _buildQuestionsView(isLight);
  }

  Widget _buildQuestionsView(bool isLight) {
    final q = _questions[_currentQuestionIndex];
    final double percentage = (_currentQuestionIndex + 1) / _questions.length;
    final int questionIdx = _currentQuestionIndex;
    final bool hasSelected = _selectedAnswers.containsKey(questionIdx);
    final bool hasChecked = _checkedQuestions[questionIdx] ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bento progress indicator bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isLight ? Colors.white : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  ),
                ),
                child: Text(
                  "Question ${questionIdx + 1} of ${_questions.length}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isLight ? const Color(0xFF0F172A) : const Color(0xFF38BDF8),
                  ),
                ),
              ),
              // Use lightbulb indicator for tips
              if (q.explanation != null && q.explanation!.trim().isNotEmpty)
                IconButton(
                  onPressed: _showRewardedAd,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B).withOpacity(0.12),
                    foregroundColor: const Color(0xFFF59E0B),
                    padding: const EdgeInsets.all(8),
                  ),
                  icon: const Icon(Icons.lightbulb_rounded, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Linear matching progress
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 6,
              backgroundColor: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
            ),
          ),
          const SizedBox(height: 16),

          // Slide/Fade Animated Transition Container of question card
          AnimatedBuilder(
            animation: _transitionController,
            builder: (context, child) {
              final double slide = 12.0 * (1.0 - _transitionController.value);
              return Transform.translate(
                offset: Offset(0, slide),
                child: Opacity(
                  opacity: _transitionController.value,
                  child: child,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Unified card incorporating background, question text and options
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isLight ? Colors.white : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.015),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Unit & Subject tag label
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E88E5).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "UNIT ${q.unit}",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E88E5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            q.subject.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[500],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Question text
                      Text(
                        q.questionText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.45,
                          color: isLight ? const Color(0xFF0F172A) : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Render Multiple Options
                      ...List.generate(q.options.length, (optIdx) {
                        final String optionStr = q.options[optIdx];
                        final bool isSel = _selectedAnswers[questionIdx] == optIdx;
                        final bool isCorrectOpt = _isOptionCorrect(q, optionStr, optIdx);

                        // Colors changing based on validation state
                        Color optBg = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
                        Color borderCol = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
                        Color textCol = isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
                        IconData? trailingIcon;
                        Color? trailingCol;

                        if (hasChecked) {
                          if (isCorrectOpt) {
                            optBg = const Color(0xFF10B981).withOpacity(0.08);
                            borderCol = const Color(0xFF10B981);
                            textCol = const Color(0xFF10B981);
                            trailingIcon = Icons.check_circle_rounded;
                            trailingCol = const Color(0xFF10B981);
                          } else if (isSel) {
                            optBg = const Color(0xFFEF4444).withOpacity(0.08);
                            borderCol = const Color(0xFFEF4444);
                            textCol = const Color(0xFFEF4444);
                            trailingIcon = Icons.cancel_rounded;
                            trailingCol = const Color(0xFFEF4444);
                          }
                        } else {
                          if (isSel) {
                            optBg = const Color(0xFF1E88E5).withOpacity(0.08);
                            borderCol = const Color(0xFF1E88E5);
                            textCol = const Color(0xFF1E88E5);
                            trailingIcon = Icons.radio_button_checked_rounded;
                            trailingCol = const Color(0xFF1E88E5);
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: InkWell(
                            onTap: hasChecked
                                ? null
                                : () {
                                    setState(() {
                                      _selectedAnswers[questionIdx] = optIdx;
                                    });
                                  },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: optBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderCol, width: isSel || (hasChecked && isCorrectOpt) ? 2.0 : 1.1),
                              ),
                              child: Row(
                                children: [
                                  // Option letter bubble (A, B, C, etc)
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSel || (hasChecked && isCorrectOpt)
                                          ? borderCol
                                          : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      String.fromCharCode(65 + optIdx),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: isSel || (hasChecked && isCorrectOpt)
                                            ? Colors.white
                                            : (isLight ? const Color(0xFF475569) : Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      optionStr,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: isSel || (hasChecked && isCorrectOpt) ? FontWeight.bold : FontWeight.w500,
                                        color: textCol,
                                      ),
                                    ),
                                  ),
                                  if (trailingIcon != null) ...[
                                    const SizedBox(width: 6),
                                    Icon(trailingIcon, color: trailingCol, size: 18),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                
                // Slide up study explanation panel
                if (hasChecked && q.explanation != null && q.explanation!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.25), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.menu_book_rounded, color: Color(0xFFF59E0B), size: 16),
                            SizedBox(width: 6),
                            Text(
                              "TUTOR EXPLANATION",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFF59E0B),
                                letterSpacing: 0.5,
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
                            fontWeight: FontWeight.w600,
                            color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // TACTILE ACTIONS DOCK (BACK, CHECK/NEXT)
          Row(
            children: [
              // Back Button
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: questionIdx == 0 ? null : _previousQuestion,
                  icon: const Icon(Icons.chevron_left, size: 18),
                  label: const Text("Back"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: isLight ? const Color(0xFF475569) : Colors.white70,
                    disabledForegroundColor: Colors.grey[400],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Validate / Move Forward Action
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: !hasSelected
                      ? null
                      : (!hasChecked ? _checkAnswer : _nextQuestion),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !hasChecked ? const Color(0xFF1E88E5) : const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                  ),
                  child: Text(
                    !hasChecked
                        ? "Check Answer"
                        : (questionIdx == _questions.length - 1 ? "Submit & View Results" : "Next Question"),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // --- RESULT VIEW ---
  Widget _buildResultsView(bool isLight) {
    final double correctRatio = _score / _questions.length;
    final bool passed = correctRatio >= 0.70; // 70% threshold

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Cup / Trophy Circle indicator
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: passed ? const Color(0xFF10B981).withOpacity(0.12) : const Color(0xFFEF4444).withOpacity(0.12),
              ),
              child: Icon(
                passed ? Icons.emoji_events_rounded : Icons.info_outline_rounded,
                color: passed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              passed ? "Outstanding Effort!" : "Study and Try Again",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isLight ? const Color(0xFF0F172A) : Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              passed
                  ? "Congratulations! You scored high in the Smart X Academy challenge."
                  : "Go through the syllabus unit, watch tutorial videos and attempt again.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 24),

            // Score details row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text("CORRECT", style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Text(
                          "$_score / ${_questions.length}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isLight ? const Color(0xFF0F172A) : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text("ACCURACY", style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Text(
                          "${(correctRatio * 100).toInt()}%",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: passed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Restart Challenge
            ElevatedButton.icon(
              onPressed: _restartQuiz,
              icon: const Icon(Icons.replay, size: 16),
              label: const Text("Restart Assessment"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),

            // Exit Button
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                side: BorderSide(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                foregroundColor: isLight ? const Color(0xFF475569) : Colors.white,
              ),
              child: const Text("Return to Course Hub"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBanner(bool isLight) {
    if (_isBannerAdLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    return Container(
      height: 48,
      color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.ad_units, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            "AdMob Test Banners Active",
            style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
