import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class DynamicQuizScreen extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;

  const DynamicQuizScreen({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    required this.onToggleTheme,
    required this.onToggleLanguage,
  });

  @override
  State<DynamicQuizScreen> createState() => _DynamicQuizScreenState();
}

class _DynamicQuizScreenState extends State<DynamicQuizScreen> with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;

  // --- Configuration Selections ---
  int _selectedGrade = 9;
  String _selectedSubject = "Physics";
  int _selectedUnit = 1;

  final List<int> _gradesList = [9, 10, 11, 12];
  final List<String> _subjectsList = [
    "Physics",
    "Chemistry",
    "Biology",
    "Mathematics",
    "Geography",
    "History",
    "Civics",
    "Agriculture"
  ];
  final List<int> _unitsList = [1, 2, 3, 4, 5, 6, 7, 8];

  // --- Quiz & Data State ---
  bool _isPlaying = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _questions = [];

  int _currentIndex = 0;
  int? _selectedOptionIndex; // null if not selected yet
  bool _isAnswerChecked = false;
  int _correctCount = 0;

  late final AnimationController _cardAnimController;

  @override
  void initState() {
    super.initState();
    _cardAnimController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _cardAnimController.dispose();
    super.dispose();
  }

  // --- 1. Generate Section ID Dynamically ---
  String _generateSectionId() {
    // String sectionId = "grade_${grade}_${subject.toLowerCase().substring(0, 4)}_${unit}";
    String subPrefix = _selectedSubject.toLowerCase();
    if (subPrefix.length > 4) {
      subPrefix = subPrefix.substring(0, 4);
    }
    return "grade_${_selectedGrade}_${subPrefix}_$_selectedUnit";
  }

  // --- 2. Fetch Questions from Supabase ---
  Future<void> _fetchQuestionsFromSupabase() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _questions = [];
      _isPlaying = false;
    });

    final String sectionId = _generateSectionId();
    debugPrint("Fetching questions for section_id: $sectionId");

    try {
      final response = await supabase
          .from('questions')
          .select()
          .eq('section_id', sectionId);

      final List<dynamic> data = response as List<dynamic>;

      if (data.isEmpty) {
        throw Exception(
          widget.languageCode == 'en'
              ? "No questions found in Supabase database for: '$sectionId'."
              : "ለዚህ ክፍል '$sectionId' በሱፓቤስ ባንክ ውስጥ ምንም ጥያቄ አልተገኘም።"
        );
      }

      setState(() {
        // Convert to secure Map list
        _questions = data.map((item) => Map<String, dynamic>.from(item)).toList();
        _isLoading = false;
        _isPlaying = true;
        _currentIndex = 0;
        _selectedOptionIndex = null;
        _isAnswerChecked = false;
        _correctCount = 0;
      });
      _cardAnimController.forward(from: 0.0);

    } catch (e) {
      debugPrint("Supabase fetch failed: $e");
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  // --- 3. Validate Answer & Highlight ---
  void _submitAnswer() {
    if (_selectedOptionIndex == null || _isAnswerChecked) return;

    final currentQuestion = _questions[_currentIndex];
    final selectedLetter = String.fromCharCode(65 + _selectedOptionIndex!); // 'A', 'B', 'C', 'D'
    final correctAnswerStr = (currentQuestion['correct_answer'] ?? '').toString().trim().toUpperCase();

    bool isCorrect = false;
    if (correctAnswerStr == selectedLetter) {
      isCorrect = true;
    } else {
      // Fallback check: Direct option text match
      final Map<int, String> indexToKey = {0: 'option_a', 1: 'option_b', 2: 'option_c', 3: 'option_d'};
      final String optionKey = indexToKey[_selectedOptionIndex!]!;
      final selectedText = (currentQuestion[optionKey] ?? '').toString().trim().toLowerCase();
      if (selectedText == correctAnswerStr.toLowerCase()) {
        isCorrect = true;
      }
    }

    setState(() {
      _isAnswerChecked = true;
      if (isCorrect) {
        _correctCount++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
        _isAnswerChecked = false;
      });
      _cardAnimController.forward(from: 0.0);
    } else {
      _showResultsSummary();
    }
  }

  void _showResultsSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isThemeLight = Theme.of(ctx).brightness == Brightness.light;
        return AlertDialog(
          backgroundColor: isThemeLight ? Colors.white : const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
              const SizedBox(width: 8),
              Text(
                widget.languageCode == 'en' ? "Practice Complete!" : "ልምምዱ ተጠናቋል!",
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.languageCode == 'en'
                    ? "Congratulations on completing this unit assessment."
                    : "እንኳን ደስ አላችሁ! የዚህን ክፍል ፈተና በተሳካ ሁኔታ አጠናቀዋል።",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isThemeLight ? Colors.grey[700] : Colors.grey[300],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.languageCode == 'en' ? "Your Score:" : "የእርስዎ ውጤት:",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    Text(
                      "$_correctCount / ${_questions.length}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _isPlaying = false;
                  _questions = [];
                });
              },
              child: Text(
                widget.languageCode == 'en' ? "Return to Config" : "ወደ ምርጫው ይመለሱ",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Translation Helper ---
  String _translate(String en, String am) {
    return widget.languageCode == 'am' ? am : en;
  }

  // --- UI Layout ---
  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final Color bgColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
        foregroundColor: isLight ? const Color(0xFF0D2353) : Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _translate("Supabase Exam Simulator", "ሱፓቤስ የፈተና መለማመጃ"),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.3),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.wb_sunny_rounded : Icons.nights_stay_outlined,
              size: 20,
            ),
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.translate, size: 20),
            onPressed: widget.onToggleLanguage,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
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
                child: _isLoading
                    ? _buildLoadingState()
                    : (_errorMessage != null
                        ? _buildErrorState()
                        : (_isPlaying ? _buildActiveQuiz(isLight) : _buildCustomSelector(isLight))),
              ),
              _buildModernFooter(isLight),
            ],
          ),
        ),
      ),
    );
  }

  // --- LOADING INDICATOR STATE ---
  Widget _buildLoadingState() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        elevation: 1,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(strokeWidth: 3.5),
              ),
              const SizedBox(height: 24),
              Text(
                _translate("Fetching exam data from Supabase...", "ጥያቄዎችን ከሱፓቤስ ሰርቨር በማውረድ ላይ..."),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                _translate("Retrieving requested section_id: '${_generateSectionId()}'", "የተጠየቀውን ክፍል ቁጥር ፈልጎ በማምጣት ላይ: '${_generateSectionId()}'"),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ERROR STATE ---
  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        child: Card(
          margin: const EdgeInsets.all(24),
          color: Theme.of(context).cardColor,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 54, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  _translate("Query Failure / Offline Structure", "የጥያቄ ስህተት / ከመስመር ውጭ የዳታ አወቃቀር"),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.redAccent),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.45),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _fetchQuestionsFromSupabase,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(_translate("Retry Request", "እንደገና ሞክር")),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                  child: Text(_translate("Change Choice", "ምርጫ ይቀይሩ")),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- PARAMETER SELECTOR SCREEN ---
  Widget _buildCustomSelector(bool isLight) {
    final cardBg = isLight ? Colors.white : const Color(0xFF1E293B);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Graphic Intro Poster Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLight
                    ? [const Color(0xFF0D2353), const Color(0xFF193B7D)]
                    : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.2), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      "SMART X COMPILER",
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _translate("Custom Exam Builder", "ብጁ የፈተና አውጪ ማዕከል"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _translate(
                    "Pick any grade, subject, and syllabus unit. We will dynamically compile the matching 'section_id' query and pull the real-time tutor-verified questions list from Supabase.",
                    "የማንኛውንም ክፍል፣ የትምህርት አይነት፣ እና ክፍል ቁጥር ይምረጡ። ስርዓተ-ትምህርቱ በራስ-ሰር የአሰሳ ቁልፉን አዋቅሮ ጥያቄዎችን በቀጥታ ከሱፓቤስ ዳታቤዝ ያወርዳል::",
                  ),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12.5,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Parameter Selectors Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. GRADE DROPDOWN
                _buildSelectorLabel(_translate("1. Select Grade Level", "፩. ክፍል ደረጃ ይምረጡ")),
                const SizedBox(height: 8),
                _buildGradeDropdown(isLight),
                const SizedBox(height: 18),

                // 2. SUBJECT DROPDOWN
                _buildSelectorLabel(_translate("2. Select Subject", "፪. የትምህርት አይነት")),
                const SizedBox(height: 8),
                _buildSubjectDropdown(isLight),
                const SizedBox(height: 18),

                // 3. UNIT DROPDOWN
                _buildSelectorLabel(_translate("3. Select Unit / Chapter", "፫. ክፍል / ምዕራፍ")),
                const SizedBox(height: 8),
                _buildUnitDropdown(isLight),
                const SizedBox(height: 18),

                const Divider(height: 24),

                // SECTION ID PREVIEW
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _translate("Query Key (section_id):", "አሰሳ መግለጫ (section_id):"),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isLight ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
                      Text(
                        _generateSectionId(),
                        style: const TextStyle(
                          fontFamily: "monospace",
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SUBMIT TRIGGER BUTTON
          ElevatedButton.icon(
            onPressed: _fetchQuestionsFromSupabase,
            icon: const Icon(Icons.cloud_download_rounded, size: 20),
            label: Text(
              _translate("Extract & Start Practice", "ጥያቄዎችን አውጥተህ ፈተና ጀምር"),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D2353),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildGradeDropdown(bool isLight) {
    return DropdownButtonFormField<int>(
      value: _selectedGrade,
      dropdownColor: isLight ? Colors.white : const Color(0xFF1E293B),
      decoration: _buildInputDecoration(isLight),
      items: _gradesList.map((g) {
        return DropdownMenuItem<int>(
          value: g,
          child: Text(
            widget.languageCode == 'am' ? "ክፍል $g" : "Grade $g",
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedGrade = val);
      },
    );
  }

  Widget _buildSubjectDropdown(bool isLight) {
    return DropdownButtonFormField<String>(
      value: _selectedSubject,
      dropdownColor: isLight ? Colors.white : const Color(0xFF1E293B),
      decoration: _buildInputDecoration(isLight),
      items: _subjectsList.map((s) {
        return DropdownMenuItem<String>(
          value: s,
          child: Text(
            s,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedSubject = val);
      },
    );
  }

  Widget _buildUnitDropdown(bool isLight) {
    return DropdownButtonFormField<int>(
      value: _selectedUnit,
      dropdownColor: isLight ? Colors.white : const Color(0xFF1E293B),
      decoration: _buildInputDecoration(isLight),
      items: _unitsList.map((u) {
        return DropdownMenuItem<int>(
          value: u,
          child: Text(
            widget.languageCode == 'am' ? "ምዕራፍ $u" : "Unit $u",
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedUnit = val);
      },
    );
  }

  InputDecoration _buildInputDecoration(bool isLight) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      filled: true,
      fillColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isLight ? const Color(0xFFCBD5E1).withOpacity(0.6) : const Color(0xFF334155).withOpacity(0.6),
        ),
      ),
    );
  }

  // --- ACTIVE QUIZ PLAYGROUND UI ---
  Widget _buildActiveQuiz(bool isLight) {
    final q = _questions[_currentIndex];
    final double percentage = (_currentIndex + 1) / _questions.length;
    final bool hasSelected = _selectedOptionIndex != null;

    // Map database columns to displayable list
    final List<String> options = [
      (q['option_a'] ?? '').toString(),
      (q['option_b'] ?? '').toString(),
      (q['option_c'] ?? '').toString(),
      (q['option_d'] ?? '').toString(),
    ].where((opt) => opt.trim().isNotEmpty).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sub heading with Progress Numbers & Cancel triggers
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
                  "${_translate("Question", "ጥያቄ")} ${_currentIndex + 1} ${_translate("of", "ከ")} ${_questions.length}",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.cancel_outlined, size: 20),
                onPressed: () {
                  setState(() {
                    _isPlaying = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Linear tracking progress
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 5,
              backgroundColor: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
          ),
          const SizedBox(height: 20),

          // Scale & slide animated Card transitions
          AnimatedBuilder(
            animation: _cardAnimController,
            builder: (ctx, child) {
              final double slide = 12.0 * (1.0 - _cardAnimController.value);
              return Transform.translate(
                offset: Offset(0, slide),
                child: Opacity(
                  opacity: _cardAnimController.value,
                  child: child,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Highlight Question Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isLight ? Colors.white : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.012),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Syllabus category reference Tag Labels
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _generateSectionId().toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _translate("LIVE SUPABASE FEED", "የቀጥታ ጥያቄዎች"),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[500],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Raw Question text from DB
                      Text(
                        (q['question'] ?? '').toString(),
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Options Generator
                      ...List.generate(options.length, (idx) {
                        final String optText = options[idx];
                        final String letter = String.fromCharCode(65 + idx); // 'A', 'B', 'C', 'D'
                        final bool isSel = _selectedOptionIndex == idx;

                        final String correctAnswerStr = (q['correct_answer'] ?? '').toString().trim().toUpperCase();
                        final bool isThisTheCorrectAnswerCode = correctAnswerStr == letter;

                        // Calculate visual colors
                        Color itemBg = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
                        Color sideBorder = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
                        Color txtColor = isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
                        IconData? checkIcon;

                        if (_isAnswerChecked) {
                          if (isThisTheCorrectAnswerCode) {
                            itemBg = const Color(0xFF10B981).withOpacity(0.08);
                            sideBorder = const Color(0xFF10B981);
                            txtColor = const Color(0xFF10B981);
                            checkIcon = Icons.check_circle_rounded;
                          } else if (isSel) {
                            itemBg = const Color(0xFFEF4444).withOpacity(0.08);
                            sideBorder = const Color(0xFFEF4444);
                            txtColor = const Color(0xFFEF4444);
                            checkIcon = Icons.cancel_rounded;
                          }
                        } else {
                          if (isSel) {
                            itemBg = Colors.blue.withOpacity(0.08);
                            sideBorder = Colors.blueAccent;
                            txtColor = Colors.blueAccent;
                            checkIcon = Icons.radio_button_checked_rounded;
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: _isAnswerChecked
                                ? null
                                : () {
                                    setState(() {
                                      _selectedOptionIndex = idx;
                                    });
                                  },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: itemBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: sideBorder,
                                  width: isSel || (_isAnswerChecked && isThisTheCorrectAnswerCode) ? 2.0 : 1.1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Letter Bubble Indicator
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSel || (_isAnswerChecked && isThisTheCorrectAnswerCode)
                                          ? sideBorder
                                          : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      letter,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSel || (_isAnswerChecked && isThisTheCorrectAnswerCode)
                                            ? Colors.white
                                            : (isLight ? const Color(0xFF475569) : Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Text(
                                      optText,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSel || (_isAnswerChecked && isThisTheCorrectAnswerCode) ? FontWeight.bold : FontWeight.w500,
                                        color: txtColor,
                                      ),
                                    ),
                                  ),

                                  if (checkIcon != null) ...[
                                    const SizedBox(width: 8),
                                    Icon(checkIcon, color: sideBorder, size: 18),
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

                // Reveal Tutor Explanation card dynamically if answered
                if (_isAnswerChecked && q['explanation'] != null && q['explanation'].toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb, color: Color(0xFFF59E0B), size: 16),
                            SizedBox(width: 6),
                            Text(
                              "TUTOR EXPLANATION",
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFF59E0B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          q['explanation'].toString(),
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
          const SizedBox(height: 24),

          // ACTIONS PANEL (Back to dashboard, Validate / Next question)
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isPlaying = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _translate("Dashboard", "ዳሽቦርድ"),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isLight ? const Color(0xFF475569) : Colors.white70),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: !hasSelected ? null : (!_isAnswerChecked ? _submitAnswer : _nextQuestion),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !_isAnswerChecked ? const Color(0xFF0D2353) : const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                  ),
                  child: Text(
                    !_isAnswerChecked
                        ? _translate("Check Answer", "መልስህን አረጋግጥ")
                        : (_currentIndex == _questions.length - 1 ? _translate("Finish Assessment", "ልምምድ ጨርስ") : _translate("Next Question", "ቀጣይ ጥያቄ")),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- STANDARD PRETTY FOOTER ---
  Widget _buildModernFooter(bool isLight) {
    return Container(
      width: double.infinity,
      color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user, size: 14, color: Colors.blueAccent),
          const SizedBox(width: 6),
          Text(
            _translate("Supabase Engine Active • Real-time DB Link", "ሱፓቤስ ሞተር ንቁ • የቀጥታ ግንኙነት"),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
