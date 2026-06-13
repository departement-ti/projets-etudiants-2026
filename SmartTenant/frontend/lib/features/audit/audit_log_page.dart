import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ui/app_error.dart';
import 'audit_log_service.dart';

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key});

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  List<dynamic> logs = [];

  bool loading = true;
  bool refreshing = false;
  bool loadingMore = false;

  String error = '';
  String search = '';
  String section = 'ALL';
  String actionFilter = 'ALL';
  String resourceFilter = 'ALL';
  String sortMode = 'Newest';

  int page = 1;
  int totalPages = 1;
  int total = 0;

  final searchCtrl = TextEditingController();

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
    {'id': 'ALL', 'label': 'All', 'icon': Icons.dashboard_customize},
    {'id': 'CRITICAL', 'label': 'Critical', 'icon': Icons.warning_amber},
    {'id': 'FINANCE', 'label': 'Finance', 'icon': Icons.payments},
    {'id': 'USERS', 'label': 'Users', 'icon': Icons.people},
    {'id': 'ORG', 'label': 'Org', 'icon': Icons.apartment},
    {'id': 'TICKETS', 'label': 'Tickets', 'icon': Icons.construction},
  ];

  final actions = const [
    'ALL',
    'TICKET_CREATED',
    'TICKET_MESSAGE_ADDED',
    'TICKET_STATUS_UPDATED',
    'TICKET_ASSIGNED',
    'TICKET_UPDATED',
    'TICKET_DELETED',
    'LEASE_CREATED',
    'LEASE_TERMINATED',
    'PAYMENT_RECORDED',
    'USER_CREATED',
    'USER_UPDATED',
    'USER_PROFILE_UPDATED',
    'USER_PASSWORD_CHANGED',
    'USER_ROLE_CHANGED',
    'USER_DELETED',
    'ORGANIZATION_CREATED',
    'ORGANIZATION_UPDATED',
    'ORGANIZATION_DEACTIVATED',
    'ORGANIZATION_REACTIVATED',
    'USER_ASSIGNED_TO_ORGANIZATION',
  ];

  final resources = const [
    'ALL',
    'Ticket',
    'Lease',
    'Payment',
    'User',
    'Organization',
    'Property',
    'Unit',
    'Invoice',
  ];

  @override
  void initState() {
    super.initState();

    searchCtrl.addListener(() {
      setState(() => search = searchCtrl.text);
    });

    loadLogs(reset: true);
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> loadLogs({bool reset = false, bool silent = false}) async {
    if (reset) {
      setState(() {
        page = 1;
        error = '';
        if (silent) {
          refreshing = true;
        } else {
          loading = true;
        }
      });
    } else {
      setState(() => loadingMore = true);
    }

    try {
      final data = await AuditLogService.getLogs(
        page: reset ? 1 : page,
        limit: 25,
        action: actionFilter == 'ALL' ? null : actionFilter,
        resource: resourceFilter == 'ALL' ? null : resourceFilter,
      );

      final items = data['items'];
      final meta = data['meta'];

      if (!mounted) return;

      setState(() {
        if (reset) {
          logs = items is List ? items : [];
        } else {
          logs.addAll(items is List ? items : []);
        }

        total = meta?['total'] is int ? meta['total'] : logs.length;
        totalPages = meta?['totalPages'] is int ? meta['totalPages'] : 1;
        page = meta?['page'] is int ? meta['page'] : page;

        loading = false;
        refreshing = false;
        loadingMore = false;
        error = '';
      });
    } catch (e) {
      if (!mounted) return;

      if (silent) {
        setState(() {
          refreshing = false;
          loadingMore = false;
        });

        await AppError.show(
          context,
          e,
          title: 'Could not refresh activity logs',
        );

        return;
      }

      setState(() {
        error = AppError.clean(e);
        loading = false;
        refreshing = false;
        loadingMore = false;
      });
    }
  }

  Future<void> refreshLogs() async {
    await loadLogs(reset: true, silent: true);
  }

  Future<void> nextPage() async {
    if (loadingMore || page >= totalPages) return;

    setState(() => page += 1);

    await loadLogs(reset: false);
  }

  Future<void> copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied')));
  }

  void resetFilters() {
    setState(() {
      searchCtrl.clear();
      search = '';
      section = 'ALL';
      actionFilter = 'ALL';
      resourceFilter = 'ALL';
      sortMode = 'Newest';
    });

    loadLogs(reset: true, silent: true);
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

    return parsed.toLocal().toString().split('.')[0];
  }

  String friendlyAction(String action) {
    return action
        .split('_')
        .map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        })
        .join(' ');
  }

  String shortId(String value) {
    if (value.length <= 8) return value;
    return value.substring(0, 8);
  }

  String actorName(dynamic log) {
    final email = log['actorEmail']?.toString();
    final role = log['actorRole']?.toString();

    if (email != null && email.trim().isNotEmpty) {
      if (role != null && role.trim().isNotEmpty) return '$email • $role';
      return email;
    }

    return role == null || role.trim().isEmpty ? 'System' : 'System • $role';
  }

  String resourceLabel(dynamic log) {
    final resource = log['resource']?.toString() ?? 'Resource';
    final id = log['resourceId']?.toString();

    if (id == null || id.isEmpty) return resource;

    return '$resource • ${shortId(id)}';
  }

  String metadataPreview(dynamic log) {
    final metadata = log['metadata'];

    if (metadata is! Map) return 'No extra details';

    final direct =
        metadata['ticketTitle'] ??
        metadata['propertyTitle'] ??
        metadata['unitTitle'] ??
        metadata['tenantEmail'] ??
        metadata['assignedToEmail'] ??
        metadata['userEmail'] ??
        metadata['email'] ??
        metadata['organizationName'] ??
        metadata['organizationSlug'];

    if (direct != null) return direct.toString();

    final amount = metadata['amount'];
    final method = metadata['method'];

    if (amount != null) {
      return method == null ? 'Amount: $amount' : 'Amount: $amount • $method';
    }

    return 'Extra details available';
  }

  String prettyJson(dynamic value) {
    if (value == null) return 'No data';

    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  bool isCritical(dynamic log) {
    final action = log['action']?.toString() ?? '';

    return action.contains('DELETED') ||
        action.contains('TERMINATED') ||
        action.contains('DEACTIVATED') ||
        action.contains('PASSWORD') ||
        action.contains('ROLE_CHANGED');
  }

  bool matchesSection(dynamic log) {
    final action = log['action']?.toString() ?? '';
    final resource = log['resource']?.toString() ?? '';

    switch (section) {
      case 'CRITICAL':
        return isCritical(log);

      case 'FINANCE':
        return action.contains('PAYMENT') ||
            resource == 'Payment' ||
            resource == 'Invoice';

      case 'USERS':
        return action.contains('USER') || resource == 'User';

      case 'ORG':
        return action.contains('ORGANIZATION') || resource == 'Organization';

      case 'TICKETS':
        return action.contains('TICKET') || resource == 'Ticket';

      case 'ALL':
      default:
        return true;
    }
  }

  int severityRank(dynamic log) {
    if (isCritical(log)) return 0;

    final action = log['action']?.toString() ?? '';

    if (action.contains('PAYMENT')) return 1;
    if (action.contains('ASSIGNED') || action.contains('UPDATED')) return 2;
    if (action.contains('CREATED')) return 3;

    return 4;
  }

  List<dynamic> get filteredLogs {
    final query = search.trim().toLowerCase();

    final filtered = logs.where((log) {
      final searchable = [
        log['action'],
        log['resource'],
        log['resourceId'],
        log['actorEmail'],
        log['actorRole'],
        metadataPreview(log),
      ].join(' ').toLowerCase();

      final matchesSearch = query.isEmpty || searchable.contains(query);

      return matchesSearch && matchesSection(log);
    }).toList();

    filtered.sort((a, b) {
      switch (sortMode) {
        case 'Oldest':
          return parseDate(a['createdAt']).compareTo(parseDate(b['createdAt']));

        case 'Critical First':
          return severityRank(a).compareTo(severityRank(b));

        case 'Action':
          return (a['action']?.toString() ?? '').compareTo(
            b['action']?.toString() ?? '',
          );

        case 'Resource':
          return (a['resource']?.toString() ?? '').compareTo(
            b['resource']?.toString() ?? '',
          );

        case 'Actor':
          return actorName(a).compareTo(actorName(b));

        case 'Newest':
        default:
          return parseDate(b['createdAt']).compareTo(parseDate(a['createdAt']));
      }
    });

    return filtered;
  }

  int get createdCount {
    return logs.where((log) {
      return log['action']?.toString().contains('CREATED') == true;
    }).length;
  }

  int get updatedCount {
    return logs.where((log) {
      final action = log['action']?.toString() ?? '';
      return action.contains('UPDATED') || action.contains('ASSIGNED');
    }).length;
  }

  int get criticalCount => logs.where(isCritical).length;

  int get paymentCount {
    return logs.where((log) {
      return log['action']?.toString().contains('PAYMENT') == true;
    }).length;
  }

  int get userActivityCount {
    return logs.where((log) {
      final action = log['action']?.toString() ?? '';
      final resource = log['resource']?.toString() ?? '';

      return action.contains('USER') || resource == 'User';
    }).length;
  }

  int get ticketActivityCount {
    return logs.where((log) {
      final action = log['action']?.toString() ?? '';
      final resource = log['resource']?.toString() ?? '';

      return action.contains('TICKET') || resource == 'Ticket';
    }).length;
  }

  int get visibleCount => filteredLogs.length;

  String get healthLabel {
    if (criticalCount > 0) return 'Review critical events';
    if (paymentCount > 0) return 'Financial activity recorded';
    if (logs.isEmpty) return 'No activity yet';
    return 'Activity looks normal';
  }

  Color get healthColor {
    if (criticalCount > 0) return warning;
    if (logs.isEmpty) return Colors.grey;
    return success;
  }

  Color actionColor(String action) {
    if (action.contains('DELETED') ||
        action.contains('TERMINATED') ||
        action.contains('DEACTIVATED') ||
        action.contains('PASSWORD')) {
      return danger;
    }

    if (action.contains('PAYMENT')) return teal;
    if (action.contains('CREATED')) return success;
    if (action.contains('UPDATED')) return info;
    if (action.contains('ASSIGNED')) return warning;
    if (action.contains('MESSAGE')) return primary;
    if (action.contains('ROLE')) return purple;
    if (action.contains('REACTIVATED')) return success;

    return Colors.grey;
  }

  IconData actionIcon(String action) {
    if (action.contains('TICKET')) return Icons.construction;
    if (action.contains('LEASE')) return Icons.description;
    if (action.contains('PAYMENT')) return Icons.payments;
    if (action.contains('USER')) return Icons.person;
    if (action.contains('ORGANIZATION')) return Icons.apartment;
    if (action.contains('PROPERTY')) return Icons.home_work;
    if (action.contains('UNIT')) return Icons.home;
    if (action.contains('INVOICE')) return Icons.receipt_long;
    if (action.contains('DELETED')) return Icons.delete_outline;
    if (action.contains('MESSAGE')) return Icons.chat_bubble_outline;
    if (action.contains('PASSWORD')) return Icons.lock_reset;
    if (action.contains('ROLE')) return Icons.admin_panel_settings;

    return Icons.history;
  }

  String actionDescription(String action) {
    if (action.contains('DELETED')) {
      return 'A record was deleted and may require review.';
    }

    if (action.contains('TERMINATED')) {
      return 'A lease or business workflow was terminated.';
    }

    if (action.contains('DEACTIVATED')) {
      return 'A workspace or account was deactivated.';
    }

    if (action.contains('PAYMENT')) {
      return 'A financial event was recorded.';
    }

    if (action.contains('CREATED')) return 'A new record was created.';

    if (action.contains('UPDATED')) return 'A record was updated.';

    if (action.contains('ASSIGNED')) {
      return 'Responsibility or ownership was assigned.';
    }

    if (action.contains('MESSAGE')) {
      return 'A communication event was added.';
    }

    if (action.contains('ROLE')) {
      return 'A user role or permission level changed.';
    }

    return 'System activity was recorded.';
  }

  Future<void> openFiltersSheet() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AuditFilterSheet(
        actions: actions,
        resources: resources,
        actionFilter: actionFilter,
        resourceFilter: resourceFilter,
        sortMode: sortMode,
        friendlyAction: friendlyAction,
      ),
    );

    if (result == null) return;

    setState(() {
      actionFilter = result['action'] ?? actionFilter;
      resourceFilter = result['resource'] ?? resourceFilter;
      sortMode = result['sort'] ?? sortMode;
    });

    await loadLogs(reset: true, silent: true);
  }

  Future<void> openInsightsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AuditInsightsSheet(
        total: total,
        loaded: logs.length,
        visible: visibleCount,
        createdCount: createdCount,
        updatedCount: updatedCount,
        criticalCount: criticalCount,
        paymentCount: paymentCount,
        userActivityCount: userActivityCount,
        ticketActivityCount: ticketActivityCount,
        healthLabel: healthLabel,
        healthColor: healthColor,
      ),
    );
  }

  Future<void> openListSheet({
    required String title,
    required List<dynamic> items,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.84,
          minChildSize: 0.50,
          maxChildSize: 0.96,
          builder: (context, controller) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: softBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SafeArea(
                top: false,
                child: ListView(
                  controller: controller,
                  children: [
                    _dragHandle(),
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
                      emptyState(compact: true)
                    else
                      ...items.map(logCard),
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

  Widget heroHeader() {
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
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.history, color: healthColor, size: 30),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity Center',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Audit trail and business activity.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: refreshing || loading ? null : refreshLogs,
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                Icon(Icons.health_and_safety, color: healthColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$healthLabel • $visibleCount visible',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Loaded',
                  value: logs.length.toString(),
                  icon: Icons.list_alt,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: heroMetric(
                  title: 'Total',
                  value: total.toString(),
                  icon: Icons.storage,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: heroMetric(
                  title: 'Critical',
                  value: criticalCount.toString(),
                  icon: Icons.warning_amber,
                ),
              ),
            ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 21),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
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
                    onPressed: openInsightsSheet,
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
                    onPressed: resetFilters,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: refreshing || loading ? null : refreshLogs,
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget compactKpis() {
    final items = [
      _AuditKpi(
        title: 'Created',
        value: createdCount.toString(),
        icon: Icons.add_circle,
        color: success,
      ),
      _AuditKpi(
        title: 'Updated',
        value: updatedCount.toString(),
        icon: Icons.edit,
        color: info,
      ),
      _AuditKpi(
        title: 'Critical',
        value: criticalCount.toString(),
        icon: Icons.report,
        color: danger,
      ),
      _AuditKpi(
        title: 'Payments',
        value: paymentCount.toString(),
        icon: Icons.payments,
        color: teal,
      ),
      _AuditKpi(
        title: 'Users',
        value: userActivityCount.toString(),
        icon: Icons.people,
        color: purple,
      ),
      _AuditKpi(
        title: 'Tickets',
        value: ticketActivityCount.toString(),
        icon: Icons.construction,
        color: warning,
      ),
    ];

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final item = items[index];

          return SizedBox(
            width: 138,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: openInsightsSheet,
                child: Container(
                  padding: const EdgeInsets.all(13),
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
                        radius: 19,
                        backgroundColor: item.color.withOpacity(0.12),
                        child: Icon(item.icon, color: item.color, size: 20),
                      ),
                      const Spacer(),
                      Text(
                        item.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
            ),
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
          final item = sections[index];
          final id = item['id'] as String;
          final label = item['label'] as String;
          final icon = item['icon'] as IconData;
          final selected = section == id;

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
            onSelected: (_) => setState(() => section = id),
          );
        },
      ),
    );
  }

  Widget searchCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                labelText: 'Search activity',
                hintText: 'Action, resource, actor, ID...',
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$visibleCount visible',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Page $page / $totalPages',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (actionFilter != 'ALL' ||
                resourceFilter != 'ALL' ||
                sortMode != 'Newest') ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (actionFilter != 'ALL')
                    activeFilterChip(friendlyAction(actionFilter)),
                  if (resourceFilter != 'ALL') activeFilterChip(resourceFilter),
                  if (sortMode != 'Newest') activeFilterChip(sortMode),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget activeFilterChip(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: primary.withOpacity(0.10),
      labelStyle: const TextStyle(
        color: primary,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      side: BorderSide.none,
    );
  }

  Widget sectionSummaryCard() {
    final data = filteredLogs;
    final shown = data.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primary.withOpacity(0.12),
                  child: const Icon(Icons.view_agenda, color: primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section == 'ALL' ? 'Latest Activity' : '$section Activity',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => openListSheet(
                    title: section == 'ALL'
                        ? 'All Visible Activity'
                        : '$section Activity',
                    items: data,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (shown.isEmpty)
              emptyState(compact: true)
            else
              ...shown.map(compactLogTile),
            if (data.length > shown.length) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => openListSheet(
                    title: section == 'ALL'
                        ? 'All Visible Activity'
                        : '$section Activity',
                    items: data,
                  ),
                  icon: const Icon(Icons.expand_more),
                  label: Text('View ${data.length - shown.length} more'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget compactLogTile(dynamic log) {
    final action = log['action']?.toString() ?? 'UNKNOWN';
    final color = actionColor(action);

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.12),
        child: Icon(actionIcon(action), color: color, size: 20),
      ),
      title: Text(
        friendlyAction(action),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${resourceLabel(log)}\n${actorName(log)}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showLogDetails(log),
    );
  }

  Widget logCard(dynamic log) {
    final action = log['action']?.toString() ?? 'UNKNOWN';
    final resource = log['resource']?.toString() ?? 'Log';
    final color = actionColor(action);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => showLogDetails(log),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: color.withOpacity(0.12),
                    child: Icon(actionIcon(action), color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friendlyAction(action),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          resourceLabel(log),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          actorName(log),
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
                  Chip(
                    label: Text(resource),
                    backgroundColor: color.withOpacity(0.12),
                    labelStyle: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    side: BorderSide.none,
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
                child: Text(
                  '${metadataPreview(log)} • ${formatDate(log['createdAt'])}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showLogDetails(dynamic log) {
    final action = log['action']?.toString() ?? 'UNKNOWN';
    final color = actionColor(action);
    final resourceId = log['resourceId']?.toString() ?? '';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.86,
          minChildSize: 0.50,
          maxChildSize: 0.96,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: softBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SafeArea(
                top: false,
                child: ListView(
                  controller: controller,
                  children: [
                    _dragHandle(),
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: color.withOpacity(0.12),
                      child: Icon(actionIcon(action), color: color, size: 36),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      friendlyAction(action),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      resourceLabel(log),
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
                          label: Text(log['resource']?.toString() ?? 'Log'),
                          backgroundColor: color.withOpacity(0.12),
                          labelStyle: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                          side: BorderSide.none,
                        ),
                        if (isCritical(log))
                          Chip(
                            avatar: const Icon(
                              Icons.warning_amber,
                              color: danger,
                              size: 18,
                            ),
                            label: const Text('Critical'),
                            backgroundColor: danger.withOpacity(0.12),
                            labelStyle: const TextStyle(
                              color: danger,
                              fontWeight: FontWeight.bold,
                            ),
                            side: BorderSide.none,
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Card(
                      color: color.withOpacity(0.07),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: color.withOpacity(0.12),
                              child: Icon(Icons.insights, color: color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                actionDescription(action),
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    detailsCard('Overview', {
                      'Action': friendlyAction(action),
                      'Resource': log['resource'],
                      'Resource ID': log['resourceId'],
                      'Actor': actorName(log),
                      'Created': formatDate(log['createdAt']),
                    }),
                    if (resourceId.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => copyText(resourceId),
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy Resource ID'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    jsonCard('Metadata', log['metadata'], color),
                    jsonCard('Before', log['before'], Colors.orange),
                    jsonCard('After', log['after'], Colors.green),
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

  Widget detailsCard(String title, Map<String, dynamic> values) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...values.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 105,
                      child: Text(
                        '${entry.key}:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        entry.value?.toString() ?? '—',
                        maxLines: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget jsonCard(String title, dynamic value, Color color) {
    final text = prettyJson(value);

    return Card(
      child: ExpansionTile(
        leading: Icon(Icons.data_object, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(text),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => copyText(text),
                icon: const Icon(Icons.copy),
                label: Text('Copy $title'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyState({bool compact = false}) {
    final noMatches = logs.isNotEmpty && filteredLogs.isEmpty;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 28),
        child: Column(
          children: [
            Icon(
              noMatches ? Icons.search_off : Icons.history,
              size: compact ? 42 : 62,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            Text(
              noMatches
                  ? 'No logs match your filters'
                  : 'No activity logs found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 17 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              noMatches
                  ? 'Try changing search, filters or section.'
                  : 'Important actions will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            if (!compact) ...[
              const SizedBox(height: 16),
              if (noMatches)
                OutlinedButton.icon(
                  onPressed: resetFilters,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset Filters'),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => loadLogs(reset: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget loadMoreButton() {
    if (page >= totalPages) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: loadingMore ? null : nextPage,
        icon: loadingMore
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.expand_more),
        label: Text(loadingMore ? 'Loading...' : 'Load More From Server'),
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
      onRefresh: () => loadLogs(reset: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 120),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: danger, size: 42),
                  const SizedBox(height: 12),
                  const Text(
                    'Could not load activity logs',
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
                    onPressed: () => loadLogs(reset: true),
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

  Widget bodyContent() {
    return RefreshIndicator(
      onRefresh: refreshLogs,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          heroHeader(),
          const SizedBox(height: 16),
          quickActions(),
          const SizedBox(height: 14),
          compactKpis(),
          const SizedBox(height: 16),
          sectionSelector(),
          const SizedBox(height: 14),
          searchCard(),
          const SizedBox(height: 14),
          sectionSummaryCard(),
          const SizedBox(height: 12),
          loadMoreButton(),
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
          'Activity Center',
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
            onPressed: logs.isEmpty ? null : openInsightsSheet,
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
            onPressed: refreshing || loading ? null : refreshLogs,
          ),
        ],
      ),
      body: loading
          ? loadingBody()
          : error.isNotEmpty
          ? errorBody()
          : bodyContent(),
    );
  }
}

class _AuditKpi {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AuditKpi({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _AuditFilterSheet extends StatefulWidget {
  final List<String> actions;
  final List<String> resources;
  final String actionFilter;
  final String resourceFilter;
  final String sortMode;
  final String Function(String action) friendlyAction;

  const _AuditFilterSheet({
    required this.actions,
    required this.resources,
    required this.actionFilter,
    required this.resourceFilter,
    required this.sortMode,
    required this.friendlyAction,
  });

  @override
  State<_AuditFilterSheet> createState() => _AuditFilterSheetState();
}

class _AuditFilterSheetState extends State<_AuditFilterSheet> {
  late String actionFilter;
  late String resourceFilter;
  late String sortMode;

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  @override
  void initState() {
    super.initState();

    actionFilter = widget.actionFilter;
    resourceFilter = widget.resourceFilter;
    sortMode = widget.sortMode;
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
              _dragHandle(),
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFFEDE9FE),
                child: Icon(Icons.filter_alt, color: primary, size: 34),
              ),
              const SizedBox(height: 14),
              const Text(
                'Audit Filters',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Filter by action, resource and sort mode.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                value: actionFilter,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Action',
                  prefixIcon: Icon(Icons.bolt),
                ),
                items: widget.actions.map((action) {
                  return DropdownMenuItem<String>(
                    value: action,
                    child: Text(
                      action == 'ALL'
                          ? 'All actions'
                          : widget.friendlyAction(action),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => actionFilter = value);
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: resourceFilter,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Resource',
                  prefixIcon: Icon(Icons.category),
                ),
                items: widget.resources.map((resource) {
                  return DropdownMenuItem<String>(
                    value: resource,
                    child: Text(
                      resource == 'ALL' ? 'All resources' : resource,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => resourceFilter = value);
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: sortMode,
                decoration: const InputDecoration(
                  labelText: 'Sort',
                  prefixIcon: Icon(Icons.sort),
                ),
                items: const [
                  DropdownMenuItem(value: 'Newest', child: Text('Newest')),
                  DropdownMenuItem(value: 'Oldest', child: Text('Oldest')),
                  DropdownMenuItem(
                    value: 'Critical First',
                    child: Text('Critical First'),
                  ),
                  DropdownMenuItem(value: 'Action', child: Text('Action')),
                  DropdownMenuItem(value: 'Resource', child: Text('Resource')),
                  DropdownMenuItem(value: 'Actor', child: Text('Actor')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => sortMode = value);
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          actionFilter = 'ALL';
                          resourceFilter = 'ALL';
                          sortMode = 'Newest';
                        });
                      },
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context, {
                          'action': actionFilter,
                          'resource': resourceFilter,
                          'sort': sortMode,
                        });
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Apply'),
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
}

class _AuditInsightsSheet extends StatelessWidget {
  final int total;
  final int loaded;
  final int visible;
  final int createdCount;
  final int updatedCount;
  final int criticalCount;
  final int paymentCount;
  final int userActivityCount;
  final int ticketActivityCount;
  final String healthLabel;
  final Color healthColor;

  const _AuditInsightsSheet({
    required this.total,
    required this.loaded,
    required this.visible,
    required this.createdCount,
    required this.updatedCount,
    required this.criticalCount,
    required this.paymentCount,
    required this.userActivityCount,
    required this.ticketActivityCount,
    required this.healthLabel,
    required this.healthColor,
  });

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.50,
      maxChildSize: 0.96,
      builder: (context, controller) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: softBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              controller: controller,
              children: [
                _dragHandle(),
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 38,
                  backgroundColor: healthColor.withOpacity(0.12),
                  child: Icon(Icons.insights, color: healthColor, size: 38),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Audit Intelligence',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Security and business activity overview',
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
                Card(
                  color: healthColor.withOpacity(0.07),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: healthColor.withOpacity(0.12),
                          child: Icon(Icons.monitor_heart, color: healthColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            criticalCount > 0
                                ? '$criticalCount critical events should be reviewed.'
                                : 'No critical audit events in the loaded activity.',
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
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
                        infoRow('Total Logs', total),
                        infoRow('Loaded Logs', loaded),
                        infoRow('Visible Logs', visible),
                        infoRow('Created', createdCount),
                        infoRow('Updated / Assigned', updatedCount),
                        infoRow('Critical', criticalCount),
                        infoRow('Payments', paymentCount),
                        infoRow('User Activity', userActivityCount),
                        infoRow('Ticket Activity', ticketActivityCount),
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
                      criticalCount > 0
                          ? 'Review deletions, terminations, password changes and role changes regularly.'
                          : 'Use audit logs to trace who changed what, when it happened, and which resource was affected.',
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

  Widget infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
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
