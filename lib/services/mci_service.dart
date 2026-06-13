import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:mymeds_app/models/mci_prediction.dart';
import 'package:mymeds_app/services/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MCIService {
  static final MCIService _instance = MCIService._();
  factory MCIService() => _instance;
  MCIService._();

  static String get _apiKey => ApiConfig.openRouterApiKey;
  static const _baseUrl = ApiConfig.openRouterBaseUrl;

  Future<MCIPrediction> predictMCI({
    required String userEmail,
    required int age,
    required String sleepQuality,
    required String memoryIssues,
    required String forgetfulnessFrequency,
    required double reactionTime,
    required String educationLevel,
    required int dailyActivityScore,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('languageCode') ?? 'fr';

    try {
      final prompt = '''Analyze this elderly person's cognitive risk factors and provide a brain health assessment.

PATIENT DATA:
- Age: $age years
- Sleep Quality: $sleepQuality
- Memory Issues: $memoryIssues
- Forgetfulness Frequency: $forgetfulnessFrequency
- Reaction Time: ${reactionTime.toStringAsFixed(1)} seconds
- Education Level: $educationLevel
- Daily Activity Score: $dailyActivityScore/10

Return ONLY a valid JSON object with these exact fields:
{
  "brain_health_score": <number 0-100>,
  "risk_level": "<Low, Moderate, or High>",
  "recommendations": [
    "<specific actionable recommendation 1>",
    "<specific actionable recommendation 2>",
    "<specific actionable recommendation 3>",
    "<specific actionable recommendation 4>",
    "<specific actionable recommendation 5>"
  ]
}

Rules for scoring:
- Age >80: high risk factor (-15 to -25)
- Poor sleep: major risk (-10 to -20)
- Frequent memory issues: high risk (-15 to -25)
- Daily forgetfulness: major risk (-15 to -20)
- Reaction time >1.5s: concerning (-10 to -15)
- Low education: moderate risk (-5 to -10)
- Low activity: moderate risk (-5 to -15)
- Risk <40 = High, 40-64 = Moderate, >=65 = Low
- Recommendations should be SPECIFIC and ACTIONABLE, not generic
- Each recommendation should be 1 sentence, practical advice
- DO NOT include generic advice like "consult a doctor"
- Focus on lifestyle changes, brain exercises, diet, sleep hygiene''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://neurocare.app',
          'X-Title': 'NeuroCare MCI Assessment',
        },
        body: jsonEncode({
          'model': 'google/gemini-2.0-flash-001',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert neurologist specialized in MCI (Mild Cognitive Impairment) assessment. You provide accurate, personalized brain health predictions in JSON format. Be precise with scores based on the risk factors provided.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.4,
          'max_tokens': 800,
          'response_format': {'type': 'json_object'},
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] ?? '';
        final parsed = jsonDecode(content);
        return _buildPrediction(parsed, userEmail, age, sleepQuality, memoryIssues,
            forgetfulnessFrequency, reactionTime, educationLevel, dailyActivityScore);
      }
    } catch (e) {
      print('MCI API error: $e');
    }

    return _localPrediction(
      userEmail: userEmail, age: age, sleepQuality: sleepQuality,
      memoryIssues: memoryIssues, forgetfulnessFrequency: forgetfulnessFrequency,
      reactionTime: reactionTime, educationLevel: educationLevel,
      dailyActivityScore: dailyActivityScore,
    );
  }

  MCIPrediction _buildPrediction(
    Map<String, dynamic> data,
    String userEmail,
    int age,
    String sleepQuality,
    String memoryIssues,
    String forgetfulnessFrequency,
    double reactionTime,
    String educationLevel,
    int dailyActivityScore,
  ) {
    final prediction = MCIPrediction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userEmail: userEmail,
      date: DateTime.now(),
      age: age,
      sleepQuality: sleepQuality,
      memoryIssues: memoryIssues,
      forgetfulnessFrequency: forgetfulnessFrequency,
      reactionTime: reactionTime,
      educationLevel: educationLevel,
      dailyActivityScore: dailyActivityScore,
      brainHealthScore: (data['brain_health_score'] ?? 50).toDouble().clamp(0, 100),
      riskLevel: data['risk_level'] ?? 'Low',
      recommendations: List<String>.from(data['recommendations'] ?? []),
    );
    _savePrediction(prediction);
    return prediction;
  }

  Future<void> _savePrediction(MCIPrediction prediction) async {
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(prediction.userEmail)
          .collection('MCIPredictions')
          .doc(prediction.id)
          .set(prediction.toMap());
    } catch (_) {}
  }

  MCIPrediction _localPrediction({
    required String userEmail,
    required int age,
    required String sleepQuality,
    required String memoryIssues,
    required String forgetfulnessFrequency,
    required double reactionTime,
    required String educationLevel,
    required int dailyActivityScore,
  }) {
    double score = 100.0;

    if (age > 80) score -= 20;
    else if (age > 75) score -= 14;
    else if (age > 65) score -= 7;
    else if (age > 55) score -= 3;

    if (sleepQuality == 'Poor') score -= 15;
    else if (sleepQuality == 'Fair') score -= 7;

    if (memoryIssues == 'Frequent') score -= 22;
    else if (memoryIssues == 'Sometimes') score -= 10;

    if (forgetfulnessFrequency == 'Daily') score -= 20;
    else if (forgetfulnessFrequency == 'Weekly') score -= 11;
    else if (forgetfulnessFrequency == 'Monthly') score -= 4;

    if (reactionTime > 1.5) score -= 14;
    else if (reactionTime > 1.0) score -= 7;

    if (educationLevel == 'Primary' || educationLevel == 'None') score -= 5;

    if (dailyActivityScore < 3) score -= 12;
    else if (dailyActivityScore < 5) score -= 6;

    score = score.clamp(0, 100);

    String risk = 'Low';
    if (score < 40) risk = 'High';
    else if (score < 65) risk = 'Moderate';

    final recommendations = <String>[];
    if (sleepQuality == 'Poor') {
      recommendations.add('Maintain a consistent sleep schedule: go to bed and wake up at the same time daily');
      recommendations.add('Avoid screens 1 hour before bedtime and keep bedroom cool and dark');
    }
    if (memoryIssues != 'Rarely') {
      recommendations.add('Practice daily memory exercises: try recalling 10 words after 5 minutes');
      recommendations.add('Use a daily journal to write down 3 things you want to remember each morning');
    }
    if (dailyActivityScore < 5) {
      recommendations.add('Walk 30 minutes daily - physical activity increases BDNF, a brain growth protein');
      recommendations.add('Try chair exercises or gentle yoga 3 times per week');
    }
    if (reactionTime > 1.0) {
      recommendations.add('Practice catching a ball or tapping exercises to improve reaction speed');
    }
    recommendations.add('Eat fatty fish (salmon, sardines) 2-3 times per week for omega-3 DHA');
    if (recommendations.length < 5) {
      recommendations.add('Stay socially active: call a friend or family member daily');
    }

    final prediction = MCIPrediction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userEmail: userEmail,
      date: DateTime.now(),
      age: age, sleepQuality: sleepQuality, memoryIssues: memoryIssues,
      forgetfulnessFrequency: forgetfulnessFrequency, reactionTime: reactionTime,
      educationLevel: educationLevel, dailyActivityScore: dailyActivityScore,
      brainHealthScore: score, riskLevel: risk, recommendations: recommendations.take(5).toList(),
    );

    _savePrediction(prediction);
    return prediction;
  }

  Future<MCIPrediction?> getLatestPrediction(String userEmail) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userEmail)
          .collection('MCIPredictions')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return MCIPrediction.fromMap(
          snapshot.docs.first.data()..['id'] = snapshot.docs.first.id,
        );
      }
    } catch (_) {}
    return null;
  }

  Future<List<MCIPrediction>> getPredictionHistory(String userEmail) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userEmail)
          .collection('MCIPredictions')
          .orderBy('date', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => MCIPrediction.fromMap(doc.data()..['id'] = doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
