import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../models/chat_session.dart';
import '../../../../models/company.dart';
import '../../../../models/intent.dart';
import '../../../../models/message.dart';
import '../../../../models/app_user.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/chat_api_service.dart';
import '../../../../services/chat_logic_service.dart';
import '../../../../services/intent_service.dart';
import '../../../../services/supabase_service.dart';

final authServiceProvider = Provider<AuthService>((_) => AuthService());
final chatApiServiceProvider = Provider<ChatApiService>((_) => ChatApiService());
final chatLogicServiceProvider = Provider<ChatLogicService>((_) => ChatLogicService());
final intentServiceProvider = Provider<IntentService>((_) => IntentService());

final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final uid = SupabaseService.instance.currentUserId;
  if (uid == null) return null;
  return ref.read(authServiceProvider).getAppUser(uid);
});

final currentCompanyProvider = FutureProvider<Company?>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;
  return ref.read(authServiceProvider).getCompany(user.companyId);
});

final chatSessionProvider = StateProvider<ChatSession?>((_) => null);
final chatMessagesProvider = StateProvider<List<ChatMessage>>((_) => []);
final failureCountProvider = StateProvider<int>((_) => 0);
final isLoadingProvider = StateProvider<bool>((_) => false);
final intentsProvider = FutureProvider.family<List<ChatIntent>, String>((ref, companyId) {
  return ref.read(intentServiceProvider).getIntents(companyId);
});

/// Sends user message, runs intent detection, saves unknown questions, and triggers handoff after max failures.
void sendMessage(WidgetRef ref, String text) async {
  if (text.trim().isEmpty) return;
  final company = await ref.read(currentCompanyProvider.future);
  final user = await ref.read(currentUserProvider.future);
  if (company == null || user == null) return;

  final chatApi = ref.read(chatApiServiceProvider);
  final chatLogic = ref.read(chatLogicServiceProvider);
  var session = ref.read(chatSessionProvider);
  final failureCount = ref.read(failureCountProvider);

  ref.read(isLoadingProvider.notifier).state = true;

  if (session == null) {
    session = await chatApi.createSession(company.id, user.email);
    ref.read(chatSessionProvider.notifier).state = session;
  }

  await chatApi.insertMessage(sessionId: session.id, sender: 'user', message: text.trim());
  final intents = await ref.read(intentsProvider(company.id).future);
  final matched = chatLogic.detectIntent(text, intents);

  String responseText;
  if (matched != null) {
    responseText = matched.responseText;
    ref.read(failureCountProvider.notifier).state = 0;
  } else {
    await chatApi.saveUnknownQuestion(company.id, text.trim());
    final newFailures = failureCount + 1;
    ref.read(failureCountProvider.notifier).state = newFailures;
    if (newFailures >= AppConstants.maxFailuresBeforeHandoff) {
      responseText = _handoffMessage(company);
    } else {
      responseText = "I couldn't find an answer for that. Could you rephrase or ask something else?";
    }
  }

  await chatApi.insertMessage(sessionId: session.id, sender: 'bot', message: responseText);
  final messages = await chatApi.getMessages(session.id);
  ref.read(chatMessagesProvider.notifier).state = messages;
  ref.read(isLoadingProvider.notifier).state = false;
}

String _handoffMessage(Company c) {
  final buffer = StringBuffer("I'm sorry I couldn't help. Here's how to reach us:\n");
  if (c.supportEmail != null && c.supportEmail!.isNotEmpty) {
    buffer.writeln("Email: ${c.supportEmail}");
  }
  if (c.supportWhatsapp != null && c.supportWhatsapp!.isNotEmpty) {
    buffer.writeln("WhatsApp: ${c.supportWhatsapp}");
  }
  if ((c.supportEmail == null || c.supportEmail!.isEmpty) &&
      (c.supportWhatsapp == null || c.supportWhatsapp!.isEmpty)) {
    buffer.writeln("Please contact support via your usual channel.");
  }
  return buffer.toString();
}

/// Loads or creates session and messages for current company.
Future<void> initChatSession(WidgetRef ref) async {
  final company = await ref.read(currentCompanyProvider.future);
  final user = await ref.read(currentUserProvider.future);
  if (company == null || user == null) return;

  final chatApi = ref.read(chatApiServiceProvider);
  final session = await chatApi.createSession(company.id, user.email);
  ref.read(chatSessionProvider.notifier).state = session;
  final messages = await chatApi.getMessages(session.id);
  ref.read(chatMessagesProvider.notifier).state = messages;
  ref.read(failureCountProvider.notifier).state = 0;
}
