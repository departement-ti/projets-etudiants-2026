class Incident {
  final String? id;
  final String reportedById;
  final String? reportedByName;
  final String elderlyId;
  final String? elderlyName;
  final String type;
  final String description;
  final DateTime dateTime;
  final int severity;
  final String? doctorNotified;

  Incident({
    this.id,
    required this.reportedById,
    this.reportedByName,
    required this.elderlyId,
    this.elderlyName,
    required this.type,
    required this.description,
    required this.dateTime,
    required this.severity,
    this.doctorNotified,
  });

  static const List<Map<String, dynamic>> incidentTypes = [
    {'label': 'Chute', 'icon': 'falling', 'weight': 15},
    {'label': 'Oubli de médicament', 'icon': 'medication', 'weight': 8},
    {'label': 'Comportement anormal', 'icon': 'psychology', 'weight': 12},
    {'label': 'Douleur / Malaise', 'icon': 'sick', 'weight': 10},
    {'label': 'Problème de mobilité', 'icon': 'accessible', 'weight': 7},
    {'label': 'Trouble du sommeil', 'icon': 'bedtime', 'weight': 5},
    {'label': 'Refus de soins', 'icon': 'not_interested', 'weight': 6},
    {'label': 'Autre', 'icon': 'report', 'weight': 4},
  ];

  int get weight {
    final found = incidentTypes.where((t) => t['label'] == type);
    return found.isNotEmpty ? (found.first['weight'] as int) : 4;
  }

  String get severityLabel {
    switch (severity) {
      case 1:
        return 'Léger';
      case 2:
        return 'Modéré';
      case 3:
        return 'Grave';
      case 4:
        return 'Critique';
      default:
        return 'Inconnu';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'reportedById': reportedById,
      'reportedByName': reportedByName,
      'elderlyId': elderlyId,
      'elderlyName': elderlyName,
      'type': type,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'severity': severity,
      'doctorNotified': doctorNotified,
    };
  }

  factory Incident.fromMap(Map<String, dynamic> map, String docId) {
    return Incident(
      id: docId,
      reportedById: map['reportedById'] ?? '',
      reportedByName: map['reportedByName'],
      elderlyId: map['elderlyId'] ?? '',
      elderlyName: map['elderlyName'],
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      dateTime: DateTime.tryParse(map['dateTime'] ?? '') ?? DateTime.now(),
      severity: map['severity'] ?? 1,
      doctorNotified: map['doctorNotified'],
    );
  }
}
