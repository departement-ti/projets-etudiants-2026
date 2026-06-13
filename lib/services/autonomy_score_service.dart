import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mymeds_app/models/autonomy_score.dart';
import 'package:mymeds_app/services/step_counter_service.dart';

const List<Map<String, dynamic>> _incidentTypeWeights = [
  {'label': 'Chute', 'weight': 15},
  {'label': 'Oubli de médicament', 'weight': 8},
  {'label': 'Comportement anormal', 'weight': 12},
  {'label': 'Douleur / Malaise', 'weight': 10},
  {'label': 'Problème de mobilité', 'weight': 7},
  {'label': 'Trouble du sommeil', 'weight': 5},
  {'label': 'Refus de soins', 'weight': 6},
  {'label': 'Autre', 'weight': 4},
];

class AutonomyScoreService {
  static final AutonomyScoreService _instance =
      AutonomyScoreService._internal();
  factory AutonomyScoreService() => _instance;
  AutonomyScoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AutonomyScore> calculateScore(String userEmail) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final medicationAdherence = await _getMedicationAdherence(
        userEmail, todayStart, todayEnd);
    final cognitiveScore =
        await _getCognitiveScore(userEmail, todayStart, todayEnd);
    final incidentPenalty =
        await _getIncidentPenalty(userEmail, todayStart, todayEnd);
    final dailyActivities =
        await _getDailyActivities(userEmail, todayStart, todayEnd);

    final score = AutonomyScore.fromCalculation(
      userId: userEmail,
      medicationAdherence: medicationAdherence,
      cognitiveScore: cognitiveScore,
      incidentPenalty: incidentPenalty,
      dailyActivities: dailyActivities,
    );

    await _firestore
        .collection('Users')
        .doc(userEmail)
        .collection('AutonomyScores')
        .add(score.toMap());

    await _firestore.collection('AutonomyScores').add({
      ...score.toMap(),
      'userEmail': userEmail,
    });

    // Vérifier baisse brutale du score et alerter
    await _checkAndAlertScoreDrop(userEmail, score.score);

