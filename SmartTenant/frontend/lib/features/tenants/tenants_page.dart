import 'package:flutter/material.dart';

import '../../core/ui/app_error.dart';
import 'tenant_service.dart';

class TenantsPage extends StatefulWidget {
  const TenantsPage({super.key});

  @override
  State<TenantsPage> createState() => _TenantsPageState();
}

class _TenantsPageState extends State<TenantsPage> {
  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);
  static const darkText = Color(0xFF1D1B20);

  bool loading = true;
  bool refreshing = false;
  String error = '';

  List<dynamic> tenants = [];

  final searchCtrl = TextEditingController();

  String statusFilter = 'ALL';
  String balanceFilter = 'ALL';
  String sortMode = 'Newest';
  String viewMode = 'CARDS';
  String? actionTenantId;

  @override
  void initState() {
    super.initState();
    searchCtrl.addListener(() => setState(() {}));
    loadTenants();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> loadTenants({bool silent = false}) async {
    if (silent) {
      setState(() => refreshing = true);
    } else {
      setState(() {
        loading = true;
        error = '';
      });
    }

    try {
      final data = await TenantService.getTenants();

      if (!mounted) return;

      setState(() {
        tenants = data;
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

  String userName(dynamic user) {
    if (user == null) return 'Tenant';

    final firstName = user['firstName']?.toString() ?? '';
    final lastName = user['lastName']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';

    final fullName = '$firstName $lastName'.trim();

    if (fullName.isNotEmpty) return fullName;
    if (email.isNotEmpty) return email;

    return 'Tenant';
  }

  String tenantName(dynamic tenant) {
    return userName(tenant['user']);
  }

  String initials(dynamic tenant) {
    final name = tenantName(tenant).trim();

    if (name.isEmpty) return 'T';

    final parts = name.split(' ').where((p) => p.trim().isNotEmpty).toList();

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return name[0].toUpperCase();
  }

  String email(dynamic tenant) {
    return tenant['user']?['email']?.toString() ?? '—';
  }

  String phone(dynamic tenant) {
    final value = tenant['user']?['phone']?.toString();

    if (value == null || value.trim().isEmpty) return 'No phone';

    return value;
  }

  String nationalId(dynamic tenant) {
    final value = tenant['nationalId']?.toString();

    if (value == null || value.trim().isEmpty) return 'No national ID';

    return value;
  }

  String unitName(dynamic tenant) {
    final unit = tenant['currentUnit'];

    if (unit == null) return 'No active unit';

    final property = unit['property'];
    final propertyName =
        property?['title'] ??
        property?['name'] ??
        property?['address'] ??
        'Property';
    final unitTitle = unit['title'] ?? unit['number'] ?? 'Unit';

    return '$propertyName • $unitTitle';
  }

  String activeLeaseLabel(dynamic tenant) {
    final lease = tenant['activeLease'];

    if (lease == null) return 'No active lease';

    final rent = money(lease['rentAmount']).toStringAsFixed(2);
    final frequency = lease['frequency']?.toString() ?? 'period';

    return '$rent / $frequency';
  }

  num money(dynamic value) {
    if (value is num) return value;

    return num.tryParse(value?.toString() ?? '') ?? 0;
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

  bool hasActiveLease(dynamic tenant) {
    return tenant['activeLease'] != null;
  }

  bool hasUnpaidBalance(dynamic tenant) {
    return money(tenant['totalUnpaid']) > 0;
  }

  int get activeTenantCount {
    return tenants.where(hasActiveLease).length;
  }

  int get inactiveTenantCount {
    return tenants.length - activeTenantCount;
  }

  int get unpaidTenantCount {
    return tenants.where(hasUnpaidBalance).length;
  }

  num get totalUnpaid {
    return tenants.fold<num>(0, (sum, tenant) {
      return sum + money(tenant['totalUnpaid']);
    });
  }

  num get totalPaid {
    return tenants.fold<num>(0, (sum, tenant) {
      return sum + money(tenant['totalPaid']);
    });
  }

  int get occupancyRate {
    if (tenants.isEmpty) return 0;

    return ((activeTenantCount / tenants.length) * 100).round();
  }

  List<dynamic> get filteredTenants {
    final query = searchCtrl.text.trim().toLowerCase();

    final filtered = tenants.where((tenant) {
      final active = hasActiveLease(tenant);
      final unpaid = hasUnpaidBalance(tenant);

      final searchable = [
        tenantName(tenant),
        email(tenant),
        phone(tenant),
        nationalId(tenant),
        unitName(tenant),
        active ? 'active' : 'inactive',
        unpaid ? 'unpaid' : 'clear',
      ].join(' ').toLowerCase();

      final matchesSearch = query.isEmpty || searchable.contains(query);

      final matchesStatus =
          statusFilter == 'ALL' ||
          (statusFilter == 'ACTIVE' && active) ||
          (statusFilter == 'NO_LEASE' && !active);

      final matchesBalance =
          balanceFilter == 'ALL' ||
          (balanceFilter == 'UNPAID' && unpaid) ||
          (balanceFilter == 'CLEAR' && !unpaid);

      return matchesSearch && matchesStatus && matchesBalance;
    }).toList();

    filtered.sort((a, b) {
      switch (sortMode) {
        case 'Name':
          return tenantName(a).compareTo(tenantName(b));

        case 'Unpaid':
          return money(b['totalUnpaid']).compareTo(money(a['totalUnpaid']));

        case 'Paid':
          return money(b['totalPaid']).compareTo(money(a['totalPaid']));

        case 'Active Lease':
          return hasActiveLease(
            b,
          ).toString().compareTo(hasActiveLease(a).toString());

        case 'Oldest':
          return parseDate(a['createdAt']).compareTo(parseDate(b['createdAt']));

        case 'Newest':
        default:
          return parseDate(b['createdAt']).compareTo(parseDate(a['createdAt']));
      }
    });

    return filtered;
  }

  Future<void> openCreateTenantSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateTenantProfileSheet(),
    );

    if (created == true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tenant created successfully')),
      );

      await loadTenants(silent: true);
    }
  }

  Future<void> openTenantDetails(dynamic tenant) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TenantDetailsSheet(
        tenant: tenant,
        onDelete: () async {
          Navigator.pop(context);
          await deleteTenant(tenant);
        },
      ),
    );
  }

  Future<bool> confirmDeleteTenant(dynamic tenant) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TenantDeleteSheet(
        tenantName: tenantName(tenant),
        hasLeaseHistory:
            (tenant['leases'] is List) && tenant['leases'].isNotEmpty,
      ),
    );

    return confirmed == true;
  }

  Future<void> deleteTenant(dynamic tenant) async {
    final confirmed = await confirmDeleteTenant(tenant);

    if (!confirmed) return;

    final id = tenant['id']?.toString();

    setState(() => actionTenantId = id);

    try {
      await TenantService.deleteTenant(tenant['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tenant profile deleted')));

      await loadTenants(silent: true);
    } catch (e) {
      if (!mounted) return;

      await AppError.show(context, e, title: 'Could not delete tenant');
    } finally {
      if (mounted) {
        setState(() => actionTenantId = null);
      }
    }
  }

  void resetFilters() {
    setState(() {
      searchCtrl.clear();
      statusFilter = 'ALL';
      balanceFilter = 'ALL';
      sortMode = 'Newest';
    });
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
                child: Icon(Icons.groups, color: primary, size: 30),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tenant Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Onboard tenants, track balances and rental history.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: refreshing ? null : () => loadTenants(silent: true),
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
                  title: 'Tenants',
                  value: tenants.length.toString(),
                  icon: Icons.groups,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Active Leases',
                  value: activeTenantCount.toString(),
                  icon: Icons.description,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Unpaid Tenants',
                  value: unpaidTenantCount.toString(),
                  icon: Icons.warning_amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Unpaid',
                  value: totalUnpaid.toStringAsFixed(2),
                  icon: Icons.account_balance_wallet,
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
                  'Tenant occupancy activity: $occupancyRate%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: occupancyRate / 100,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: openCreateTenantSheet,
              icon: const Icon(Icons.person_add),
              label: const Text('Create Tenant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
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
                labelText: 'Search tenants',
                hintText: 'Name, email, phone, national ID or unit',
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
                  filterChip(
                    group: 'status',
                    value: 'ALL',
                    label: 'ALL',
                    icon: Icons.all_inclusive,
                    color: primary,
                  ),
                  filterChip(
                    group: 'status',
                    value: 'ACTIVE',
                    label: 'ACTIVE LEASE',
                    icon: Icons.description,
                    color: Colors.green,
                  ),
                  filterChip(
                    group: 'status',
                    value: 'NO_LEASE',
                    label: 'NO LEASE',
                    icon: Icons.home_outlined,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  balanceChip(
                    'ALL',
                    'ALL BALANCES',
                    Icons.all_inclusive,
                    primary,
                  ),
                  balanceChip(
                    'UNPAID',
                    'UNPAID',
                    Icons.warning_amber,
                    Colors.red,
                  ),
                  balanceChip(
                    'CLEAR',
                    'CLEAR',
                    Icons.check_circle,
                    Colors.green,
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
                      DropdownMenuItem(value: 'Name', child: Text('Name')),
                      DropdownMenuItem(value: 'Unpaid', child: Text('Unpaid')),
                      DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                      DropdownMenuItem(
                        value: 'Active Lease',
                        child: Text('Active Lease'),
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

  Widget filterChip({
    required String group,
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final selected = statusFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        avatar: Icon(icon, size: 18, color: selected ? Colors.white : color),
        label: Text(label),
        selectedColor: color,
        backgroundColor: color.withOpacity(0.10),
        labelStyle: TextStyle(
          color: selected ? Colors.white : color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        side: BorderSide.none,
        onSelected: (_) => setState(() => statusFilter = value),
      ),
    );
  }

  Widget balanceChip(String value, String label, IconData icon, Color color) {
    final selected = balanceFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        avatar: Icon(icon, size: 18, color: selected ? Colors.white : color),
        label: Text(label),
        selectedColor: color,
        backgroundColor: color.withOpacity(0.10),
        labelStyle: TextStyle(
          color: selected ? Colors.white : color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        side: BorderSide.none,
        onSelected: (_) => setState(() => balanceFilter = value),
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

  Widget statusChip(dynamic tenant) {
    final active = hasActiveLease(tenant);
    final color = active ? Colors.green : Colors.grey;

    return Chip(
      avatar: Icon(
        active ? Icons.description : Icons.home_outlined,
        size: 16,
        color: color,
      ),
      label: Text(active ? 'ACTIVE LEASE' : 'NO LEASE'),
      backgroundColor: color.withOpacity(0.12),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 10,
      ),
      side: BorderSide.none,
    );
  }

  Widget balanceBadge(dynamic tenant) {
    final unpaid = money(tenant['totalUnpaid']);
    final color = unpaid > 0 ? Colors.red : Colors.green;

    return Chip(
      avatar: Icon(
        unpaid > 0 ? Icons.warning_amber : Icons.check_circle,
        size: 16,
        color: color,
      ),
      label: Text(unpaid > 0 ? unpaid.toStringAsFixed(2) : 'CLEAR'),
      backgroundColor: color.withOpacity(0.12),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 10,
      ),
      side: BorderSide.none,
    );
  }

  Widget tenantCard(dynamic tenant) {
    final unpaid = money(tenant['totalUnpaid']);
    final active = hasActiveLease(tenant);
    final color = active ? primary : Colors.grey;
    final busy = actionTenantId == tenant['id']?.toString();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: busy ? null : () => openTenantDetails(tenant),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: color.withOpacity(0.12),
                    child: busy
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            initials(tenant),
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
                          tenantName(tenant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: darkText,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          email(tenant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          unitName(tenant),
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
                    enabled: !busy,
                    onSelected: (value) {
                      if (value == 'view') openTenantDetails(tenant);
                      if (value == 'delete') deleteTenant(tenant);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility),
                            SizedBox(width: 10),
                            Text('View details'),
                          ],
                        ),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 10),
                            Text('Delete profile'),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                child: Row(
                  children: [
                    Icon(
                      active ? Icons.home_work : Icons.info_outline,
                      color: active ? primary : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        active
                            ? 'Current lease: ${activeLeaseLabel(tenant)}'
                            : 'No active lease yet. This tenant is ready for leasing.',
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
                  statusChip(tenant),
                  const SizedBox(width: 8),
                  balanceBadge(tenant),
                  const Spacer(),
                  Text(
                    unpaid > 0 ? 'Needs follow-up' : 'Good standing',
                    style: TextStyle(
                      color: unpaid > 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : () => openTenantDetails(tenant),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Details'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: busy ? null : () => openTenantDetails(tenant),
                      icon: const Icon(Icons.timeline),
                      label: const Text('Timeline'),
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

  Widget compactTenantTile(dynamic tenant) {
    final active = hasActiveLease(tenant);
    final color = active ? primary : Colors.grey;
    final busy = actionTenantId == tenant['id']?.toString();

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  initials(tenant),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
        ),
        title: Text(
          tenantName(tenant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${email(tenant)} • ${unitName(tenant)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: balanceBadge(tenant),
        onTap: busy ? null : () => openTenantDetails(tenant),
      ),
    );
  }

  Widget emptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(Icons.groups, size: 62, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            const Text(
              'No tenants found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              searchCtrl.text.trim().isNotEmpty ||
                      statusFilter != 'ALL' ||
                      balanceFilter != 'ALL'
                  ? 'Try changing the search text or filters.'
                  : 'Create tenant accounts and profiles before creating leases.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: openCreateTenantSheet,
              icon: const Icon(Icons.person_add),
              label: const Text('Create Tenant'),
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
      onRefresh: () => loadTenants(),
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
                    'Could not load tenants',
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
                    onPressed: () => loadTenants(),
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
    final data = filteredTenants;

    return RefreshIndicator(
      onRefresh: () => loadTenants(silent: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          heroHeader(),

          const SizedBox(height: 18),

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
            ...data.map(compactTenantTile)
          else
            ...data.map(tenantCard),

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
          'Tenants',
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
            onPressed: refreshing ? null : () => loadTenants(silent: true),
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: openCreateTenantSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openCreateTenantSheet,
        icon: const Icon(Icons.person_add),
        label: const Text('Tenant'),
      ),
      body: loading
          ? loadingBody()
          : error.isNotEmpty
          ? errorBody()
          : contentBody(),
    );
  }
}

class _CreateTenantProfileSheet extends StatefulWidget {
  const _CreateTenantProfileSheet();

  @override
  State<_CreateTenantProfileSheet> createState() =>
      _CreateTenantProfileSheetState();
}

class _CreateTenantProfileSheetState extends State<_CreateTenantProfileSheet> {
  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  bool loadingUsers = true;
  bool creating = false;
  bool createNewAccount = true;

  String error = '';

  List<dynamic> availableUsers = [];
  String? selectedUserId;

  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final nationalIdCtrl = TextEditingController();

  bool obscurePassword = true;

  bool get isExistingUserMode => !createNewAccount;

  bool get canCreateNewAccount {
    return emailCtrl.text.trim().isNotEmpty &&
        passwordCtrl.text.trim().length >= 6;
  }

  bool get canCreateExistingProfile {
    return selectedUserId != null && selectedUserId!.isNotEmpty;
  }

  int get setupScore {
    int score = 0;

    if (createNewAccount) {
      if (emailCtrl.text.trim().isNotEmpty) score += 30;
      if (passwordCtrl.text.trim().length >= 6) score += 25;
      if (firstNameCtrl.text.trim().isNotEmpty) score += 15;
      if (lastNameCtrl.text.trim().isNotEmpty) score += 15;
      if (nationalIdCtrl.text.trim().isNotEmpty) score += 15;
    } else {
      if (selectedUserId != null) score += 70;
      if (nationalIdCtrl.text.trim().isNotEmpty) score += 30;
    }

    return score.clamp(0, 100);
  }

  @override
  void initState() {
    super.initState();

    emailCtrl.addListener(() => setState(() {}));
    passwordCtrl.addListener(() => setState(() {}));
    firstNameCtrl.addListener(() => setState(() {}));
    lastNameCtrl.addListener(() => setState(() {}));
    phoneCtrl.addListener(() => setState(() {}));
    nationalIdCtrl.addListener(() => setState(() {}));

    loadAvailableUsers();
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    nationalIdCtrl.dispose();
    super.dispose();
  }

  Future<void> loadAvailableUsers() async {
    setState(() {
      loadingUsers = true;
      error = '';
    });

    try {
      final users = await TenantService.getAvailableTenantUsers();

      if (!mounted) return;

      setState(() {
        availableUsers = users;
        selectedUserId = users.isNotEmpty
            ? users.first['id']?.toString()
            : null;
        loadingUsers = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = AppError.clean(e);
        loadingUsers = false;
      });
    }
  }

  String userName(dynamic user) {
    final firstName = user['firstName']?.toString() ?? '';
    final lastName = user['lastName']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';

    final fullName = '$firstName $lastName'.trim();

    if (fullName.isNotEmpty) return fullName;
    if (email.isNotEmpty) return email;

    return 'Tenant user';
  }

  String cleanText(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();

    setState(() => error = '');

    if (createNewAccount) {
      if (!canCreateNewAccount) {
        setState(() {
          error = 'Email and a password of at least 6 characters are required';
        });
        return;
      }
    } else {
      if (!canCreateExistingProfile) {
        setState(() {
          error = 'Please select an available tenant user';
        });
        return;
      }
    }

    setState(() => creating = true);

    try {
      if (createNewAccount) {
        await TenantService.createTenantAccountAndProfile(
          email: emailCtrl.text.trim(),
          password: passwordCtrl.text,
          firstName: cleanText(firstNameCtrl.text),
          lastName: cleanText(lastNameCtrl.text),
          phone: cleanText(phoneCtrl.text),
          nationalId: cleanText(nationalIdCtrl.text),
        );
      } else {
        await TenantService.createTenantProfile(
          userId: selectedUserId!,
          nationalId: cleanText(nationalIdCtrl.text),
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = AppError.clean(e);
      });

      await AppError.show(
        context,
        e,
        title: createNewAccount
            ? 'Could not create tenant account'
            : 'Could not create tenant profile',
      );
    } finally {
      if (mounted) setState(() => creating = false);
    }
  }

  Widget modeSwitch() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    selected: createNewAccount,
                    label: const Text('New account'),
                    avatar: Icon(
                      Icons.person_add,
                      color: createNewAccount ? Colors.white : primary,
                      size: 18,
                    ),
                    selectedColor: primary,
                    backgroundColor: primary.withOpacity(0.08),
                    labelStyle: TextStyle(
                      color: createNewAccount ? Colors.white : primary,
                      fontWeight: FontWeight.bold,
                    ),
                    side: BorderSide.none,
                    onSelected: creating
                        ? null
                        : (_) => setState(() {
                            createNewAccount = true;
                            error = '';
                          }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    selected: !createNewAccount,
                    label: const Text('Existing user'),
                    avatar: Icon(
                      Icons.person_search,
                      color: !createNewAccount ? Colors.white : primary,
                      size: 18,
                    ),
                    selectedColor: primary,
                    backgroundColor: primary.withOpacity(0.08),
                    labelStyle: TextStyle(
                      color: !createNewAccount ? Colors.white : primary,
                      fontWeight: FontWeight.bold,
                    ),
                    side: BorderSide.none,
                    onSelected: creating
                        ? null
                        : (_) => setState(() {
                            createNewAccount = false;
                            error = '';
                          }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget progressCard() {
    return Card(
      color: primary.withOpacity(0.07),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primary.withOpacity(0.12),
                  child: const Icon(Icons.task_alt, color: primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tenant setup progress',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Text(
                  '$setupScore%',
                  style: const TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: setupScore / 100,
                minHeight: 8,
                backgroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      enabled: !creating,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget newAccountForm() {
    return Column(
      children: [
        input(
          controller: emailCtrl,
          label: 'Tenant Email',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        input(
          controller: passwordCtrl,
          label: 'Temporary Password',
          icon: Icons.lock,
          obscure: obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              obscurePassword ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: creating
                ? null
                : () {
                    setState(() => obscurePassword = !obscurePassword);
                  },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: input(
                controller: firstNameCtrl,
                label: 'First Name',
                icon: Icons.person,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: input(
                controller: lastNameCtrl,
                label: 'Last Name',
                icon: Icons.person_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        input(
          controller: phoneCtrl,
          label: 'Phone',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget existingUserForm() {
    if (loadingUsers) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (availableUsers.isEmpty) {
      return Card(
        color: Colors.orange.withOpacity(0.10),
        child: const ListTile(
          leading: Icon(Icons.info_outline, color: Colors.orange),
          title: Text(
            'No available tenant users',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Create a new tenant account here, or ask the admin to create a TENANT user first.',
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: selectedUserId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Available Tenant User',
        prefixIcon: Icon(Icons.person_search),
      ),
      items: availableUsers.map((user) {
        return DropdownMenuItem<String>(
          value: user['id']?.toString(),
          child: Text(
            '${userName(user)} • ${user['email'] ?? '—'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: creating
          ? null
          : (value) {
              setState(() => selectedUserId = value);
            },
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

  Widget helperCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline, color: primary),
        title: const Text(
          'Tenant onboarding',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          createNewAccount
              ? 'This creates both the tenant user account and the tenant profile in your organization.'
              : 'This creates a tenant profile for an existing TENANT user without a profile.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = createNewAccount
        ? 'Create Tenant Account'
        : 'Create Tenant Profile';

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

                CircleAvatar(
                  radius: 30,
                  backgroundColor: primary.withOpacity(0.12),
                  child: const Icon(Icons.person_add, color: primary, size: 30),
                ),

                const SizedBox(height: 14),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Prepare the tenant profile so it can be used in lease creation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),

                const SizedBox(height: 18),

                modeSwitch(),

                const SizedBox(height: 14),

                progressCard(),

                const SizedBox(height: 18),

                if (createNewAccount) newAccountForm() else existingUserForm(),

                const SizedBox(height: 14),

                input(
                  controller: nationalIdCtrl,
                  label: 'National ID',
                  icon: Icons.badge,
                ),

                const SizedBox(height: 14),

                helperCard(),

                if (error.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  errorCard(),
                ],

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: creating ? null : submit,
                    icon: creating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add),
                    label: Text(
                      creating
                          ? 'Creating...'
                          : createNewAccount
                          ? 'Create Tenant Account'
                          : 'Create Tenant Profile',
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: creating ? null : () => Navigator.pop(context),
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

class _TenantDetailsSheet extends StatelessWidget {
  final dynamic tenant;
  final Future<void> Function() onDelete;

  const _TenantDetailsSheet({required this.tenant, required this.onDelete});

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  String userName(dynamic user) {
    if (user == null) return 'Tenant';

    final firstName = user['firstName']?.toString() ?? '';
    final lastName = user['lastName']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';

    final fullName = '$firstName $lastName'.trim();

    if (fullName.isNotEmpty) return fullName;
    if (email.isNotEmpty) return email;

    return 'Tenant';
  }

  String initials() {
    final name = userName(tenant['user']);

    if (name.trim().isEmpty) return 'T';

    final parts = name.split(' ').where((p) => p.trim().isNotEmpty).toList();

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return name[0].toUpperCase();
  }

  String formatDate(dynamic value) {
    if (value == null) return '—';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    return parsed.toLocal().toString().split(' ')[0];
  }

  num money(dynamic value) {
    if (value is num) return value;

    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  String unitName() {
    final unit = tenant['currentUnit'];

    if (unit == null) return 'No active unit';

    final property = unit['property'];
    final propertyName =
        property?['title'] ??
        property?['name'] ??
        property?['address'] ??
        'Property';
    final unitTitle = unit['title'] ?? unit['number'] ?? 'Unit';

    return '$propertyName • $unitTitle';
  }

  List<dynamic> leases() {
    final data = tenant['leases'];

    if (data is List) return data;

    return [];
  }

  List<dynamic> timeline() {
    final data = tenant['timeline'];

    if (data is List) return data;

    return [];
  }

  Color timelineColor(String? type) {
    switch (type) {
      case 'TENANT_PROFILE_CREATED':
      case 'TENANT_ACCOUNT_CREATED':
        return primary;
      case 'LEASE_CREATED':
      case 'LEASE_STARTED':
      case 'CURRENT_UNIT_ASSIGNED':
        return Colors.green;
      case 'INVOICE_GENERATED':
        return Colors.blue;
      case 'PAYMENT_RECEIVED':
        return Colors.green;
      case 'INVOICE_UNPAID':
      case 'OUTSTANDING_BALANCE':
        return Colors.red;
      case 'LEASE_TERMINATED':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData timelineIcon(String? type) {
    switch (type) {
      case 'TENANT_PROFILE_CREATED':
      case 'TENANT_ACCOUNT_CREATED':
        return Icons.person_add;
      case 'LEASE_CREATED':
        return Icons.description;
      case 'LEASE_STARTED':
        return Icons.play_arrow;
      case 'CURRENT_UNIT_ASSIGNED':
        return Icons.home_work;
      case 'INVOICE_GENERATED':
        return Icons.receipt_long;
      case 'PAYMENT_RECEIVED':
        return Icons.payments;
      case 'INVOICE_UNPAID':
      case 'OUTSTANDING_BALANCE':
        return Icons.warning_amber;
      case 'LEASE_TERMINATED':
        return Icons.cancel;
      default:
        return Icons.history;
    }
  }

  Widget infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget financialSnapshot() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.24,
      children: [
        metric(
          title: 'Invoiced',
          value: money(tenant['totalInvoiced']).toStringAsFixed(2),
          icon: Icons.receipt_long,
          color: primary,
        ),
        metric(
          title: 'Paid',
          value: money(tenant['totalPaid']).toStringAsFixed(2),
          icon: Icons.payments,
          color: Colors.green,
        ),
        metric(
          title: 'Unpaid',
          value: money(tenant['totalUnpaid']).toStringAsFixed(2),
          icon: Icons.warning_amber,
          color: Colors.red,
        ),
        metric(
          title: 'Leases',
          value: leases().length.toString(),
          icon: Icons.description,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget profileCard() {
    final user = tenant['user'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tenant Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            infoRow('Name', userName(user)),
            infoRow('Email', user?['email']),
            infoRow('Phone', user?['phone']),
            infoRow('National ID', tenant['nationalId']),
            infoRow('Current Unit', unitName()),
            infoRow('Created', formatDate(tenant['createdAt'])),
          ],
        ),
      ),
    );
  }

  Widget leaseCard(dynamic lease) {
    final status = lease['status']?.toString() ?? '—';
    final active = status == 'ACTIVE';

    final unit = lease['unit'];
    final property = unit?['property'];

    final propertyName =
        property?['title'] ??
        property?['name'] ??
        property?['address'] ??
        'Property';
    final unitTitle = unit?['title'] ?? unit?['number'] ?? 'Unit';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: active
              ? Colors.green.withOpacity(0.12)
              : Colors.red.withOpacity(0.12),
          child: Icon(
            Icons.description,
            color: active ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          '$propertyName • $unitTitle',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Rent: ${money(lease['rentAmount']).toStringAsFixed(2)} • ${lease['frequency'] ?? '—'}\n'
          '${formatDate(lease['startDate'])} → ${formatDate(lease['endDate'])}',
        ),
        isThreeLine: true,
        trailing: Text(
          status,
          style: TextStyle(
            color: active ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget leasesSection() {
    final data = leases();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lease History',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (data.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('No leases yet'),
            ),
          )
        else
          ...data.map(leaseCard),
      ],
    );
  }

  Widget timelineItem(dynamic item) {
    final type = item['type']?.toString();
    final color = timelineColor(type);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(timelineIcon(type), color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title']?.toString() ?? 'Timeline event',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['description']?.toString() ?? '',
                    style: TextStyle(color: Colors.grey.shade700, height: 1.35),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatDate(item['date']),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

  Widget timelineSection() {
    final data = timeline();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tenant Timeline',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (data.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('No timeline events yet'),
            ),
          )
        else
          ...data.map(timelineItem),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = tenant['user'];
    final unpaid = money(tenant['totalUnpaid']);

    return DraggableScrollableSheet(
      initialChildSize: 0.90,
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
                  backgroundColor: primary.withOpacity(0.12),
                  child: Text(
                    initials(),
                    style: const TextStyle(
                      color: primary,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  userName(user),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  user?['email']?.toString() ?? '—',
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
                      avatar: Icon(
                        tenant['activeLease'] != null
                            ? Icons.description
                            : Icons.home_outlined,
                        color: tenant['activeLease'] != null
                            ? Colors.green
                            : Colors.grey,
                        size: 18,
                      ),
                      label: Text(
                        tenant['activeLease'] != null
                            ? 'ACTIVE LEASE'
                            : 'NO ACTIVE LEASE',
                      ),
                      backgroundColor:
                          (tenant['activeLease'] != null
                                  ? Colors.green
                                  : Colors.grey)
                              .withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: tenant['activeLease'] != null
                            ? Colors.green
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide.none,
                    ),
                    Chip(
                      avatar: Icon(
                        unpaid > 0 ? Icons.warning_amber : Icons.check_circle,
                        color: unpaid > 0 ? Colors.red : Colors.green,
                        size: 18,
                      ),
                      label: Text(
                        unpaid > 0
                            ? 'UNPAID ${unpaid.toStringAsFixed(2)}'
                            : 'BALANCE CLEAR',
                      ),
                      backgroundColor: (unpaid > 0 ? Colors.red : Colors.green)
                          .withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: unpaid > 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide.none,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                financialSnapshot(),

                const SizedBox(height: 16),

                profileCard(),

                const SizedBox(height: 16),

                leasesSection(),

                const SizedBox(height: 16),

                timelineSection(),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Delete Tenant Profile',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
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

class _TenantDeleteSheet extends StatelessWidget {
  final String tenantName;
  final bool hasLeaseHistory;

  const _TenantDeleteSheet({
    required this.tenantName,
    required this.hasLeaseHistory,
  });

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
                child: const Icon(Icons.delete, color: Colors.red, size: 34),
              ),

              const SizedBox(height: 16),

              const Text(
                'Delete Tenant Profile',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                tenantName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Text(
                hasLeaseHistory
                    ? 'This tenant has lease history. The backend will block deletion if related rental records exist.'
                    : 'This is only allowed if the tenant has no leases or important rental history.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, height: 1.45),
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
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete Profile'),
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
