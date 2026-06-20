import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizScreen extends StatefulWidget {
  final int grade;
  final String? subject;
  final int? unit;

  const QuizScreen({
    super.key,
    required this.grade,
    this.subject,
    this.unit,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _questions = [];
  
  int _currentIndex = 0;
  final Map<int, int> _selectedAnswers = {};
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
      _currentIndex = 0;
      _itemKeys.clear();
    });

    try {
      final response = await Supabase.instance.client
          .from('questions')
          .select('*, options(*), correct_answers(*)')
          .eq('unit_id', widget.unit ?? 1)
          .order('id');
          
      final data = List<Map<String, dynamic>>.from(response as List);
      
      for (var i = 0; i < data.length; i++) {
        _itemKeys[i] = GlobalKey();
      }

      setState(() {
        _questions = data;
        _isLoading = false;
      });
      
      if (_questions.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToIndex(0);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load quiz. Please check your connection.";
        _isLoading = false;
      });
      debugPrint("Error loading questions: $e");
    }
  }

  void _onOptionSelected(int qIndex, int optionIndex) {
    setState(() {
      _selectedAnswers[qIndex] = optionIndex;
    });

    if (qIndex < _questions.length - 1) {
      setState(() => _currentIndex = qIndex + 1);
      _scrollToIndex(qIndex + 1);
    } else {
      // Reached the end, scroll to finish section
      setState(() => _currentIndex = qIndex + 1);
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
      setState(() => _currentIndex = index);
      _scrollToIndex(index);
    }
  }

  void _scrollToIndex(int index) {
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

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final backgroundColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final titleTextColor = isLight ? const Color(0xFF0F172A) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.subject != null ? "${widget.subject!.toUpperCase()} QUIZ" : "QUIZ",
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: titleTextColor,
        centerTitle: true,
      ),
      body: _buildBody(),
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

  Widget _buildQuestionCard(int index, Map<String, dynamic> q) {
    final isActive = index == _currentIndex;
    final opacity = isActive ? 1.0 : 0.4;
    
    final optionsData = q['options'] is List ? (q['options'] as List) : [];
    
    // Support generic question structures
    final qText = q['question_text']?.toString() ?? q['question']?.toString() ?? 'Challenge details missing.';

    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final cardColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final descColor = isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);

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
                final optMap = entry.value as Map<String, dynamic>;
                
                final optText = optMap['option_text']?.toString() ?? 
                                optMap['text']?.toString() ?? 
                                optMap['option']?.toString() ?? 
                                'Option ${optIdx + 1}';
                
                final isSelected = _selectedAnswers[index] == optIdx;

                final Color borderCol = isSelected
                    ? const Color(0xFF3B82F6)
                    : (isLight ? const Color(0xFFEDF2F7) : const Color(0xFF475569));
                final Color bgCol = isSelected
                    ? const Color(0xFF3B82F6).withOpacity(isLight ? 0.08 : 0.15)
                    : Colors.transparent;
                final Color txtCol = isSelected ? const Color(0xFF3B82F6) : descColor;

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
                        width: isSelected ? 2.0 : 1.2,
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
                            optText,
                            style: TextStyle(
                              fontSize: 15,
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
    );
  }

  Widget _buildFinishedSection() {
    final bool allAnswered = _selectedAnswers.length == _questions.length;
    
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
              child: const Text("View Results", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  void _showResults() {
    int score = 0;
    
    for (int i = 0; i < _questions.length; i++) {
        final q = _questions[i];
        final correctAnsList = q['correct_answers'] is List ? (q['correct_answers'] as List) : [];
        if (correctAnsList.isNotEmpty && _selectedAnswers.containsKey(i)) {
            final selectedIdx = _selectedAnswers[i];
            final optionsData = q['options'] is List ? (q['options'] as List) : [];
            
            if (selectedIdx != null && selectedIdx < optionsData.length) {
                final selectedOption = optionsData[selectedIdx];
                final isCorrect = correctAnsList.any((ans) => 
                     ans['option_id'] == selectedOption['id'] || 
                     ans['text'] == selectedOption['option_text'] ||
                     ans['id'] == selectedOption['id']);
                
                if (isCorrect) score++;
            }
        }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Center(child: Text("Results", style: TextStyle(fontWeight: FontWeight.w900))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 64),
            const SizedBox(height: 16),
            Text(
              "You scored $score out of ${_questions.length}!",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text("Finish", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      )
    );
  }
}
