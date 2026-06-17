import '../models/intent.dart';
import '../services/intent_service.dart';

class IntentRepository {
  IntentRepository(this._intentService);
  final IntentService _intentService;

  Future<List<ChatIntent>> getIntents(String companyId) =>
      _intentService.getIntents(companyId);

  Future<ChatIntent> createIntent({
    required String companyId,
    required String intentName,
    required List<String> trainingPhrases,
    required String responseText,
  }) =>
      _intentService.createIntent(
        companyId: companyId,
        intentName: intentName,
        trainingPhrases: trainingPhrases,
        responseText: responseText,
      );

  Future<void> updateIntent(String id, {String? intentName, List<String>? trainingPhrases, String? responseText}) =>
      _intentService.updateIntent(id, intentName: intentName, trainingPhrases: trainingPhrases, responseText: responseText);

  Future<void> deleteIntent(String id) => _intentService.deleteIntent(id);
}
