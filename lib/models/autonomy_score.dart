class AutonomyScore {
  final String? id;
  final String userId;
  final DateTime date;
  final double score;
  final double medicationAdherence;
  final double cognitiveScore;
  final double incidentPenalty;
  final double dailyActivities;
  final String level;
  final String label;

  AutonomyScore({
    this.id,
    required this.userId,
    required this.date,
    required this.score,
    required this.medicationAdherence,
    required this.cognitiveScore,
    required this.incidentPenalty,
    required this.dailyActivities,
    required this.level,
    required this.label,
  });

  factory AutonomyScore.fromCalculation({
    required String userId,
    required double medicationAdherence,
    required double cognitiveScore,
    required double incidentPenalty,
    required double dailyActivities,
  }) {
    final s = 0.35 * medicationAdherence +
        0.25 * cognitiveScore +
        0.25 * (100 - incidentPenalty) +
        0.15 * dailyActivities;

    final score = s.clamp(0, 100);
    String level;
    String label;

    if (score >= 80) {
      level = 'Excellent';
      label = 'Autonomie preservee';
    } else if (score >= 60) {
      level = 'Satisfaisant';
      label = 'Légère dépendance';
    } else if (score >= 40) {
      level = 'Modéré';
      label = 'Risque modéré';
    } else {
      level = 'Critique';
      label = 'Déclin significatif';
    }

    return AutonomyScore(
      userId: userId,
      date: DateTime.now(),
      score: double.parse(score.toStringAsFixed(1)),
      medicationAdherence: medicationAdherence,
      cognitiveScore: cognitiveScore,
      incidentPenalty: incidentPenalty,
      dailyActivities: dailyActivities,
      level: level,
      label: label,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': date.toIso8601String(),
      'score': score,
      'medicationAdherence': medicationAdherence,
      'cognitiveScore': cognitiveScore,
      'incidentPenalty': incidentPenalty,
      'dailyActivities': dailyActivities,
      'level': level,
      'label': label,
    };
  }

  factory AutonomyScore.fromMap(Map<String, dynamic> map, String docId) {
    return AutonomyScore(
      id: docId,
      userId: map['userId'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      score: (map['score'] ?? 0).toDouble(),
      medicationAdherence: (map['medicationAdherence'] ?? 0).toDouble(),
      cognitiveScore: (map['cognitiveScore'] ?? 0).toDouble(),
      incidentPenalty: (map['incidentPenalty'] ?? 0).toDouble(),
      dailyActivities: (map['dailyActivities'] ?? 0).toDouble(),
      level: map['level'] ?? '',
      label: map['label'] ?? '',
    );
  }
}
