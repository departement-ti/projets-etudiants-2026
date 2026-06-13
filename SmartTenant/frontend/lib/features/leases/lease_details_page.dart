import 'package:flutter/material.dart';

import '../../core/auth/auth_storage.dart';
import '../../core/ui/app_error.dart';
import '../invoice/invoice_details.dart';
import 'lease_service.dart';

class LeaseDetailsPage extends StatefulWidget {
  final String leaseId;

  const LeaseDetailsPage({super.key, required this.leaseId});

  @override
  State<LeaseDetailsPage> createState() => _LeaseDetailsPageState();
}

class _LeaseDetailsPageState extends State<LeaseDetailsPage> {
  Map<String, dynamic>? lease;

  bool loading = true;
  bool refreshing = false;
  bool terminating = false;

  String error = '';
  String? role;

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);
  static const darkText = Color(0xFF1D1B20);

  bool get canTerminateLease {
    return role == 'ADMIN' || role == 'OWNER';
  }

  bool get canViewLeaseFinancials {
    return role == 'ADMIN' || role == 'OWNER' || role == 'TENANT';
  }

  bool get isActiveLease {
    return lease?['status']?.toString() == 'ACTIVE';
  }

  @override
  void initState() {
    super.initState();
    loadLease();
  }

  Future<void> loadLease({bool silent = false}) async {
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
      final data = await LeaseService.getLease(widget.leaseId);

      if (!mounted) return;

      setState(() {
        role = userRole;
        lease = data;
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

  String formatDate(dynamic value) {
    if (value == null) return '—';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    return parsed.toLocal().toString().split(' ')[0];
  }

  DateTime? parseDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }

  String tenantName() {
    final user = lease?['tenant']?['user'];

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
    return lease?['tenant']?['user']?['email']?.toString() ?? '—';
  }

  String tenantPhone() {
    final phone = lease?['tenant']?['user']?['phone']?.toString();

    if (phone == null || phone.trim().isEmpty) return 'No phone';

    return phone;
  }

  String unitName() {
    final unit = lease?['unit'];

    if (unit != null) {
      return unit['title']?.toString() ?? unit['number']?.toString() ?? 'Unit';
    }

    return 'Unit';
  }

  String unitNumber() {
    final value = lease?['unit']?['number']?.toString();

    if (value == null || value.trim().isEmpty) return 'No unit number';

    return value;
  }

  String propertyName() {
    final property = lease?['unit']?['property'];

    if (property != null) {
      return property['title']?.toString() ??
          property['name']?.toString() ??
          property['address']?.toString() ??
          'Property';
    }

    return 'Property';
  }

  String propertyAddress() {
    final address = lease?['unit']?['property']?['address']?.toString();

    if (address == null || address.trim().isEmpty) return 'No address';

    return address;
  }

  num rentAmount() {
    final value = lease?['rentAmount'];

    if (value is num) return value;

    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  num depositAmount() {
    final value = lease?['depositAmount'];

    if (value is num) return value;

    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<dynamic> invoices() {
    final data = lease?['invoices'];

    if (data is List) return data;

    return [];
  }

  List<dynamic> sortedInvoices() {
    final data = [...invoices()];

    data.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['dueDate']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          DateTime.tryParse(b['dueDate']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);

      return bDate.compareTo(aDate);
    });

    return data;
  }

  num invoiceAmount(dynamic invoice) {
    final value = invoice['amount'];

    if (value is num) return value;

    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  num invoiceRemaining(dynamic invoice) {
    final remaining = invoice['remainingAmount'];

    if (remaining is num) return remaining;

    final parsed = num.tryParse(remaining?.toString() ?? '');

    if (parsed != null) return parsed;

    final status = invoice['status']?.toString();

    if (status == 'PAID') return 0;

    return invoiceAmount(invoice);
  }

  bool invoiceOverdue(dynamic invoice) {
    if (invoice['isOverdue'] == true) return true;

    final status = invoice['status']?.toString();
    if (status == 'PAID') return false;

    final due = parseDate(invoice['dueDate']);
    if (due == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);

    return dueDay.isBefore(today);
  }

  int get paidInvoices {
    return invoices().where((invoice) {
      return invoice['status']?.toString() == 'PAID';
    }).length;
  }

  int get unpaidInvoices {
    return invoices().where((invoice) {
      final status = invoice['status']?.toString();
      return status == 'UNPAID' || status == 'PARTIALLY_PAID';
    }).length;
  }

  int get overdueInvoices {
    return invoices().where(invoiceOverdue).length;
  }

  num get totalBilled {
    return invoices().fold<num>(0, (sum, invoice) {
      return sum + invoiceAmount(invoice);
    });
  }

  num get totalRemaining {
    return invoices().fold<num>(0, (sum, invoice) {
      return sum + invoiceRemaining(invoice);
    });
  }

  num get totalPaid {
    return (totalBilled - totalRemaining).clamp(0, totalBilled);
  }

  DateTime? get leaseStartDate {
    return parseDate(lease?['startDate']);
  }

  DateTime? get leaseEndDate {
    return parseDate(lease?['endDate']);
  }

  int get daysUntilEnd {
    final end = leaseEndDate;
    if (end == null) return 999999;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(end.year, end.month, end.day);

    return endDay.difference(today).inDays;
  }

  int get leaseDurationDays {
    final start = leaseStartDate;
    final end = leaseEndDate;

    if (start == null || end == null) return 0;

    return end.difference(start).inDays.abs();
  }

  int get leaseElapsedDays {
    final start = leaseStartDate;

    if (start == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(start.year, start.month, start.day);

    return today.difference(startDay).inDays.clamp(0, 999999);
  }

  double get leaseProgress {
    if (lease?['status']?.toString() == 'TERMINATED') return 1;

    if (leaseDurationDays <= 0) return 0;

    return (leaseElapsedDays / leaseDurationDays).clamp(0, 1).toDouble();
  }

  bool get isExpiredActiveLease {
    return isActiveLease && daysUntilEnd < 0;
  }

  bool get isEndingSoon {
    return isActiveLease && daysUntilEnd >= 0 && daysUntilEnd <= 30;
  }

  bool get hasRenewalAlert {
    return isExpiredActiveLease || isEndingSoon;
  }

  String renewalLabel() {
    if (lease?['status']?.toString() == 'TERMINATED') return 'TERMINATED';
    if (isExpiredActiveLease) return 'EXPIRED';
    if (isEndingSoon) return 'ENDING SOON';

    return 'ON TRACK';
  }

  String renewalDescription() {
    if (lease?['status']?.toString() == 'TERMINATED') {
      return 'This lease has already been terminated.';
    }

    if (isExpiredActiveLease) {
      return 'Lease expired ${daysUntilEnd.abs()} day${daysUntilEnd.abs() == 1 ? '' : 's'} ago.';
    }

    if (isEndingSoon) {
      return 'Lease ends in $daysUntilEnd day${daysUntilEnd == 1 ? '' : 's'}. Consider renewal follow-up.';
    }

    if (daysUntilEnd == 999999) return 'Lease end date is unavailable.';

    return '$daysUntilEnd day${daysUntilEnd == 1 ? '' : 's'} remaining.';
  }

  Color renewalColor() {
    if (isExpiredActiveLease) return Colors.red;
    if (isEndingSoon) return Colors.orange;
    if (lease?['status']?.toString() == 'TERMINATED') return Colors.grey;

    return Colors.green;
  }

  Color statusColor(String? status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'TERMINATED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData statusIcon(String? status) {
    switch (status) {
      case 'ACTIVE':
        return Icons.check_circle;
      case 'TERMINATED':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String statusDescription(String? status) {
    switch (status) {
      case 'ACTIVE':
        return 'This lease is currently active. The unit should be occupied and rent invoices should continue.';
      case 'TERMINATED':
        return 'This lease has ended. The unit should be released and available again.';
      default:
        return 'Lease status information is unavailable.';
    }
  }

  Color invoiceStatusColor(String? status) {
    switch (status) {
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

  String initials() {
    final clean = unitName().trim();

    if (clean.isEmpty) return 'L';

    final parts = clean.split(' ').where((part) => part.trim().isNotEmpty);
    final list = parts.toList();

    if (list.length >= 2) {
      return '${list[0][0]}${list[1][0]}'.toUpperCase();
    }

    return clean[0].toUpperCase();
  }

  Future<void> openInvoice(dynamic invoice) async {
    if (!canViewLeaseFinancials) {
      await AppError.show(
        context,
        'Financial invoice details are restricted.',
        title: 'Access restricted',
      );
      return;
    }

    final id = invoice['id']?.toString();

    if (id == null || id.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvoiceDetailsPage(invoiceId: id)),
    );

    await loadLease(silent: true);
  }

  Future<void> terminateLease() async {
    if (!canTerminateLease) {
      await AppError.show(
        context,
        'You are not allowed to terminate leases.',
        title: 'Permission required',
      );
      return;
    }

    if (!isActiveLease) {
      await AppError.show(
        context,
        'Only active leases can be terminated.',
        title: 'Lease already closed',
      );
      return;
    }

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TerminateLeaseSheet(
        tenantName: tenantName(),
        unitName: unitName(),
        propertyName: propertyName(),
        endDate: formatDate(lease?['endDate']),
      ),
    );

    if (confirm != true) return;

    setState(() => terminating = true);

    try {
      await LeaseService.terminateLease(widget.leaseId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lease terminated successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      await AppError.show(context, e, title: 'Could not terminate lease');
    } finally {
      if (mounted) {
        setState(() => terminating = false);
      }
    }
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
    final status = lease?['status']?.toString() ?? '—';
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
                radius: 30,
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
                      unitName(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$propertyName • ${tenantName()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: refreshing ? null : () => loadLease(silent: true),
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
                avatar: Icon(Icons.event_busy, color: renewalColor(), size: 18),
                label: Text(renewalLabel()),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: renewalColor(),
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
                  title: 'Rent',
                  value: rentAmount().toStringAsFixed(2),
                  icon: Icons.payments,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Deposit',
                  value: depositAmount().toStringAsFixed(2),
                  icon: Icons.savings,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

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
                  title: 'Remaining',
                  value: totalRemaining.toStringAsFixed(2),
                  icon: Icons.warning_amber,
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
                  'Lease progress: ${(leaseProgress * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                renewalLabel(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: leaseProgress,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: darkText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget metricsGrid() {
    final cards = <Widget>[
      metricCard(
        title: 'Paid',
        value: totalPaid.toStringAsFixed(2),
        icon: Icons.check_circle,
        color: Colors.green,
      ),
      metricCard(
        title: 'Unpaid',
        value: totalRemaining.toStringAsFixed(2),
        icon: Icons.warning_amber,
        color: totalRemaining > 0 ? Colors.red : Colors.green,
      ),
      metricCard(
        title: 'Invoices',
        value: invoices().length.toString(),
        icon: Icons.receipt_long,
        color: primary,
      ),
      metricCard(
        title: 'Overdue',
        value: overdueInvoices.toString(),
        icon: Icons.event_busy,
        color: overdueInvoices > 0 ? Colors.red : Colors.green,
      ),
    ];

    final occupancyCards = <Widget>[
      metricCard(
        title: 'Duration',
        value: '$leaseDurationDays days',
        icon: Icons.date_range,
        color: primary,
      ),
      metricCard(
        title: 'Remaining',
        value: daysUntilEnd == 999999 ? '—' : '$daysUntilEnd days',
        icon: Icons.event_busy,
        color: renewalColor(),
      ),
      metricCard(
        title: 'Status',
        value: lease?['status']?.toString() ?? '—',
        icon: statusIcon(lease?['status']?.toString()),
        color: statusColor(lease?['status']?.toString()),
      ),
      metricCard(
        title: 'Progress',
        value: '${(leaseProgress * 100).round()}%',
        icon: Icons.timeline,
        color: primary,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.24,
      children: canViewLeaseFinancials ? cards : occupancyCards,
    );
  }

  Widget statusMeaningCard() {
    final status = lease?['status']?.toString() ?? '—';
    final color = statusColor(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(statusIcon(status), color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lease Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    statusDescription(status),
                    style: TextStyle(color: Colors.grey.shade700, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget renewalCard() {
    final color = renewalColor();

    return Card(
      color: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(Icons.event_busy, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    renewalLabel(),
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    renewalDescription(),
                    style: TextStyle(color: Colors.grey.shade800, height: 1.35),
                  ),
                ],
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

  Widget propertyUnitCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: primary.withOpacity(0.12),
              child: const Icon(Icons.home_work, color: primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Property & Unit',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  infoRow('Property', propertyName()),
                  infoRow('Address', propertyAddress()),
                  infoRow('Unit', unitName()),
                  infoRow('Number', unitNumber()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget leaseInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lease Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            infoRow('Status', lease?['status']),
            infoRow('Rent', rentAmount().toStringAsFixed(2)),
            infoRow('Deposit', depositAmount().toStringAsFixed(2)),
            infoRow('Frequency', lease?['frequency']),
            infoRow('Start Date', formatDate(lease?['startDate'])),
            infoRow('End Date', formatDate(lease?['endDate'])),
            infoRow('Created', formatDate(lease?['createdAt'])),
            infoRow('Updated', formatDate(lease?['updatedAt'])),
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

  Widget invoiceChip(String status) {
    final color = invoiceStatusColor(status);

    return Chip(
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

  Widget invoiceCard(dynamic invoice) {
    final status = invoice['status']?.toString() ?? 'UNPAID';
    final overdue = invoiceOverdue(invoice);
    final remaining = invoiceRemaining(invoice);
    final color = overdue ? Colors.red : invoiceStatusColor(status);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(
            overdue ? Icons.warning_amber : Icons.receipt_long,
            color: color,
          ),
        ),
        title: Text(
          'Amount: ${invoiceAmount(invoice).toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Remaining: ${remaining.toStringAsFixed(2)}\n'
          'Due: ${formatDate(invoice['dueDate'])}',
        ),
        isThreeLine: true,
        trailing: invoiceChip(overdue && status != 'PAID' ? 'OVERDUE' : status),
        onTap: () => openInvoice(invoice),
      ),
    );
  }

  Widget invoicesSection() {
    final data = sortedInvoices();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle(
          'Invoices',
          'Review generated rent invoices and payment status.',
        ),
        const SizedBox(height: 8),
        if (data.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('No invoices generated yet'),
            ),
          )
        else
          ...data.map(invoiceCard),
      ],
    );
  }

  Widget sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
      ],
    );
  }

  Widget readOnlyNotice() {
    if (canTerminateLease) return const SizedBox.shrink();

    final text = role == 'AGENT'
        ? 'Agent access is read-only and focused on occupancy context. Financial invoice details and lease termination are restricted.'
        : 'You can view lease information, invoices and tenant details. Termination is restricted to admins and owners.';

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
                text,
                style: TextStyle(color: Colors.grey.shade700, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget dangerZone() {
    if (!canTerminateLease || !isActiveLease) return const SizedBox.shrink();

    return Card(
      color: Colors.red.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.warning_amber, color: Colors.red),
              title: Text(
                'Danger Zone',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Terminating this lease will release the unit and stop the active rental relationship.',
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: terminating ? null : terminateLease,
                icon: terminating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel),
                label: Text(terminating ? 'Terminating...' : 'Terminate Lease'),
              ),
            ),
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
      onRefresh: () => loadLease(),
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
                    'Could not load lease',
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
                    onPressed: () => loadLease(),
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
      onRefresh: () => loadLease(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 150),
          Icon(Icons.description, size: 64, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Lease not found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget contentBody() {
    return RefreshIndicator(
      onRefresh: () => loadLease(silent: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          heroHeader(),

          const SizedBox(height: 18),

          metricsGrid(),

          const SizedBox(height: 14),

          renewalCard(),

          const SizedBox(height: 14),

          statusMeaningCard(),

          const SizedBox(height: 14),

          readOnlyNotice(),

          if (!canTerminateLease) const SizedBox(height: 14),

          tenantCard(),

          const SizedBox(height: 14),

          propertyUnitCard(),

          const SizedBox(height: 14),

          leaseInfoCard(),

          const SizedBox(height: 20),
          if (canViewLeaseFinancials) ...[
            invoicesSection(),
            const SizedBox(height: 20),
          ],

          dangerZone(),

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
          'Lease Details',
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
            onPressed: refreshing ? null : () => loadLease(silent: true),
          ),
          if (canTerminateLease && isActiveLease)
            IconButton(
              icon: terminating
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cancel),
              onPressed: terminating ? null : terminateLease,
            ),
        ],
      ),
      body: loading
          ? loadingBody()
          : error.isNotEmpty
          ? errorBody()
          : lease == null
          ? emptyBody()
          : contentBody(),
    );
  }
}

class _TerminateLeaseSheet extends StatelessWidget {
  final String tenantName;
  final String unitName;
  final String propertyName;
  final String endDate;

  const _TerminateLeaseSheet({
    required this.tenantName,
    required this.unitName,
    required this.propertyName,
    required this.endDate,
  });

  static const softBg = Color(0xFFF8F5FF);

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
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
                backgroundColor: Colors.red.withOpacity(0.12),
                child: const Icon(Icons.cancel, color: Colors.red, size: 34),
              ),

              const SizedBox(height: 16),

              const Text(
                'Terminate Lease?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                'This action will terminate the lease and make the unit available again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),

              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      infoRow('Tenant', tenantName),
                      infoRow('Property', propertyName),
                      infoRow('Unit', unitName),
                      infoRow('End Date', endDate),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Card(
                color: Colors.orange.withOpacity(0.10),
                child: const ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.orange),
                  title: Text(
                    'Important',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Invoices and payment history will remain stored for reporting and tenant timeline.',
                  ),
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Terminate Lease'),
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
}
