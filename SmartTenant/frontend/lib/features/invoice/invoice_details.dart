import 'package:flutter/material.dart';

import '../../core/auth/auth_storage.dart';
import '../../core/ui/app_error.dart';
import '../payments/payment_service.dart';
import 'invoice_service.dart';

class InvoiceDetailsPage extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailsPage({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailsPage> createState() => _InvoiceDetailsPageState();
}

class _InvoiceDetailsPageState extends State<InvoiceDetailsPage> {
  Map<String, dynamic>? invoice;
  List<dynamic> payments = [];

  bool loading = true;
  bool refreshing = false;

  String error = '';
  String? role;

  String selectedSection = 'OVERVIEW';
  String paymentSortMode = 'Newest';

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);
  static const darkText = Color(0xFF1D1B20);

  bool get canRecordPayment {
    return role == 'ADMIN' || role == 'OWNER' || role == 'TENANT';
  }

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
      final userRole = await AuthStorage.getUserRole();
      final invoiceData = await InvoiceService.getInvoice(widget.invoiceId);
      final paymentsData = await PaymentService.getPayments(widget.invoiceId);

      if (!mounted) return;

      setState(() {
        role = userRole;
        invoice = invoiceData;
        payments = paymentsData;
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

  String formatDateTime(dynamic value) {
    if (value == null) return '—';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    return parsed.toLocal().toString().split('.')[0];
  }

  num money(dynamic value) {
    if (value is num) return value;

    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  num invoiceAmount() {
    return money(invoice?['amount']);
  }

  num paymentAmount(dynamic payment) {
    return money(payment['amount']);
  }

  num get totalPaid {
    final serverPaid = invoice?['totalPaid'];
    if (serverPaid is num) return serverPaid;

    return payments.fold<num>(0, (sum, payment) {
      return sum + paymentAmount(payment);
    });
  }

  num get remaining {
    final serverRemaining = invoice?['remainingAmount'];

    if (serverRemaining is num) return serverRemaining;

    final calculated = invoiceAmount() - totalPaid;

    return calculated < 0 ? 0 : calculated;
  }

  double get paidRatio {
    final total = invoiceAmount();

    if (total <= 0) return 0;

    return (totalPaid / total).clamp(0, 1).toDouble();
  }

  int get paidPercent {
    return (paidRatio * 100).round();
  }

  bool get isPaid {
    final status = invoice?['status']?.toString();

    return status == 'PAID' || remaining <= 0;
  }

  bool get isPartiallyPaid {
    final status = invoice?['status']?.toString();

    return status == 'PARTIALLY_PAID' || (totalPaid > 0 && remaining > 0);
  }

  bool get isOverdue {
    if (isPaid || remaining <= 0) return false;

    if (invoice?['isOverdue'] == true) return true;

    final due = DateTime.tryParse(invoice?['dueDate']?.toString() ?? '');
    if (due == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);

    return dueDay.isBefore(today);
  }

  int get overdueDays {
    if (!isOverdue) return 0;

    final due = DateTime.tryParse(invoice?['dueDate']?.toString() ?? '');
    if (due == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);

    return today.difference(dueDay).inDays;
  }

  int get daysUntilDue {
    final due = DateTime.tryParse(invoice?['dueDate']?.toString() ?? '');

    if (due == null) return 999999;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);

    return dueDay.difference(today).inDays;
  }

  String dueLabel() {
    if (isPaid) return 'Paid';

    if (daysUntilDue == 999999) return 'No due date';
    if (daysUntilDue < 0) {
      return 'Overdue by ${daysUntilDue.abs()} day${daysUntilDue.abs() == 1 ? '' : 's'}';
    }
    if (daysUntilDue == 0) return 'Due today';

    return 'Due in $daysUntilDue day${daysUntilDue == 1 ? '' : 's'}';
  }

  String effectiveStatus() {
    if (isOverdue) return 'OVERDUE';
    if (isPaid) return 'PAID';
    if (isPartiallyPaid) return 'PARTIALLY_PAID';

    return invoice?['status']?.toString() ?? 'UNPAID';
  }

  String tenantName() {
    final user =
        invoice?['tenant']?['user'] ?? invoice?['lease']?['tenant']?['user'];

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

  String tenantEmail() {
    final user =
        invoice?['tenant']?['user'] ?? invoice?['lease']?['tenant']?['user'];

    return user?['email']?.toString() ?? '—';
  }

  String tenantPhone() {
    final user =
        invoice?['tenant']?['user'] ?? invoice?['lease']?['tenant']?['user'];
    final phone = user?['phone']?.toString();

    if (phone == null || phone.trim().isEmpty) return 'No phone';

    return phone;
  }

  String unitName() {
    final unit = invoice?['unit'] ?? invoice?['lease']?['unit'];

    if (unit != null) {
      return unit['title']?.toString() ?? unit['number']?.toString() ?? 'Unit';
    }

    return 'Unit';
  }

  String unitNumber() {
    final unit = invoice?['unit'] ?? invoice?['lease']?['unit'];
    final number = unit?['number']?.toString();

    if (number == null || number.trim().isEmpty) return 'No unit number';

    return number;
  }

  String propertyName() {
    final property =
        invoice?['property'] ??
        invoice?['unit']?['property'] ??
        invoice?['lease']?['unit']?['property'];

    if (property != null) {
      return property['title']?.toString() ??
          property['name']?.toString() ??
          property['address']?.toString() ??
          'Property';
    }

    return 'Property';
  }

  String propertyAddress() {
    final property =
        invoice?['property'] ??
        invoice?['unit']?['property'] ??
        invoice?['lease']?['unit']?['property'];

    final address = property?['address']?.toString();

    if (address == null || address.trim().isEmpty) return 'No address';

    return address;
  }

  String leaseFrequency() {
    return invoice?['lease']?['frequency']?.toString() ?? '—';
  }

  String leaseStatus() {
    return invoice?['lease']?['status']?.toString() ?? '—';
  }

  String leasePeriod() {
    final start = formatDate(invoice?['lease']?['startDate']);
    final end = formatDate(invoice?['lease']?['endDate']);

    return '$start → $end';
  }

  String initials() {
    final clean = tenantName().trim();

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

  List<dynamic> get sortedPayments {
    final list = [...payments];

    list.sort((a, b) {
      switch (paymentSortMode) {
        case 'Oldest':
          return parseDate(a['createdAt']).compareTo(parseDate(b['createdAt']));

        case 'Amount High':
          return paymentAmount(b).compareTo(paymentAmount(a));

        case 'Amount Low':
          return paymentAmount(a).compareTo(paymentAmount(b));

        case 'Method':
          return (a['method']?.toString() ?? '').compareTo(
            b['method']?.toString() ?? '',
          );

        case 'Newest':
        default:
          return parseDate(b['createdAt']).compareTo(parseDate(a['createdAt']));
      }
    });

    return list;
  }

  String paymentMethodLabel(String method) {
    switch (method) {
      case 'CASH':
        return 'Cash';
      case 'BANK_TRANSFER':
        return 'Bank Transfer';
      case 'CARD':
        return 'Card';
      case 'MOBILE_MONEY':
        return 'Mobile Money';
      default:
        return method;
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'OVERDUE':
        return Colors.red;
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

  IconData statusIcon(String status) {
    switch (status) {
      case 'OVERDUE':
        return Icons.event_busy;
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

  Color methodColor(String method) {
    switch (method) {
      case 'CASH':
        return Colors.green;
      case 'BANK_TRANSFER':
        return Colors.blue;
      case 'CARD':
        return Colors.deepPurple;
      case 'MOBILE_MONEY':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData methodIcon(String method) {
    switch (method) {
      case 'CASH':
        return Icons.payments;
      case 'BANK_TRANSFER':
        return Icons.account_balance;
      case 'CARD':
        return Icons.credit_card;
      case 'MOBILE_MONEY':
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  String statusDescription() {
    final status = effectiveStatus();

    switch (status) {
      case 'OVERDUE':
        return 'This invoice is overdue and needs payment follow-up.';
      case 'PAID':
        return 'This invoice has been fully paid.';
      case 'PARTIALLY_PAID':
        return 'This invoice has received a partial payment and still has a balance.';
      case 'UNPAID':
        return 'This invoice has not received any payment yet.';
      default:
        return 'Invoice status information is unavailable.';
    }
  }

  int get invoiceHealthScore {
    if (isPaid) return 100;
    if (isOverdue) {
      final penalty = (overdueDays * 4).clamp(0, 45);
      final base = (paidRatio * 70).round();
      return (base - penalty).clamp(0, 100);
    }

    final dueBonus = daysUntilDue > 7 ? 20 : 10;
    return ((paidRatio * 80).round() + dueBonus).clamp(0, 100);
  }

  String invoiceHealthLabel() {
    if (isPaid) return 'Healthy';
    if (isOverdue) return 'Needs follow-up';
    if (isPartiallyPaid) return 'In progress';
    if (daysUntilDue <= 3 && daysUntilDue >= 0) return 'Due soon';

    return 'Open';
  }

  Color invoiceHealthColor() {
    if (isPaid) return Colors.green;
    if (isOverdue) return Colors.red;
    if (isPartiallyPaid) return Colors.orange;
    if (daysUntilDue <= 3 && daysUntilDue >= 0) return Colors.orange;

    return primary;
  }

  Future<void> openPaymentSheet() async {
    if (!canRecordPayment) {
      await AppError.show(
        context,
        'You are not allowed to record payments.',
        title: 'Permission required',
      );
      return;
    }

    if (isPaid) {
      await AppError.show(
        context,
        'This invoice is already fully paid.',
        title: 'Invoice paid',
      );
      return;
    }

    final paid = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentSheet(
        invoiceId: widget.invoiceId,
        remaining: remaining,
        invoiceAmount: invoiceAmount(),
        tenantName: tenantName(),
        propertyName: propertyName(),
        unitName: unitName(),
      ),
    );

    if (paid == true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded successfully')),
      );

      await load(silent: true);
    }
  }

  Future<void> openInsightSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InvoiceInsightSheet(
        tenantName: tenantName(),
        propertyName: propertyName(),
        unitName: unitName(),
        status: effectiveStatus(),
        healthScore: invoiceHealthScore,
        healthLabel: invoiceHealthLabel(),
        healthColor: invoiceHealthColor(),
        amount: invoiceAmount(),
        paid: totalPaid,
        remaining: remaining,
        paidPercent: paidPercent,
        paymentsCount: payments.length,
        dueLabel: dueLabel(),
        isOverdue: isOverdue,
        overdueDays: overdueDays,
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
            width: 118,
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
    final status = effectiveStatus();
    final color = statusColor(status);

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
              CircleAvatar(
                radius: 31,
                backgroundColor: Colors.white,
                child: Text(
                  initials(),
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      canRecordPayment ? 'Invoice Details' : 'Invoice View',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${propertyName()} • ${unitName()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

          const SizedBox(height: 20),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(statusIcon(status), color: color, size: 18),
                label: Text(status),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                side: BorderSide.none,
              ),
              Chip(
                avatar: Icon(
                  Icons.health_and_safety,
                  color: invoiceHealthColor(),
                  size: 18,
                ),
                label: Text(invoiceHealthLabel()),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: invoiceHealthColor(),
                  fontWeight: FontWeight.bold,
                ),
                side: BorderSide.none,
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Amount',
                  value: invoiceAmount().toStringAsFixed(2),
                  icon: Icons.receipt_long,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Remaining',
                  value: remaining.toStringAsFixed(2),
                  icon: Icons.account_balance_wallet,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Paid',
                  value: totalPaid.toStringAsFixed(2),
                  icon: Icons.payments,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Collected',
                  value: '$paidPercent%',
                  icon: Icons.auto_graph,
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
                  '${dueLabel()} • Health score: $invoiceHealthScore%',
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
              value: paidRatio,
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
                    onPressed: openInsightSheet,
                    icon: const Icon(Icons.insights),
                    label: const Text('Insights'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: refreshing ? null : () => load(silent: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ),
              ],
            ),
            if (canRecordPayment && !isPaid) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: refreshing ? null : openPaymentSheet,
                  icon: const Icon(Icons.payment),
                  label: const Text('Record Payment'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget sectionSwitch() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            sectionChip('OVERVIEW', 'Overview', Icons.dashboard_customize),
            const SizedBox(width: 8),
            sectionChip('PAYMENTS', 'Payments', Icons.payments),
            const SizedBox(width: 8),
            sectionChip('LEASE', 'Lease', Icons.description),
          ],
        ),
      ),
    );
  }

  Widget sectionChip(String value, String label, IconData icon) {
    final selected = selectedSection == value;

    return Expanded(
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        avatar: Icon(icon, size: 18, color: selected ? Colors.white : primary),
        selectedColor: primary,
        backgroundColor: primary.withOpacity(0.08),
        labelStyle: TextStyle(
          color: selected ? Colors.white : primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        side: BorderSide.none,
        onSelected: (_) => setState(() => selectedSection = value),
      ),
    );
  }

  Widget statusBadge() {
    final status = effectiveStatus();
    final color = statusColor(status);

    return Chip(
      avatar: Icon(statusIcon(status), size: 16, color: color),
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

  Widget invoiceSummaryCard() {
    final status = effectiveStatus();
    final color = statusColor(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 31,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(statusIcon(status), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        propertyName(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: darkText,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        unitName(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tenant: ${tenantName()}',
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
                statusBadge(),
              ],
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: softBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  infoRow('Invoice Amount', invoiceAmount().toStringAsFixed(2)),
                  infoRow('Total Paid', totalPaid.toStringAsFixed(2)),
                  infoRow('Remaining', remaining.toStringAsFixed(2)),
                  infoRow('Due Date', formatDate(invoice?['dueDate'])),
                  infoRow('Paid At', formatDate(invoice?['paidAt'])),
                  infoRow('Created', formatDateTime(invoice?['createdAt'])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget healthCard() {
    final color = invoiceHealthColor();

    return Card(
      color: color.withOpacity(0.07),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(Icons.health_and_safety, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoiceHealthLabel(),
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    statusDescription(),
                    style: TextStyle(color: Colors.grey.shade800, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: invoiceHealthScore / 100,
                      minHeight: 8,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget overdueCard() {
    if (!isOverdue) return const SizedBox.shrink();

    return Card(
      color: Colors.red.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.12),
              child: const Icon(Icons.event_busy, color: Colors.red),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'This invoice is overdue by $overdueDays day${overdueDays == 1 ? '' : 's'}. Remaining balance: ${remaining.toStringAsFixed(2)}.',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget paymentActionCard() {
    if (!canRecordPayment) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.withOpacity(0.12),
                child: const Icon(Icons.lock_outline, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Read-only access. You can view invoice details and payment history, but cannot record payments.',
                  style: TextStyle(color: Colors.grey.shade700, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isPaid) {
      return Card(
        color: Colors.green.withOpacity(0.07),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0x1A4CAF50),
                child: Icon(Icons.check_circle, color: Colors.green),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Invoice fully paid',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: primary.withOpacity(0.07),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primary.withOpacity(0.12),
                  child: const Icon(Icons.payment, color: primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Remaining balance: ${remaining.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Record a partial or full payment. The invoice status will update automatically after payment.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.35),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: refreshing ? null : openPaymentSheet,
                icon: const Icon(Icons.payment),
                label: const Text('Record Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tenantCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: primary.withOpacity(0.12),
              child: const Icon(Icons.person, color: primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tenant',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  infoRow('Name', tenantName()),
                  infoRow('Email', tenantEmail()),
                  infoRow('Phone', tenantPhone()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget leaseCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: primary.withOpacity(0.12),
              child: const Icon(Icons.description, color: primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lease & Unit',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  infoRow('Property', propertyName()),
                  infoRow('Address', propertyAddress()),
                  infoRow('Unit', unitName()),
                  infoRow('Unit Number', unitNumber()),
                  infoRow('Frequency', leaseFrequency()),
                  infoRow('Lease Status', leaseStatus()),
                  infoRow('Lease Period', leasePeriod()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget paymentHistoryHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Payment History',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          width: 165,
          child: DropdownButtonFormField<String>(
            value: paymentSortMode,
            decoration: const InputDecoration(
              labelText: 'Sort',
              prefixIcon: Icon(Icons.sort),
            ),
            items: const [
              DropdownMenuItem(value: 'Newest', child: Text('Newest')),
              DropdownMenuItem(value: 'Oldest', child: Text('Oldest')),
              DropdownMenuItem(value: 'Amount High', child: Text('High')),
              DropdownMenuItem(value: 'Amount Low', child: Text('Low')),
              DropdownMenuItem(value: 'Method', child: Text('Method')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => paymentSortMode = value);
            },
          ),
        ),
      ],
    );
  }

  Widget paymentCard(dynamic payment) {
    final amount = paymentAmount(payment);
    final method = payment['method']?.toString() ?? 'CASH';
    final date = formatDateTime(payment['createdAt']);
    final color = methodColor(method);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(methodIcon(method), color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    amount.toStringAsFixed(2),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    paymentMethodLabel(method),
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    date,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget paymentHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        paymentHistoryHeader(),

        const SizedBox(height: 8),

        if (payments.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                children: [
                  Icon(Icons.payments, size: 54, color: Colors.grey.shade500),
                  const SizedBox(height: 12),
                  const Text(
                    'No payments yet',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Once a payment is recorded, it will appear here with method, amount and date.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          )
        else
          ...sortedPayments.map(paymentCard),
      ],
    );
  }

  Widget overviewSection() {
    return Column(
      children: [
        invoiceSummaryCard(),
        const SizedBox(height: 14),
        healthCard(),
        const SizedBox(height: 14),
        overdueCard(),
        if (isOverdue) const SizedBox(height: 14),
        paymentActionCard(),
        const SizedBox(height: 14),
        tenantCard(),
      ],
    );
  }

  Widget paymentsSection() {
    return Column(
      children: [
        paymentActionCard(),
        const SizedBox(height: 18),
        paymentHistory(),
      ],
    );
  }

  Widget leaseSection() {
    return Column(
      children: [leaseCard(), const SizedBox(height: 14), tenantCard()],
    );
  }

  Widget selectedSectionBody() {
    if (selectedSection == 'PAYMENTS') return paymentsSection();
    if (selectedSection == 'LEASE') return leaseSection();

    return overviewSection();
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
                  const Icon(Icons.error_outline, color: Colors.red, size: 42),
                  const SizedBox(height: 12),
                  const Text(
                    'Could not load invoice',
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
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 150),
          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Invoice not found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget contentBody() {
    return RefreshIndicator(
      onRefresh: () => load(silent: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          heroHeader(),

          const SizedBox(height: 18),

          quickActions(),

          const SizedBox(height: 14),

          sectionSwitch(),

          const SizedBox(height: 14),

          selectedSectionBody(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = canRecordPayment ? 'Invoice Details' : 'Invoice View';

    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: refreshing
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: refreshing ? null : () => load(silent: true),
          ),
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: invoice == null ? null : openInsightSheet,
          ),
        ],
      ),
      body: loading
          ? loadingBody()
          : error.isNotEmpty
          ? errorBody()
          : invoice == null
          ? emptyBody()
          : contentBody(),
    );
  }
}

class _PaymentSheet extends StatefulWidget {
  final String invoiceId;
  final num remaining;
  final num invoiceAmount;
  final String tenantName;
  final String propertyName;
  final String unitName;

  const _PaymentSheet({
    required this.invoiceId,
    required this.remaining,
    required this.invoiceAmount,
    required this.tenantName,
    required this.propertyName,
    required this.unitName,
  });

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final amountCtrl = TextEditingController();

  bool paying = false;
  String paymentMethod = 'CASH';
  String error = '';

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  final methods = const ['CASH', 'BANK_TRANSFER', 'CARD', 'MOBILE_MONEY'];

  @override
  void initState() {
    super.initState();
    amountCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }

  double get enteredAmount {
    return double.tryParse(amountCtrl.text.trim()) ?? 0;
  }

  bool get validAmount {
    return enteredAmount > 0 && enteredAmount <= widget.remaining;
  }

  double get paymentRatio {
    if (widget.remaining <= 0) return 0;

    return (enteredAmount / widget.remaining).clamp(0, 1).toDouble();
  }

  String methodLabel(String method) {
    switch (method) {
      case 'CASH':
        return 'Cash';
      case 'BANK_TRANSFER':
        return 'Bank Transfer';
      case 'CARD':
        return 'Card';
      case 'MOBILE_MONEY':
        return 'Mobile Money';
      default:
        return method;
    }
  }

  Color methodColor(String method) {
    switch (method) {
      case 'CASH':
        return Colors.green;
      case 'BANK_TRANSFER':
        return Colors.blue;
      case 'CARD':
        return Colors.deepPurple;
      case 'MOBILE_MONEY':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData methodIcon(String method) {
    switch (method) {
      case 'CASH':
        return Icons.payments;
      case 'BANK_TRANSFER':
        return Icons.account_balance;
      case 'CARD':
        return Icons.credit_card;
      case 'MOBILE_MONEY':
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  void fillRemaining() {
    amountCtrl.text = widget.remaining.toStringAsFixed(2);
    amountCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: amountCtrl.text.length),
    );
  }

  Future<void> submitPayment() async {
    FocusScope.of(context).unfocus();

    setState(() => error = '');

    if (enteredAmount <= 0) {
      setState(() => error = 'Payment amount must be greater than zero');
      return;
    }

    if (enteredAmount > widget.remaining) {
      setState(() => error = 'Payment exceeds remaining amount');
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmPaymentSheet(
        amount: enteredAmount,
        method: methodLabel(paymentMethod),
        tenantName: widget.tenantName,
        remaining: widget.remaining,
      ),
    );

    if (confirmed != true) return;

    setState(() => paying = true);

    try {
      await PaymentService.pay(
        invoiceId: widget.invoiceId,
        amount: enteredAmount,
        method: paymentMethod,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = AppError.clean(e);
      });

      await AppError.show(context, e, title: 'Could not record payment');
    } finally {
      if (mounted) {
        setState(() => paying = false);
      }
    }
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget summaryCard() {
    return Card(
      color: primary.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            infoRow('Tenant', widget.tenantName),
            infoRow('Property', widget.propertyName),
            infoRow('Unit', widget.unitName),
            infoRow('Invoice Amount', widget.invoiceAmount.toStringAsFixed(2)),
            infoRow('Remaining', widget.remaining.toStringAsFixed(2)),
          ],
        ),
      ),
    );
  }

  Widget methodChoice(String method) {
    final selected = paymentMethod == method;
    final color = methodColor(method);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        label: Text(methodLabel(method)),
        avatar: Icon(
          methodIcon(method),
          color: selected ? Colors.white : color,
          size: 18,
        ),
        selectedColor: color,
        backgroundColor: color.withOpacity(0.10),
        labelStyle: TextStyle(
          color: selected ? Colors.white : color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        side: BorderSide.none,
        onSelected: paying
            ? null
            : (_) => setState(() => paymentMethod = method),
      ),
    );
  }

  Widget amountProgress() {
    final color = methodColor(paymentMethod);

    return Card(
      color: color.withOpacity(0.07),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment coverage: ${(paymentRatio * 100).round()}%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: paymentRatio,
                minHeight: 9,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              enteredAmount <= 0
                  ? 'Enter a payment amount.'
                  : enteredAmount > widget.remaining
                  ? 'Amount exceeds remaining balance.'
                  : 'Remaining after payment: ${(widget.remaining - enteredAmount).toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget errorCard() {
    if (error.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Colors.red.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = methodColor(paymentMethod);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
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

                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withOpacity(0.12),
                      child: Icon(methodIcon(paymentMethod), color: color),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Record Payment',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: paying ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  'Add a partial or full payment for this invoice.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),

                const SizedBox(height: 18),

                summaryCard(),

                const SizedBox(height: 14),

                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  enabled: !paying,
                  decoration: InputDecoration(
                    labelText: 'Payment Amount',
                    prefixIcon: const Icon(Icons.payments),
                    helperText:
                        'Maximum: ${widget.remaining.toStringAsFixed(2)}',
                    suffixIcon: TextButton(
                      onPressed: paying ? null : fillRemaining,
                      child: const Text('MAX'),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Payment Method',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: methods.map(methodChoice).toList()),
                ),

                const SizedBox(height: 14),

                amountProgress(),

                const SizedBox(height: 14),

                errorCard(),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: paying || !validAmount ? null : submitPayment,
                    icon: paying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(paying ? 'Recording...' : 'Record Payment'),
                  ),
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: paying ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmPaymentSheet extends StatelessWidget {
  final double amount;
  final String method;
  final String tenantName;
  final num remaining;

  const _ConfirmPaymentSheet({
    required this.amount,
    required this.method,
    required this.tenantName,
    required this.remaining,
  });

  static const softBg = Color(0xFFF8F5FF);

  @override
  Widget build(BuildContext context) {
    final afterPayment = (remaining - amount).clamp(0, remaining);

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

              const SizedBox(height: 22),

              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.green.withOpacity(0.12),
                child: const Icon(Icons.payment, color: Colors.green, size: 34),
              ),

              const SizedBox(height: 16),

              const Text(
                'Confirm Payment?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                'Record ${amount.toStringAsFixed(2)} from $tenantName using $method.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),

              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _row('Amount', amount.toStringAsFixed(2)),
                      _row('Method', method),
                      _row('Remaining Before', remaining.toStringAsFixed(2)),
                      _row('Remaining After', afterPayment.toStringAsFixed(2)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Confirm Payment'),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _InvoiceInsightSheet extends StatelessWidget {
  final String tenantName;
  final String propertyName;
  final String unitName;
  final String status;
  final int healthScore;
  final String healthLabel;
  final Color healthColor;
  final num amount;
  final num paid;
  final num remaining;
  final int paidPercent;
  final int paymentsCount;
  final String dueLabel;
  final bool isOverdue;
  final int overdueDays;

  const _InvoiceInsightSheet({
    required this.tenantName,
    required this.propertyName,
    required this.unitName,
    required this.status,
    required this.healthScore,
    required this.healthLabel,
    required this.healthColor,
    required this.amount,
    required this.paid,
    required this.remaining,
    required this.paidPercent,
    required this.paymentsCount,
    required this.dueLabel,
    required this.isOverdue,
    required this.overdueDays,
  });

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  Widget scoreCard({
    required String title,
    required int value,
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
                  '$value%',
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
                value: value / 100,
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
                  radius: 36,
                  backgroundColor: healthColor.withOpacity(0.12),
                  child: Icon(Icons.insights, color: healthColor, size: 36),
                ),

                const SizedBox(height: 14),

                const Text(
                  'Invoice Intelligence',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                Text(
                  '$propertyName • $unitName',
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
                  title: 'Invoice Health',
                  value: healthScore,
                  icon: Icons.health_and_safety,
                  color: healthColor,
                ),

                const SizedBox(height: 10),

                scoreCard(
                  title: 'Collection Progress',
                  value: paidPercent,
                  icon: Icons.pie_chart,
                  color: paidPercent >= 100
                      ? Colors.green
                      : paidPercent > 0
                      ? Colors.orange
                      : Colors.red,
                ),

                const SizedBox(height: 14),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        infoRow('Tenant', tenantName),
                        infoRow('Status', status),
                        infoRow('Due Signal', dueLabel),
                        infoRow('Invoice Amount', amount.toStringAsFixed(2)),
                        infoRow('Paid', paid.toStringAsFixed(2)),
                        infoRow('Remaining', remaining.toStringAsFixed(2)),
                        infoRow('Payments', paymentsCount),
                        if (isOverdue) infoRow('Overdue Days', overdueDays),
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
                      isOverdue
                          ? 'This invoice should be followed up because it is past the due date and still has an outstanding balance.'
                          : remaining <= 0
                          ? 'This invoice is fully collected and contributes positively to revenue reports.'
                          : 'Track partial payments and follow up before the due date to keep collection health strong.',
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
