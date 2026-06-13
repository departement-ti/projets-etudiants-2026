import 'package:flutter/material.dart';

import '../../core/ui/app_error.dart';
import 'invoice_details.dart';
import 'invoice_service.dart';

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key});

  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  List<dynamic> invoices = [];

  bool loading = true;
  bool refreshing = false;
  String error = '';

  String selectedStatus = 'ALL';
  String sortMode = 'Newest';
  String viewMode = 'CARDS';

  final searchCtrl = TextEditingController();

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);
  static const darkText = Color(0xFF1D1B20);

  final statuses = const ['ALL', 'OVERDUE', 'UNPAID', 'PARTIALLY_PAID', 'PAID'];

  @override
  void initState() {
    super.initState();
    searchCtrl.addListener(() => setState(() {}));
    loadInvoices();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> loadInvoices({bool silent = false}) async {
    if (silent) {
      setState(() => refreshing = true);
    } else {
      setState(() {
        loading = true;
        error = '';
      });
    }

    try {
      final data = await InvoiceService.getInvoices();

      if (!mounted) return;

      setState(() {
        invoices = data;
        loading = false;
        refreshing = false;
        error = '';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = AppError.clean(e);
        loading = false;
        refreshing = false;
      });
    }
  }

  Future<void> openInvoice(dynamic invoice) async {
    final id = invoice['id']?.toString();

    if (id == null || id.isEmpty) return;

    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvoiceDetailsPage(invoiceId: id)),
    );

    if (changed == true) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invoice updated')));
    }

    await loadInvoices(silent: true);
  }

  Future<void> openInvoicePreview(dynamic invoice) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InvoicePreviewSheet(
        invoice: invoice,
        tenantName: tenantName(invoice),
        tenantEmail: tenantEmail(invoice),
        propertyName: propertyName(invoice),
        unitName: unitName(invoice),
        amount: amount(invoice),
        remaining: remaining(invoice),
        paid: paidAmount(invoice),
        status: invoiceStatus(invoice),
        overdue: isOverdue(invoice),
        daysOverdue: daysOverdue(invoice),
        dueLabel: dueDateLabel(invoice),
        formatDate: formatDate,
        onOpenDetails: () async {
          Navigator.pop(context);
          await openInvoice(invoice);
        },
      ),
    );
  }

  Future<void> openInvoicesInsight() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InvoicesInsightSheet(
        totalInvoices: invoices.length,
        paidCount: paidCount,
        unpaidCount: unpaidCount,
        partialCount: partialCount,
        overdueCount: overdueCount,
        totalBilled: totalBilled,
        totalPaid: totalPaid,
        totalRemaining: totalRemaining,
        collectionRate: collectionRate,
        overdueAmount: overdueAmount,
        averageInvoice: averageInvoice,
      ),
    );
  }

  List<dynamic> get filteredInvoices {
    final query = searchCtrl.text.trim().toLowerCase();

    final filtered = invoices.where((invoice) {
      final status = invoiceStatus(invoice);

      final searchable = [
        tenantName(invoice),
        tenantEmail(invoice),
        propertyName(invoice),
        unitName(invoice),
        amount(invoice).toString(),
        remaining(invoice).toString(),
        paidAmount(invoice).toString(),
        status,
        isOverdue(invoice) ? 'overdue late unpaid' : 'on time',
      ].join(' ').toLowerCase();

      final matchesSearch = query.isEmpty || searchable.contains(query);

      final matchesStatus = selectedStatus == 'ALL'
          ? true
          : selectedStatus == 'OVERDUE'
          ? isOverdue(invoice)
          : status == selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();

    filtered.sort((a, b) {
      switch (sortMode) {
        case 'Amount High':
          return amount(b).compareTo(amount(a));

        case 'Amount Low':
          return amount(a).compareTo(amount(b));

        case 'Remaining High':
          return remaining(b).compareTo(remaining(a));

        case 'Remaining Low':
          return remaining(a).compareTo(remaining(b));

        case 'Tenant':
          return tenantName(a).compareTo(tenantName(b));

        case 'Property':
          return propertyName(a).compareTo(propertyName(b));

        case 'Status':
          return invoiceStatus(a).compareTo(invoiceStatus(b));

        case 'Due Date':
          return parseDate(a['dueDate']).compareTo(parseDate(b['dueDate']));

        case 'Overdue First':
          final aOverdue = isOverdue(a);
          final bOverdue = isOverdue(b);

          if (aOverdue && !bOverdue) return -1;
          if (!aOverdue && bOverdue) return 1;

          return parseDate(a['dueDate']).compareTo(parseDate(b['dueDate']));

        case 'Oldest':
          return parseDate(a['createdAt']).compareTo(parseDate(b['createdAt']));

        case 'Newest':
        default:
          return parseDate(b['createdAt']).compareTo(parseDate(a['createdAt']));
      }
    });

    return filtered;
  }

  void resetFilters() {
    setState(() {
      searchCtrl.clear();
      selectedStatus = 'ALL';
      sortMode = 'Newest';
    });
  }

  DateTime parseDate(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);

    return DateTime.tryParse(value.toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String formatDate(dynamic value) {
    if (value == null) return '—';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    return parsed.toLocal().toString().split(' ')[0];
  }

  String tenantName(dynamic invoice) {
    final user =
        invoice['tenant']?['user'] ?? invoice['lease']?['tenant']?['user'];

    if (user != null) {
      final firstName = user['firstName']?.toString() ?? '';
      final lastName = user['lastName']?.toString() ?? '';
      final email = user['email']?.toString() ?? '';

      final fullName = '$firstName $lastName'.trim();

      if (fullName.isNotEmpty) return fullName;
      if (email.isNotEmpty) return email;
    }

    return 'Tenant';
  }

  String tenantEmail(dynamic invoice) {
    final user =
        invoice['tenant']?['user'] ?? invoice['lease']?['tenant']?['user'];

    return user?['email']?.toString() ?? '—';
  }

  String unitName(dynamic invoice) {
    final unit = invoice['unit'] ?? invoice['lease']?['unit'];

    if (unit != null) {
      return unit['title']?.toString() ?? unit['number']?.toString() ?? 'Unit';
    }

    return 'Unit';
  }

  String propertyName(dynamic invoice) {
    final property =
        invoice['property'] ??
        invoice['unit']?['property'] ??
        invoice['lease']?['unit']?['property'];

    if (property != null) {
      return property['title']?.toString() ??
          property['name']?.toString() ??
          property['address']?.toString() ??
          'Property';
    }

    return 'Property';
  }

  String invoiceStatus(dynamic invoice) {
    return invoice['status']?.toString() ?? 'UNPAID';
  }

  num amount(dynamic invoice) {
    final value = invoice['amount'];

    if (value is num) return value;

    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  num remaining(dynamic invoice) {
    final direct = invoice['remainingAmount'];

    if (direct is num) return direct;

    final parsed = num.tryParse(direct?.toString() ?? '');
    if (parsed != null) return parsed;

    final status = invoiceStatus(invoice);
    if (status == 'PAID') return 0;

    return amount(invoice);
  }

  num paidAmount(dynamic invoice) {
    final direct = invoice['totalPaid'];

    if (direct is num) return direct;

    final parsed = num.tryParse(direct?.toString() ?? '');
    if (parsed != null) return parsed;

    final payments = invoice['payments'];

    if (payments is List) {
      return payments.fold<num>(0, (sum, payment) {
        final value = payment['amount'];

        if (value is num) return sum + value;

        return sum + (num.tryParse(value?.toString() ?? '') ?? 0);
      });
    }

    return (amount(invoice) - remaining(invoice)).clamp(0, amount(invoice));
  }

  bool isOverdue(dynamic invoice) {
    if (invoice['isOverdue'] == true) return true;

    final status = invoiceStatus(invoice);
    if (status == 'PAID') return false;

    final due = DateTime.tryParse(invoice['dueDate']?.toString() ?? '');
    if (due == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);

    return dueDay.isBefore(today);
  }

  int daysUntilDue(dynamic invoice) {
    final due = DateTime.tryParse(invoice['dueDate']?.toString() ?? '');

    if (due == null) return 999999;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);

    return dueDay.difference(today).inDays;
  }

  int daysOverdue(dynamic invoice) {
    final days = daysUntilDue(invoice);

    if (days >= 0) return 0;

    return days.abs();
  }

  String dueDateLabel(dynamic invoice) {
    final status = invoiceStatus(invoice);

    if (status == 'PAID') return 'Paid';

    final days = daysUntilDue(invoice);

    if (days == 999999) return 'No due date';
    if (days < 0)
      return 'Overdue by ${days.abs()} day${days.abs() == 1 ? '' : 's'}';
    if (days == 0) return 'Due today';

    return 'Due in $days day${days == 1 ? '' : 's'}';
  }

  double invoiceProgress(dynamic invoice) {
    final total = amount(invoice);

    if (total <= 0) return 0;

    final paid = paidAmount(invoice);

    return (paid / total).clamp(0, 1).toDouble();
  }

  int statusCount(String status) {
    return invoices.where((invoice) => invoiceStatus(invoice) == status).length;
  }

  int get paidCount => statusCount('PAID');
  int get partialCount => statusCount('PARTIALLY_PAID');
  int get unpaidCount => statusCount('UNPAID');

  int get overdueCount {
    return invoices.where(isOverdue).length;
  }

  num get totalBilled {
    return invoices.fold<num>(0, (sum, invoice) => sum + amount(invoice));
  }

  num get totalRemaining {
    return invoices.fold<num>(0, (sum, invoice) => sum + remaining(invoice));
  }

  num get totalPaid {
    return invoices.fold<num>(0, (sum, invoice) => sum + paidAmount(invoice));
  }

  num get overdueAmount {
    return invoices.fold<num>(0, (sum, invoice) {
      if (!isOverdue(invoice)) return sum;

      return sum + remaining(invoice);
    });
  }

  num get averageInvoice {
    if (invoices.isEmpty) return 0;

    return totalBilled / invoices.length;
  }

  double get collectionRate {
    if (totalBilled <= 0) return 0;

    return ((totalPaid / totalBilled) * 100).clamp(0, 100).toDouble();
  }

  double get unpaidRate {
    if (totalBilled <= 0) return 0;

    return ((totalRemaining / totalBilled) * 100).clamp(0, 100).toDouble();
  }

  Color statusColor(String? status) {
    switch (status) {
      case 'PAID':
        return Colors.green;
      case 'PARTIALLY_PAID':
        return Colors.orange;
      case 'UNPAID':
        return Colors.red;
      case 'OVERDUE':
        return Colors.red;
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

  String statusDescription(String status) {
    switch (status) {
      case 'PAID':
        return 'Fully paid';
      case 'PARTIALLY_PAID':
        return 'Partially collected';
      case 'UNPAID':
        return 'Waiting payment';
      case 'OVERDUE':
        return 'Past due date';
      default:
        return 'All invoices';
    }
  }

  String initials(dynamic invoice) {
    final clean = tenantName(invoice).trim();

    if (clean.isEmpty) return 'I';

    final parts = clean
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return clean[0].toUpperCase();
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 29,
                backgroundColor: Colors.white,
                child: Icon(Icons.receipt_long, color: primary, size: 31),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice Command Center',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Track rent invoices, unpaid balances and overdue risks.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: refreshing ? null : () => loadInvoices(silent: true),
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

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Billed',
                  value: totalBilled.toStringAsFixed(2),
                  icon: Icons.receipt_long,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Collected',
                  value: totalPaid.toStringAsFixed(2),
                  icon: Icons.payments,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Remaining',
                  value: totalRemaining.toStringAsFixed(2),
                  icon: Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Overdue',
                  value: overdueCount.toString(),
                  icon: Icons.event_busy,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Collection',
                  value: '${collectionRate.round()}%',
                  icon: Icons.pie_chart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Invoices',
                  value: invoices.length.toString(),
                  icon: Icons.folder_copy,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              const Icon(Icons.timeline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  overdueCount > 0
                      ? '$overdueCount overdue invoice${overdueCount == 1 ? '' : 's'} need follow-up.'
                      : 'No overdue invoices. Collection health looks good.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: (collectionRate / 100).clamp(0, 1),
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
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
                    onPressed: openInvoicesInsight,
                    icon: const Icon(Icons.insights),
                    label: const Text('Insights'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: refreshing
                        ? null
                        : () => loadInvoices(silent: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget summaryStrip() {
    return Row(
      children: [
        Expanded(
          child: miniSummaryCard(
            title: 'Paid',
            value: paidCount.toString(),
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: miniSummaryCard(
            title: 'Partial',
            value: partialCount.toString(),
            icon: Icons.timelapse,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: miniSummaryCard(
            title: 'Unpaid',
            value: unpaidCount.toString(),
            icon: Icons.warning_amber,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget miniSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: darkText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget searchAndFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                labelText: 'Search invoices',
                hintText: 'Tenant, email, property, unit, amount or status',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchCtrl.text.trim().isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => searchCtrl.clear(),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: statuses.map(statusFilterChip).toList()),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: sortMode,
                    decoration: const InputDecoration(
                      labelText: 'Sort',
                      prefixIcon: Icon(Icons.sort),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Newest', child: Text('Newest')),
                      DropdownMenuItem(value: 'Oldest', child: Text('Oldest')),
                      DropdownMenuItem(
                        value: 'Overdue First',
                        child: Text('Overdue First'),
                      ),
                      DropdownMenuItem(
                        value: 'Due Date',
                        child: Text('Due Date'),
                      ),
                      DropdownMenuItem(
                        value: 'Amount High',
                        child: Text('Amount High'),
                      ),
                      DropdownMenuItem(
                        value: 'Amount Low',
                        child: Text('Amount Low'),
                      ),
                      DropdownMenuItem(
                        value: 'Remaining High',
                        child: Text('Remaining High'),
                      ),
                      DropdownMenuItem(
                        value: 'Remaining Low',
                        child: Text('Remaining Low'),
                      ),
                      DropdownMenuItem(value: 'Tenant', child: Text('Tenant')),
                      DropdownMenuItem(
                        value: 'Property',
                        child: Text('Property'),
                      ),
                      DropdownMenuItem(value: 'Status', child: Text('Status')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => sortMode = value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: resetFilters,
                  icon: const Icon(Icons.restart_alt),
                  tooltip: 'Reset filters',
                ),
              ],
            ),

            const SizedBox(height: 14),

            viewModeSwitch(),
          ],
        ),
      ),
    );
  }

  Widget statusFilterChip(String status) {
    final active = selectedStatus == status;
    final color = status == 'ALL' ? primary : statusColor(status);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: active,
        label: Text(status),
        avatar: Icon(
          status == 'ALL' ? Icons.all_inclusive : statusIcon(status),
          size: 18,
          color: active ? Colors.white : color,
        ),
        selectedColor: color,
        backgroundColor: color.withOpacity(0.10),
        labelStyle: TextStyle(
          color: active ? Colors.white : color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        side: BorderSide.none,
        onSelected: (_) {
          setState(() => selectedStatus = status);
        },
      ),
    );
  }

  Widget viewModeSwitch() {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            selected: viewMode == 'CARDS',
            label: const Text('Cards'),
            avatar: Icon(
              Icons.dashboard_customize,
              color: viewMode == 'CARDS' ? Colors.white : primary,
              size: 18,
            ),
            selectedColor: primary,
            backgroundColor: primary.withOpacity(0.08),
            labelStyle: TextStyle(
              color: viewMode == 'CARDS' ? Colors.white : primary,
              fontWeight: FontWeight.bold,
            ),
            side: BorderSide.none,
            onSelected: (_) => setState(() => viewMode = 'CARDS'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceChip(
            selected: viewMode == 'COMPACT',
            label: const Text('Compact'),
            avatar: Icon(
              Icons.view_list,
              color: viewMode == 'COMPACT' ? Colors.white : primary,
              size: 18,
            ),
            selectedColor: primary,
            backgroundColor: primary.withOpacity(0.08),
            labelStyle: TextStyle(
              color: viewMode == 'COMPACT' ? Colors.white : primary,
              fontWeight: FontWeight.bold,
            ),
            side: BorderSide.none,
            onSelected: (_) => setState(() => viewMode = 'COMPACT'),
          ),
        ),
      ],
    );
  }

  Widget invoiceStatusChip(dynamic invoice) {
    final overdue = isOverdue(invoice);
    final status = overdue ? 'OVERDUE' : invoiceStatus(invoice);
    final color = statusColor(status);

    return Chip(
      avatar: Icon(statusIcon(status), color: color, size: 17),
      label: Text(status),
      backgroundColor: color.withOpacity(0.12),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
      side: BorderSide.none,
    );
  }

  Widget dueBadge(dynamic invoice) {
    final overdue = isOverdue(invoice);
    final status = invoiceStatus(invoice);
    final color = status == 'PAID'
        ? Colors.green
        : overdue
        ? Colors.red
        : daysUntilDue(invoice) <= 3
        ? Colors.orange
        : primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            status == 'PAID'
                ? Icons.check_circle
                : overdue
                ? Icons.event_busy
                : Icons.event,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${dueDateLabel(invoice)} • Remaining ${remaining(invoice).toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget invoiceCard(dynamic invoice) {
    final status = invoiceStatus(invoice);
    final overdue = isOverdue(invoice);
    final color = overdue ? Colors.red : statusColor(status);
    final progress = invoiceProgress(invoice);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => openInvoicePreview(invoice),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: color.withOpacity(0.12),
                    child: Text(
                      initials(invoice),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tenantName(invoice),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: darkText,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${propertyName(invoice)} • ${unitName(invoice)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Due: ${formatDate(invoice['dueDate'])}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'preview') openInvoicePreview(invoice);
                      if (value == 'details') openInvoice(invoice);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'preview',
                        child: Row(
                          children: [
                            Icon(Icons.visibility),
                            SizedBox(width: 10),
                            Text('Quick preview'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.open_in_new),
                            SizedBox(width: 10),
                            Text('Open details'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              dueBadge(invoice),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: softBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, size: 18, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Amount ${amount(invoice).toStringAsFixed(2)} • Paid ${paidAmount(invoice).toStringAsFixed(2)} • Remaining ${remaining(invoice).toStringAsFixed(2)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.withOpacity(0.16),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  invoiceStatusChip(invoice),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => openInvoice(invoice),
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget compactInvoiceTile(dynamic invoice) {
    final status = invoiceStatus(invoice);
    final overdue = isOverdue(invoice);
    final color = overdue ? Colors.red : statusColor(status);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Text(
            initials(invoice),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          tenantName(invoice),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${propertyName(invoice)} • ${unitName(invoice)}\n'
          '${remaining(invoice).toStringAsFixed(2)} remaining • ${dueDateLabel(invoice)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: invoiceStatusChip(invoice),
        onTap: () => openInvoicePreview(invoice),
      ),
    );
  }

  Widget emptyState() {
    final hasFilters =
        searchCtrl.text.trim().isNotEmpty || selectedStatus != 'ALL';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(Icons.receipt_long, size: 62, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            const Text(
              'No invoices found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters
                  ? 'Try changing the search text or invoice status filter.'
                  : 'Invoices are generated from leases. Create a lease to generate rent invoices.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: resetFilters,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset Filters'),
              ),
            ],
          ],
        ),
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
      onRefresh: () => loadInvoices(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 120),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 42),
                  const SizedBox(height: 12),
                  const Text(
                    'Could not load invoices',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () => loadInvoices(),
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

  Widget contentBody() {
    final data = filteredInvoices;

    return RefreshIndicator(
      onRefresh: () => loadInvoices(silent: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          heroHeader(),

          const SizedBox(height: 18),

          quickActions(),

          const SizedBox(height: 14),

          summaryStrip(),

          const SizedBox(height: 14),

          searchAndFilters(),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Text(
                  '${data.length} result${data.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (refreshing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),

          const SizedBox(height: 10),

          if (data.isEmpty)
            emptyState()
          else if (viewMode == 'COMPACT')
            ...data.map(compactInvoiceTile)
          else
            ...data.map(invoiceCard),

          const SizedBox(height: 80),
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
          'Invoices',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: refreshing
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: refreshing ? null : () => loadInvoices(silent: true),
          ),
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: invoices.isEmpty ? null : openInvoicesInsight,
          ),
        ],
      ),
      body: loading
          ? loadingBody()
          : error.isNotEmpty
          ? errorBody()
          : contentBody(),
    );
  }
}

class _InvoicePreviewSheet extends StatelessWidget {
  final dynamic invoice;
  final String tenantName;
  final String tenantEmail;
  final String propertyName;
  final String unitName;
  final num amount;
  final num remaining;
  final num paid;
  final String status;
  final bool overdue;
  final int daysOverdue;
  final String dueLabel;
  final String Function(dynamic value) formatDate;
  final Future<void> Function() onOpenDetails;

  const _InvoicePreviewSheet({
    required this.invoice,
    required this.tenantName,
    required this.tenantEmail,
    required this.propertyName,
    required this.unitName,
    required this.amount,
    required this.remaining,
    required this.paid,
    required this.status,
    required this.overdue,
    required this.daysOverdue,
    required this.dueLabel,
    required this.formatDate,
    required this.onOpenDetails,
  });

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  double get progress {
    if (amount <= 0) return 0;

    return (paid / amount).clamp(0, 1).toDouble();
  }

  Color statusColor(String? value) {
    if (overdue && status != 'PAID') return Colors.red;

    switch (value) {
      case 'PAID':
        return Colors.green;
      case 'PARTIALLY_PAID':
        return Colors.orange;
      case 'UNPAID':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData statusIcon(String? value) {
    if (overdue && status != 'PAID') return Icons.event_busy;

    switch (value) {
      case 'PAID':
        return Icons.check_circle;
      case 'PARTIALLY_PAID':
        return Icons.timelapse;
      case 'UNPAID':
        return Icons.warning_amber;
      default:
        return Icons.receipt_long;
    }
  }

  String initials() {
    final clean = tenantName.trim();

    if (clean.isEmpty) return 'I';

    final parts = clean
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return clean[0].toUpperCase();
  }

  Widget infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
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

  Widget metric({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget metricsGrid() {
    final color = statusColor(status);

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.25,
      children: [
        metric(
          title: 'Amount',
          value: amount.toStringAsFixed(2),
          icon: Icons.receipt_long,
          color: primary,
        ),
        metric(
          title: 'Paid',
          value: paid.toStringAsFixed(2),
          icon: Icons.payments,
          color: Colors.green,
        ),
        metric(
          title: 'Remaining',
          value: remaining.toStringAsFixed(2),
          icon: Icons.warning_amber,
          color: remaining > 0 ? Colors.red : Colors.green,
        ),
        metric(
          title: 'Progress',
          value: '${(progress * 100).round()}%',
          icon: Icons.timeline,
          color: color,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    final visibleStatus = overdue && status != 'PAID' ? 'OVERDUE' : status;

    return DraggableScrollableSheet(
      initialChildSize: 0.86,
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
                  radius: 40,
                  backgroundColor: color.withOpacity(0.12),
                  child: Text(
                    initials(),
                    style: TextStyle(
                      color: color,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  tenantName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '$propertyName • $unitName',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),

                const SizedBox(height: 14),

                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: Icon(statusIcon(status), color: color, size: 18),
                      label: Text(visibleStatus),
                      backgroundColor: color.withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide.none,
                    ),
                    Chip(
                      avatar: Icon(
                        overdue ? Icons.event_busy : Icons.event,
                        color: color,
                        size: 18,
                      ),
                      label: Text(dueLabel),
                      backgroundColor: color.withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide.none,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                metricsGrid(),

                const SizedBox(height: 14),

                Card(
                  color: color.withOpacity(0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: color.withOpacity(0.12),
                          child: Icon(statusIcon(status), color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            overdue && status != 'PAID'
                                ? 'This invoice is overdue by $daysOverdue day${daysOverdue == 1 ? '' : 's'} and needs follow-up.'
                                : status == 'PAID'
                                ? 'This invoice has been fully paid.'
                                : 'This invoice still has an outstanding balance.',
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        infoRow('Tenant', tenantName),
                        infoRow('Email', tenantEmail),
                        infoRow('Property', propertyName),
                        infoRow('Unit', unitName),
                        infoRow('Due Date', formatDate(invoice['dueDate'])),
                        infoRow('Created', formatDate(invoice['createdAt'])),
                        infoRow('Status', visibleStatus),
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
                          'Payment Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 9,
                            backgroundColor: Colors.grey.withOpacity(0.16),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(progress * 100).round()}% collected.',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onOpenDetails,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Invoice Details'),
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

class _InvoicesInsightSheet extends StatelessWidget {
  final int totalInvoices;
  final int paidCount;
  final int unpaidCount;
  final int partialCount;
  final int overdueCount;
  final num totalBilled;
  final num totalPaid;
  final num totalRemaining;
  final double collectionRate;
  final num overdueAmount;
  final num averageInvoice;

  const _InvoicesInsightSheet({
    required this.totalInvoices,
    required this.paidCount,
    required this.unpaidCount,
    required this.partialCount,
    required this.overdueCount,
    required this.totalBilled,
    required this.totalPaid,
    required this.totalRemaining,
    required this.collectionRate,
    required this.overdueAmount,
    required this.averageInvoice,
  });

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  Color healthColor() {
    if (overdueCount > 0) return Colors.orange;
    if (collectionRate >= 85) return Colors.green;
    if (collectionRate >= 55) return primary;

    return Colors.red;
  }

  String healthLabel() {
    if (totalInvoices == 0) return 'No invoices yet';
    if (overdueCount > 0) return 'Needs follow-up';
    if (collectionRate >= 85) return 'Strong collection';
    if (collectionRate >= 55) return 'Moderate collection';

    return 'Weak collection';
  }

  Widget scoreCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
  }) {
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
                  '${value.round()}%',
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
                value: (value / 100).clamp(0, 1),
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
            width: 128,
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

  Widget statusRow({
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
    final color = healthColor();

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
                  radius: 36,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(Icons.insights, color: color, size: 36),
                ),

                const SizedBox(height: 14),

                const Text(
                  'Invoice Intelligence',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                Text(
                  'Collection health and unpaid balance overview',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),

                const SizedBox(height: 16),

                Chip(
                  avatar: Icon(Icons.health_and_safety, color: color, size: 18),
                  label: Text(healthLabel()),
                  backgroundColor: color.withOpacity(0.12),
                  labelStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  side: BorderSide.none,
                ),

                const SizedBox(height: 18),

                scoreCard(
                  title: 'Collection Rate',
                  value: collectionRate,
                  icon: Icons.pie_chart,
                  color: color,
                ),

                const SizedBox(height: 10),

                scoreCard(
                  title: 'Unpaid Exposure',
                  value: totalBilled <= 0
                      ? 0
                      : ((totalRemaining / totalBilled) * 100)
                            .clamp(0, 100)
                            .toDouble(),
                  icon: Icons.warning_amber,
                  color: totalRemaining > 0 ? Colors.orange : Colors.green,
                ),

                const SizedBox(height: 14),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        infoRow('Total Invoices', totalInvoices),
                        infoRow('Total Billed', totalBilled.toStringAsFixed(2)),
                        infoRow('Collected', totalPaid.toStringAsFixed(2)),
                        infoRow('Remaining', totalRemaining.toStringAsFixed(2)),
                        infoRow(
                          'Overdue Amount',
                          overdueAmount.toStringAsFixed(2),
                        ),
                        infoRow(
                          'Average Invoice',
                          averageInvoice.toStringAsFixed(2),
                        ),
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
                          'Status Breakdown',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        statusRow(
                          title: 'Paid',
                          value: paidCount,
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                        statusRow(
                          title: 'Partially Paid',
                          value: partialCount,
                          icon: Icons.timelapse,
                          color: Colors.orange,
                        ),
                        statusRow(
                          title: 'Unpaid',
                          value: unpaidCount,
                          icon: Icons.warning_amber,
                          color: Colors.red,
                        ),
                        statusRow(
                          title: 'Overdue',
                          value: overdueCount,
                          icon: Icons.event_busy,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  color: primary.withOpacity(0.07),
                  child: const ListTile(
                    leading: Icon(Icons.lightbulb_outline, color: primary),
                    title: Text(
                      'Operational note',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Strong invoice health means high collection rate, low overdue exposure, and fast follow-up on unpaid balances.',
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
