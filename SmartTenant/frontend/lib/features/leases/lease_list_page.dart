import 'package:flutter/material.dart';

import '../../core/auth/auth_storage.dart';
import '../../core/ui/app_error.dart';
import 'lease_service.dart';
import 'lease_details_page.dart';
import 'create_lease_page.dart';

class LeaseListPage extends StatefulWidget {
  const LeaseListPage({super.key});

  @override
  State<LeaseListPage> createState() => _LeaseListPageState();
}

class _LeaseListPageState extends State<LeaseListPage> {
  List<dynamic> leases = [];

  bool loading = true;
  bool refreshing = false;
  String error = '';
  String? role;

  String selectedStatus = 'ALL';
  String alertFilter = 'ALL';
  String sortMode = 'Newest';
  String viewMode = 'CARDS';

  final searchCtrl = TextEditingController();

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);
  static const darkText = Color(0xFF1D1B20);

  bool get canCreateLease {
    return role == 'ADMIN' || role == 'OWNER';
  }

  @override
  void initState() {
    super.initState();
    searchCtrl.addListener(() => setState(() {}));
    loadLeases();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> loadLeases({bool silent = false}) async {
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
      final data = await LeaseService.getLeases();

      if (!mounted) return;

      setState(() {
        role = userRole;
        leases = data;
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

  Future<void> refreshLeases() async {
    await loadLeases(silent: true);
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

  String tenantName(dynamic lease) {
    final user = lease['tenant']?['user'];

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

  String tenantEmail(dynamic lease) {
    return lease['tenant']?['user']?['email']?.toString() ?? '—';
  }

  String unitName(dynamic lease) {
    final unit = lease['unit'];

    if (unit != null) {
      return unit['title']?.toString() ?? unit['number']?.toString() ?? 'Unit';
    }

    return 'Unit';
  }

  String propertyName(dynamic lease) {
    final property = lease['unit']?['property'];

    if (property != null) {
      return property['title']?.toString() ??
          property['name']?.toString() ??
          property['address']?.toString() ??
          'Property';
    }

    return 'Property';
  }

  String propertyAddress(dynamic lease) {
    final property = lease['unit']?['property'];
    final address = property?['address']?.toString();

    if (address == null || address.trim().isEmpty) return 'No address';

    return address;
  }

  num rentAmount(dynamic lease) {
    final value = lease['rentAmount'];

    if (value is num) return value;

    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? leaseStartDate(dynamic lease) {
    return DateTime.tryParse(lease['startDate']?.toString() ?? '');
  }

  DateTime? leaseEndDate(dynamic lease) {
    return DateTime.tryParse(lease['endDate']?.toString() ?? '');
  }

  int daysUntilLeaseEnd(dynamic lease) {
    final end = leaseEndDate(lease);
    if (end == null) return 999999;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(end.year, end.month, end.day);

    return endDay.difference(today).inDays;
  }

  int leaseDurationDays(dynamic lease) {
    final start = leaseStartDate(lease);
    final end = leaseEndDate(lease);

    if (start == null || end == null) return 0;

    return end.difference(start).inDays.abs();
  }

  int leaseElapsedDays(dynamic lease) {
    final start = leaseStartDate(lease);

    if (start == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(start.year, start.month, start.day);

    return today.difference(startDay).inDays.clamp(0, 999999);
  }

  double leaseProgress(dynamic lease) {
    final status = lease['status']?.toString();

    if (status == 'TERMINATED') return 1;

    final duration = leaseDurationDays(lease);
    if (duration <= 0) return 0;

    final progress = leaseElapsedDays(lease) / duration;

    return progress.clamp(0, 1).toDouble();
  }

  bool isLeaseExpired(dynamic lease) {
    final status = lease['status']?.toString();
    if (status != 'ACTIVE') return false;

    return daysUntilLeaseEnd(lease) < 0;
  }

  bool isLeaseEndingSoon(dynamic lease) {
    final status = lease['status']?.toString();
    if (status != 'ACTIVE') return false;

    final days = daysUntilLeaseEnd(lease);

    return days >= 0 && days <= 30;
  }

  bool hasRenewalAlert(dynamic lease) {
    return isLeaseExpired(lease) || isLeaseEndingSoon(lease);
  }

  String renewalLabel(dynamic lease) {
    if (isLeaseExpired(lease)) return 'EXPIRED';
    if (isLeaseEndingSoon(lease)) return 'ENDING SOON';

    return 'ON TRACK';
  }

  Color renewalColor(dynamic lease) {
    if (isLeaseExpired(lease)) return Colors.red;
    if (isLeaseEndingSoon(lease)) return Colors.orange;

    return Colors.green;
  }

  String renewalDescription(dynamic lease) {
    final days = daysUntilLeaseEnd(lease);

    if (isLeaseExpired(lease)) {
      return 'Expired ${days.abs()} day${days.abs() == 1 ? '' : 's'} ago';
    }

    if (isLeaseEndingSoon(lease)) {
      return 'Ends in $days day${days == 1 ? '' : 's'}';
    }

    if (lease['status']?.toString() == 'TERMINATED') {
      return 'Lease already terminated';
    }

    if (days == 999999) return 'End date unavailable';

    return '$days day${days == 1 ? '' : 's'} remaining';
  }

  int get activeCount => statusCount('ACTIVE');

  int get terminatedCount => statusCount('TERMINATED');

  int statusCount(String status) {
    return leases.where((lease) {
      return lease['status']?.toString() == status;
    }).length;
  }

  int get renewalAlertCount {
    return leases.where(hasRenewalAlert).length;
  }

  num get totalActiveRent {
    return leases.fold<num>(0, (sum, lease) {
      if (lease['status']?.toString() != 'ACTIVE') return sum;

      return sum + rentAmount(lease);
    });
  }

  num get averageActiveRent {
    if (activeCount == 0) return 0;

    return totalActiveRent / activeCount;
  }

  int get activeRate {
    if (leases.isEmpty) return 0;

    return ((activeCount / leases.length) * 100).round().clamp(0, 100);
  }

  List<dynamic> invoices(dynamic lease) {
    final data = lease['invoices'];

    if (data is List) return data;

    return [];
  }

  int invoiceCount(dynamic lease) {
    return invoices(lease).length;
  }

  List<dynamic> get filteredLeases {
    final query = searchCtrl.text.trim().toLowerCase();

    final filtered = leases.where((lease) {
      final status = lease['status']?.toString() ?? 'ACTIVE';

      final searchable = [
        tenantName(lease),
        tenantEmail(lease),
        unitName(lease),
        propertyName(lease),
        propertyAddress(lease),
        rentAmount(lease).toString(),
        status,
        lease['frequency']?.toString() ?? '',
        renewalLabel(lease),
      ].join(' ').toLowerCase();

      final matchesSearch = query.isEmpty || searchable.contains(query);

      final matchesStatus = selectedStatus == 'ALL' || status == selectedStatus;

      final matchesAlert =
          alertFilter == 'ALL' ||
          (alertFilter == 'ALERTS' && hasRenewalAlert(lease)) ||
          (alertFilter == 'CLEAR' && !hasRenewalAlert(lease));

      return matchesSearch && matchesStatus && matchesAlert;
    }).toList();

    filtered.sort((a, b) {
      switch (sortMode) {
        case 'Renewal Alert':
          final aAlert = hasRenewalAlert(a);
          final bAlert = hasRenewalAlert(b);

          if (aAlert && !bAlert) return -1;
          if (!aAlert && bAlert) return 1;

          return daysUntilLeaseEnd(a).compareTo(daysUntilLeaseEnd(b));

        case 'Ending Soon':
          return daysUntilLeaseEnd(a).compareTo(daysUntilLeaseEnd(b));

        case 'Rent High':
          return rentAmount(b).compareTo(rentAmount(a));

        case 'Rent Low':
          return rentAmount(a).compareTo(rentAmount(b));

        case 'Tenant':
          return tenantName(a).compareTo(tenantName(b));

        case 'Unit':
          return unitName(a).compareTo(unitName(b));

        case 'Property':
          return propertyName(a).compareTo(propertyName(b));

        case 'Start Date':
          return parseDate(a['startDate']).compareTo(parseDate(b['startDate']));

        case 'End Date':
          return parseDate(a['endDate']).compareTo(parseDate(b['endDate']));

        case 'Oldest':
          return parseDate(a['createdAt']).compareTo(parseDate(b['createdAt']));

        case 'Newest':
        default:
          return parseDate(b['createdAt']).compareTo(parseDate(a['createdAt']));
      }
    });

    return filtered;
  }

  Future<void> openCreateLease() async {
    if (!canCreateLease) {
      await AppError.show(
        context,
        'You are not allowed to create leases.',
        title: 'Permission required',
      );
      return;
    }

    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateLeasePage()),
    );

    if (created == true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lease created successfully')),
      );

      await loadLeases(silent: true);
    }
  }

  Future<void> openLeaseDetails(dynamic lease) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LeaseDetailsPage(leaseId: lease['id'])),
    );

    await loadLeases(silent: true);
  }

  Future<void> openLeasePreview(dynamic lease) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LeasePreviewSheet(
        lease: lease,
        tenantName: tenantName(lease),
        tenantEmail: tenantEmail(lease),
        unitName: unitName(lease),
        propertyName: propertyName(lease),
        propertyAddress: propertyAddress(lease),
        rentAmount: rentAmount(lease),
        statusColor: statusColor(lease['status']?.toString()),
        statusIcon: statusIcon(lease['status']?.toString()),
        renewalColor: renewalColor(lease),
        renewalLabel: renewalLabel(lease),
        renewalDescription: renewalDescription(lease),
        progress: leaseProgress(lease),
        invoiceCount: invoiceCount(lease),
        formatDate: formatDate,
        canCreateLease: canCreateLease,
        onOpenDetails: () async {
          Navigator.pop(context);
          await openLeaseDetails(lease);
        },
      ),
    );
  }

  void resetFilters() {
    setState(() {
      searchCtrl.clear();
      selectedStatus = 'ALL';
      alertFilter = 'ALL';
      sortMode = 'Newest';
    });
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
        return 'This lease is active. The unit should currently be occupied.';
      case 'TERMINATED':
        return 'This lease has ended and the related unit should be released.';
      default:
        return 'Lease status information is unavailable.';
    }
  }

  String initials(dynamic lease) {
    final clean = unitName(lease).trim();

    if (clean.isEmpty) return 'L';

    final parts = clean.split(' ').where((part) => part.trim().isNotEmpty);
    final list = parts.toList();

    if (list.length >= 2) {
      return '${list[0][0]}${list[1][0]}'.toUpperCase();
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
                radius: 27,
                backgroundColor: Colors.white,
                child: Icon(Icons.description, color: primary, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      canCreateLease ? 'Lease Command Center' : 'Leases View',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      canCreateLease
                          ? 'Create contracts, monitor occupancy and renewal risks.'
                          : 'Browse lease and tenant occupancy information.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: refreshing ? null : refreshLeases,
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
                  title: 'Active',
                  value: activeCount.toString(),
                  icon: Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Terminated',
                  value: terminatedCount.toString(),
                  icon: Icons.cancel,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Active Rent',
                  value: totalActiveRent.toStringAsFixed(2),
                  icon: Icons.payments,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Renewal Alerts',
                  value: renewalAlertCount.toString(),
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
                  title: 'Avg Active Rent',
                  value: averageActiveRent.toStringAsFixed(2),
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Total Leases',
                  value: leases.length.toString(),
                  icon: Icons.folder_copy,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              const Icon(Icons.pie_chart, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Active lease rate: $activeRate%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                renewalAlertCount > 0 ? 'Needs review' : 'Healthy',
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
              value: activeRate / 100,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          if (canCreateLease) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: openCreateLease,
                icon: const Icon(Icons.add),
                label: const Text('Create Lease'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget readOnlyNotice() {
    if (canCreateLease) return const SizedBox.shrink();

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
                'You can view lease information, but creating or terminating leases is restricted to admins and owners.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
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
                labelText: 'Search leases',
                hintText: 'Tenant, email, unit, property, rent or status',
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
              child: Row(
                children: [
                  statusFilterChip('ALL', Icons.all_inclusive),
                  statusFilterChip('ACTIVE', Icons.check_circle),
                  statusFilterChip('TERMINATED', Icons.cancel),
                ],
              ),
            ),

            const SizedBox(height: 10),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  alertFilterChip(
                    value: 'ALL',
                    label: 'ALL ALERTS',
                    icon: Icons.all_inclusive,
                    color: primary,
                  ),
                  alertFilterChip(
                    value: 'ALERTS',
                    label: 'RENEWAL RISK',
                    icon: Icons.warning_amber,
                    color: Colors.orange,
                  ),
                  alertFilterChip(
                    value: 'CLEAR',
                    label: 'ON TRACK',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ],
              ),
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
                        value: 'Renewal Alert',
                        child: Text('Renewal Alert'),
                      ),
                      DropdownMenuItem(
                        value: 'Ending Soon',
                        child: Text('Ending Soon'),
                      ),
                      DropdownMenuItem(
                        value: 'Start Date',
                        child: Text('Start Date'),
                      ),
                      DropdownMenuItem(
                        value: 'End Date',
                        child: Text('End Date'),
                      ),
                      DropdownMenuItem(value: 'Tenant', child: Text('Tenant')),
                      DropdownMenuItem(
                        value: 'Property',
                        child: Text('Property'),
                      ),
                      DropdownMenuItem(value: 'Unit', child: Text('Unit')),
                      DropdownMenuItem(
                        value: 'Rent High',
                        child: Text('Rent High'),
                      ),
                      DropdownMenuItem(
                        value: 'Rent Low',
                        child: Text('Rent Low'),
                      ),
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
            backgroundColor: Colors.white,
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
            backgroundColor: Colors.white,
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

  Widget statusFilterChip(String status, IconData icon) {
    final active = selectedStatus == status;
    final color = status == 'ALL' ? primary : statusColor(status);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: active,
        label: Text(status),
        avatar: Icon(icon, size: 18, color: active ? Colors.white : color),
        selectedColor: color,
        backgroundColor: color.withOpacity(0.10),
        labelStyle: TextStyle(
          color: active ? Colors.white : color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        side: BorderSide.none,
        onSelected: (_) => setState(() => selectedStatus = status),
      ),
    );
  }

  Widget alertFilterChip({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final active = alertFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: active,
        label: Text(label),
        avatar: Icon(icon, size: 18, color: active ? Colors.white : color),
        selectedColor: color,
        backgroundColor: color.withOpacity(0.10),
        labelStyle: TextStyle(
          color: active ? Colors.white : color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        side: BorderSide.none,
        onSelected: (_) => setState(() => alertFilter = value),
      ),
    );
  }

  Widget leaseStatusChip(String status) {
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

  Widget renewalBadge(dynamic lease) {
    final color = renewalColor(lease);
    final label = renewalLabel(lease);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            hasRenewalAlert(lease)
                ? Icons.warning_amber
                : Icons.check_circle_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label • ${renewalDescription(lease)}',
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

  Widget leaseCard(dynamic lease) {
    final status = lease['status']?.toString() ?? 'ACTIVE';
    final color = statusColor(status);
    final progress = leaseProgress(lease);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => openLeasePreview(lease),
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
                      initials(lease),
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
                          unitName(lease),
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
                          propertyName(lease),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          'Tenant: ${tenantName(lease)}',
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
                      if (value == 'preview') openLeasePreview(lease);
                      if (value == 'details') openLeaseDetails(lease);
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

              renewalBadge(lease),

              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: softBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payments, size: 18, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rent: ${rentAmount(lease).toStringAsFixed(2)} • ${lease['frequency'] ?? '—'} • ${formatDate(lease['startDate'])} → ${formatDate(lease['endDate'])}',
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
                  leaseStatusChip(status),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('${invoiceCount(lease)} invoice(s)'),
                    backgroundColor: primary.withOpacity(0.10),
                    labelStyle: const TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    side: BorderSide.none,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => openLeaseDetails(lease),
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

  Widget compactLeaseTile(dynamic lease) {
    final status = lease['status']?.toString() ?? 'ACTIVE';
    final color = statusColor(status);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Text(
            initials(lease),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          unitName(lease),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${propertyName(lease)} • ${tenantName(lease)}\n'
          '${rentAmount(lease).toStringAsFixed(2)} • ${renewalDescription(lease)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: leaseStatusChip(status),
        onTap: () => openLeasePreview(lease),
      ),
    );
  }

  Widget emptyState() {
    final hasFilters =
        searchCtrl.text.trim().isNotEmpty ||
        selectedStatus != 'ALL' ||
        alertFilter != 'ALL';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(Icons.description, size: 62, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            const Text(
              'No leases found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters
                  ? 'Try changing the search text, status filter or renewal alert filter.'
                  : canCreateLease
                  ? 'Create a lease from an available unit to start tracking occupancy.'
                  : 'You have read-only access to lease data.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            if (canCreateLease && !hasFilters) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: openCreateLease,
                icon: const Icon(Icons.add),
                label: const Text('Create Lease'),
              ),
            ],
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
      onRefresh: () => loadLeases(),
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
                    'Could not load leases',
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
                    onPressed: () => loadLeases(),
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
    final data = filteredLeases;

    return RefreshIndicator(
      onRefresh: refreshLeases,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          heroHeader(),

          const SizedBox(height: 18),

          readOnlyNotice(),

          if (!canCreateLease) const SizedBox(height: 14),

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
            ...data.map(compactLeaseTile)
          else
            ...data.map(leaseCard),

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
        title: Text(
          canCreateLease ? 'Leases' : 'Leases View',
          style: const TextStyle(fontWeight: FontWeight.bold),
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
            onPressed: refreshing ? null : refreshLeases,
          ),
          if (canCreateLease)
            IconButton(icon: const Icon(Icons.add), onPressed: openCreateLease),
        ],
      ),
      floatingActionButton: canCreateLease
          ? FloatingActionButton.extended(
              onPressed: openCreateLease,
              icon: const Icon(Icons.add),
              label: const Text('Lease'),
            )
          : null,
      body: loading
          ? loadingBody()
          : error.isNotEmpty
          ? errorBody()
          : contentBody(),
    );
  }
}

class _LeasePreviewSheet extends StatelessWidget {
  final dynamic lease;
  final String tenantName;
  final String tenantEmail;
  final String unitName;
  final String propertyName;
  final String propertyAddress;
  final num rentAmount;
  final Color statusColor;
  final IconData statusIcon;
  final Color renewalColor;
  final String renewalLabel;
  final String renewalDescription;
  final double progress;
  final int invoiceCount;
  final String Function(dynamic value) formatDate;
  final bool canCreateLease;
  final Future<void> Function() onOpenDetails;

  const _LeasePreviewSheet({
    required this.lease,
    required this.tenantName,
    required this.tenantEmail,
    required this.unitName,
    required this.propertyName,
    required this.propertyAddress,
    required this.rentAmount,
    required this.statusColor,
    required this.statusIcon,
    required this.renewalColor,
    required this.renewalLabel,
    required this.renewalDescription,
    required this.progress,
    required this.invoiceCount,
    required this.formatDate,
    required this.canCreateLease,
    required this.onOpenDetails,
  });

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  String status() {
    return lease['status']?.toString() ?? 'ACTIVE';
  }

  String initials() {
    final clean = unitName.trim();

    if (clean.isEmpty) return 'L';

    final parts = clean.split(' ').where((part) => part.trim().isNotEmpty);
    final list = parts.toList();

    if (list.length >= 2) {
      return '${list[0][0]}${list[1][0]}'.toUpperCase();
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
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString().isNotEmpty == true ? value.toString() : '—',
              maxLines: 5,
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
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.25,
      children: [
        metric(
          title: 'Rent',
          value: rentAmount.toStringAsFixed(2),
          icon: Icons.payments,
          color: Colors.green,
        ),
        metric(
          title: 'Frequency',
          value: lease['frequency']?.toString() ?? '—',
          icon: Icons.calendar_month,
          color: primary,
        ),
        metric(
          title: 'Invoices',
          value: invoiceCount.toString(),
          icon: Icons.receipt_long,
          color: Colors.orange,
        ),
        metric(
          title: 'Progress',
          value: '${(progress * 100).round()}%',
          icon: Icons.timeline,
          color: statusColor,
        ),
      ],
    );
  }

  Widget statusCard() {
    return Card(
      color: statusColor.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.12),
              child: Icon(statusIcon, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                status() == 'ACTIVE'
                    ? 'This lease is currently active and the unit should be occupied.'
                    : 'This lease is terminated and the unit should be released.',
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

  Widget renewalCard() {
    return Card(
      color: renewalColor.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: renewalColor.withOpacity(0.12),
              child: Icon(Icons.event_busy, color: renewalColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$renewalLabel • $renewalDescription',
                style: TextStyle(
                  color: renewalColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget detailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            infoRow('Tenant', tenantName),
            infoRow('Email', tenantEmail),
            infoRow('Property', propertyName),
            infoRow('Address', propertyAddress),
            infoRow('Unit', unitName),
            infoRow('Start', formatDate(lease['startDate'])),
            infoRow('End', formatDate(lease['endDate'])),
            infoRow('Created', formatDate(lease['createdAt'])),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  backgroundColor: statusColor.withOpacity(0.12),
                  child: Text(
                    initials(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  unitName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '$propertyName • $tenantName',
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
                      avatar: Icon(statusIcon, color: statusColor, size: 18),
                      label: Text(status()),
                      backgroundColor: statusColor.withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide.none,
                    ),
                    Chip(
                      avatar: Icon(
                        Icons.event_busy,
                        color: renewalColor,
                        size: 18,
                      ),
                      label: Text(renewalLabel),
                      backgroundColor: renewalColor.withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: renewalColor,
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide.none,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                metricsGrid(),

                const SizedBox(height: 14),

                statusCard(),

                const SizedBox(height: 12),

                renewalCard(),

                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lease Progress',
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(progress * 100).round()}% of the lease period elapsed.',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                detailsCard(),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onOpenDetails,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Full Lease Details'),
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