    return score;
  }

  /// Vérifie une baisse brutale du score et envoie des alertes
  Future<void> _checkAndAlertScoreDrop(
      String userEmail, double currentScore) async {
    try {
      // Récupérer le score de la veille
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      // Chercher le score précédent dans l'historique
      final historySnapshot = await _firestore
          .collection('Users')
          .doc(userEmail)
          .collection('AutonomyScores')
          .orderBy('date', descending: true)
          .limit(2)
          .get();

      if (historySnapshot.docs.length < 2) return; // Pas assez d'historique

      final previousScore =
          (historySnapshot.docs[1].data()['score'] as num?)?.toDouble() ?? 0.0;

      if (previousScore == 0.0) return;

      final drop = previousScore - currentScore;

      // Seuils d'alerte
      if (drop >= 20) {
        await _sendCriticalAlert(userEmail, currentScore, previousScore, drop,
            level: 'CRITIQUE');
      } else if (drop >= 10) {
        await _sendCriticalAlert(userEmail, currentScore, previousScore, drop,
            level: 'SURVEILLANCE');
      }
    } catch (e) {
      print('Score drop check error: $e');
    }
  }

  /// Envoie une alerte au médecin et à la famille
  Future<void> _sendCriticalAlert(
    String patientEmail,
    double currentScore,
    double previousScore,
    double drop, {
    required String level,
  }) async {
    try {
      final patientDoc =
          await _firestore.collection('Users').doc(patientEmail).get();
      final patientData = patientDoc.data();
      final patientName = patientData?['name'] ?? patientEmail;

      // Récupérer les médecins liés
      final linkedDoctorEmails =
          (patientData?['linkedDoctorEmails'] as List<dynamic>?)?.cast<String>() ?? [];
      final familyEmails =
          (patientData?['linkedFamilyEmails'] as List<dynamic>?)?.cast<String>() ?? [];

      final alertEmails = <String>{...linkedDoctorEmails, ...familyEmails};

      final title = '⚠️ $level - Score d\'autonomie en baisse';
      final body =
          'Patient: $patientName\n'
          'Score actuel: ${currentScore.toStringAsFixed(1)}/100\n'
          'Score précédent: ${previousScore.toStringAsFixed(1)}/100\n'
          'Baisse de: ${drop.toStringAsFixed(1)} points\n'
          'Action recommandée: ${level == 'CRITIQUE' ? 'Contacter immédiatement le patient' : 'Surveiller le patient et planifier une visite'}';

      // Notifier chaque médecin et membre de famille
      for (final email in alertEmails) {
        if (email.isEmpty) continue;
        await _firestore.collection('Notifications').add({
          'targetEmail': email,
          'title': title,
          'body': body,
          'type': 'autonomy_alert',
          'level': level,
          'patientEmail': patientEmail,
          'patientName': patientName,
          'currentScore': currentScore,
          'previousScore': previousScore,
          'drop': drop,
          'sentAt': DateTime.now().toIso8601String(),
          'read': false,
        });

        // Créer un rappel urgent
        await _firestore.collection('Reminders').add({
          'caregiverEmail': email,
          'type': 'autonomy_score_drop',
          'level': level,
          'message': body,
          'patientEmail': patientEmail,
          'createdAt': DateTime.now().toIso8601String(),
          'read': false,
        });
      }

      print('🚨 Alert sent to ${alertEmails.length} contacts for $patientName (drop: ${drop.toStringAsFixed(1)})');
    } catch (e) {
      print('Error sending score drop alert: $e');
    }
  }

  Future<double> _getMedicationAdherence(
      String userEmail, DateTime start, DateTime end) async {
    try {
      final medsSnapshot = await _firestore
          .collection('Users')
          .doc(userEmail)
          .collection('Medications')
          .get();

      int totalRappels = 0;
      int totalConfirmees = 0;

      for (final medDoc in medsSnapshot.docs) {
        final logsSnapshot = await _firestore
            .collection('Users')
            .doc(userEmail)
            .collection('Medications')
            .doc(medDoc.id)
            .collection('Logs')
            .get();

        for (final logDoc in logsSnapshot.docs) {
          final logDate = _parseLogDate(logDoc.id);
          if (logDate != null &&
              logDate.isAfter(start.subtract(const Duration(days: 7))) &&
              logDate.isBefore(end)) {
            totalRappels++;
            final data = logDoc.data();
            if (data['isTaken'] == true) {
              totalConfirmees++;
            }
          }
        }
      }

      if (totalRappels == 0) return 0;
      return (totalConfirmees / totalRappels * 100).clamp(0, 100);
    } catch (_) {
      return 0;
    }
  }

  Future<double> _getCognitiveScore(
      String userEmail, DateTime start, DateTime end) async {
    try {
      final scoresSnapshot = await _firestore
          .collection('Users')
          .doc(userEmail)
          .collection('CognitiveScores')
          .where('date',
              isGreaterThanOrEqualTo: start.subtract(const Duration(days: 7)))
          .where('date', isLessThan: end.add(const Duration(days: 1)))
          .get();

      if (scoresSnapshot.docs.isEmpty) return 0;

      double total = 0;
      for (final doc in scoresSnapshot.docs) {
        total += (doc.data()['score'] ?? 0).toDouble();
      }

      return (total / scoresSnapshot.docs.length).clamp(0, 100);
    } catch (_) {
      return 0;
    }
  }

  Future<double> _getIncidentPenalty(
      String userEmail, DateTime start, DateTime end) async {
    try {
      // Requête simplifiée sans index composé
      final incidentsSnapshot = await _firestore
          .collection('Incidents')
          .where('elderlyId', isEqualTo: userEmail)
          .get();

      double penalty = 0;
      for (final doc in incidentsSnapshot.docs) {
        final data = doc.data();
        final dateTimeStr = data['dateTime'] as String?;
        if (dateTimeStr == null) continue;

        // Filtrer côté client par date
        final dateTime = DateTime.tryParse(dateTimeStr);
        if (dateTime == null) continue;
        final cutoffStart = start.subtract(const Duration(days: 7));
        final cutoffEnd = end.add(const Duration(days: 1));
        if (dateTime.isBefore(cutoffStart) || dateTime.isAfter(cutoffEnd)) continue;

        final severity = data['severity'] ?? 1;
        final type = data['type'] ?? 'Autre';

        final found =
            _incidentTypeWeights.where((t) => t['label'] == type);
        final weight =
            found.isNotEmpty ? (found.first['weight'] as int).toDouble() : 4.0;

        penalty += weight * severity;
      }

      return penalty.clamp(0, 100);
    } catch (_) {
      return 0;
    }
  }

  Future<double> _getDailyActivities(
      String userEmail, DateTime start, DateTime end) async {
    try {
      // 1. Récupérer les activités planifiées
      final activitiesSnapshot = await _firestore
          .collection('Users')
          .doc(userEmail)
          .collection('DailyActivities')
          .where('date',
              isGreaterThanOrEqualTo:
                  start.toIso8601String().substring(0, 10))
          .where('date',
              isLessThan: end.toIso8601String().substring(0, 10))
          .get();

      int totalDone = 0;
      int totalPlanned = 0;

      for (final doc in activitiesSnapshot.docs) {
        final data = doc.data();
        final done = (data['doneCount'] ?? 0) as int;
        final planned = (data['totalCount'] ?? 0) as int;
        totalDone += done;
        totalPlanned += planned;
      }

      final activityScore = totalPlanned == 0
          ? 0.0
          : (totalDone / totalPlanned * 100).clamp(0, 100);

      // 2. Score de pas quotidien (0 à 10000 pas = 0% à 100%)
      final steps = await StepCounterService.getTodaySteps(userEmail);
      final stepScore = (steps.toDouble() / 10000 * 100).clamp(0.0, 100.0);

      // 3. Moyenne pondérée : 50% activités + 50% pas
      if (totalPlanned == 0) {
        return stepScore; // Si pas d'activités planifiées, juste les pas
      }
      return (activityScore * 0.5 + stepScore * 0.5).clamp(0.0, 100.0);
    } catch (_) {
      return 0;
    }
  }

  DateTime? _parseLogDate(String logId) {
    try {
      final parts = logId.split(' ');
      if (parts.length < 2) return null;
      return DateTime.tryParse(
          '${parts[0].replaceAll('/', '-')} ${parts[1]}');
    } catch (_) {
      return null;
    }
  }

  Future<List<AutonomyScore>> getScoreHistory(String userEmail,
      {int limit = 30}) async {
    try {
      final snapshot = await _firestore
          .collection('Users')
          .doc(userEmail)
          .collection('AutonomyScores')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AutonomyScore.fromMap(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<AutonomyScore?> getLatestScore(String userEmail) async {
    try {
      final snapshot = await _firestore
          .collection('Users')
          .doc(userEmail)
          .collection('AutonomyScores')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return AutonomyScore.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (_) {
      return null;
    }
  }
}
