import 'package:flutter/material.dart';

import '../../core/ui/app_error.dart';
import 'reports_service.dart';

class FinancialReportPage extends StatefulWidget {
  const FinancialReportPage({super.key});

  @override
  State<FinancialReportPage> createState() => _FinancialReportPageState();
}

class _FinancialReportPageState extends State<FinancialReportPage> {
  Map<String, dynamic>? report;

  bool loading = true;
  bool refreshing = false;
  bool exportingPdf = false;

  String error = '';
  String selectedSection = 'OVERVIEW';

  DateTime? startDate;
  DateTime? endDate;

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);
  static const darkText = Color(0xFF1D1B20);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF97316);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF0EA5E9);
  static const teal = Color(0xFF14B8A6);
  static const purple = Color(0xFF8B5CF6);

  final sections = const [
    {'id': 'OVERVIEW', 'label': 'Overview', 'icon': Icons.dashboard_customize},
    {'id': 'PAYMENTS', 'label': 'Payments', 'icon': Icons.payments},
    {'id': 'UNPAID', 'label': 'Unpaid', 'icon': Icons.warning_amber},
    {'id': 'INVOICES', 'label': 'Invoices', 'icon': Icons.receipt_long},
  ];

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  bool get invalidPeriod {
    return startDate != null &&
        endDate != null &&
        endDate!.isBefore(startDate!);
  }

  Map<String, dynamic> get summary {
    final value = report?['summary'];

    if (value is Map<String, dynamic>) return value;

    return {};
  }

  List<dynamic> listValue(String key) {
    final value = report?[key];

    if (value is List) return value;

    return [];
  }

  num numValue(Map<String, dynamic> map, String key) {
    final value = map[key];

    if (value is num) return value;

    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  num get totalInvoiced => numValue(summary, 'totalInvoiced');
  num get totalRevenue => numValue(summary, 'totalRevenue');
  num get totalUnpaid => numValue(summary, 'totalUnpaid');
  num get collectionRate => numValue(summary, 'collectionRate');

  int get paymentCount {
    final value = summary['paymentCount'];
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int get paidInvoiceCount {
    final value = summary['paidInvoiceCount'];
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int get unpaidInvoiceCount {
    final value = summary['unpaidInvoiceCount'];
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int get outstandingCount => listValue('outstandingInvoices').length;
  int get recentPaymentCount => listValue('recentPayments').length;
  int get topUnpaidTenantCount => listValue('topUnpaidTenants').length;

  Color get collectionColor {
    if (collectionRate >= 85) return success;
    if (collectionRate >= 60) return warning;

    return danger;
  }

  String get collectionLabel {
    if (collectionRate >= 85) return 'Healthy collection';
    if (collectionRate >= 60) return 'Needs monitoring';

    return 'Needs attention';
  }

  Future<void> loadReport({bool silent = false}) async {
    if (invalidPeriod) {
      setState(() {
        error = 'End date must be after start date';
        loading = false;
        refreshing = false;
      });
      return;
    }

    if (silent) {
      setState(() => refreshing = true);
    } else {
      setState(() {
        loading = true;
        error = '';
      });
    }

    try {
      final data = await ReportsService.financialReport(
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) return;

      setState(() {
        report = data;
        loading = false;
        refreshing = false;
        error = '';
      });
    } catch (e) {
      if (!mounted) return;

      if (silent) {
        setState(() => refreshing = false);

        await AppError.show(
          context,
          e,
          title: 'Could not refresh financial report',
        );

        return;
      }

      setState(() {
        error = AppError.clean(e);
        loading = false;
        refreshing = false;
      });
    }
  }

  Future<void> exportPdf() async {
    if (invalidPeriod) {
      await AppError.show(
        context,
        'End date must be after start date.',
        title: 'Invalid report period',
      );
      return;
    }

    setState(() => exportingPdf = true);

    try {
      await ReportsService.openFinancialPdf(
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF report opened')));
    } catch (e) {
      if (!mounted) return;

      await AppError.show(context, e, title: 'Could not export PDF report');
    } finally {
      if (mounted) {
        setState(() => exportingPdf = false);
      }
    }
  }

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() => startDate = picked);

    if (invalidPeriod) {
      await AppError.show(
        context,
        'End date must be after start date.',
        title: 'Invalid report period',
      );
      return;
    }

    await loadReport(silent: true);
  }

  Future<void> pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() => endDate = picked);

    if (invalidPeriod) {
      await AppError.show(
        context,
        'End date must be after start date.',
        title: 'Invalid report period',
      );
      return;
    }

    await loadReport(silent: true);
  }

  Future<void> clearDates() async {
    setState(() {
      startDate = null;
      endDate = null;
      error = '';
    });

    await loadReport(silent: true);
  }

  Future<void> applyQuickRange(String range) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? start;
    DateTime? end;

    switch (range) {
      case 'THIS_MONTH':
        start = DateTime(today.year, today.month, 1);
        end = today;
        break;

      case 'LAST_30':
        start = today.subtract(const Duration(days: 30));
        end = today;
        break;

      case 'THIS_YEAR':
        start = DateTime(today.year, 1, 1);
        end = today;
        break;

      case 'ALL':
      default:
        start = null;
        end = null;
        break;
    }

    setState(() {
      startDate = start;
      endDate = end;
      error = '';
    });

    await loadReport(silent: true);
  }

  Future<void> openFiltersSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportFilterSheet(
        startDate: startDate,
        endDate: endDate,
        formatDate: formatDate,
        onPickStart: pickStartDate,
        onPickEnd: pickEndDate,
        onClear: clearDates,
        onQuickRange: applyQuickRange,
      ),
    );
  }

  Future<void> openReportInsights() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FinancialInsightsSheet(
        periodLabel: selectedPeriodLabel(),
        totalInvoiced: totalInvoiced,
        totalRevenue: totalRevenue,
        totalUnpaid: totalUnpaid,
        collectionRate: collectionRate,
        paymentCount: paymentCount,
        paidInvoiceCount: paidInvoiceCount,
        unpaidInvoiceCount: unpaidInvoiceCount,
        outstandingCount: outstandingCount,
        topUnpaidTenantCount: topUnpaidTenantCount,
        collectionLabel: collectionLabel,
        collectionColor: collectionColor,
        money: money,
      ),
    );
  }

  Future<void> openListSheet({
    required String title,
    required List<dynamic> items,
    required Widget Function(dynamic item) itemBuilder,
    required String emptyMessage,
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
                    dragHandle(),

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

                    if (items.isEmpty)
                      emptyCard(emptyMessage)
                    else
                      ...items.map(itemBuilder),

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

  String selectedPeriodLabel() {
    if (startDate == null && endDate == null) return 'All time';

    return '${formatDate(startDate)} → ${formatDate(endDate)}';
  }

  Color statusColor(String? status) {
    switch (status) {
      case 'PAID':
        return success;
      case 'PARTIALLY_PAID':
        return warning;
      case 'UNPAID':
      case 'OVERDUE':
        return danger;
      default:
        return Colors.grey;
    }
  }

  IconData statusIcon(String? status) {
    switch (status) {
      case 'PAID':
        return Icons.check_circle;
      case 'PARTIALLY_PAID':
        return Icons.timelapse;
      case 'UNPAID':
        return Icons.warning_amber;
      case 'OVERDUE':
        return Icons.event_busy;
      default:
        return Icons.receipt_long;
    }
  }

  Widget dragHandle() {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget heroHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
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
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 31,
                backgroundColor: Colors.white,
                child: Icon(Icons.bar_chart, color: collectionColor, size: 31),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Financial Command Center',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedPeriodLabel(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Refresh',
                onPressed: refreshing || loading
                    ? null
                    : () => loadReport(silent: true),
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

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                Icon(Icons.health_and_safety, color: collectionColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$collectionLabel • ${collectionRate.toStringAsFixed(1)}% collection rate',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Revenue',
                  value: money(totalRevenue),
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Unpaid',
                  value: money(totalUnpaid),
                  icon: Icons.warning_amber,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Invoiced',
                  value: money(totalInvoiced),
                  icon: Icons.receipt_long,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Payments',
                  value: paymentCount.toString(),
                  icon: Icons.payments,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: (collectionRate / 100).clamp(0, 1).toDouble(),
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget heroMetric({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget quickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: openFiltersSheet,
                    icon: const Icon(Icons.filter_alt),
                    label: const Text('Filters'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: openReportInsights,
                    icon: const Icon(Icons.insights),
                    label: const Text('Insights'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: loading || refreshing
                        ? null
                        : () => loadReport(silent: true),
                    icon: refreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(refreshing ? 'Refreshing...' : 'Refresh'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: exportingPdf || loading ? null : exportPdf,
                    icon: exportingPdf
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf),
                    label: Text(exportingPdf ? 'Exporting...' : 'Export PDF'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget periodChipBar() {
    final chips = [
      ('ALL', 'All time', Icons.all_inclusive),
      ('THIS_MONTH', 'This month', Icons.calendar_month),
      ('LAST_30', 'Last 30d', Icons.history),
      ('THIS_YEAR', 'This year', Icons.event),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final chip = chips[index];

          return ActionChip(
            avatar: Icon(chip.$3, size: 18, color: primary),
            label: Text(chip.$2),
            backgroundColor: Colors.white,
            side: BorderSide(color: Colors.black.withOpacity(0.05)),
            onPressed: loading || refreshing
                ? null
                : () => applyQuickRange(chip.$1),
          );
        },
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
        title: 'Invoiced',
        value: money(totalInvoiced),
        icon: Icons.receipt_long,
        color: primary,
      ),
      _KpiData(
        title: 'Revenue',
        value: money(totalRevenue),
        icon: Icons.payments,
        color: success,
      ),
      _KpiData(
        title: 'Unpaid',
        value: money(totalUnpaid),
        icon: Icons.warning_amber,
        color: danger,
      ),
      _KpiData(
        title: 'Collection',
        value: '${collectionRate.toStringAsFixed(0)}%',
        icon: Icons.pie_chart,
        color: collectionColor,
      ),
      _KpiData(
        title: 'Paid Invoices',
        value: paidInvoiceCount.toString(),
        icon: Icons.check_circle,
        color: success,
      ),
      _KpiData(
        title: 'Unpaid Invoices',
        value: unpaidInvoiceCount.toString(),
        icon: Icons.error,
        color: warning,
      ),
    ];

    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kpis.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          return SizedBox(width: 145, child: compactKpiCard(kpis[index]));
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
        onTap: openReportInsights,
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
    VoidCallback? onViewAll,
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
        if (onViewAll != null)
          TextButton.icon(
            onPressed: onViewAll,
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('View'),
          ),
      ],
    );
  }

  Widget overviewSection() {
    final recentPayments = listValue('recentPayments');
    final topUnpaidTenants = listValue('topUnpaidTenants');
    final outstandingInvoices = listValue('outstandingInvoices');

    return Column(
      children: [
        collectionHealthCard(),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: miniActionCard(
                title: 'Payments',
                value: recentPaymentCount.toString(),
                icon: Icons.payments,
                color: success,
                onTap: () => setState(() => selectedSection = 'PAYMENTS'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: miniActionCard(
                title: 'Unpaid',
                value: topUnpaidTenantCount.toString(),
                icon: Icons.person_search,
                color: danger,
                onTap: () => setState(() => selectedSection = 'UNPAID'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: miniActionCard(
                title: 'Invoices',
                value: outstandingCount.toString(),
                icon: Icons.receipt_long,
                color: warning,
                onTap: () => setState(() => selectedSection = 'INVOICES'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        sectionHeader(
          title: 'Recent Activity',
          subtitle: 'Latest payment and collection signals',
        ),

        const SizedBox(height: 8),

        if (recentPayments.isNotEmpty)
          recentPaymentCard(recentPayments.first)
        else
          emptyCard('No recent payments found'),

        if (topUnpaidTenants.isNotEmpty) ...[
          const SizedBox(height: 10),
          topUnpaidTenantCard(topUnpaidTenants.first, 0),
        ],

        if (outstandingInvoices.isNotEmpty) ...[
          const SizedBox(height: 10),
          outstandingInvoiceCard(outstandingInvoices.first),
        ],
      ],
    );
  }

  Widget collectionHealthCard() {
    return Card(
      color: collectionColor.withOpacity(0.07),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: collectionColor.withOpacity(0.12),
                  child: Icon(Icons.health_and_safety, color: collectionColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    collectionLabel,
                    style: TextStyle(
                      color: collectionColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${collectionRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: collectionColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: (collectionRate / 100).clamp(0, 1).toDouble(),
                minHeight: 8,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(collectionColor),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              totalUnpaid > 0
                  ? 'There is ${money(totalUnpaid)} still unpaid for this report period.'
                  : 'All invoices in this report period are fully collected.',
              style: TextStyle(color: Colors.grey.shade800, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget miniActionCard({
    required String title,
    required String value,
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
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget paymentsSection() {
    final recentPayments = listValue('recentPayments');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(
          title: 'Recent Payments',
          subtitle: 'Latest payments recorded in this period',
          onViewAll: () => openListSheet(
            title: 'Recent Payments',
            items: recentPayments,
            itemBuilder: recentPaymentCard,
            emptyMessage: 'No recent payments found',
          ),
        ),

        const SizedBox(height: 8),

        if (recentPayments.isEmpty)
          emptyCard('No recent payments found')
        else
          ...recentPayments.take(6).map(recentPaymentCard),

        if (recentPayments.length > 6)
          viewMoreButton(
            label: 'View all ${recentPayments.length} payments',
            onTap: () => openListSheet(
              title: 'Recent Payments',
              items: recentPayments,
              itemBuilder: recentPaymentCard,
              emptyMessage: 'No recent payments found',
            ),
          ),
      ],
    );
  }

  Widget unpaidSection() {
    final topUnpaidTenants = listValue('topUnpaidTenants');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(
          title: 'Top Unpaid Tenants',
          subtitle: 'Tenants with the highest outstanding balances',
          onViewAll: () => openListSheet(
            title: 'Top Unpaid Tenants',
            items: topUnpaidTenants,
            itemBuilder: (tenant) {
              final index = topUnpaidTenants.indexOf(tenant);
              return topUnpaidTenantCard(tenant, index);
            },
            emptyMessage: 'No unpaid tenant balances',
          ),
        ),

        const SizedBox(height: 8),

        if (topUnpaidTenants.isEmpty)
          emptyCard('No unpaid tenant balances')
        else
          ...topUnpaidTenants
              .asMap()
              .entries
              .take(6)
              .map((entry) => topUnpaidTenantCard(entry.value, entry.key)),

        if (topUnpaidTenants.length > 6)
          viewMoreButton(
            label: 'View all ${topUnpaidTenants.length} tenants',
            onTap: () => openListSheet(
              title: 'Top Unpaid Tenants',
              items: topUnpaidTenants,
              itemBuilder: (tenant) {
                final index = topUnpaidTenants.indexOf(tenant);
                return topUnpaidTenantCard(tenant, index);
              },
              emptyMessage: 'No unpaid tenant balances',
            ),
          ),
      ],
    );
  }

  Widget invoicesSection() {
    final outstandingInvoices = listValue('outstandingInvoices');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(
          title: 'Outstanding Invoices',
          subtitle: 'Invoices still requiring payment follow-up',
          onViewAll: () => openListSheet(
            title: 'Outstanding Invoices',
            items: outstandingInvoices,
            itemBuilder: outstandingInvoiceCard,
            emptyMessage: 'No outstanding invoices',
          ),
        ),

        const SizedBox(height: 8),

        if (outstandingInvoices.isEmpty)
          emptyCard('No outstanding invoices')
        else
          ...outstandingInvoices.take(6).map(outstandingInvoiceCard),

        if (outstandingInvoices.length > 6)
          viewMoreButton(
            label: 'View all ${outstandingInvoices.length} invoices',
            onTap: () => openListSheet(
              title: 'Outstanding Invoices',
              items: outstandingInvoices,
              itemBuilder: outstandingInvoiceCard,
              emptyMessage: 'No outstanding invoices',
            ),
          ),
      ],
    );
  }

  Widget selectedSectionBody() {
    switch (selectedSection) {
      case 'PAYMENTS':
        return paymentsSection();

      case 'UNPAID':
        return unpaidSection();

      case 'INVOICES':
        return invoicesSection();

      case 'OVERVIEW':
      default:
        return overviewSection();
    }
  }

  Widget recentPaymentCard(dynamic payment) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: success.withOpacity(0.12),
          child: const Icon(Icons.payments, color: success),
        ),
        title: Text(
          '${money(payment['amount'])} • ${payment['method'] ?? '—'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${payment['tenantName'] ?? 'Tenant'}\n'
          '${payment['propertyName'] ?? 'Property'} • ${payment['unitName'] ?? 'Unit'}',
        ),
        isThreeLine: true,
        trailing: Text(
          formatDate(payment['createdAt']),
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget outstandingInvoiceCard(dynamic invoice) {
    final status = invoice['status']?.toString() ?? 'UNPAID';
    final color = statusColor(status);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(statusIcon(status), color: color),
        ),
        title: Text(
          'Remaining: ${money(invoice['remainingAmount'])}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${invoice['tenantName'] ?? 'Tenant'}\n'
          '${invoice['propertyName'] ?? 'Property'} • ${invoice['unitName'] ?? 'Unit'}\n'
          'Due: ${formatDate(invoice['dueDate'])}',
        ),
        isThreeLine: true,
        trailing: Text(
          status,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget topUnpaidTenantCard(dynamic tenant, int index) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: danger.withOpacity(0.12),
          child: Text(
            '${index + 1}',
            style: const TextStyle(color: danger, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          tenant['tenantName']?.toString() ?? 'Tenant',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${tenant['tenantEmail'] ?? '—'}\n'
          'Invoices: ${tenant['invoices'] ?? 0}',
        ),
        isThreeLine: true,
        trailing: Text(
          money(tenant['unpaid']),
          style: const TextStyle(color: danger, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget emptyCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: primary.withOpacity(0.10),
              child: const Icon(Icons.info_outline, color: primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
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

  Widget invalidPeriodCard() {
    if (!invalidPeriod) return const SizedBox.shrink();

    return Card(
      color: danger.withOpacity(0.08),
      child: const ListTile(
        leading: Icon(Icons.error_outline, color: danger),
        title: Text(
          'Invalid report period',
          style: TextStyle(color: danger, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'End date must be after start date.',
          style: TextStyle(color: danger),
        ),
      ),
    );
  }

  Widget bodyContent() {
    return RefreshIndicator(
      onRefresh: () => loadReport(silent: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          heroHeader(),

          const SizedBox(height: 16),

          quickActions(),

          const SizedBox(height: 14),

          periodChipBar(),

          const SizedBox(height: 14),

          invalidPeriodCard(),

          if (invalidPeriod) const SizedBox(height: 14),

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
      onRefresh: () => loadReport(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 130),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: danger, size: 42),
                  const SizedBox(height: 12),
                  const Text(
                    'Could not load financial report',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: danger),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () => loadReport(),
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
      onRefresh: () => loadReport(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 120),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Icon(Icons.bar_chart, size: 60, color: Colors.grey.shade500),
                  const SizedBox(height: 12),
                  const Text(
                    'No report data available',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try changing the report period or refreshing the page.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => loadReport(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Report'),
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
          'Financial Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Filters',
            icon: const Icon(Icons.filter_alt),
            onPressed: loading ? null : openFiltersSheet,
          ),
          IconButton(
            tooltip: 'Insights',
            icon: const Icon(Icons.insights),
            onPressed: report == null ? null : openReportInsights,
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
            onPressed: loading || refreshing
                ? null
                : () => loadReport(silent: true),
          ),
        ],
      ),
      body: loading
          ? loadingBody()
          : error.isNotEmpty
          ? errorBody()
          : report == null
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

  const _KpiData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _ReportFilterSheet extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final String Function(dynamic value) formatDate;
  final Future<void> Function() onPickStart;
  final Future<void> Function() onPickEnd;
  final Future<void> Function() onClear;
  final Future<void> Function(String range) onQuickRange;

  const _ReportFilterSheet({
    required this.startDate,
    required this.endDate,
    required this.formatDate,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onClear,
    required this.onQuickRange,
  });

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  @override
  Widget build(BuildContext context) {
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
              _dragHandle(),

              const SizedBox(height: 20),

              const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFFEDE9FE),
                child: Icon(Icons.filter_alt, color: primary, size: 34),
              ),

              const SizedBox(height: 14),

              const Text(
                'Report Filters',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              Text(
                'Choose a custom period or use a quick range.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await onPickStart();
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        startDate == null
                            ? 'Start date'
                            : formatDate(startDate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await onPickEnd();
                      },
                      icon: const Icon(Icons.event),
                      label: Text(
                        endDate == null ? 'End date' : formatDate(endDate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  quickChip(context, 'ALL', 'All time', Icons.all_inclusive),
                  quickChip(
                    context,
                    'THIS_MONTH',
                    'This month',
                    Icons.calendar_month,
                  ),
                  quickChip(context, 'LAST_30', 'Last 30 days', Icons.history),
                  quickChip(context, 'THIS_YEAR', 'This year', Icons.event),
                ],
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await onClear();
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget quickChip(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: primary),
      label: Text(label),
      backgroundColor: Colors.white,
      onPressed: () async {
        Navigator.pop(context);
        await onQuickRange(value);
      },
    );
  }
}

class _FinancialInsightsSheet extends StatelessWidget {
  final String periodLabel;
  final num totalInvoiced;
  final num totalRevenue;
  final num totalUnpaid;
  final num collectionRate;
  final int paymentCount;
  final int paidInvoiceCount;
  final int unpaidInvoiceCount;
  final int outstandingCount;
  final int topUnpaidTenantCount;
  final String collectionLabel;
  final Color collectionColor;
  final String Function(dynamic value) money;

  const _FinancialInsightsSheet({
    required this.periodLabel,
    required this.totalInvoiced,
    required this.totalRevenue,
    required this.totalUnpaid,
    required this.collectionRate,
    required this.paymentCount,
    required this.paidInvoiceCount,
    required this.unpaidInvoiceCount,
    required this.outstandingCount,
    required this.topUnpaidTenantCount,
    required this.collectionLabel,
    required this.collectionColor,
    required this.money,
  });

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.84,
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
                _dragHandle(),

                const SizedBox(height: 20),

                CircleAvatar(
                  radius: 38,
                  backgroundColor: collectionColor.withOpacity(0.12),
                  child: Icon(Icons.insights, color: collectionColor, size: 38),
                ),

                const SizedBox(height: 14),

                const Text(
                  'Financial Intelligence',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                Text(
                  periodLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),

                const SizedBox(height: 16),

                Chip(
                  avatar: Icon(
                    Icons.health_and_safety,
                    color: collectionColor,
                    size: 18,
                  ),
                  label: Text(collectionLabel),
                  backgroundColor: collectionColor.withOpacity(0.12),
                  labelStyle: TextStyle(
                    color: collectionColor,
                    fontWeight: FontWeight.bold,
                  ),
                  side: BorderSide.none,
                ),

                const SizedBox(height: 18),

                scoreCard(
                  title: 'Collection Rate',
                  value: collectionRate,
                  icon: Icons.pie_chart,
                  color: collectionColor,
                ),

                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        infoRow('Total Invoiced', money(totalInvoiced)),
                        infoRow('Total Revenue', money(totalRevenue)),
                        infoRow('Total Unpaid', money(totalUnpaid)),
                        infoRow('Payments', paymentCount),
                        infoRow('Paid Invoices', paidInvoiceCount),
                        infoRow('Unpaid Invoices', unpaidInvoiceCount),
                        infoRow('Outstanding Items', outstandingCount),
                        infoRow('Unpaid Tenants', topUnpaidTenantCount),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  color: primary.withOpacity(0.07),
                  child: ListTile(
                    leading: const Icon(
                      Icons.lightbulb_outline,
                      color: primary,
                    ),
                    title: const Text(
                      'Operational note',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      totalUnpaid > 0
                          ? 'Follow up on unpaid invoices and top unpaid tenants to improve collection health.'
                          : 'Collection health is strong for this period. Keep monitoring upcoming due dates.',
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
            width: 132,
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
}

Widget _dragHandle() {
  return Center(
    child: Container(
      width: 42,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );
}
