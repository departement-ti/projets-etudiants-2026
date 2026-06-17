import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/analytics_service.dart';
import '../../../chat/presentation/providers/chat_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(currentCompanyProvider);
    final company = companyAsync.valueOrNull;
    if (company == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(currentCompanyProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionTitle(title: 'Quick actions'),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _ActionCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Intents',
                    onTap: () => context.push('/intents'),
                  ),
                  _ActionCard(
                    icon: Icons.analytics_outlined,
                    label: 'Analytics',
                    onTap: () => context.push('/analytics'),
                  ),
                  _ActionCard(
                    icon: Icons.help_outline_rounded,
                    label: 'Unanswered',
                    onTap: () => context.push('/intents?tab=unknown'),
                  ),
                  _ActionCard(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    onTap: () => context.push('/settings'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Overview'),
              const SizedBox(height: 8),
              _StatsCards(companyId: company.id),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Most asked questions'),
              const SizedBox(height: 8),
              _MostAskedQuestions(companyId: company.id),
            ],
          ),
        ),
      ),
    );
  }
}

class _MostAskedQuestions extends StatelessWidget {
  final String companyId;

  const _MostAskedQuestions({required this.companyId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AnalyticsService().getMostAskedQuestions(companyId, limit: 5),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No data yet', style: TextStyle(color: Colors.grey[600])),
            ),
          );
        }
        final list = snapshot.data!;
        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final e = list[index];
              final text = e['text'] as String? ?? '';
              final count = e['count'] as int? ?? 0;
              return ListTile(
                title: Text(text.length > 50 ? '${text.substring(0, 50)}...' : text, maxLines: 2),
                trailing: Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: AppTheme.primaryColor),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsCards extends ConsumerWidget {
  final String companyId;

  const _StatsCards({required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = AnalyticsService();
    return FutureBuilder<Map<String, dynamic>>(
      future: analytics.getDashboardStats(companyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final stats = snapshot.data!;
        final avgDuration = stats['avgConversationDurationSeconds'] as num?;
        final satisfaction = stats['satisfactionRate'] as num?;
        final unansweredPct = stats['unansweredPercentage'] as num?;
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Sessions',
                    value: '${stats['totalSessions'] ?? 0}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Messages',
                    value: '${stats['totalMessages'] ?? 0}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Satisfaction',
                    value: satisfaction != null ? '${satisfaction.toStringAsFixed(0)}%' : '-',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Unanswered %',
                    value: unansweredPct != null ? '${unansweredPct.toStringAsFixed(1)}%' : '0%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Avg duration',
                    value: avgDuration != null && avgDuration > 0
                        ? '${(avgDuration / 60).toStringAsFixed(1)} min'
                        : '-',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Pending Qs',
                    value: '${stats['pendingUnknownQuestions'] ?? 0}',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
