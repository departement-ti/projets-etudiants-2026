import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/intent.dart';
import '../../../../models/unknown_question.dart';
import '../../../../services/intent_service.dart';
import '../../../../services/unknown_questions_service.dart';
import '../../../chat/presentation/providers/chat_provider.dart';

void _showCreateIntentFromSuggestion(
  BuildContext context,
  WidgetRef ref,
  String companyId,
  String suggestedQuestion,
  String unknownQuestionId,
  VoidCallback onRefresh,
) {
  final nameController = TextEditingController(text: suggestedQuestion.length > 30 ? '${suggestedQuestion.substring(0, 30)}...' : suggestedQuestion);
  final phrasesController = TextEditingController(text: suggestedQuestion);
  final responseController = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Create Intent from Suggestion'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will add a new intent using the repeated question as a training phrase.', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Intent name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phrasesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Training phrases (one per line)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: responseController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Response text'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final name = nameController.text.trim();
            final phrases = phrasesController.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            final response = responseController.text.trim();
            if (name.isEmpty || phrases.isEmpty || response.isEmpty) return;
            await IntentService().createIntent(
              companyId: companyId,
              intentName: name,
              trainingPhrases: phrases,
              responseText: response,
            );
            await UnknownQuestionsService().approve(unknownQuestionId);
            ref.invalidate(intentsProvider(companyId));
            onRefresh();
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Create Intent'),
        ),
      ],
    ),
  );
}

class IntentManagementScreen extends ConsumerStatefulWidget {
  const IntentManagementScreen({super.key});

  @override
  ConsumerState<IntentManagementScreen> createState() => _IntentManagementScreenState();
}

class _IntentManagementScreenState extends ConsumerState<IntentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _intentService = IntentService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final company = ref.watch(currentCompanyProvider).valueOrNull;
    if (company == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Intents')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intent management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Intents', icon: Icon(Icons.chat_bubble_outline)),
            Tab(text: 'Suggested', icon: Icon(Icons.lightbulb_outline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _IntentsList(companyId: company.id),
          _UnknownQuestionsList(companyId: company.id, onRefresh: () => setState(() {})),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => _showAddIntentDialog(context, ref, company.id),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddIntentDialog(BuildContext context, WidgetRef ref, String companyId) {
    final nameController = TextEditingController();
    final phrasesController = TextEditingController();
    final responseController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New intent'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Intent name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phrasesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Training phrases (one per line)',
                  hintText: 'How do I reset password?\nReset my password',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: responseController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Response text'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phrases = phrasesController.text
                  .split('\n')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              final response = responseController.text.trim();
              if (name.isEmpty || phrases.isEmpty || response.isEmpty) return;
              await _intentService.createIntent(
                companyId: companyId,
                intentName: name,
                trainingPhrases: phrases,
                responseText: response,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              ref.invalidate(intentsProvider(companyId));
              setState(() {});
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _IntentsList extends ConsumerWidget {
  final String companyId;

  const _IntentsList({required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intentsAsync = ref.watch(intentsProvider(companyId));
    return intentsAsync.when(
      data: (List<ChatIntent> intents) {
        if (intents.isEmpty) {
          return const Center(
            child: Text('No intents yet. Add one to train your chatbot.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: intents.length,
          itemBuilder: (context, index) {
            final intent = intents[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(intent.intentName),
                subtitle: Text(
                  '${intent.trainingPhrases.length} phrases · ${intent.responseText.length} chars',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showIntentDetail(context, ref, intent),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showIntentDetail(BuildContext context, WidgetRef ref, ChatIntent intent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(intent.intentName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Phrases: ${intent.trainingPhrases.join(", ")}'),
              const SizedBox(height: 8),
              Text('Response: ${intent.responseText}'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await IntentService().deleteIntent(intent.id);
                  ref.invalidate(intentsProvider(intent.companyId));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Delete intent', style: TextStyle(color: AppTheme.errorColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnknownQuestionsList extends ConsumerWidget {
  final String companyId;
  final VoidCallback onRefresh;

  const _UnknownQuestionsList({required this.companyId, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<UnknownQuestion>>(
      future: UnknownQuestionsService().getPending(companyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snapshot.data!;
        if (list.isEmpty) {
          return const Center(
            child: Text('No pending suggested questions.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final q = list[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(q.question),
                subtitle: Text('Asked ${q.frequency} time(s)'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Create Intent from Suggestion',
                      onPressed: () {
                        _showCreateIntentFromSuggestion(context, ref, companyId, q.question, q.id, onRefresh);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: AppTheme.successColor),
                      tooltip: 'Mark approved',
                      onPressed: () async {
                        await UnknownQuestionsService().approve(q.id);
                        ref.invalidate(intentsProvider(companyId));
                        onRefresh();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                      onPressed: () async {
                        await UnknownQuestionsService().delete(q.id);
                        onRefresh();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
