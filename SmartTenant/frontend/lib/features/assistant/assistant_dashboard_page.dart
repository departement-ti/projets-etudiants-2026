import 'package:flutter/material.dart';

import '../../core/auth/auth_storage.dart';
import '../../core/ui/app_error.dart';
import '../auth/login_page.dart';
import '../notifications/notification_page.dart';
import '../notifications/notification_service.dart';
import '../profile/profile_page.dart';
import '../properties/properties_page.dart';
import '../tickets/create_ticket_page.dart';
import '../tickets/ticket_details_page.dart';
import '../tickets/ticket_list_page.dart';
import '../tickets/ticket_service.dart';
import '../leases/lease_list_page.dart';

class AssistantDashboardPage extends StatefulWidget {
  const AssistantDashboardPage({super.key});

  @override
  State<AssistantDashboardPage> createState() => _AssistantDashboardPageState();
}

class _AssistantDashboardPageState extends State<AssistantDashboardPage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  String displayName = 'Assistant';
  String? userId;

  int unreadNotifications = 0;
  List<dynamic> tickets = [];

  bool loading = true;
  bool refreshing = false;
  bool loggingOut = false;

  String error = '';
  String selectedSection = 'OVERVIEW';

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);
  static const darkText = Color(0xFF1D1B20);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF97316);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF0EA5E9);
  static const purple = Color(0xFF8B5CF6);
  static const slate = Color(0xFF64748B);

  final sections = const [
    {'id': 'OVERVIEW', 'label': 'Overview', 'icon': Icons.dashboard_customize},
    {'id': 'OPEN', 'label': 'Open', 'icon': Icons.report_problem},
    {'id': 'MINE', 'label': 'Mine', 'icon': Icons.edit_note},
    {'id': 'PRIORITY', 'label': 'Priority', 'icon': Icons.warning_amber},
  ];

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll({bool silent = false}) async {
    if (silent) {
      setState(() => refreshing = true);
    } else {
      setState(() {
        loading = true;
        error = '';
      });
    }

    try {
      await Future.wait([
        loadAssistantDashboard(silent: true),
        loadUnreadNotifications(),
      ]);

      if (!mounted) return;

      setState(() {
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
          title: 'Could not refresh assistant dashboard',
        );
        return;
      }

      setState(() {
        loading = false;
        refreshing = false;
        error = AppError.clean(e);
      });
    }
  }

  Future<void> loadUnreadNotifications() async {
    try {
      final count = await NotificationService.unreadCount();

      if (!mounted) return;

      setState(() => unreadNotifications = count);
    } catch (_) {}
  }

  Future<void> loadAssistantDashboard({bool silent = false}) async {
    try {
      final name = await AuthStorage.getDisplayName();
      final id = await AuthStorage.getUserId();
      final ticketData = await TicketService.getAll();

      if (!mounted) return;

      setState(() {
        displayName = name.trim().isEmpty ? 'Assistant' : name;
        userId = id;
        tickets = ticketData;
      });
    } catch (e) {
      if (!silent) rethrow;
      throw e;
    }
  }

  Future<void> refreshDashboard() async {
    await loadAll(silent: true);
  }

  Future<void> closeDrawerThenContinue() async {
    if (scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
      await Future.delayed(const Duration(milliseconds: 160));
    }
  }

  Future<void> reopenDrawerAfterReturn(bool reopenDrawer) async {
    if (!reopenDrawer || !mounted) return;

    await Future.delayed(const Duration(milliseconds: 180));

    if (!mounted) return;

    scaffoldKey.currentState?.openDrawer();
  }

  Future<void> openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationPage()),
    );

    await loadUnreadNotifications();
  }

  Future<void> openProfile({bool fromDrawer = false}) async {
    await closeDrawerThenContinue();

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );

    await refreshDashboard();
    await reopenDrawerAfterReturn(fromDrawer);
  }

  Future<void> openTickets({bool fromDrawer = false}) async {
    await closeDrawerThenContinue();

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TicketListPage()),
    );

    await refreshDashboard();
    await reopenDrawerAfterReturn(fromDrawer);
  }

  Future<void> openCreateTicket({bool fromDrawer = false}) async {
    await closeDrawerThenContinue();

    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateTicketPage()),
    );

    if (created == true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket created successfully')),
      );

      await refreshDashboard();
    }

    await reopenDrawerAfterReturn(fromDrawer);
  }

  Future<void> openProperties({bool fromDrawer = false}) async {
    await closeDrawerThenContinue();

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PropertiesPage()),
    );

    await refreshDashboard();
    await reopenDrawerAfterReturn(fromDrawer);
  }

  Future<void> openLeases({bool fromDrawer = false}) async {
    await closeDrawerThenContinue();

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeaseListPage()),
    );

    await refreshDashboard();
    await reopenDrawerAfterReturn(fromDrawer);
  }

  Future<void> openTicketDetails(dynamic ticket) async {
    final ticketId = ticket['id']?.toString();

    if (ticketId == null || ticketId.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TicketDetailsPage(ticketId: ticketId)),
    );

    await refreshDashboard();
  }

  Future<void> confirmLogout() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LogoutSheet(),
    );

    if (confirmed != true) return;

    await logout();
  }

  Future<void> logout() async {
    setState(() => loggingOut = true);

    try {
      await AuthStorage.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      await AppError.show(context, e, title: 'Could not logout');
    } finally {
      if (mounted) {
        setState(() => loggingOut = false);
      }
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

  String userName(dynamic user) {
    if (user == null) return 'Unassigned';

    final firstName = user['firstName']?.toString() ?? '';
    final lastName = user['lastName']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';

    final fullName = '$firstName $lastName'.trim();

    if (fullName.isNotEmpty) return fullName;
    if (email.isNotEmpty) return email;

    return 'User';
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

  int get openTicketsCount {
    return tickets.where((ticket) {
      final status = ticket['status']?.toString();
      return status == 'OPEN' || status == 'IN_PROGRESS';
    }).length;
  }

  int get onlyOpenTicketsCount {
    return tickets.where((ticket) {
      return ticket['status']?.toString() == 'OPEN';
    }).length;
  }

  int get inProgressTicketsCount {
    return tickets.where((ticket) {
      return ticket['status']?.toString() == 'IN_PROGRESS';
    }).length;
  }

  int get resolvedTicketsCount {
    return tickets.where((ticket) {
      return ticket['status']?.toString() == 'RESOLVED';
    }).length;
  }

  int get closedTicketsCount {
    return tickets.where((ticket) {
      return ticket['status']?.toString() == 'CLOSED';
    }).length;
  }

  int get createdByMeCount {
    return tickets.where((ticket) {
      return ticket['createdById']?.toString() == userId;
    }).length;
  }

  int get urgentTicketsCount {
    return tickets.where((ticket) {
      final priority = ticket['priority']?.toString().toLowerCase();
      return priority == 'urgent' || priority == 'high';
    }).length;
  }

  int get unassignedTicketsCount {
    return tickets.where((ticket) {
      return ticket['assignedToId'] == null;
    }).length;
  }

  int get completionRate {
    if (tickets.isEmpty) return 100;

    final completed = resolvedTicketsCount + closedTicketsCount;
    return ((completed / tickets.length) * 100).round().clamp(0, 100);
  }

  int get workloadScore {
    return openTicketsCount + urgentTicketsCount + unassignedTicketsCount;
  }

  String get healthLabel {
    if (urgentTicketsCount > 0) return 'Priority requests need attention';
    if (unassignedTicketsCount > 0) return 'Some requests need assignment';
    if (openTicketsCount > 5) return 'Support queue needs monitoring';
    if (tickets.isEmpty) return 'No support tickets yet';

    return 'Support desk looks healthy';
  }

  Color get healthColor {
    if (urgentTicketsCount > 0) return warning;
    if (unassignedTicketsCount > 0) return info;
    if (openTicketsCount > 5) return warning;
    if (tickets.isEmpty) return Colors.grey;

    return success;
  }

  List<dynamic> get sortedTickets {
    final copy = [...tickets];

    copy.sort((a, b) {
      return parseDate(b['createdAt']).compareTo(parseDate(a['createdAt']));
    });

    return copy;
  }

  List<dynamic> get recentTickets {
    return sortedTickets.take(5).toList();
  }

  List<dynamic> get openTicketItems {
    return sortedTickets.where((ticket) {
      final status = ticket['status']?.toString();
      return status == 'OPEN' || status == 'IN_PROGRESS';
    }).toList();
  }

  List<dynamic> get mineTickets {
    return sortedTickets.where((ticket) {
      return ticket['createdById']?.toString() == userId;
    }).toList();
  }

  List<dynamic> get priorityTickets {
    return sortedTickets.where((ticket) {
      final priority = ticket['priority']?.toString().toLowerCase();
      return priority == 'urgent' || priority == 'high';
    }).toList();
  }

  List<dynamic> currentSectionTickets() {
    switch (selectedSection) {
      case 'OPEN':
        return openTicketItems;
      case 'MINE':
        return mineTickets;
      case 'PRIORITY':
        return priorityTickets;
      case 'OVERVIEW':
      default:
        return recentTickets;
    }
  }

  String sectionTitleText() {
    switch (selectedSection) {
      case 'OPEN':
        return 'Open Support Requests';
      case 'MINE':
        return 'Created by Me';
      case 'PRIORITY':
        return 'Priority Requests';
      case 'OVERVIEW':
      default:
        return 'Recent Support Activity';
    }
  }

  String sectionSubtitleText() {
    switch (selectedSection) {
      case 'OPEN':
        return 'Requests still waiting for response or resolution.';
      case 'MINE':
        return 'Tickets you created from desk, phone or email.';
      case 'PRIORITY':
        return 'High and urgent requests that need faster follow-up.';
      case 'OVERVIEW':
      default:
        return 'Latest support tickets in the workspace.';
    }
  }

  Color ticketStatusColor(String? status) {
    switch (status) {
      case 'OPEN':
        return danger;
      case 'IN_PROGRESS':
        return warning;
      case 'RESOLVED':
        return success;
      case 'CLOSED':
        return Colors.grey;
      default:
        return info;
    }
  }

  IconData ticketStatusIcon(String? status) {
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
        return Icons.confirmation_number;
    }
  }

  Color priorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'urgent':
        return danger;
      case 'high':
        return warning;
      case 'medium':
        return info;
      case 'low':
        return success;
      default:
        return Colors.grey;
    }
  }

  Widget drawerBadge(int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value.toString(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
    Widget? trailing,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                colors: [Color(0xFF6750A4), Color(0xFF8B7DD8)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        borderRadius: BorderRadius.circular(18),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withOpacity(0.18)
                : primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: selected ? Colors.white : primary, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            color: selected ? Colors.white : darkText,
          ),
        ),
        trailing: trailing,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onTap: onTap,
      ),
    );
  }

  Widget appDrawer() {
    return Drawer(
      backgroundColor: softBg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4C1D95), Color(0xFF6750A4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.support_agent,
                        color: primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Assistant Desk',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      drawerItem(
                        icon: Icons.dashboard,
                        title: 'Dashboard',
                        selected: true,
                        onTap: () => Navigator.pop(context),
                      ),
                      drawerItem(
                        icon: Icons.assignment_ind,
                        title: 'Dispatch Tickets',
                        trailing: openTicketsCount > 0
                            ? drawerBadge(openTicketsCount, warning)
                            : null,
                        onTap: () => openTickets(fromDrawer: true),
                      ),
                      drawerItem(
                        icon: Icons.add_task,
                        title: 'Create Ticket',
                        onTap: () => openCreateTicket(fromDrawer: true),
                      ),
                      drawerItem(
                        icon: Icons.apartment,
                        title: 'Properties Lookup',
                        onTap: () => openProperties(fromDrawer: true),
                      ),
                      drawerItem(
                        icon: Icons.description,
                        title: 'Lease Lookup',
                        onTap: () => openLeases(fromDrawer: true),
                      ),
                      drawerItem(
                        icon: Icons.person,
                        title: 'My Profile',
                        onTap: () => openProfile(fromDrawer: true),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: loggingOut
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout, color: danger),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: danger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: loggingOut ? null : confirmLogout,
                ),
              ),
            ],
          ),
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
              const CircleAvatar(
                radius: 31,
                backgroundColor: Colors.white,
                child: Icon(Icons.support_agent, color: primary, size: 31),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $displayName 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Administrative support and tenant communication desk.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: refreshing || loading ? null : refreshDashboard,
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
                Icon(Icons.health_and_safety, color: healthColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$healthLabel • $workloadScore support signals',
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
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: completionRate / 100,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Open',
                  value: openTicketsCount.toString(),
                  icon: Icons.report_problem,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: heroMetric(
                  title: 'Mine',
                  value: createdByMeCount.toString(),
                  icon: Icons.edit_note,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: heroMetric(
                  title: 'Priority',
                  value: urgentTicketsCount.toString(),
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
                  child: ElevatedButton.icon(
                    onPressed: openCreateTicket,
                    icon: const Icon(Icons.add_task),
                    label: const Text('Create Ticket'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: openTickets,
                    icon: const Icon(Icons.assignment_ind),
                    label: const Text('Dispatch'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: openProperties,
                    icon: const Icon(Icons.apartment),
                    label: const Text('Lookup'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: openLeases,
                    icon: const Icon(Icons.description),
                    label: const Text('Leases'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: openProfile,
                    icon: const Icon(Icons.person),
                    label: const Text('Profile'),
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
      _AssistantKpi(
        title: 'Open',
        value: openTicketsCount.toString(),
        icon: Icons.report_problem,
        color: danger,
        onTap: () => setState(() => selectedSection = 'OPEN'),
      ),
      _AssistantKpi(
        title: 'Unassigned',
        value: unassignedTicketsCount.toString(),
        icon: Icons.person_search,
        color: warning,
        onTap: () => setState(() => selectedSection = 'OPEN'),
      ),
      _AssistantKpi(
        title: 'Created',
        value: createdByMeCount.toString(),
        icon: Icons.edit_note,
        color: primary,
        onTap: () => setState(() => selectedSection = 'MINE'),
      ),
      _AssistantKpi(
        title: 'Priority',
        value: urgentTicketsCount.toString(),
        icon: Icons.priority_high,
        color: danger,
        onTap: () => setState(() => selectedSection = 'PRIORITY'),
      ),
      _AssistantKpi(
        title: 'In Progress',
        value: inProgressTicketsCount.toString(),
        icon: Icons.sync,
        color: info,
        onTap: () => setState(() => selectedSection = 'OPEN'),
      ),
      _AssistantKpi(
        title: 'Completed',
        value: '$completionRate%',
        icon: Icons.task_alt,
        color: success,
        onTap: openInsightsSheet,
      ),
    ];

    return SizedBox(
      height: 122,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final item = items[index];

          return SizedBox(
            width: 142,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: item.onTap,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget supportHub() {
    final actions = [
      _SupportAction(
        title: 'Create Ticket',
        subtitle: 'Register requests from desk, phone or email',
        icon: Icons.add_task,
        color: primary,
        featured: true,
        onTap: openCreateTicket,
      ),
      _SupportAction(
        title: 'Dispatch Tickets',
        subtitle: 'Review requests and assign work to agents',
        icon: Icons.assignment_ind,
        color: warning,
        onTap: openTickets,
      ),
      _SupportAction(
        title: 'Properties Lookup',
        subtitle: 'Find properties and units quickly',
        icon: Icons.apartment,
        color: info,
        onTap: openProperties,
      ),
      _SupportAction(
        title: 'Lease Lookup',
        subtitle: 'View leases in read-only mode',
        icon: Icons.description,
        color: purple,
        onTap: openLeases,
      ),
      _SupportAction(
        title: 'My Profile',
        subtitle: 'View and update your account',
        icon: Icons.person,
        color: slate,
        onTap: openProfile,
      ),
    ];

    return SizedBox(
      height: 154,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final item = actions[index];

          return SizedBox(
            width: item.featured ? 220 : 190,
            child: Material(
              color: item.featured ? item.color : Colors.white,
              borderRadius: BorderRadius.circular(26),
              child: InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: item.onTap,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: item.featured
                          ? Colors.transparent
                          : Colors.black.withOpacity(0.04),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: item.featured
                            ? item.color.withOpacity(0.24)
                            : Colors.black.withOpacity(0.025),
                        blurRadius: 14,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: item.featured
                            ? Colors.white.withOpacity(0.18)
                            : item.color.withOpacity(0.12),
                        child: Icon(
                          item.icon,
                          color: item.featured ? Colors.white : item.color,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: item.featured ? Colors.white : darkText,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: item.featured
                              ? Colors.white70
                              : Colors.grey.shade700,
                          fontSize: 12,
                          height: 1.25,
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

  Widget workflowCard() {
    return Card(
      color: healthColor.withOpacity(0.07),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: healthColor.withOpacity(0.12),
                  child: Icon(Icons.monitor_heart, color: healthColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    healthLabel,
                    style: TextStyle(
                      color: healthColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '$completionRate%',
                  style: TextStyle(
                    color: healthColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: completionRate / 100,
                minHeight: 8,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(healthColor),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              urgentTicketsCount > 0
                  ? 'Start by checking priority requests, then continue open and unassigned support tickets.'
                  : 'Assistant access is focused on ticket creation, tenant communication, dispatching work to agents and property lookup.',
              style: TextStyle(color: Colors.grey.shade800, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget currentSectionCard() {
    final items = currentSectionTickets();
    final shown = items.take(5).toList();

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sectionTitleText(),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sectionSubtitleText(),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: openTickets,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Open'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (shown.isEmpty)
              emptyInline('No tickets found in this section')
            else
              ...shown.map(compactTicketTile),
          ],
        ),
      ),
    );
  }

  Widget compactTicketTile(dynamic ticket) {
    final status = ticket['status']?.toString() ?? 'OPEN';
    final priority = ticket['priority']?.toString() ?? 'medium';
    final color = ticketStatusColor(status);

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.12),
        child: Icon(ticketStatusIcon(status), color: color, size: 20),
      ),
      title: Text(
        ticket['title']?.toString() ?? 'Ticket',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${propertyName(ticket)} • ${unitName(ticket)}\n'
        '${priority.toUpperCase()} • ${formatDate(ticket['createdAt'])}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => openTicketDetails(ticket),
    );
  }

  Widget emptyInline(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: softBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> openInsightsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssistantInsightsSheet(
        displayName: displayName,
        totalTickets: tickets.length,
        openTickets: openTicketsCount,
        createdByMe: createdByMeCount,
        urgentTickets: urgentTicketsCount,
        unassignedTickets: unassignedTicketsCount,
        inProgressTickets: inProgressTicketsCount,
        completionRate: completionRate,
        healthLabel: healthLabel,
        healthColor: healthColor,
      ),
    );
  }

  Widget dashboardBody() {
    return RefreshIndicator(
      onRefresh: refreshDashboard,
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
          const SizedBox(height: 16),
          workflowCard(),
          const SizedBox(height: 14),
          supportHub(),
          const SizedBox(height: 14),
          currentSectionCard(),
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
      onRefresh: () => loadAll(),
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
                    'Could not load assistant dashboard',
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
                    onPressed: () => loadAll(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: softBg,
      drawer: appDrawer(),
      appBar: AppBar(
        title: const Text(
          'Assistant Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Insights',
            icon: const Icon(Icons.insights),
            onPressed: tickets.isEmpty ? null : openInsightsSheet,
          ),
          Stack(
            children: [
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications),
                onPressed: openNotifications,
              ),
              if (unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: danger,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadNotifications > 99
                          ? '99+'
                          : unreadNotifications.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
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
            onPressed: refreshing || loading ? null : refreshDashboard,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: loading
          ? loadingBody()
          : error.isNotEmpty
          ? errorBody()
          : dashboardBody(),
    );
  }
}

class _AssistantKpi {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AssistantKpi({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _SupportAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool featured;
  final VoidCallback onTap;

  const _SupportAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.featured = false,
  });
}

class _AssistantInsightsSheet extends StatelessWidget {
  final String displayName;
  final int totalTickets;
  final int openTickets;
  final int createdByMe;
  final int urgentTickets;
  final int unassignedTickets;
  final int inProgressTickets;
  final int completionRate;
  final String healthLabel;
  final Color healthColor;

  const _AssistantInsightsSheet({
    required this.displayName,
    required this.totalTickets,
    required this.openTickets,
    required this.createdByMe,
    required this.urgentTickets,
    required this.unassignedTickets,
    required this.inProgressTickets,
    required this.completionRate,
    required this.healthLabel,
    required this.healthColor,
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

  Widget scoreCard() {
    return Card(
      color: healthColor.withOpacity(0.07),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: healthColor.withOpacity(0.12),
                  child: Icon(Icons.monitor_heart, color: healthColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    healthLabel,
                    style: TextStyle(
                      color: healthColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '$completionRate%',
                  style: TextStyle(
                    color: healthColor,
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
                value: completionRate / 100,
                minHeight: 8,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(healthColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                  'Assistant Desk Insights',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  displayName,
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
                scoreCard(),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        infoRow('Total Tickets', totalTickets),
                        infoRow('Open Tickets', openTickets),
                        infoRow('In Progress', inProgressTickets),
                        infoRow('Created by Me', createdByMe),
                        infoRow('Priority Tickets', urgentTickets),
                        infoRow('Unassigned', unassignedTickets),
                        infoRow('Completion Rate', '$completionRate%'),
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
                      'Workflow note',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      urgentTickets > 0
                          ? 'Priority requests should be checked first, then open and unassigned tickets.'
                          : 'Keep tickets updated, reply quickly, and use property lookup when creating clear support requests.',
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

class _LogoutSheet extends StatelessWidget {
  const _LogoutSheet();

  static const softBg = Color(0xFFF8F5FF);
  static const danger = Color(0xFFEF4444);

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
              const SizedBox(height: 22),
              CircleAvatar(
                radius: 32,
                backgroundColor: danger.withOpacity(0.12),
                child: const Icon(Icons.logout, color: danger, size: 34),
              ),
              const SizedBox(height: 16),
              const Text(
                'Logout from SmartTenant?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Your local session will be cleared and you will return to the login screen.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, height: 1.45),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: danger,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
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
