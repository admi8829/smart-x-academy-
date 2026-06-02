import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_helper.dart';

class QuizQuestion {
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final String hint;

  const QuizQuestion({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    required this.hint,
  });
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // --- Quiz State ---
  final List<QuizQuestion> _questions = const [
    QuizQuestion(
      questionText: "What is the capital city of Ethiopia?",
      options: ["Asmara", "Addis Ababa", "Nairobi", "Djibouti"],
      correctAnswerIndex: 1,
      hint: "It is the third highest capital in the world and means 'New Flower'.",
    ),
    QuizQuestion(
      questionText: "Which chemical element has the symbol 'Au'?",
      options: ["Silver", "Gold", "Copper", "Platinum"],
      correctAnswerIndex: 1,
      hint: "It has atomic number 79 and is highly prized for jewelry and investment.",
    ),
    QuizQuestion(
      questionText: "In which year did Ethiopia defeat the Italian army at the Battle of Adwa?",
      options: ["1889", "1896", "1935", "1941"],
      correctAnswerIndex: 1,
      hint: "It happened on the 1st of March in a leap year during the late 19th century.",
    ),
    QuizQuestion(
      questionText: "What is the primary power generation source of the Grand Ethiopian Renaissance Dam (GERD)?",
      options: ["Hydroelectric", "Geothermal", "Solar Power", "Wind Energy"],
      correctAnswerIndex: 0,
      hint: "It utilizes the mighty Blue Nile flow running through massive water turbos.",
    ),
  ];

  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  int _score = 0;
  bool _quizFinished = false;
  bool _hasUsedHintForCurrentQuestion = false;

