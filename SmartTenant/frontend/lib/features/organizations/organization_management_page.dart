import 'package:flutter/material.dart';

import '../../core/ui/app_error.dart';
import 'organization_service.dart';

class OrganizationManagementPage extends StatefulWidget {
  const OrganizationManagementPage({super.key});

  @override
  State<OrganizationManagementPage> createState() =>
      _OrganizationManagementPageState();
}

class _OrganizationManagementPageState
    extends State<OrganizationManagementPage> {
  List<dynamic> organizations = [];

  final searchCtrl = TextEditingController();

  bool loading = true;
  bool refreshing = false;
  String error = '';

  String statusFilter = 'ALL';
  String sortMode = 'Newest';
  String viewMode = 'CARDS';
  String? actionOrgId;

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);
  static const darkText = Color(0xFF1D1B20);

  @override
  void initState() {
    super.initState();
    searchCtrl.addListener(() => setState(() {}));
    loadOrganizations();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> loadOrganizations({bool silent = false}) async {
    if (silent) {
      setState(() => refreshing = true);
    } else {
      setState(() {
        loading = true;
        error = '';
      });
    }

    try {
      final data = await OrganizationService.getAll();

      if (!mounted) return;

      setState(() {
        organizations = data;
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

  String organizationName(dynamic org) {
    return org['name']?.toString() ?? 'Organization';
  }

  String organizationSlug(dynamic org) {
    return org['slug']?.toString() ?? '—';
  }

  bool isActive(dynamic org) {
    return org['isActive'] == true;
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

  String initials(dynamic org) {
    final name = organizationName(org).trim();

    if (name.isEmpty) return 'O';

    final parts = name
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return name[0].toUpperCase();
  }

  int get activeCount {
    return organizations.where((org) => isActive(org)).length;
  }

  int get inactiveCount {
    return organizations.length - activeCount;
  }

  double get activeRate {
    if (organizations.isEmpty) return 0;

    return activeCount / organizations.length;
  }

  List<dynamic> get filteredOrganizations {
    final query = searchCtrl.text.trim().toLowerCase();

    final filtered = organizations.where((org) {
      final active = isActive(org);
      final name = organizationName(org).toLowerCase();
      final slug = organizationSlug(org).toLowerCase();

      final matchesSearch =
          query.isEmpty || name.contains(query) || slug.contains(query);

      final matchesStatus =
          statusFilter == 'ALL' ||
          (statusFilter == 'ACTIVE' && active) ||
          (statusFilter == 'INACTIVE' && !active);

      return matchesSearch && matchesStatus;
    }).toList();

    filtered.sort((a, b) {
      switch (sortMode) {
        case 'Name':
          return organizationName(a).compareTo(organizationName(b));

        case 'Slug':
          return organizationSlug(a).compareTo(organizationSlug(b));

        case 'Status':
          return isActive(b).toString().compareTo(isActive(a).toString());

        case 'Oldest':
          return parseDate(a['createdAt']).compareTo(parseDate(b['createdAt']));

        case 'Newest':
        default:
          return parseDate(b['createdAt']).compareTo(parseDate(a['createdAt']));
      }
    });

    return filtered;
  }

  Future<void> openCreateOrganization() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _OrganizationFormSheet(),
    );

    if (created == true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organization created successfully')),
      );

      await loadOrganizations(silent: true);
    }
  }

  Future<void> openEditOrganization(dynamic org) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrganizationFormSheet(organization: org),
    );

    if (updated == true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organization updated successfully')),
      );

      await loadOrganizations(silent: true);
    }
  }

  Future<void> openOrganizationDetails(dynamic org) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrganizationDetailsSheet(
        organization: org,
        name: organizationName(org),
        slug: organizationSlug(org),
        active: isActive(org),
        initials: initials(org),
        formatDate: formatDate,
        onEdit: () async {
          Navigator.pop(context);
          await openEditOrganization(org);
        },
        onDeactivate: () async {
          Navigator.pop(context);
          await deactivateOrganization(org);
        },
        onReactivate: () async {
          Navigator.pop(context);
          await reactivateOrganization(org);
        },
      ),
    );
  }

  Future<bool> confirmOrganizationAction({
    required dynamic org,
    required bool deactivate,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrganizationActionSheet(
        title: deactivate
            ? 'Deactivate Organization'
            : 'Reactivate Organization',
        organizationName: organizationName(org),
        message: deactivate
            ? 'This will suspend the workspace without deleting its data. Users, properties, leases, invoices and history will remain stored.'
            : 'This workspace will become active again and assigned users can continue working normally.',
        confirmLabel: deactivate ? 'Deactivate' : 'Reactivate',
        icon: deactivate ? Icons.block : Icons.check_circle,
        color: deactivate ? Colors.red : Colors.green,
      ),
    );

    return result == true;
  }

  Future<void> deactivateOrganization(dynamic org) async {
    if (!isActive(org)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organization is already inactive')),
      );
      return;
    }

    final confirmed = await confirmOrganizationAction(
      org: org,
      deactivate: true,
    );

    if (!confirmed) return;

    final id = org['id']?.toString();

    setState(() => actionOrgId = id);

    try {
      await OrganizationService.deactivate(org['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Organization deactivated')));

      await loadOrganizations(silent: true);
    } catch (e) {
      if (!mounted) return;

      await AppError.show(
        context,
        e,
        title: 'Could not deactivate organization',
      );
    } finally {
      if (mounted) {
        setState(() => actionOrgId = null);
      }
    }
  }

  Future<void> reactivateOrganization(dynamic org) async {
    if (isActive(org)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organization is already active')),
      );
      return;
    }

    final confirmed = await confirmOrganizationAction(
      org: org,
      deactivate: false,
    );

    if (!confirmed) return;

    final id = org['id']?.toString();

    setState(() => actionOrgId = id);

    try {
      await OrganizationService.reactivate(org['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Organization reactivated')));

      await loadOrganizations(silent: true);
    } catch (e) {
      if (!mounted) return;

      await AppError.show(
        context,
        e,
        title: 'Could not reactivate organization',
      );
    } finally {
      if (mounted) {
        setState(() => actionOrgId = null);
      }
    }
  }

  void resetFilters() {
    setState(() {
      searchCtrl.clear();
      statusFilter = 'ALL';
      sortMode = 'Newest';
    });
  }

  Widget headerMetric({
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
    final rate = (activeRate * 100).round();

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
                child: Icon(Icons.business, color: primary, size: 30),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Organizations Control Center',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage platform workspaces with confidence.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: refreshing
                    ? null
                    : () => loadOrganizations(silent: true),
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
                child: headerMetric(
                  title: 'Total',
                  value: organizations.length.toString(),
                  icon: Icons.business,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: headerMetric(
                  title: 'Active',
                  value: activeCount.toString(),
                  icon: Icons.check_circle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: headerMetric(
                  title: 'Inactive',
                  value: inactiveCount.toString(),
                  icon: Icons.block,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: headerMetric(
                  title: 'Health',
                  value: '$rate%',
                  icon: Icons.pie_chart,
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
                  'Active workspace rate: $rate%',
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
              value: activeRate.clamp(0, 1),
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: openCreateOrganization,
              icon: const Icon(Icons.add_business),
              label: const Text('Create Organization'),
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

  Widget searchAndFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                labelText: 'Search organizations',
                hintText: 'Search by name or slug',
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
                  statusFilterChip('INACTIVE', Icons.block),
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
                      DropdownMenuItem(value: 'Slug', child: Text('Slug')),
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

  Widget statusFilterChip(String value, IconData icon) {
    final selected = statusFilter == value;
    final color = value == 'ACTIVE'
        ? Colors.green
        : value == 'INACTIVE'
        ? Colors.grey
        : primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        avatar: Icon(icon, size: 18, color: selected ? Colors.white : color),
        label: Text(value),
        selectedColor: color,
        backgroundColor: color.withOpacity(0.10),
        labelStyle: TextStyle(
          color: selected ? Colors.white : color,
          fontWeight: FontWeight.bold,
        ),
        side: BorderSide.none,
        onSelected: (_) => setState(() => statusFilter = value),
      ),
    );
  }

  Widget statusChip(bool active) {
    final color = active ? Colors.green : Colors.grey;

    return Chip(
      avatar: Icon(
        active ? Icons.check_circle : Icons.block,
        size: 17,
        color: color,
      ),
      label: Text(active ? 'ACTIVE' : 'INACTIVE'),
      backgroundColor: color.withOpacity(0.12),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
      side: BorderSide.none,
    );
  }

  Widget organizationCard(dynamic org) {
    final active = isActive(org);
    final color = active ? Colors.green : Colors.grey;
    final busy = actionOrgId == org['id']?.toString();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: busy ? null : () => openOrganizationDetails(org),
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
                              initials(org),
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
                            organizationName(org),
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
                            organizationSlug(org),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),

                    PopupMenuButton<String>(
                      enabled: !busy,
                      onSelected: (value) {
                        if (value == 'view') openOrganizationDetails(org);
                        if (value == 'edit') openEditOrganization(org);
                        if (value == 'deactivate') deactivateOrganization(org);
                        if (value == 'reactivate') reactivateOrganization(org);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility),
                              SizedBox(width: 10),
                              Text('View details'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 10),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        if (active)
                          const PopupMenuItem(
                            value: 'deactivate',
                            child: Row(
                              children: [
                                Icon(Icons.block, color: Colors.red),
                                SizedBox(width: 10),
                                Text('Deactivate'),
                              ],
                            ),
                          ),
                        if (!active)
                          const PopupMenuItem(
                            value: 'reactivate',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 10),
                                Text('Reactivate'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    statusChip(active),
                    const Spacer(),
                    Text(
                      'Created: ${formatDate(org['createdAt'])}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

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
                      Icon(
                        active ? Icons.verified : Icons.pause_circle,
                        color: color,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          active
                              ? 'Workspace is active and available for assigned users.'
                              : 'Workspace is suspended. Data remains safely stored.',
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
                      child: OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () => openOrganizationDetails(org),
                        icon: const Icon(Icons.visibility),
                        label: const Text('Details'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: busy
                            ? null
                            : active
                            ? () => deactivateOrganization(org)
                            : () => reactivateOrganization(org),
                        icon: Icon(active ? Icons.block : Icons.check_circle),
                        label: Text(active ? 'Deactivate' : 'Reactivate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: active ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget compactOrganizationTile(dynamic org) {
    final active = isActive(org);
    final color = active ? Colors.green : Colors.grey;
    final busy = actionOrgId == org['id']?.toString();

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
                  initials(org),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
        ),
        title: Text(
          organizationName(org),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${organizationSlug(org)} • Created ${formatDate(org['createdAt'])}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: statusChip(active),
        onTap: busy ? null : () => openOrganizationDetails(org),
      ),
    );
  }

  Widget emptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(Icons.business, size: 58, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            const Text(
              'No organizations found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              searchCtrl.text.trim().isNotEmpty || statusFilter != 'ALL'
                  ? 'Try changing the search text or status filter.'
                  : 'Create your first organization workspace.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: openCreateOrganization,
              icon: const Icon(Icons.add_business),
              label: const Text('Create Organization'),
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
      onRefresh: () => loadOrganizations(),
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
                    'Could not load organizations',
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
                    onPressed: () => loadOrganizations(),
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
    final data = filteredOrganizations;

    return RefreshIndicator(
      onRefresh: () => loadOrganizations(silent: true),
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
            ...data.map(compactOrganizationTile)
          else
            ...data.map(organizationCard),

          const SizedBox(height: 24),
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
          'Organizations',
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
            onPressed: refreshing
                ? null
                : () => loadOrganizations(silent: true),
          ),
          IconButton(
            icon: const Icon(Icons.add_business),
            onPressed: openCreateOrganization,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openCreateOrganization,
        icon: const Icon(Icons.add_business),
        label: const Text('Organization'),
      ),
      body: loading
          ? loadingBody()
          : error.isNotEmpty
          ? errorBody()
          : contentBody(),
    );
  }
}

class _OrganizationFormSheet extends StatefulWidget {
  final Map<String, dynamic>? organization;

  const _OrganizationFormSheet({this.organization});

  @override
  State<_OrganizationFormSheet> createState() => _OrganizationFormSheetState();
}

class _OrganizationFormSheetState extends State<_OrganizationFormSheet> {
  final nameCtrl = TextEditingController();
  final slugCtrl = TextEditingController();

  bool saving = false;
  bool slugTouched = false;
  String error = '';

  bool get isEditing => widget.organization != null;

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      nameCtrl.text = widget.organization?['name']?.toString() ?? '';
      slugCtrl.text = widget.organization?['slug']?.toString() ?? '';
      slugTouched = true;
    }

    nameCtrl.addListener(() {
      if (!slugTouched && !isEditing) {
        final generated = cleanSlug(nameCtrl.text);

        slugCtrl.text = generated;
        slugCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: slugCtrl.text.length),
        );
      }

      setState(() {});
    });

    slugCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    slugCtrl.dispose();
    super.dispose();
  }

  String cleanSlug(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9-]'), '')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  Future<void> save() async {
    final name = nameCtrl.text.trim();
    final slug = cleanSlug(slugCtrl.text);

    setState(() => error = '');

    if (name.isEmpty) {
      setState(() => error = 'Organization name is required');
      return;
    }

    if (slug.isEmpty) {
      setState(() => error = 'Slug is required');
      return;
    }

    if (slug.length < 3) {
      setState(() => error = 'Slug must be at least 3 characters');
      return;
    }

    setState(() => saving = true);

    try {
      if (isEditing) {
        await OrganizationService.update(
          id: widget.organization!['id'],
          name: name,
          slug: slug,
        );
      } else {
        await OrganizationService.create(name: name, slug: slug);
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        saving = false;
        error = AppError.clean(e);
      });

      await AppError.show(
        context,
        e,
        title: isEditing
            ? 'Could not update organization'
            : 'Could not create organization',
      );
    }
  }

  Widget progressHeader() {
    final nameReady = nameCtrl.text.trim().isNotEmpty;
    final slugReady = cleanSlug(slugCtrl.text).length >= 3;
    final readySteps = [nameReady, slugReady].where((value) => value).length;
    final progress = readySteps / 2;

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
                  child: Icon(
                    isEditing ? Icons.edit : Icons.add_business,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEditing ? 'Workspace update' : 'Workspace setup',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
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
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ruleRow('Organization name added', nameReady),
            ruleRow('Unique slug prepared', slugReady),
          ],
        ),
      ),
    );
  }

  Widget ruleRow(String label, bool passed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: passed ? Colors.green : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: passed ? Colors.green : Colors.grey.shade700,
                fontWeight: passed ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget previewCard() {
    final name = nameCtrl.text.trim().isEmpty
        ? 'Organization name'
        : nameCtrl.text.trim();

    final slug = cleanSlug(slugCtrl.text).isEmpty
        ? 'organization-slug'
        : cleanSlug(slugCtrl.text);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: primary.withOpacity(0.12),
              child: const Icon(Icons.business, color: primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    slug,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
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
    final title = isEditing ? 'Edit Organization' : 'Create Organization';
    final subtitle = isEditing
        ? 'Update workspace name and slug.'
        : 'Create a new company, landlord or agency workspace.';

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
                  child: Icon(
                    isEditing ? Icons.edit : Icons.add_business,
                    color: primary,
                    size: 30,
                  ),
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
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),

                const SizedBox(height: 18),

                progressHeader(),

                const SizedBox(height: 14),

                previewCard(),

                const SizedBox(height: 18),

                TextField(
                  controller: nameCtrl,
                  enabled: !saving,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Organization Name',
                    prefixIcon: Icon(Icons.business),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: slugCtrl,
                  enabled: !saving,
                  decoration: const InputDecoration(
                    labelText: 'Slug',
                    prefixIcon: Icon(Icons.link),
                    hintText: 'example-agency',
                  ),
                  onChanged: (value) {
                    slugTouched = true;

                    final clean = cleanSlug(value);

                    if (clean != value) {
                      slugCtrl.text = clean;
                      slugCtrl.selection = TextSelection.fromPosition(
                        TextPosition(offset: slugCtrl.text.length),
                      );
                    }
                  },
                ),

                const SizedBox(height: 14),

                const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Slug format'),
                    subtitle: Text(
                      'Use lowercase letters, numbers and hyphens. Slugs must be unique.',
                    ),
                  ),
                ),

                if (error.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  errorCard(),
                ],

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: saving ? null : save,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(isEditing ? Icons.save : Icons.add_business),
                    label: Text(
                      saving
                          ? 'Saving...'
                          : isEditing
                          ? 'Save Changes'
                          : 'Create Organization',
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(context, false),
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

class _OrganizationDetailsSheet extends StatelessWidget {
  final dynamic organization;
  final String name;
  final String slug;
  final bool active;
  final String initials;
  final String Function(dynamic value) formatDate;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDeactivate;
  final Future<void> Function() onReactivate;

  const _OrganizationDetailsSheet({
    required this.organization,
    required this.name,
    required this.slug,
    required this.active,
    required this.initials,
    required this.formatDate,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

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
    final color = active ? Colors.green : Colors.grey;

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
                  radius: 38,
                  backgroundColor: color.withOpacity(0.12),
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  slug,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),

                const SizedBox(height: 16),

                Chip(
                  avatar: Icon(
                    active ? Icons.check_circle : Icons.block,
                    color: color,
                    size: 18,
                  ),
                  label: Text(active ? 'ACTIVE' : 'INACTIVE'),
                  backgroundColor: color.withOpacity(0.12),
                  labelStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  side: BorderSide.none,
                ),

                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        infoRow('Name', name),
                        infoRow('Slug', slug),
                        infoRow('Status', active ? 'Active' : 'Inactive'),
                        infoRow(
                          'Created',
                          formatDate(organization['createdAt']),
                        ),
                        infoRow(
                          'Updated',
                          formatDate(organization['updatedAt']),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  color: primary.withOpacity(0.07),
                  child: ListTile(
                    leading: Icon(
                      active ? Icons.verified : Icons.pause_circle,
                      color: active ? Colors.green : Colors.grey,
                    ),
                    title: Text(
                      active ? 'Workspace is active' : 'Workspace is suspended',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      active
                          ? 'Assigned users can access and manage this organization normally.'
                          : 'Data is preserved, but assigned users should not use this workspace until reactivated.',
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => onEdit(),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Organization'),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: active
                        ? () => onDeactivate()
                        : () => onReactivate(),
                    icon: Icon(
                      active ? Icons.block : Icons.check_circle,
                      color: active ? Colors.red : Colors.green,
                    ),
                    label: Text(
                      active
                          ? 'Deactivate Organization'
                          : 'Reactivate Organization',
                      style: TextStyle(
                        color: active ? Colors.red : Colors.green,
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
        ),
      ),
    );
  }
}

class _OrganizationActionSheet extends StatelessWidget {
  final String title;
  final String message;
  final String organizationName;
  final String confirmLabel;
  final Color color;
  final IconData icon;

  const _OrganizationActionSheet({
    required this.title,
    required this.message,
    required this.organizationName,
    required this.confirmLabel,
    required this.color,
    required this.icon,
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
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 34),
              ),

              const SizedBox(height: 16),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                organizationName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  onPressed: () => Navigator.pop(context, true),
                  icon: Icon(icon),
                  label: Text(confirmLabel),
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
