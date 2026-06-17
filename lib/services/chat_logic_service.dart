import '../core/constants/app_constants.dart';
import '../models/intent.dart';

/// In-app intent detection and response logic (keyword + phrase matching).
/// Can be backed by Edge Function for heavier AI later.
class ChatLogicService {
  /// Detect intent from user message using training phrases (keyword + similarity).
  ChatIntent? detectIntent(String userMessage, List<ChatIntent> intents) {
    if (userMessage.trim().isEmpty) return null;
    final normalized = _normalize(userMessage);
    if (normalized.length < AppConstants.minPhraseMatchLength) return null;

    // 1) Exact phrase match
    for (final intent in intents) {
      for (final phrase in intent.trainingPhrases) {
        if (_normalize(phrase) == normalized) return intent;
      }
    }

    // 2) Contains phrase (longest first)
    final sortedByPhraseLength = List<ChatIntent>.from(intents)
      ..sort((a, b) {
        final aMax = a.trainingPhrases.map((p) => p.length).fold(0, (a, b) => a > b ? a : b);
        final bMax = b.trainingPhrases.map((p) => p.length).fold(0, (a, b) => a > b ? a : b);
        return bMax.compareTo(aMax);
      });
    for (final intent in sortedByPhraseLength) {
      for (final phrase in intent.trainingPhrases) {
        final np = _normalize(phrase);
        if (np.length >= AppConstants.minPhraseMatchLength && normalized.contains(np)) {
          return intent;
        }
      }
    }

    // 3) Keyword overlap (count matching words)
    int bestScore = 0;
    ChatIntent? bestIntent;
    final userWords = normalized.split(RegExp(r'\s+')).toSet();
    for (final intent in intents) {
      int score = 0;
      for (final phrase in intent.trainingPhrases) {
        final phraseWords = _normalize(phrase).split(RegExp(r'\s+')).toSet();
        score += userWords.intersection(phraseWords).length;
      }
      if (score > bestScore) {
        bestScore = score;
        bestIntent = intent;
      }
    }
    if (bestScore >= 2) return bestIntent;

    return null;
  }

  String _normalize(String s) => s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
}
