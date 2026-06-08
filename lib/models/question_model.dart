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
    }

    return QuestionModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.parse(json['id'].toString()),
      grade: json['grade'] is num ? (json['grade'] as num).toInt() : int.parse(json['grade'].toString()),
      subject: json['subject'] as String? ?? '',
      unit: json['unit'] is num ? (json['unit'] as num).toInt() : int.parse(json['unit'].toString()),
      questionText: json['question_text'] as String? ?? json['questionText'] as String? ?? '',
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
