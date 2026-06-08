import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question_model.dart';
import 'package:flutter/foundation.dart';

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
}
