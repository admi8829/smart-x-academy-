import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question_model.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_limiter.dart';

class QuizService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches filtered questions from Supabase.
  /// If [grade] is supplied, filters by grade.
  /// If [subject] is supplied, filters by subject (case-insensitive).
  /// If [unit] is supplied, filters by unit.
  static Future<List<QuestionModel>> fetchQuestions({
    required int grade,
    String? subject,
    int? unit,
  }) async {
    try {
      SupabaseRequestLimiter.increment();
      // Build dynamic section_id: "grade_${grade}_${subject.toLowerCase().substring(0, 4)}_${unit}"
      String subPrefix = (subject ?? "physics").toLowerCase().trim();
      if (subPrefix.length > 4) {
        subPrefix = subPrefix.substring(0, 4);
      }
      final String sectionId = "grade_${grade}_${subPrefix}_${unit ?? 1}";

      debugPrint("QuizService: Fetching questions with section_id = $sectionId");

      final response = await _supabase
          .from('questions')
          .select()
          .eq('section_id', sectionId)
          .order('id', ascending: true);
      
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => QuestionModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Supabase query failed: $e');
      rethrow;
    }
  }

  /// Submits the student's quiz score to the user_progress table.
  static Future<void> submitLeaderboardScore({
    required String fullName,
    required String phoneNumber,
    required String subjectId,
    required int unitId,
    required int score,
    required int totalQuestions,
  }) async {
    try {
      SupabaseRequestLimiter.increment();
      final prefs = await SharedPreferences.getInstance();
      final String studentId = prefs.getString('user_id') ?? 'user_${DateTime.now().millisecondsSinceEpoch}';

      await _supabase.from('user_progress').insert({
        'user_id': studentId,
        'subject_id': subjectId,
        'unit_id': unitId,
        'score': score,
        'total_questions': totalQuestions,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint("QuizService: Quiz score submitted successfully to user_progress.");
    } catch (e) {
      debugPrint('Supabase user_progress insertion failed: $e');
      rethrow;
    }
  }
}
