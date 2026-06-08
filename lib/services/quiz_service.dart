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
      var query = _supabase.from('questions').select();

      // Filter by grade
      query = query.eq('grade', grade);

      // Filter by subject if specified (using ilike for case-insensitive matches)
      if (subject != null && subject.trim().isNotEmpty) {
        query = query.ilike('subject', subject.trim());
      }

      // Filter by unit if specified
      if (unit != null) {
        query = query.eq('unit', unit);
      }

      // Order by ID or random
      final response = await query.order('id', ascending: true);
      
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => QuestionModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Supabase query failed: $e');
      rethrow;
    }
  }
}
