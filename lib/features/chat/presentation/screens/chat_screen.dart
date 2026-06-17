import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/company.dart';
import '../../../../models/message.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initChatSession(ref);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(currentCompanyProvider);
    final messages = ref.watch(chatMessagesProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final company = companyAsync.valueOrNull;
    final welcomeMessage = company?.welcomeMessage ?? 'Hello! How can I help you today?';

    return Scaffold(
      appBar: AppBar(
        title: Text(company?.name ?? 'Chat'),
        actions: [
          if (company != null)
            IconButton(
              icon: const Icon(Icons.dashboard_rounded),
              onPressed: () => context.push('/admin'),
            ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: companyAsync.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.isEmpty ? 1 : messages.length + (isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (messages.isEmpty && !isLoading) {
                        return _WelcomeBubble(message: welcomeMessage);
                      }
                      if (index == messages.length) {
                        return const _TypingIndicator();
                      }
                      final msg = messages[index];
                      final isLastAndHandoff = index == messages.length - 1 && _isHandoffMessage(msg, company);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MessageBubble(message: msg, showTimestamp: true),
                          if (isLastAndHandoff && company != null) _HandoffButtons(company: company),
                        ],
                      );
                    },
                  ),
          ),
          if (messages.isNotEmpty) _buildFaqButtons(ref),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(ref),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: isLoading ? null : () => _send(ref),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send(WidgetRef r) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    sendMessage(r, text);
    _scrollToBottom();
  }

  bool _isHandoffMessage(ChatMessage msg, Company? company) {
    if (!msg.isFromBot || company == null) return false;
    final failureCount = ref.read(failureCountProvider);
    if (failureCount < AppConstants.maxFailuresBeforeHandoff) return false;
    return msg.message.contains("Here's how to reach us") || msg.message.contains('contact support');
  }

  Widget _buildFaqButtons(WidgetRef r) {
    final companyId = r.watch(currentCompanyProvider).valueOrNull?.id ?? '';
    if (companyId.isEmpty) return const SizedBox.shrink();
    final intentsAsync = r.watch(intentsProvider(companyId));
    final phrases = intentsAsync.valueOrNull?.expand((i) => i.trainingPhrases.take(2)).toList() ?? [];
    if (phrases.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: phrases.take(5).map((phrase) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(phrase.length > 25 ? '${phrase.substring(0, 25)}...' : phrase),
              onPressed: () {
                _textController.text = phrase;
                _send(r);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _WelcomeBubble extends StatelessWidget {
  final String message;

  const _WelcomeBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16).copyWith(topLeft: Radius.zero),
        ),
        child: Text(message, style: const TextStyle(fontSize: 15)),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showTimestamp;

  const _MessageBubble({required this.message, this.showTimestamp = false});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isFromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16).copyWith(
            topLeft: isUser ? const Radius.circular(16) : Radius.zero,
            topRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.message,
              style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 15),
            ),
            if (showTimestamp)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isUser ? Colors.white70 : Colors.black45,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _HandoffButtons extends StatelessWidget {
  final Company company;

  const _HandoffButtons({required this.company});

  @override
  Widget build(BuildContext context) {
    final hasWhatsApp = company.supportWhatsapp != null && company.supportWhatsapp!.isNotEmpty;
    final hasEmail = company.supportEmail != null && company.supportEmail!.isNotEmpty;
    if (!hasWhatsApp && !hasEmail) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (hasWhatsApp)
            FilledButton.icon(
              icon: const Icon(Icons.chat_rounded, size: 18),
              label: const Text('WhatsApp'),
              onPressed: () {
                final num = company.supportWhatsapp!.replaceAll(RegExp(r'[^\d+]'), '');
                launchUrl(Uri.parse('https://wa.me/$num'));
              },
            ),
          if (hasEmail)
            OutlinedButton.icon(
              icon: const Icon(Icons.email_outlined, size: 18),
              label: const Text('Email'),
              onPressed: () => launchUrl(Uri.parse('mailto:${company.supportEmail}')),
            ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16).copyWith(topRight: const Radius.circular(16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(),
            const SizedBox(width: 4),
            _dot(delay: 200),
            const SizedBox(width: 4),
            _dot(delay: 400),
          ],
        ),
      ),
    );
  }

  Widget _dot({int delay = 0}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Opacity(
          opacity: 0.4 + 0.6 * value,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
          ),
        );
      },
    );
  }
}
