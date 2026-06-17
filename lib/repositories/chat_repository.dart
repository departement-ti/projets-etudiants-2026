import '../models/chat_session.dart';
import '../models/message.dart';
import '../models/rating.dart';
import '../services/chat_api_service.dart';

class ChatRepository {
  ChatRepository(this._chatApi);
  final ChatApiService _chatApi;

  Future<ChatSession> createSession(String companyId, String userIdentifier) =>
      _chatApi.createSession(companyId, userIdentifier);

  Future<void> endSession(String sessionId) => _chatApi.endSession(sessionId);

  Future<ChatMessage> insertMessage({
    required String sessionId,
    required String sender,
    required String message,
  }) =>
      _chatApi.insertMessage(sessionId: sessionId, sender: sender, message: message);

  Future<List<ChatMessage>> getMessages(String sessionId) =>
      _chatApi.getMessages(sessionId);

  Future<void> saveUnknownQuestion(String companyId, String question) =>
      _chatApi.saveUnknownQuestion(companyId, question);

  Future<void> submitRating({required String sessionId, required int rating, String? feedback}) =>
      _chatApi.submitRating(sessionId: sessionId, rating: rating, feedback: feedback);

  Future<SessionRating?> getRatingForSession(String sessionId) =>
      _chatApi.getRatingForSession(sessionId);
}
