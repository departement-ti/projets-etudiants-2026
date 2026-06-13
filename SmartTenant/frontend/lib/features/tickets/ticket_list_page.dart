import 'package:flutter/material.dart';

import '../../core/ui/app_error.dart';
import 'create_ticket_page.dart';
import 'ticket_details_page.dart';
import 'ticket_service.dart';
import '../../core/auth/auth_storage.dart';

class TicketListPage extends StatefulWidget {
  const TicketListPage({super.key});

  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage> {
  List<dynamic> tickets = [];

  bool loading = true;
  bool refreshing = false;
  String error = '';

  String statusFilter = 'ALL';
  String priorityFilter = 'ALL';
  String assignmentFilter = 'ALL';
  String sortMode = 'Newest';
  String viewMode = 'CARDS';
  String? role;
  String? currentUserId;

  final searchCtrl = TextEditingController();

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);
  static const darkText = Color(0xFF1D1B20);

  final statuses = const ['ALL', 'OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'];

  final priorities = const ['ALL', 'urgent', 'high', 'medium', 'low'];

  final assignments = const ['ALL', 'ASSIGNED', 'UNASSIGNED'];

  @override
  void initState() {
    super.initState();
    searchCtrl.addListener(() => setState(() {}));
    loadTickets();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  bool get canCreateTicket {
    return role == 'ADMIN' ||
        role == 'OWNER' ||
        role == 'ASSISTANT' ||
        role == 'TENANT';
  }

  Future<void> loadTickets({bool silent = false}) async {
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
      final userId = await AuthStorage.getUserId();

      final data = await TicketService.getAll();

      final visibleTickets = userRole == 'AGENT'
          ? data.where((ticket) {
              return ticket['assignedToId']?.toString() == userId;
            }).toList()
          : data;

      if (!mounted) return;

      setState(() {
        role = userRole;
        currentUserId = userId;
        tickets = visibleTickets;

        if (userRole == 'AGENT') {
          assignmentFilter = 'ALL';
        }

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

  Future<void> openCreateTicket() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateTicketPage()),
    );

    if (created == true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket created successfully')),
      );

      await loadTickets(silent: true);
    }
  }

