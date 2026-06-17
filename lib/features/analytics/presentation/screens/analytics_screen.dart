import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/analytics_service.dart';
import '../../../chat/presentation/providers/chat_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final company = ref.watch(currentCompanyProvider).valueOrNull;
    if (company == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: AnalyticsService().getDashboardStats(company.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Total sessions',
                  value: '${stats['totalSessions'] ?? 0}',
                ),
                _StatTile(
                  icon: Icons.message_outlined,
                  title: 'Total messages',
                  value: '${stats['totalMessages'] ?? 0}',
                ),
                _StatTile(
                  icon: Icons.timer_outlined,
                  title: 'Avg conversation duration',
                  value: _formatDuration((stats['avgConversationDurationSeconds'] as num?)?.toDouble() ?? 0),
                ),
                _StatTile(
                  icon: Icons.star_outline_rounded,
                  title: 'Customer satisfaction (avg)',
                  value: (stats['averageRating'] != null)
                      ? '${(stats['averageRating'] as num).toStringAsFixed(1)} / 5'
                      : 'No ratings yet',
                ),
                _StatTile(
                  icon: Icons.rate_review_outlined,
                  title: 'Total ratings',
                  value: '${stats['totalRatings'] ?? 0}',
                ),
                _StatTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Unanswered (pending)',
                  value: '${stats['pendingUnknownQuestions'] ?? 0}',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(double seconds) {
    if (seconds < 60) return '${seconds.toStringAsFixed(0)}s';
    final m = (seconds / 60).floor();
    final s = (seconds % 60).round();
    return '${m}m ${s}s';
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatTile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
