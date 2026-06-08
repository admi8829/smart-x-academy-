class QuestionModel {
  final int id;
  final int grade;
  final String subject;
  final int unit;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final String? createdAt;

  QuestionModel({
    required this.id,
    required this.grade,
    required this.subject,
    required this.unit,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.createdAt,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedOptions = [];
    if (json['options'] != null) {
      if (json['options'] is List) {
        parsedOptions = List<String>.from((json['options'] as List).map((item) => item.toString()));
      }
    } else {
      // Decode from option_a, option_b, option_c, option_d if available
      final oA = json['option_a'];
      final oB = json['option_b'];
      final oC = json['option_c'];
      final oD = json['option_d'];
      if (oA != null && oA.toString().trim().isNotEmpty) parsedOptions.add(oA.toString());
      if (oB != null && oB.toString().trim().isNotEmpty) parsedOptions.add(oB.toString());
      if (oC != null && oC.toString().trim().isNotEmpty) parsedOptions.add(oC.toString());
      if (oD != null && oD.toString().trim().isNotEmpty) parsedOptions.add(oD.toString());
    }

    // Parse grade, subject, unit from section_id if not present
    int parsedGrade = 9;
    String parsedSubject = '';
    int parsedUnit = 1;
    
    final sectionId = json['section_id']?.toString() ?? '';
    if (sectionId.isNotEmpty) {
      final parts = sectionId.split('_');
      if (parts.length >= 4) {
        // e.g. "grade_9_phys_1"
        parsedGrade = int.tryParse(parts[1]) ?? 9;
        parsedSubject = parts[2].toUpperCase();
        parsedUnit = int.tryParse(parts[3]) ?? 1;
      }
    }

    final int finalGrade = json['grade'] is num 
        ? (json['grade'] as num).toInt() 
        : (json['grade'] != null ? (int.tryParse(json['grade'].toString()) ?? parsedGrade) : parsedGrade);

    final String finalSubject = json['subject'] as String? ?? parsedSubject;

    final int finalUnit = json['unit'] is num 
        ? (json['unit'] as num).toInt() 
        : (json['unit'] != null ? (int.tryParse(json['unit'].toString()) ?? parsedUnit) : parsedUnit);

    return QuestionModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.parse(json['id'].toString()),
      grade: finalGrade,
      subject: finalSubject,
      unit: finalUnit,
      questionText: json['question'] as String? ?? json['question_text'] as String? ?? json['questionText'] as String? ?? '',
      options: parsedOptions,
      correctAnswer: json['correct_answer'] as String? ?? json['correctAnswer'] as String? ?? '',
      explanation: json['explanation'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grade': grade,
      'subject': subject,
      'unit': unit,
      'question_text': questionText,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'created_at': createdAt,
    };
  }
}
