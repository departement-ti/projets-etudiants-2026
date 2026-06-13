class MCIPrediction {
  final String id;
  final String userEmail;
  final DateTime date;
  final int age;
  final String sleepQuality;
  final String memoryIssues;
  final String forgetfulnessFrequency;
  final double reactionTime;
  final String educationLevel;
  final int dailyActivityScore;
  final double brainHealthScore;
  final String riskLevel;
  final List<String> recommendations;

  MCIPrediction({
    required this.id,
    required this.userEmail,
    required this.date,
    required this.age,
    required this.sleepQuality,
    required this.memoryIssues,
    required this.forgetfulnessFrequency,
    required this.reactionTime,
    required this.educationLevel,
    required this.dailyActivityScore,
    required this.brainHealthScore,
    required this.riskLevel,
    required this.recommendations,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userEmail': userEmail,
        'date': date.toIso8601String(),
        'age': age,
        'sleepQuality': sleepQuality,
        'memoryIssues': memoryIssues,
        'forgetfulnessFrequency': forgetfulnessFrequency,
        'reactionTime': reactionTime,
        'educationLevel': educationLevel,
        'dailyActivityScore': dailyActivityScore,
        'brainHealthScore': brainHealthScore,
        'riskLevel': riskLevel,
        'recommendations': recommendations,
      };

  factory MCIPrediction.fromMap(Map<String, dynamic> map) {
    return MCIPrediction(
      id: map['id'] ?? '',
      userEmail: map['userEmail'] ?? '',
      date: DateTime.parse(map['date']),
      age: map['age'] ?? 0,
      sleepQuality: map['sleepQuality'] ?? '',
      memoryIssues: map['memoryIssues'] ?? '',
      forgetfulnessFrequency: map['forgetfulnessFrequency'] ?? '',
      reactionTime: (map['reactionTime'] ?? 0.0).toDouble(),
      educationLevel: map['educationLevel'] ?? '',
      dailyActivityScore: map['dailyActivityScore'] ?? 0,
      brainHealthScore: (map['brainHealthScore'] ?? 50.0).toDouble(),
      riskLevel: map['riskLevel'] ?? 'Low',
      recommendations: List<String>.from(map['recommendations'] ?? []),
    );
  }

  String getRiskColor() {
    switch (riskLevel) {
      case 'Low':
        return '#4CAF50';
      case 'Moderate':
        return '#FF9800';
      case 'High':
        return '#F44336';
      default:
        return '#757575';
    }
  }

  String getScoreLabel() {
    if (brainHealthScore >= 80) return 'Excellent';
    if (brainHealthScore >= 60) return 'Good';
    if (brainHealthScore >= 40) return 'Fair';
    return 'Needs Attention';
  }
}
