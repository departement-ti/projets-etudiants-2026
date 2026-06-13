import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/ui/app_error.dart';
import '../invoice/invoice_details.dart';
import '../invoice/invoice_list_page.dart';
import '../leases/lease_details_page.dart';
import '../leases/lease_list_page.dart';
import '../properties/properties_page.dart';
import '../reports/financial_report_page.dart';
import '../tickets/ticket_details_page.dart';
import '../tickets/ticket_list_page.dart';
import 'copilot_service.dart';

class CopilotPage extends StatefulWidget {
  const CopilotPage({super.key});

  @override
  State<CopilotPage> createState() => _CopilotPageState();
}

class _CopilotPageState extends State<CopilotPage> {
  Map<String, dynamic>? data;

  bool loading = true;
  bool refreshing = false;
  String error = '';

  String selectedSection = 'OVERVIEW';

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);
  static const darkText = Color(0xFF1D1B20);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF97316);
  static const success = Color(0xFF22C55E);
  static const info = Color(0xFF0EA5E9);
  static const teal = Color(0xFF14B8A6);
  static const purple = Color(0xFF8B5CF6);

  final sections = const [
    {'id': 'OVERVIEW', 'label': 'Overview', 'icon': Icons.dashboard_customize},
    {'id': 'RISKS', 'label': 'Risks', 'icon': Icons.warning_amber},
    {'id': 'ACTIONS', 'label': 'Actions', 'icon': Icons.tips_and_updates},
    {'id': 'MONEY', 'label': 'Money', 'icon': Icons.payments},
    {'id': 'WORK', 'label': 'Work', 'icon': Icons.construction},
    {'id': 'LEASES', 'label': 'Leases', 'icon': Icons.description},
  ];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({bool silent = false}) async {
    if (silent) {
      setState(() => refreshing = true);
    } else {
      setState(() {
        loading = true;
        error = '';
      });
    }

    try {
      final res = await CopilotService.briefing();

      if (!mounted) return;

      setState(() {
        data = res;
        loading = false;
        refreshing = false;
        error = '';
      });
    } catch (e) {
      if (!mounted) return;

      if (silent) {
        setState(() => refreshing = false);

        await AppError.show(context, e, title: 'Could not refresh Copilot');

        return;
      }

      setState(() {
        error = AppError.clean(e);
        loading = false;
        refreshing = false;
      });
    }
  }

  Map<String, dynamic> get health {
    final value = data?['health'];
    if (value is Map<String, dynamic>) return value;
    return {};
  }

  Map<String, dynamic> get summary {
    final value = data?['summary'];
    if (value is Map<String, dynamic>) return value;
    return {};
  }

  List<dynamic> listValue(String key) {
    final value = data?[key];
    if (value is List) return value;
    return [];
  }

  num numValue(Map<String, dynamic> map, String key) {
    final value = map[key];

    if (value is num) return value;

    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  String money(dynamic value) {
    if (value is num) return value.toStringAsFixed(2);

    final parsed = num.tryParse(value?.toString() ?? '');

    return (parsed ?? 0).toStringAsFixed(2);
  }

  String formatDate(dynamic value) {
    if (value == null) return '—';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    return parsed.toLocal().toString().split(' ')[0];
  }

  num get healthScore => numValue(health, 'score');

  int get alertCount => listValue('alerts').length;

  int get recommendationCount => listValue('recommendations').length;

  int get overdueInvoiceCount => listValue('overdueInvoices').length;

  int get urgentTicketCount => listValue('urgentTickets').length;

  int get endingLeaseCount => listValue('leasesEndingSoon').length;

  int get hotspotCount => listValue('maintenanceHotspots').length;

  num get totalUnpaid => numValue(summary, 'totalUnpaid');

  num get totalRevenue => numValue(summary, 'totalRevenue');

  num get occupancyRate => numValue(health, 'occupancyRate');

  num get collectionRate => numValue(health, 'collectionRate');

  num get revenueTrend => numValue(health, 'revenueTrend');

  Color scoreColor(num score) {
    if (score >= 85) return success;
    if (score >= 70) return info;
    if (score >= 55) return warning;

    return danger;
  }

  String portfolioHealthLabel() {
    final label = health['label']?.toString();
    if (label != null && label.trim().isNotEmpty) return label;

    if (healthScore >= 85) return 'Excellent health';
    if (healthScore >= 70) return 'Healthy portfolio';
    if (healthScore >= 55) return 'Needs monitoring';

    return 'Needs attention';
  }

  String generatedAtLabel() {
    final generatedAt = data?['generatedAt'];

    if (generatedAt == null) return 'Generated just now';

    return 'Generated ${formatDate(generatedAt)}';
  }

  Color severityColor(String? severity) {
    switch (severity) {
      case 'HIGH':
      case 'URGENT':
        return danger;
      case 'MEDIUM':
      case 'NORMAL':
        return warning;
      case 'LOW':
        return success;
      default:
        return Colors.grey;
    }
  }

  IconData alertIcon(String? type) {
    switch (type) {
      case 'PAYMENT_RISK':
        return Icons.warning_amber;
      case 'MAINTENANCE_RISK':
        return Icons.construction;
      case 'LEASE_RENEWAL':
        return Icons.description;
      case 'OCCUPANCY':
        return Icons.home_work;
      case 'GOOD_NEWS':
        return Icons.check_circle;
      default:
        return Icons.info_outline;
    }
  }

  IconData actionIcon(String? action) {
    switch (action) {
      case 'OPEN_INVOICES':
        return Icons.receipt_long;
      case 'OPEN_TICKETS':
        return Icons.construction;
      case 'OPEN_LEASES':
        return Icons.description;
      case 'OPEN_UNITS':
      case 'OPEN_PROPERTIES':
        return Icons.apartment;
      case 'OPEN_REPORTS':
        return Icons.bar_chart;
      default:
        return Icons.auto_awesome;
    }
  }

  Color actionColor(String? action) {
    switch (action) {
      case 'OPEN_INVOICES':
        return danger;
      case 'OPEN_TICKETS':
        return warning;
      case 'OPEN_LEASES':
        return info;
      case 'OPEN_UNITS':
      case 'OPEN_PROPERTIES':
        return primary;
      case 'OPEN_REPORTS':
        return teal;
      default:
        return purple;
    }
  }

  String actionLabel(String? action) {
    switch (action) {
      case 'OPEN_INVOICES':
        return 'Open invoices';
      case 'OPEN_TICKETS':
        return 'Open tickets';
      case 'OPEN_LEASES':
        return 'Open leases';
      case 'OPEN_UNITS':
      case 'OPEN_PROPERTIES':
        return 'Open properties';
      case 'OPEN_REPORTS':
        return 'Open reports';
      default:
        return 'Review';
    }
  }

  Future<void> pushPage(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    if (!mounted) return;

    await load(silent: true);
  }

  Future<void> openReports() async {
    await pushPage(const FinancialReportPage());
  }

  Future<void> openInvoices() async {
    await pushPage(const InvoiceListPage());
  }

  Future<void> openTickets() async {
    await pushPage(const TicketListPage());
  }

  Future<void> openLeases() async {
    await pushPage(const LeaseListPage());
  }

  Future<void> openProperties() async {
    await pushPage(const PropertiesPage());
  }

  Future<void> handleRecommendation(dynamic recommendation) async {
    final action = recommendation['action']?.toString();

    switch (action) {
      case 'OPEN_INVOICES':
        await openInvoices();
        return;
      case 'OPEN_TICKETS':
        await openTickets();
        return;
      case 'OPEN_LEASES':
        await openLeases();
        return;
      case 'OPEN_UNITS':
      case 'OPEN_PROPERTIES':
        await openProperties();
        return;
      case 'OPEN_REPORTS':
        await openReports();
        return;
      default:
        showSmartBottomSheet(
          title: recommendation['title']?.toString() ?? 'Recommendation',
          icon: actionIcon(action),
          color: actionColor(action),
          body: recommendation['body']?.toString() ?? '',
          chips: [
            recommendation['priority']?.toString() ?? 'NORMAL',
            action ?? 'ACTION',
          ],
        );
    }
  }

  Future<void> openPortfolioInsights() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CopilotInsightsSheet(
        score: healthScore,
        healthLabel: portfolioHealthLabel(),
        healthColor: scoreColor(healthScore),
        generatedAt: generatedAtLabel(),
        briefing: data?['briefing']?.toString() ?? '',
        alertCount: alertCount,
        recommendationCount: recommendationCount,
        overdueInvoiceCount: overdueInvoiceCount,
        urgentTicketCount: urgentTicketCount,
        endingLeaseCount: endingLeaseCount,
        hotspotCount: hotspotCount,
        totalUnpaid: totalUnpaid,
        totalRevenue: totalRevenue,
        occupancyRate: occupancyRate,
        collectionRate: collectionRate,
        revenueTrend: revenueTrend,
      ),
    );
  }

  Widget heroHeader() {
    final color = scoreColor(healthScore);
    final briefing = data?['briefing']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF6750A4), Color(0xFF8B7DD8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.25),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              HealthRing(score: healthScore.toDouble(), color: color),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SmartTenant Copilot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      portfolioHealthLabel(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      generatedAtLabel(),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: refreshing ? null : () => load(silent: true),
                icon: refreshing
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: ((healthScore / 100).clamp(0, 1)).toDouble(),
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Text(
              briefing.trim().isEmpty
                  ? 'Copilot is ready to analyze your portfolio.'
                  : briefing,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: heroButton(
                  icon: Icons.insights,
                  label: 'Insights',
                  onTap: openPortfolioInsights,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: heroButton(
                  icon: Icons.receipt_long,
                  label: 'Invoices',
                  onTap: openInvoices,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: heroButton(
                  icon: Icons.construction,
                  label: 'Tickets',
                  onTap: openTickets,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget heroButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget sectionSelector() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final section = sections[index];
          final id = section['id'] as String;
          final label = section['label'] as String;
          final icon = section['icon'] as IconData;
          final selected = selectedSection == id;

          return ChoiceChip(
            selected: selected,
            avatar: Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : primary,
            ),
            label: Text(label),
            selectedColor: primary,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: selected ? Colors.white : darkText,
              fontWeight: FontWeight.bold,
            ),
            side: BorderSide(
              color: selected ? primary : Colors.black.withOpacity(0.06),
            ),
            onSelected: (_) => setState(() => selectedSection = id),
          );
        },
      ),
    );
  }

  Widget compactKpis() {
    final kpis = [
      _KpiData(
        title: 'Unpaid',
        value: money(totalUnpaid),
        icon: Icons.warning_amber,
        color: danger,
        onTap: openInvoices,
      ),
      _KpiData(
        title: 'Collection',
        value: '${collectionRate.toStringAsFixed(0)}%',
        icon: Icons.payments,
        color: success,
        onTap: openReports,
      ),
      _KpiData(
        title: 'Occupancy',
        value: '${occupancyRate.toStringAsFixed(0)}%',
        icon: Icons.home_work,
        color: primary,
        onTap: openProperties,
      ),
      _KpiData(
        title: 'Urgent',
        value: urgentTicketCount.toString(),
        icon: Icons.construction,
        color: warning,
        onTap: openTickets,
      ),
      _KpiData(
        title: 'Ending',
        value: endingLeaseCount.toString(),
        icon: Icons.description,
        color: info,
        onTap: openLeases,
      ),
      _KpiData(
        title: 'Revenue',
        value: money(totalRevenue),
        icon: Icons.trending_up,
        color: teal,
        onTap: openReports,
      ),
    ];

    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kpis.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final item = kpis[index];

          return SizedBox(width: 145, child: compactKpiCard(item));
        },
      ),
    );
  }

  Widget compactKpiCard(_KpiData item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: item.color.withOpacity(0.12),
                child: Icon(item.icon, color: item.color, size: 21),
              ),
              const Spacer(),
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.title,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget sectionHeader({
    required String title,
    required String subtitle,
    VoidCallback? onOpen,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
        ),
        if (onOpen != null)
          TextButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Open'),
          ),
      ],
    );
  }

  Widget overviewSection() {
    final alerts = listValue('alerts');
    final recommendations = listValue('recommendations');

    return Column(
      children: [
        executiveSnapshot(),

        const SizedBox(height: 14),

        actionGrid(),

        const SizedBox(height: 20),

        sectionHeader(
          title: 'Today’s Focus',
          subtitle: 'Most important signals for your portfolio',
        ),

        const SizedBox(height: 8),

        if (alerts.isNotEmpty)
          alertCard(alerts.first)
        else
          goodNewsCard('No critical alerts right now'),

        if (recommendations.isNotEmpty) ...[
          const SizedBox(height: 10),
          recommendationCard(recommendations.first),
        ],
      ],
    );
  }

  Widget executiveSnapshot() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            snapshotRow(
              title: 'Portfolio health',
              value: '${healthScore.toStringAsFixed(0)}%',
              icon: Icons.health_and_safety,
              color: scoreColor(healthScore),
            ),
            const Divider(height: 18),
            snapshotRow(
              title: 'Open risks',
              value: alertCount.toString(),
              icon: Icons.warning_amber,
              color: alertCount > 0 ? warning : success,
            ),
            const Divider(height: 18),
            snapshotRow(
              title: 'Recommended actions',
              value: recommendationCount.toString(),
              icon: Icons.tips_and_updates,
              color: recommendationCount > 0 ? primary : success,
            ),
          ],
        ),
      ),
    );
  }

  Widget snapshotRow({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget actionGrid() {
    return Row(
      children: [
        Expanded(
          child: actionCard(
            title: 'Reports',
            icon: Icons.bar_chart,
            color: teal,
            onTap: openReports,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: actionCard(
            title: 'Leases',
            icon: Icons.description,
            color: info,
            onTap: openLeases,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: actionCard(
            title: 'Properties',
            icon: Icons.apartment,
            color: primary,
            onTap: openProperties,
          ),
        ),
      ],
    );
  }

  Widget actionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 25),
              const SizedBox(height: 7),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget risksSection() {
    final alerts = listValue('alerts');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(
          title: 'Risk Alerts',
          subtitle: 'Critical issues that need attention',
        ),
        const SizedBox(height: 8),
        if (alerts.isEmpty)
          goodNewsCard('No active risk alerts')
        else
          ...alerts.take(4).map(alertCard),
        if (alerts.length > 4)
          viewMoreButton(
            label: 'View all ${alerts.length} alerts',
            onTap: () => showListSheet(
              title: 'All Risk Alerts',
              children: alerts.map(alertCard).toList(),
            ),
          ),
      ],
    );
  }

  Widget actionsSection() {
    final recommendations = listValue('recommendations');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(
          title: 'Recommended Actions',
          subtitle: 'Tap to jump directly to the right workflow',
        ),
        const SizedBox(height: 8),
        if (recommendations.isEmpty)
          goodNewsCard('No recommendations for now')
        else
          ...recommendations.take(4).map(recommendationCard),
        if (recommendations.length > 4)
          viewMoreButton(
            label: 'View all ${recommendations.length} recommendations',
            onTap: () => showListSheet(
              title: 'All Recommendations',
              children: recommendations.map(recommendationCard).toList(),
            ),
          ),
      ],
    );
  }

  Widget moneySection() {
    final overdueInvoices = listValue('overdueInvoices');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(
          title: 'Money Signals',
          subtitle: 'Revenue, unpaid balance and overdue invoices',
          onOpen: openInvoices,
        ),
        const SizedBox(height: 8),
        moneyHealthCard(),
        const SizedBox(height: 12),
        if (overdueInvoices.isEmpty)
          goodNewsCard('No overdue invoices')
        else
          ...overdueInvoices.take(4).map(overdueInvoiceCard),
        if (overdueInvoices.length > 4)
          viewMoreButton(
            label: 'View all ${overdueInvoices.length} overdue invoices',
            onTap: () => showListSheet(
              title: 'Overdue Invoices',
              children: overdueInvoices.map(overdueInvoiceCard).toList(),
            ),
          ),
      ],
    );
  }

  Widget moneyHealthCard() {
    final color = collectionRate >= 80 ? success : warning;

    return Card(
      color: color.withOpacity(0.07),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            snapshotRow(
              title: 'Collection rate',
              value: '${collectionRate.toStringAsFixed(1)}%',
              icon: Icons.payments,
              color: color,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: (collectionRate / 100).clamp(0, 1).toDouble(),
                minHeight: 8,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 12),
            snapshotRow(
              title: 'Total unpaid',
              value: money(totalUnpaid),
              icon: Icons.warning_amber,
              color: totalUnpaid > 0 ? danger : success,
            ),
          ],
        ),
      ),
    );
  }

  Widget workSection() {
    final urgentTickets = listValue('urgentTickets');
    final hotspots = listValue('maintenanceHotspots');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(
          title: 'Maintenance Workload',
          subtitle: 'Urgent tickets and repeated issue hotspots',
          onOpen: openTickets,
        ),
        const SizedBox(height: 8),
        if (urgentTickets.isEmpty)
          goodNewsCard('No urgent tickets')
        else
          ...urgentTickets.take(3).map(urgentTicketCard),
        if (urgentTickets.length > 3)
          viewMoreButton(
            label: 'View all ${urgentTickets.length} urgent tickets',
            onTap: () => showListSheet(
              title: 'Urgent Tickets',
              children: urgentTickets.map(urgentTicketCard).toList(),
            ),
          ),
        const SizedBox(height: 18),
        sectionHeader(
          title: 'Hotspots',
          subtitle: 'Units with repeated ticket activity',
        ),
        const SizedBox(height: 8),
        if (hotspots.isEmpty)
          goodNewsCard('No maintenance hotspots')
        else
          ...hotspots.take(3).map(hotspotCard),
      ],
    );
  }

  Widget leasesSection() {
    final leases = listValue('leasesEndingSoon');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(
          title: 'Lease Renewals',
          subtitle: 'Leases ending soon and renewal opportunities',
          onOpen: openLeases,
        ),
        const SizedBox(height: 8),
        if (leases.isEmpty)
          goodNewsCard('No leases ending soon')
        else
          ...leases.take(5).map(leaseEndingCard),
        if (leases.length > 5)
          viewMoreButton(
            label: 'View all ${leases.length} ending leases',
            onTap: () => showListSheet(
              title: 'Leases Ending Soon',
              children: leases.map(leaseEndingCard).toList(),
            ),
          ),
      ],
    );
  }

  Widget selectedSectionBody() {
    switch (selectedSection) {
      case 'RISKS':
        return risksSection();
      case 'ACTIONS':
        return actionsSection();
      case 'MONEY':
        return moneySection();
      case 'WORK':
        return workSection();
      case 'LEASES':
        return leasesSection();
      case 'OVERVIEW':
      default:
        return overviewSection();
    }
  }

  Widget alertCard(dynamic alert) {
    final severity = alert['severity']?.toString();
    final type = alert['type']?.toString();
    final color = severityColor(severity);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          showSmartBottomSheet(
            title: alert['title']?.toString() ?? 'Alert',
            icon: alertIcon(type),
            color: color,
            body: alert['body']?.toString() ?? '',
            chips: [severity ?? 'INFO', type ?? 'ALERT'],
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                child: Icon(alertIcon(type), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert['title']?.toString() ?? 'Alert',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      alert['body']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget recommendationCard(dynamic recommendation) {
    final action = recommendation['action']?.toString();
    final priority = recommendation['priority']?.toString();
    final color = actionColor(action);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => handleRecommendation(recommendation),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.12),
                    child: Icon(actionIcon(action), color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      recommendation['title']?.toString() ?? 'Recommendation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Chip(
                    label: Text(priority ?? 'NORMAL'),
                    backgroundColor: severityColor(priority).withOpacity(0.12),
                    labelStyle: TextStyle(
                      color: severityColor(priority),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    side: BorderSide.none,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  recommendation['body']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => handleRecommendation(recommendation),
                  icon: Icon(actionIcon(action)),
                  label: Text(actionLabel(action)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget overdueInvoiceCard(dynamic invoice) {
    final id = invoice['id']?.toString();

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: danger.withOpacity(0.12),
          child: const Icon(Icons.receipt_long, color: danger),
        ),
        title: Text(
          'Remaining: ${money(invoice['remainingAmount'])}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${invoice['tenantName'] ?? 'Tenant'} • ${invoice['propertyName'] ?? 'Property'}\n'
          'Due: ${formatDate(invoice['dueDate'])}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: id == null
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InvoiceDetailsPage(invoiceId: id),
                  ),
                ).then((_) => load(silent: true));
              },
      ),
    );
  }

  Widget urgentTicketCard(dynamic ticket) {
    final id = ticket['id']?.toString();

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: warning.withOpacity(0.12),
          child: const Icon(Icons.construction, color: warning),
        ),
        title: Text(
          ticket['title']?.toString() ?? 'Ticket',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${ticket['propertyName'] ?? 'Property'} • ${ticket['unitName'] ?? 'Unit'}\n'
          'Age: ${ticket['ageDays'] ?? 0} days • ${ticket['priority'] ?? 'medium'}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: id == null
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TicketDetailsPage(ticketId: id),
                  ),
                ).then((_) => load(silent: true));
              },
      ),
    );
  }

  Widget leaseEndingCard(dynamic lease) {
    final id = lease['id']?.toString();

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: info.withOpacity(0.12),
          child: const Icon(Icons.description, color: info),
        ),
        title: Text(
          lease['tenantName']?.toString() ?? 'Tenant',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${lease['propertyName'] ?? 'Property'} • ${lease['unitName'] ?? 'Unit'}\n'
          'Ends: ${formatDate(lease['endDate'])} • ${lease['daysLeft']} days left',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: id == null
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LeaseDetailsPage(leaseId: id),
                  ),
                ).then((_) => load(silent: true));
              },
      ),
    );
  }

  Widget hotspotCard(dynamic hotspot) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: purple.withOpacity(0.12),
          child: const Icon(Icons.local_fire_department, color: purple),
        ),
        title: Text(
          hotspot['unitName']?.toString() ?? 'Unit',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(hotspot['propertyName']?.toString() ?? 'Property'),
        trailing: Chip(
          label: Text('${hotspot['count']} tickets'),
          backgroundColor: purple.withOpacity(0.12),
          labelStyle: const TextStyle(
            color: purple,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          side: BorderSide.none,
        ),
        onTap: openTickets,
      ),
    );
  }

  Widget goodNewsCard(String message) {
    return Card(
      color: success.withOpacity(0.07),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: success.withOpacity(0.12),
              child: const Icon(Icons.check_circle, color: success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget viewMoreButton({required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.expand_more),
          label: Text(label),
        ),
      ),
    );
  }

  Future<void> showListSheet({
    required String title,
    required List<Widget> children,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.50,
          maxChildSize: 0.96,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: softBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SafeArea(
                top: false,
                child: ListView(
                  controller: scrollController,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...children,
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
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

  void showSmartBottomSheet({
    required String title,
    required IconData icon,
    required Color color,
    required String body,
    required List<String> chips,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: softBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 20),

                  CircleAvatar(
                    radius: 34,
                    backgroundColor: color.withOpacity(0.12),
                    child: Icon(icon, color: color, size: 34),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: chips.map((chip) {
                      return Chip(
                        label: Text(chip),
                        backgroundColor: color.withOpacity(0.12),
                        labelStyle: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        body.trim().isEmpty
                            ? 'No extra details available.'
                            : body,
                        style: const TextStyle(fontSize: 15, height: 1.45),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget bodyContent() {
    return RefreshIndicator(
      onRefresh: () => load(silent: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          heroHeader(),

          const SizedBox(height: 16),

          compactKpis(),

          const SizedBox(height: 16),

          sectionSelector(),

          const SizedBox(height: 18),

          selectedSectionBody(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget loadingBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SizedBox(height: 180),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget errorBody() {
    return RefreshIndicator(
      onRefresh: () => load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 120),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: danger, size: 44),
                  const SizedBox(height: 12),
                  const Text(
                    'Could not load Copilot',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: danger),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => load(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyBody() {
    return RefreshIndicator(
      onRefresh: () => load(),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const SizedBox(height: 120),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 60,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No briefing available',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Refresh Copilot to generate a new intelligence briefing.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => load(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Generate Briefing'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        title: const Text(
          'Copilot',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Insights',
            icon: const Icon(Icons.insights),
            onPressed: data == null ? null : openPortfolioInsights,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: refreshing
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: refreshing ? null : () => load(silent: true),
          ),
        ],
      ),
      body: loading
          ? loadingBody()
          : error.isNotEmpty
          ? errorBody()
          : data == null
          ? emptyBody()
          : bodyContent(),
    );
  }
}

class _KpiData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _KpiData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _CopilotInsightsSheet extends StatelessWidget {
  final num score;
  final String healthLabel;
  final Color healthColor;
  final String generatedAt;
  final String briefing;
  final int alertCount;
  final int recommendationCount;
  final int overdueInvoiceCount;
  final int urgentTicketCount;
  final int endingLeaseCount;
  final int hotspotCount;
  final num totalUnpaid;
  final num totalRevenue;
  final num occupancyRate;
  final num collectionRate;
  final num revenueTrend;

  const _CopilotInsightsSheet({
    required this.score,
    required this.healthLabel,
    required this.healthColor,
    required this.generatedAt,
    required this.briefing,
    required this.alertCount,
    required this.recommendationCount,
    required this.overdueInvoiceCount,
    required this.urgentTicketCount,
    required this.endingLeaseCount,
    required this.hotspotCount,
    required this.totalUnpaid,
    required this.totalRevenue,
    required this.occupancyRate,
    required this.collectionRate,
    required this.revenueTrend,
  });

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  Widget scoreCard({
    required String title,
    required num value,
    required IconData icon,
    required Color color,
  }) {
    final safeValue = value.clamp(0, 100).toDouble();

    return Card(
      color: color.withOpacity(0.07),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '${safeValue.round()}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: safeValue / 100,
                minHeight: 8,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 138,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString().isNotEmpty == true ? value.toString() : '—',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget signalRow({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.84,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: softBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                CircleAvatar(
                  radius: 38,
                  backgroundColor: healthColor.withOpacity(0.12),
                  child: Icon(Icons.insights, color: healthColor, size: 38),
                ),

                const SizedBox(height: 14),

                const Text(
                  'Copilot Intelligence',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                Text(
                  generatedAt,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),

                const SizedBox(height: 16),

                Chip(
                  avatar: Icon(
                    Icons.health_and_safety,
                    color: healthColor,
                    size: 18,
                  ),
                  label: Text(healthLabel),
                  backgroundColor: healthColor.withOpacity(0.12),
                  labelStyle: TextStyle(
                    color: healthColor,
                    fontWeight: FontWeight.bold,
                  ),
                  side: BorderSide.none,
                ),

                const SizedBox(height: 18),

                scoreCard(
                  title: 'Portfolio Health',
                  value: score,
                  icon: Icons.health_and_safety,
                  color: healthColor,
                ),

                const SizedBox(height: 10),

                scoreCard(
                  title: 'Collection Rate',
                  value: collectionRate,
                  icon: Icons.payments,
                  color: collectionRate >= 80 ? Colors.green : Colors.orange,
                ),

                const SizedBox(height: 10),

                scoreCard(
                  title: 'Occupancy Rate',
                  value: occupancyRate,
                  icon: Icons.home_work,
                  color: occupancyRate >= 80 ? Colors.green : primary,
                ),

                const SizedBox(height: 14),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        infoRow(
                          'Total Revenue',
                          totalRevenue.toStringAsFixed(2),
                        ),
                        infoRow('Total Unpaid', totalUnpaid.toStringAsFixed(2)),
                        infoRow(
                          'Revenue Trend',
                          '${revenueTrend.toStringAsFixed(1)}%',
                        ),
                        infoRow('Recommendations', recommendationCount),
                        infoRow('Risk Alerts', alertCount),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Signals Breakdown',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        signalRow(
                          title: 'Overdue Invoices',
                          value: overdueInvoiceCount,
                          icon: Icons.receipt_long,
                          color: Colors.red,
                        ),
                        signalRow(
                          title: 'Urgent Tickets',
                          value: urgentTicketCount,
                          icon: Icons.construction,
                          color: Colors.orange,
                        ),
                        signalRow(
                          title: 'Leases Ending Soon',
                          value: endingLeaseCount,
                          icon: Icons.description,
                          color: Colors.blue,
                        ),
                        signalRow(
                          title: 'Maintenance Hotspots',
                          value: hotspotCount,
                          icon: Icons.local_fire_department,
                          color: Colors.deepPurple,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  color: primary.withOpacity(0.07),
                  child: ListTile(
                    leading: const Icon(Icons.auto_awesome, color: primary),
                    title: const Text(
                      'Executive briefing',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      briefing.trim().isEmpty
                          ? 'No briefing text was generated.'
                          : briefing,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class HealthRing extends StatelessWidget {
  final double score;
  final Color color;

  const HealthRing({super.key, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    final safeScore = score.clamp(0, 100).toDouble();

    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(84, 84),
            painter: HealthRingPainter(progress: safeScore / 100, color: color),
          ),
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              safeScore.toStringAsFixed(0),
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HealthRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  HealthRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..shader = SweepGradient(
        colors: [Colors.white, color, Colors.white],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant HealthRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
