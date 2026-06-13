class CognitiveScore {
  final String id;
  final String userEmail;
  final String testType;
  final DateTime date;
  final double score;
  final double maxScore;
  final int reactionTimeMs;
  final int correctAnswers;
  final int totalQuestions;
  final String notes;

  CognitiveScore({
    required this.id,
    required this.userEmail,
    required this.testType,
    required this.date,
    required this.score,
    required this.maxScore,
    this.reactionTimeMs = 0,
    this.correctAnswers = 0,
    this.totalQuestions = 0,
    this.notes = '',
  });

  double get percentage => maxScore > 0 ? (score / maxScore * 100).clamp(0, 100) : 0;

  String getPerformanceLevel() {
    if (percentage >= 80) return 'Excellent';
    if (percentage >= 60) return 'Good';
    if (percentage >= 40) return 'Fair';
    return 'Needs Practice';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userEmail': userEmail,
        'testType': testType,
        'date': date.toIso8601String(),
        'score': score,
        'maxScore': maxScore,
        'reactionTimeMs': reactionTimeMs,
        'correctAnswers': correctAnswers,
        'totalQuestions': totalQuestions,
        'notes': notes,
      };

  factory CognitiveScore.fromMap(Map<String, dynamic> map) {
    return CognitiveScore(
      id: map['id'] ?? '',
      userEmail: map['userEmail'] ?? '',
      testType: map['testType'] ?? '',
      date: DateTime.parse(map['date']),
      score: (map['score'] ?? 0).toDouble(),
      maxScore: (map['maxScore'] ?? 10).toDouble(),
      reactionTimeMs: map['reactionTimeMs'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      notes: map['notes'] ?? '',
    );
  }
}