  Future<void> openTicketDetails(dynamic ticket) async {
    final id = ticket['id']?.toString();

    if (id == null || id.isEmpty) {
      await AppError.show(
        context,
        'This ticket does not have a valid identifier.',
        title: 'Cannot open ticket',
      );
      return;
    }

    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TicketDetailsPage(ticketId: id)),
    );

    if (changed == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ticket updated')));
    }

    await loadTickets(silent: true);
  }

  Future<void> openTicketPreview(dynamic ticket) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TicketPreviewSheet(
        ticket: ticket,
        title: ticketTitle(ticket),
        description: ticketDescription(ticket),
        status: ticketStatus(ticket),
        priority: ticketPriority(ticket),
        propertyName: propertyName(ticket),
        unitName: unitName(ticket),
        creatorName: creatorName(ticket),
        assignedName: assignedName(ticket),
        createdAt: formatDateTime(ticket['createdAt']),
        updatedAt: formatDateTime(ticket['updatedAt']),
        messagesCount: messagesCount(ticket),
        ageLabel: ticketAgeLabel(ticket),
        healthScore: ticketHealthScore(ticket),
        healthLabel: ticketHealthLabel(ticket),
        healthColor: ticketHealthColor(ticket),
        statusColor: statusColor,
        statusIcon: statusIcon,
        priorityColor: priorityColor,
        priorityIcon: priorityIcon,
        onOpenDetails: () async {
          Navigator.pop(context);
          await openTicketDetails(ticket);
        },
      ),
    );
  }

  Future<void> openTicketsInsight() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TicketsInsightSheet(
        totalTickets: tickets.length,
        openCount: openCount,
        inProgressCount: inProgressCount,
        resolvedCount: resolvedCount,
        closedCount: closedCount,
        urgentCount: urgentCount,
        highCount: highCount,
        unassignedCount: unassignedCount,
        assignedCount: assignedCount,
        averageAgeDays: averageAgeDays,
        completionRate: completionRate,
        responseCoverage: responseCoverage,
        workloadHealth: workloadHealthLabel(),
        workloadColor: workloadHealthColor(),
      ),
    );
  }

  void resetFilters() {
    setState(() {
      searchCtrl.clear();
      statusFilter = 'ALL';
      priorityFilter = 'ALL';
      assignmentFilter = 'ALL';
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

  String formatDateTime(dynamic value) {
    if (value == null) return '—';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    return parsed.toLocal().toString().split('.')[0];
  }

  String ticketTitle(dynamic ticket) {
    final value = ticket['title']?.toString();

    if (value == null || value.trim().isEmpty) return 'Ticket';

    return value.trim();
  }

  String ticketDescription(dynamic ticket) {
    final value = ticket['description']?.toString();

    if (value == null || value.trim().isEmpty) {
      return 'No description provided';
    }

    return value.trim();
  }

  String ticketStatus(dynamic ticket) {
    return ticket['status']?.toString() ?? 'OPEN';
  }

  String ticketPriority(dynamic ticket) {
    return ticket['priority']?.toString() ?? 'medium';
  }

  String creatorName(dynamic ticket) {
    final user = ticket['createdBy'];

    if (user != null) {
      final firstName = user['firstName']?.toString() ?? '';
      final lastName = user['lastName']?.toString() ?? '';
      final email = user['email']?.toString() ?? '';

      final fullName = '$firstName $lastName'.trim();

      if (fullName.isNotEmpty) return fullName;
      if (email.isNotEmpty) return email;
    }

    return 'User';
  }

  String assignedName(dynamic ticket) {
    final user = ticket['assignedTo'];

    if (user != null) {
      final firstName = user['firstName']?.toString() ?? '';
      final lastName = user['lastName']?.toString() ?? '';
      final email = user['email']?.toString() ?? '';

      final fullName = '$firstName $lastName'.trim();

      if (fullName.isNotEmpty) return fullName;
      if (email.isNotEmpty) return email;
    }

    return 'Unassigned';
  }

  String propertyName(dynamic ticket) {
    final property = ticket['property'];

    if (property != null) {
      return property['title']?.toString() ??
          property['name']?.toString() ??
          property['address']?.toString() ??
          'Property';
    }

    return 'No property';
  }

  String unitName(dynamic ticket) {
    final unit = ticket['unit'];

    if (unit != null) {
      return unit['title']?.toString() ?? unit['number']?.toString() ?? 'Unit';
    }

    return 'No unit';
  }

  int messagesCount(dynamic ticket) {
    final messages = ticket['messages'];

    if (messages is List) return messages.length;

    final count = ticket['messagesCount'];
    if (count is num) return count.toInt();

    return 0;
  }

  bool isAssigned(dynamic ticket) {
    return ticket['assignedTo'] != null || ticket['assignedToId'] != null;
  }

  int ticketAgeDays(dynamic ticket) {
    final createdAt = parseDate(ticket['createdAt']);

    if (createdAt.millisecondsSinceEpoch == 0) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final createdDay = DateTime(createdAt.year, createdAt.month, createdAt.day);

    return today.difference(createdDay).inDays.clamp(0, 999999);
  }

  String ticketAgeLabel(dynamic ticket) {
    final days = ticketAgeDays(ticket);

    if (days == 0) return 'Created today';
    if (days == 1) return '1 day old';

    return '$days days old';
  }

  bool isOpenLike(dynamic ticket) {
    final status = ticketStatus(ticket);

    return status == 'OPEN' || status == 'IN_PROGRESS';
  }

  bool isClosedLike(dynamic ticket) {
    final status = ticketStatus(ticket);

    return status == 'RESOLVED' || status == 'CLOSED';
  }

  int priorityRank(dynamic value) {
    switch (value?.toString()) {
      case 'urgent':
        return 0;
      case 'high':
        return 1;
      case 'medium':
        return 2;
      case 'low':
        return 3;
      default:
        return 4;
    }
  }

  int statusRank(String status) {
    switch (status) {
      case 'OPEN':
        return 0;
      case 'IN_PROGRESS':
        return 1;
      case 'RESOLVED':
        return 2;
      case 'CLOSED':
        return 3;
      default:
        return 4;
    }
  }

  List<dynamic> get filteredTickets {
    final query = searchCtrl.text.trim().toLowerCase();

    final filtered = tickets.where((ticket) {
      final status = ticketStatus(ticket);
      final priority = ticketPriority(ticket);

      final searchable = [
        ticketTitle(ticket),
        ticketDescription(ticket),
        propertyName(ticket),
        unitName(ticket),
        creatorName(ticket),
        assignedName(ticket),
        status,
        priority,
      ].join(' ').toLowerCase();

      final matchesSearch = query.isEmpty || searchable.contains(query);
      final matchesStatus = statusFilter == 'ALL' || status == statusFilter;
      final matchesPriority =
          priorityFilter == 'ALL' || priority == priorityFilter;

      final matchesAssignment = role == 'AGENT'
          ? true
          : assignmentFilter == 'ALL'
          ? true
          : assignmentFilter == 'ASSIGNED'
          ? isAssigned(ticket)
          : !isAssigned(ticket);

      return matchesSearch &&
          matchesStatus &&
          matchesPriority &&
          matchesAssignment;
    }).toList();

    filtered.sort((a, b) {
      switch (sortMode) {
        case 'Oldest':
          return parseDate(a['createdAt']).compareTo(parseDate(b['createdAt']));

        case 'Priority':
          return priorityRank(
            a['priority'],
          ).compareTo(priorityRank(b['priority']));

        case 'Status':
          return statusRank(
            ticketStatus(a),
          ).compareTo(statusRank(ticketStatus(b)));

        case 'Title':
          return ticketTitle(a).compareTo(ticketTitle(b));

        case 'Assigned':
          return assignedName(a).compareTo(assignedName(b));

        case 'Age':
          return ticketAgeDays(b).compareTo(ticketAgeDays(a));

        case 'Messages':
          return messagesCount(b).compareTo(messagesCount(a));

        case 'Newest':
        default:
          return parseDate(b['createdAt']).compareTo(parseDate(a['createdAt']));
      }
    });

    return filtered;
  }

  int statusCount(String status) {
    return tickets.where((ticket) => ticketStatus(ticket) == status).length;
  }

  int priorityCount(String priority) {
    return tickets.where((ticket) => ticketPriority(ticket) == priority).length;
  }

  int get openCount => statusCount('OPEN');
  int get inProgressCount => statusCount('IN_PROGRESS');
  int get resolvedCount => statusCount('RESOLVED');
  int get closedCount => statusCount('CLOSED');
  int get urgentOnlyCount => priorityCount('urgent');
  int get highCount => priorityCount('high');
  int get urgentCount => priorityCount('urgent') + priorityCount('high');

  int get assignedCount {
    return tickets.where(isAssigned).length;
  }

  int get unassignedCount {
    return tickets.where((ticket) => !isAssigned(ticket)).length;
  }

  int get openWorkload {
    return tickets.where(isOpenLike).length;
  }

  double get completionRate {
    if (tickets.isEmpty) return 0;

    return ((resolvedCount + closedCount) / tickets.length) * 100;
  }

  double get responseCoverage {
    if (tickets.isEmpty) return 0;

    final withMessages = tickets.where((ticket) {
      return messagesCount(ticket) > 0;
    }).length;

    return (withMessages / tickets.length) * 100;
  }

  double get averageAgeDays {
    final active = tickets.where(isOpenLike).toList();

    if (active.isEmpty) return 0;

    final total = active.fold<int>(0, (sum, ticket) {
      return sum + ticketAgeDays(ticket);
    });

    return total / active.length;
  }

  String workloadHealthLabel() {
    if (tickets.isEmpty) return 'No tickets yet';
    if (urgentCount > 0 || unassignedCount > 0) return 'Needs attention';
    if (completionRate >= 75) return 'Healthy';
    if (completionRate >= 45) return 'Moderate';

    return 'Busy';
  }

  Color workloadHealthColor() {
    if (tickets.isEmpty) return Colors.grey;
    if (urgentCount > 0 || unassignedCount > 0) return Colors.orange;
    if (completionRate >= 75) return Colors.green;
    if (completionRate >= 45) return primary;

    return Colors.red;
  }

  int ticketHealthScore(dynamic ticket) {
    final status = ticketStatus(ticket);
    final priority = ticketPriority(ticket);
    final age = ticketAgeDays(ticket);

    if (status == 'CLOSED') return 100;
    if (status == 'RESOLVED') return 90;

    int score = 70;

    if (status == 'IN_PROGRESS') score += 10;
    if (isAssigned(ticket)) score += 10;
    if (messagesCount(ticket) > 0) score += 10;

    if (priority == 'urgent') score -= 25;
    if (priority == 'high') score -= 15;
    if (age >= 7) score -= 20;
    if (age >= 14) score -= 20;

    return score.clamp(0, 100);
  }

  String ticketHealthLabel(dynamic ticket) {
    final status = ticketStatus(ticket);

    if (status == 'CLOSED') return 'Closed';
    if (status == 'RESOLVED') return 'Resolved';
    if (ticketPriority(ticket) == 'urgent') return 'Urgent';
    if (!isAssigned(ticket)) return 'Unassigned';
    if (ticketAgeDays(ticket) >= 7) return 'Aging';

    return 'On track';
  }

  Color ticketHealthColor(dynamic ticket) {
    final label = ticketHealthLabel(ticket);

    switch (label) {
      case 'Closed':
        return Colors.grey;
      case 'Resolved':
      case 'On track':
        return Colors.green;
      case 'Urgent':
      case 'Aging':
        return Colors.red;
      case 'Unassigned':
        return Colors.orange;
      default:
        return primary;
    }
  }

  Color statusColor(String? status) {
    switch (status) {
      case 'OPEN':
        return Colors.red;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'RESOLVED':
        return Colors.green;
      case 'CLOSED':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  IconData statusIcon(String? status) {
    switch (status) {
      case 'OPEN':
        return Icons.report_problem;
      case 'IN_PROGRESS':
        return Icons.sync;
      case 'RESOLVED':
        return Icons.check_circle;
      case 'CLOSED':
        return Icons.lock;
      default:
        return Icons.construction;
    }
  }

  String statusDescription(String? status) {
    switch (status) {
      case 'OPEN':
        return 'New or waiting for staff action.';
      case 'IN_PROGRESS':
        return 'Currently being handled by the team.';
      case 'RESOLVED':
        return 'Work is completed and ready to close.';
      case 'CLOSED':
        return 'Ticket is closed and archived for history.';
      default:
        return 'Ticket status information is unavailable.';
    }
  }

  Color priorityColor(String? priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData priorityIcon(String? priority) {
    switch (priority) {
      case 'urgent':
        return Icons.priority_high;
      case 'high':
        return Icons.keyboard_double_arrow_up;
      case 'medium':
        return Icons.remove_circle_outline;
      case 'low':
        return Icons.keyboard_arrow_down;
      default:
        return Icons.flag;
    }
  }

  String initials(dynamic ticket) {
    final clean = ticketTitle(ticket).trim();

    if (clean.isEmpty) return 'T';

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
    final doneRate = completionRate.round();
    final healthColor = workloadHealthColor();

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
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.construction, color: primary, size: 32),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ticket Command Center',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Track tenant requests, priorities, assignments and progress.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: refreshing ? null : () => loadTickets(silent: true),
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
                avatar: Icon(
                  Icons.health_and_safety,
                  color: healthColor,
                  size: 18,
                ),
                label: Text(workloadHealthLabel()),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: healthColor,
                  fontWeight: FontWeight.bold,
                ),
                side: BorderSide.none,
              ),
              Chip(
                avatar: const Icon(Icons.folder_copy, color: primary, size: 18),
                label: Text('${tickets.length} tickets'),
                backgroundColor: Colors.white,
                labelStyle: const TextStyle(
                  color: primary,
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
                  title: 'Open',
                  value: openCount.toString(),
                  icon: Icons.report_problem,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'In Progress',
                  value: inProgressCount.toString(),
                  icon: Icons.sync,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Urgent / High',
                  value: urgentCount.toString(),
                  icon: Icons.priority_high,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Unassigned',
                  value: unassignedCount.toString(),
                  icon: Icons.person_search,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Completion',
                  value: '$doneRate%',
                  icon: Icons.pie_chart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Avg Age',
                  value: '${averageAgeDays.toStringAsFixed(1)}d',
                  icon: Icons.schedule,
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
                  urgentCount > 0 || unassignedCount > 0
                      ? 'Some tickets need quick follow-up or assignment.'
                      : 'Ticket workload is currently under control.',
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
              value: (completionRate / 100).clamp(0, 1),
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          const SizedBox(height: 18),
          if (canCreateTicket) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: openCreateTicket,
                icon: const Icon(Icons.add_task),
                label: const Text('Create Ticket'),
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
                    onPressed: tickets.isEmpty ? null : openTicketsInsight,
                    icon: const Icon(Icons.insights),
                    label: const Text('Insights'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: refreshing
                        ? null
                        : () => loadTickets(silent: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (canCreateTicket)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: openCreateTicket,
                  icon: const Icon(Icons.add_task),
                  label: const Text('Create New Ticket'),
                ),
              ),
          ],
        ),
      ),
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

  Widget summaryStrip() {
    return Row(
      children: [
        Expanded(
          child: miniSummaryCard(
            title: 'Resolved',
            value: resolvedCount.toString(),
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: miniSummaryCard(
            title: 'Closed',
            value: closedCount.toString(),
            icon: Icons.lock,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: miniSummaryCard(
            title: 'Messages',
            value: tickets.fold<int>(0, (sum, ticket) {
              return sum + messagesCount(ticket);
            }).toString(),
            icon: Icons.chat_bubble,
            color: primary,
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
                labelText: 'Search tickets',
                hintText: 'Title, property, unit, creator, assigned staff...',
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

            const SizedBox(height: 10),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: priorities.map(priorityFilterChip).toList()),
            ),

            if (role != 'AGENT') ...[
              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: assignments.map(assignmentFilterChip).toList(),
                ),
              ),
            ],

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
                        value: 'Priority',
                        child: Text('Priority'),
                      ),
                      DropdownMenuItem(value: 'Status', child: Text('Status')),
                      DropdownMenuItem(value: 'Title', child: Text('Title')),
                      DropdownMenuItem(
                        value: 'Assigned',
                        child: Text('Assigned'),
                      ),
                      DropdownMenuItem(value: 'Age', child: Text('Age')),
                      DropdownMenuItem(
                        value: 'Messages',
                        child: Text('Messages'),
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

  Widget statusFilterChip(String status) {
    final active = statusFilter == status;
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
        onSelected: (_) => setState(() => statusFilter = status),
      ),
    );
  }

  Widget priorityFilterChip(String priority) {
    final active = priorityFilter == priority;
    final color = priority == 'ALL' ? primary : priorityColor(priority);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: active,
        label: Text(priority == 'ALL' ? 'ALL PRIORITIES' : priority),
        avatar: Icon(
          priority == 'ALL' ? Icons.flag : priorityIcon(priority),
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
        onSelected: (_) => setState(() => priorityFilter = priority),
      ),
    );
  }

  Widget assignmentFilterChip(String assignment) {
    final active = assignmentFilter == assignment;

    final color = assignment == 'UNASSIGNED'
        ? Colors.orange
        : assignment == 'ASSIGNED'
        ? Colors.green
        : primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: active,
        label: Text(assignment),
        avatar: Icon(
          assignment == 'UNASSIGNED'
              ? Icons.person_search
              : assignment == 'ASSIGNED'
              ? Icons.assignment_ind
              : Icons.all_inclusive,
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
        onSelected: (_) => setState(() => assignmentFilter = assignment),
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

  Widget statusChip(String status) {
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

  Widget priorityBadge(String priority) {
    final color = priorityColor(priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(priorityIcon(priority), color: color, size: 15),
          const SizedBox(width: 5),
          Text(
            priority,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget healthBadge(dynamic ticket) {
    final color = ticketHealthColor(ticket);
    final score = ticketHealthScore(ticket);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.health_and_safety, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${ticketHealthLabel(ticket)} • $score% ticket health',
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

  Widget ticketCard(dynamic ticket) {
    final status = ticketStatus(ticket);
    final priority = ticketPriority(ticket);
    final color = statusColor(status);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => openTicketPreview(ticket),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: color.withOpacity(0.12),
                    child: Icon(statusIcon(status), color: color),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticketTitle(ticket),
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
                          '${propertyName(ticket)} • ${unitName(ticket)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'By: ${creatorName(ticket)}',
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
                      if (value == 'preview') openTicketPreview(ticket);
                      if (value == 'details') openTicketDetails(ticket);
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

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: softBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(Icons.assignment_ind, size: 18, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Assigned: ${assignedName(ticket)} • ${ticketAgeLabel(ticket)} • ${messagesCount(ticket)} message${messagesCount(ticket) == 1 ? '' : 's'}',
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

              healthBadge(ticket),

              const SizedBox(height: 12),

              Row(
                children: [
                  statusChip(status),
                  const SizedBox(width: 8),
                  priorityBadge(priority),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => openTicketDetails(ticket),
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

  Widget compactTicketTile(dynamic ticket) {
    final status = ticketStatus(ticket);
    final priority = ticketPriority(ticket);
    final color = statusColor(status);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(statusIcon(status), color: color),
        ),
        title: Text(
          ticketTitle(ticket),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${propertyName(ticket)} • ${unitName(ticket)}\n'
          '${assignedName(ticket)} • ${ticketAgeLabel(ticket)} • $priority',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: statusChip(status),
        onTap: () => openTicketPreview(ticket),
      ),
    );
  }

  Widget emptyState({required bool noMatches}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              noMatches ? Icons.search_off : Icons.construction,
              size: 62,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            Text(
              noMatches
                  ? 'No tickets match your filters'
                  : role == 'AGENT'
                  ? 'No assigned tickets yet'
                  : 'No tickets found',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              noMatches
                  ? 'Try changing the search, status, priority or assignment filters.'
                  : role == 'AGENT'
                  ? 'Tickets assigned to you by an assistant, owner or admin will appear here.'
                  : 'Create a ticket to start tracking maintenance requests.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            if (noMatches)
              OutlinedButton.icon(
                onPressed: resetFilters,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset Filters'),
              )
            else if (canCreateTicket)
              ElevatedButton.icon(
                onPressed: openCreateTicket,
                icon: const Icon(Icons.add_task),
                label: const Text('Create Ticket'),
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
      onRefresh: () => loadTickets(),
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
                    'Could not load tickets',
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
                    onPressed: () => loadTickets(),
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
    final data = filteredTickets;

    return RefreshIndicator(
      onRefresh: () => loadTickets(silent: true),
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

          if (tickets.isEmpty)
            emptyState(noMatches: false)
          else if (data.isEmpty)
            emptyState(noMatches: true)
          else if (viewMode == 'COMPACT')
            ...data.map(compactTicketTile)
          else
            ...data.map(ticketCard),

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
          'Tickets',
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
            onPressed: refreshing ? null : () => loadTickets(silent: true),
          ),
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: tickets.isEmpty ? null : openTicketsInsight,
          ),
          if (canCreateTicket)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: openCreateTicket,
            ),
        ],
      ),
      floatingActionButton: canCreateTicket
          ? FloatingActionButton.extended(
              onPressed: openCreateTicket,
              icon: const Icon(Icons.add_task),
              label: const Text('Ticket'),
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

class _TicketPreviewSheet extends StatelessWidget {
  final dynamic ticket;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String propertyName;
  final String unitName;
  final String creatorName;
  final String assignedName;
  final String createdAt;
  final String updatedAt;
  final int messagesCount;
  final String ageLabel;
  final int healthScore;
  final String healthLabel;
  final Color healthColor;
  final Color Function(String? status) statusColor;
  final IconData Function(String? status) statusIcon;
  final Color Function(String? priority) priorityColor;
  final IconData Function(String? priority) priorityIcon;
  final Future<void> Function() onOpenDetails;

  const _TicketPreviewSheet({
    required this.ticket,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.propertyName,
    required this.unitName,
    required this.creatorName,
    required this.assignedName,
    required this.createdAt,
    required this.updatedAt,
    required this.messagesCount,
    required this.ageLabel,
    required this.healthScore,
    required this.healthLabel,
    required this.healthColor,
    required this.statusColor,
    required this.statusIcon,
    required this.priorityColor,
    required this.priorityIcon,
    required this.onOpenDetails,
  });

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  String initials() {
    final clean = title.trim();

    if (clean.isEmpty) return 'T';

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
          title: 'Health',
          value: '$healthScore%',
          icon: Icons.health_and_safety,
          color: healthColor,
        ),
        metric(
          title: 'Messages',
          value: messagesCount.toString(),
          icon: Icons.chat_bubble,
          color: primary,
        ),
        metric(
          title: 'Priority',
          value: priority,
          icon: priorityIcon(priority),
          color: priorityColor(priority),
        ),
        metric(
          title: 'Age',
          value: ageLabel,
          icon: Icons.schedule,
          color: Colors.orange,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sColor = statusColor(status);
    final pColor = priorityColor(priority);

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
                  backgroundColor: sColor.withOpacity(0.12),
                  child: Text(
                    initials(),
                    style: TextStyle(
                      color: sColor,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  title,
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
                      avatar: Icon(statusIcon(status), color: sColor, size: 18),
                      label: Text(status),
                      backgroundColor: sColor.withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: sColor,
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide.none,
                    ),
                    Chip(
                      avatar: Icon(
                        priorityIcon(priority),
                        color: pColor,
                        size: 18,
                      ),
                      label: Text(priority),
                      backgroundColor: pColor.withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: pColor,
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide.none,
                    ),
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
                  ],
                ),

                const SizedBox(height: 18),

                metricsGrid(),

                const SizedBox(height: 14),

                Card(
                  color: healthColor.withOpacity(0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: healthColor.withOpacity(0.12),
                          child: Icon(Icons.insights, color: healthColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            healthLabel == 'Unassigned'
                                ? 'This ticket should be assigned to a team member.'
                                : healthLabel == 'Urgent'
                                ? 'This ticket has urgent priority and needs quick follow-up.'
                                : healthLabel == 'Aging'
                                ? 'This ticket has been open for several days and should be reviewed.'
                                : 'This ticket is currently under control.',
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
                        infoRow('Description', description),
                        infoRow('Created By', creatorName),
                        infoRow('Assigned To', assignedName),
                        infoRow('Created', createdAt),
                        infoRow('Updated', updatedAt),
                        infoRow('Status', status),
                        infoRow('Priority', priority),
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
                    label: const Text('Open Ticket Details'),
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

class _TicketsInsightSheet extends StatelessWidget {
  final int totalTickets;
  final int openCount;
  final int inProgressCount;
  final int resolvedCount;
  final int closedCount;
  final int urgentCount;
  final int highCount;
  final int unassignedCount;
  final int assignedCount;
  final double averageAgeDays;
  final double completionRate;
  final double responseCoverage;
  final String workloadHealth;
  final Color workloadColor;

  const _TicketsInsightSheet({
    required this.totalTickets,
    required this.openCount,
    required this.inProgressCount,
    required this.resolvedCount,
    required this.closedCount,
    required this.urgentCount,
    required this.highCount,
    required this.unassignedCount,
    required this.assignedCount,
    required this.averageAgeDays,
    required this.completionRate,
    required this.responseCoverage,
    required this.workloadHealth,
    required this.workloadColor,
  });

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

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
    final activeCount = openCount + inProgressCount;

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
                  backgroundColor: workloadColor.withOpacity(0.12),
                  child: Icon(Icons.insights, color: workloadColor, size: 36),
                ),

                const SizedBox(height: 14),

                const Text(
                  'Ticket Intelligence',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                Text(
                  'Maintenance workload and support quality overview',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),

                const SizedBox(height: 16),

                Chip(
                  avatar: Icon(
                    Icons.health_and_safety,
                    color: workloadColor,
                    size: 18,
                  ),
                  label: Text(workloadHealth),
                  backgroundColor: workloadColor.withOpacity(0.12),
                  labelStyle: TextStyle(
                    color: workloadColor,
                    fontWeight: FontWeight.bold,
                  ),
                  side: BorderSide.none,
                ),

                const SizedBox(height: 18),

                scoreCard(
                  title: 'Completion Rate',
                  value: completionRate,
                  icon: Icons.pie_chart,
                  color: completionRate >= 70 ? Colors.green : workloadColor,
                ),

                const SizedBox(height: 10),

                scoreCard(
                  title: 'Response Coverage',
                  value: responseCoverage,
                  icon: Icons.chat_bubble,
                  color: responseCoverage >= 70 ? Colors.green : primary,
                ),

                const SizedBox(height: 14),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        infoRow('Total Tickets', totalTickets),
                        infoRow('Active Workload', activeCount),
                        infoRow('Assigned', assignedCount),
                        infoRow('Unassigned', unassignedCount),
                        infoRow('Urgent / High', urgentCount),
                        infoRow(
                          'Average Active Age',
                          '${averageAgeDays.toStringAsFixed(1)} days',
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
                          title: 'Open',
                          value: openCount,
                          icon: Icons.report_problem,
                          color: Colors.red,
                        ),
                        statusRow(
                          title: 'In Progress',
                          value: inProgressCount,
                          icon: Icons.sync,
                          color: Colors.orange,
                        ),
                        statusRow(
                          title: 'Resolved',
                          value: resolvedCount,
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                        statusRow(
                          title: 'Closed',
                          value: closedCount,
                          icon: Icons.lock,
                          color: Colors.grey,
                        ),
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
                      unassignedCount > 0
                          ? 'Unassigned tickets should be routed quickly so tenants know someone is handling their request.'
                          : urgentCount > 0
                          ? 'Urgent and high priority tickets need fast follow-up to protect tenant satisfaction.'
                          : 'A healthy ticket workflow has quick assignment, active replies, and strong closure rates.',
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