  // --- AdMob Ads State ---
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  // --- BANNER AD ---
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isBannerAdReady = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err. Code: ${err.code}');
          ad.dispose();
          // Fail gracefully, keep state unchanged
        },
      ),
    );
    _bannerAd?.load();
  }

  // --- INTERSTITIAL AD ---
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdLoaded = false;
              // Push to final score results page
              _finishQuizAfterAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              debugPrint('InterstitialAd failed to show: $err');
              ad.dispose();
              _isInterstitialAdLoaded = false;
              _finishQuizAfterAd(); // Fail gracefully and proceed
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('InterstitialAd failed to load: $err');
          _isInterstitialAdLoaded = false;
          // Soft failure - the user won't experience blocking
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      debugPrint('Interstitial ad not loaded. Fallback directly.');
      _finishQuizAfterAd();
    }
  }

  // --- REWARDED AD ---
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isRewardedAdLoaded = false;
              _loadRewardedAd(); // Preload next one
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              debugPrint('Rewarded ad failed to show: $err');
              ad.dispose();
              _isRewardedAdLoaded = false;
              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('Rewarded ad failed to load: $err');
          _isRewardedAdLoaded = false;
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          if (mounted) {
            setState(() {
              _hasUsedHintForCurrentQuestion = true;
            });
            _showHintDialog();
          }
        },
      );
    } else {
      // "Ad failed to load: 3" No Fill handling
      // Provide a graceful fallback to ensure the student's learning flow is not halted
      debugPrint('Rewarded ad not ready. Fallback active.');
      if (mounted) {
        setState(() {
          _hasUsedHintForCurrentQuestion = true;
        });
        _showHintDialog(isFallback: true);
      }
      _loadRewardedAd(); // Attempt to load a new ad
    }
  }

  // --- Helpers & Actions ---
  void _submitAnswer() {
    if (_selectedAnswerIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an option before continuing!"),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Check correctness
    final currentQ = _questions[_currentQuestionIndex];
    if (_selectedAnswerIndex == currentQ.correctAnswerIndex) {
      _score++;
    }

    // Advance Quiz or Show Interstitial at the finish
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _hasUsedHintForCurrentQuestion = false;
      });
    } else {
      // Quiz Finished! trigger Interstitial Ad
      _showInterstitialAd();
    }
  }

  void _finishQuizAfterAd() {
    if (mounted) {
      setState(() {
        _quizFinished = true;
      });
    }
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswerIndex = null;
      _score = 0;
      _quizFinished = false;
      _hasUsedHintForCurrentQuestion = false;
    });
    // Preload fresh ads for the brand-new run
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  void _showHintDialog({bool isFallback = false}) {
    final currentQ = _questions[_currentQuestionIndex];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFF0F172A),
          title: Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.amber, size: 28),
              const SizedBox(width: 10),
              Text(
                isFallback ? "Unlocked Fast-Hint" : "Quiz Hint Unlocked!",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isFallback)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    "Note: No video loading wait, granted hint instantly!",
                    style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ),
              Text(
                currentQ.hint,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Help Tip: Match with options closely.",
                        style: TextStyle(color: Color(0xFF34D399), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Got it!",
                style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // --- Memory Leak Prevention ---
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final primaryBlue = const Color(0xFF0D2353);

    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          "Smart X Quiz Arena",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Quick dialog describing reward schema
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Quiz Information"),
                  content: const Text(
                    "This test utilizes AdMob Test Ads:\n"
                    "• Rewarded Video Ads play if you unlock a Quiz Hint.\n"
                    "• Interstitial Ads run when the test successfully finishes.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _quizFinished
                  ? _buildResultsView(isLight, primaryBlue)
                  : _buildQuestionsView(isLight, primaryBlue),
            ),
            
            // --- Bottom Anchor AdMob Banner ---
            if (_isBannerAdReady && _bannerAd != null)
              Container(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                color: Colors.transparent,
                alignment: Alignment.center,
                child: AdWidget(ad: _bannerAd!),
              )
            else
              // Elegant tiny matching space fallback (no jarring layout shift)
              Container(
                height: 50,
                color: isLight ? Colors.grey[200] : const Color(0xFF1E293B),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.ad_units, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      "Banner Ad Area (Test AdMob Loaded)",
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- QUESTIONS MAIN LAYOUT ---
  Widget _buildQuestionsView(bool isLight, Color primaryBlue) {
    final currentQ = _questions[_currentQuestionIndex];
    final double percentage = (_currentQuestionIndex + 1) / _questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Elegant Header Progress Bento Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isLight ? Colors.white : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLight ? Colors.grey[300]! : Colors.transparent,
                  ),
                ),
                child: Text(
                  "Question ${_currentQuestionIndex + 1} of ${_questions.length}",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isLight ? primaryBlue : const Color(0xFF38BDF8),
                  ),
                ),
              ),
              
              // REWARDED VIDEO HINT BUTTON
              ElevatedButton.icon(
                onPressed: _showRewardedAd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B), // Vibrant Amber Accent
                  foregroundColor: Colors.white,
                  elevation: 1.5,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.lightbulb_outline, size: 16),
                label: Text(
                  _hasUsedHintForCurrentQuestion ? "Hint Active 💡" : "Get Hint 💡",
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Smoother Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 10,
              backgroundColor: isLight ? Colors.grey[300] : const Color(0xFF334155),
              valueColor: AlwaysStoppedAnimation<Color>(
                isLight ? const Color(0xFF1E88E5) : const Color(0xFF0EA5E9),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // STYLISH QUESTION CARD
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLight 
                    ? [Colors.white, const Color(0xFFF8FAFC)]
                    : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isLight ? 0.05 : 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: isLight ? Colors.grey[200]! : const Color(0xFF334155),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: Color(0xFF1E88E5),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "ACADEMY CHALLENGE",
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  currentQ.questionText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                    color: isLight ? primaryBlue : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // MULTIPLE CHOICE OPTIONS
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: currentQ.options.length,
            itemBuilder: (context, index) {
              final optionText = currentQ.options[index];
              final isSelected = _selectedAnswerIndex == index;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedAnswerIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isLight
                                ? const Color(0xFF1E88E5).withOpacity(0.08)
                                : const Color(0xFF38BDF8).withOpacity(0.12))
                            : (isLight ? Colors.white : const Color(0xFF1E293B)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? (isLight ? const Color(0xFF1E88E5) : const Color(0xFF38BDF8))
                              : (isLight ? Colors.grey[200]! : Colors.transparent),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          if (!isSelected)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Modern circular indexing
                          Container(
                            height: 28,
                            width: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? (isLight ? const Color(0xFF1E88E5) : const Color(0xFF38BDF8))
                                  : (isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              String.fromCharCode(65 + index), // A, B, C, D
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : (isLight ? primaryBlue : Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              optionText,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? (isLight ? const Color(0xFF1E88E5) : const Color(0xFF38BDF8))
                                    : (isLight ? primaryBlue : const Color(0xFFCBD5E1)),
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: isLight ? const Color(0xFF1E88E5) : const Color(0xFF38BDF8),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 18),
          
          // ACTION BUTTONS (SUBMIT/NEXT)
          ElevatedButton(
            onPressed: _submitAnswer,
            style: ElevatedButton.styleFrom(
              backgroundColor: isLight ? primaryBlue : const Color(0xFF38BDF8),
              foregroundColor: isLight ? Colors.white : Colors.black,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: Text(
              _currentQuestionIndex == _questions.length - 1 ? "Submit Challenge" : "Continue",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.2),
            ),
          ),
        ],
      ),
    );
  }

  // --- FINAL SCORE RESULTS VIEW ---
  Widget _buildResultsView(bool isLight, Color primaryBlue) {
    final double correctRatio = _score / _questions.length;
    final bool passed = correctRatio >= 0.75;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Card(
        color: isLight ? Colors.white : const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.06),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Beautiful animated-like badge
              Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: passed ? const Color(0xFF10B981).withOpacity(0.12) : Colors.red[500]!.withOpacity(0.12),
                ),
                child: Icon(
                  passed ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                  color: passed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  size: 46,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                passed ? "Congratulations!" : "Keep Practicing!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isLight ? primaryBlue : Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                passed
                    ? "You qualified with flying colors in Smart X Arena!"
                    : "Review the course materials and syllabus and try again.",
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // BENTO RESULT DIGIT BOXES
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLight ? Colors.grey[200]! : const Color(0xFF334155),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text("SCORE", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            "${_score}/${_questions.length}",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isLight ? primaryBlue : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLight ? Colors.grey[200]! : const Color(0xFF334155),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text("PERCENTAGE", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            "${(correctRatio * 100).toInt()}%",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: passed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // RESTART BUTTON
              ElevatedButton.icon(
                onPressed: _restartQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: passed ? const Color(0xFF1E88E5) : const Color(0xFF64748B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.replay_rounded),
                label: const Text(
                  "Restart Arena Challenge",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // GO BACK HOME BUTTON
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(
                    color: isLight ? Colors.grey[300]! : const Color(0xFF334155),
                  ),
                ),
                child: Text(
                  "Exit to Lobby",
                  style: TextStyle(
                    color: isLight ? primaryBlue : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
