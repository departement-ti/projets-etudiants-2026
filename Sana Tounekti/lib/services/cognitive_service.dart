import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:mymeds_app/models/cognitive_score.dart';

class CognitiveService {
  static final CognitiveService _instance = CognitiveService._();
  factory CognitiveService() => _instance;
  CognitiveService._();

  Future<void> submitTestResult({
    required String userEmail,
    required String testType,
    required double score,
    required double maxScore,
    int reactionTimeMs = 0,
    int correctAnswers = 0,
    int totalQuestions = 0,
  }) async {
    final result = CognitiveScore(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userEmail: userEmail,
      testType: testType,
      date: DateTime.now(),
      score: score,
      maxScore: maxScore,
      reactionTimeMs: reactionTimeMs,
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
    );

    try {
      await http.post(
        Uri.parse('https://api.neurocare.app/submit-cognitive-test'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(result.toMap()),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}

    await _saveLocally(result);
  }

  Future<void> _saveLocally(CognitiveScore score) async {
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(score.userEmail)
          .collection('CognitiveScores')
          .doc(score.id)
          .set(score.toMap());
    } catch (_) {}
  }

  Future<Map<String, double>> getWeeklyAverages(String userEmail) async {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userEmail)
          .collection('CognitiveScores')
          .where('date', isGreaterThanOrEqualTo: weekAgo.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      final scores = snapshot.docs
          .map((doc) => CognitiveScore.fromMap(doc.data()..['id'] = doc.id))
          .toList();

      final byType = <String, List<CognitiveScore>>{};
      for (final s in scores) {
        byType.putIfAbsent(s.testType, () => []).add(s);
      }

      final averages = <String, double>{};
      byType.forEach((type, list) {
        averages[type] = list.fold(0.0, (sum, s) => sum + s.percentage) / list.length;
      });

      return averages;
    } catch (_) {
      return {};
    }
  }

  Future<List<CognitiveScore>> getScoreHistory(String userEmail, {String? testType}) async {
    try {
      var query = FirebaseFirestore.instance
          .collection('Users')
          .doc(userEmail)
          .collection('CognitiveScores')
          .orderBy('date', descending: true)
          .limit(30);

      if (testType != null) {
        query = query.where('testType', isEqualTo: testType);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => CognitiveScore.fromMap(doc.data()..['id'] = doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<CognitiveScore?> getLatestScore(String userEmail, String testType) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userEmail)
          .collection('CognitiveScores')
          .where('testType', isEqualTo: testType)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return CognitiveScore.fromMap(
          snapshot.docs.first.data()..['id'] = snapshot.docs.first.id,
        );
      }
    } catch (_) {}
    return null;
  }
}
