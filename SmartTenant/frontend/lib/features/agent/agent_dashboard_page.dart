import 'package:flutter/material.dart';

import '../../core/auth/auth_storage.dart';
import '../../core/ui/app_error.dart';
import '../auth/login_page.dart';
import '../leases/lease_list_page.dart';
import '../notifications/notification_page.dart';
import '../notifications/notification_service.dart';
import '../profile/profile_page.dart';
import '../properties/properties_page.dart';
import '../tickets/ticket_details_page.dart';
import '../tickets/ticket_list_page.dart';
import '../tickets/ticket_service.dart';

class AgentDashboardPage extends StatefulWidget {
  const AgentDashboardPage({super.key});

  @override
  State<AgentDashboardPage> createState() => _AgentDashboardPageState();
}

class _AgentDashboardPageState extends State<AgentDashboardPage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  String displayName = 'Agent';
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

  final sections = const [
    {'id': 'OVERVIEW', 'label': 'Overview', 'icon': Icons.dashboard_customize},
    {'id': 'WORK', 'label': 'Workload', 'icon': Icons.construction},
    {'id': 'PRIORITY', 'label': 'Priority', 'icon': Icons.warning_amber},
    {'id': 'ASSIGNED', 'label': 'Mine', 'icon': Icons.assignment_ind},
  ];

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll({bool silent = false}) async {
    if (silent) {
      setState(() => refreshing = true);
    }

    await Future.wait([
      loadAgentDashboard(silent: silent),
      loadUnreadNotifications(),
    ]);

    if (mounted) {
      setState(() => refreshing = false);
    }
  }

  Future<void> loadUnreadNotifications() async {
    try {
      final count = await NotificationService.unreadCount();

      if (!mounted) return;

      setState(() => unreadNotifications = count);
    } catch (_) {}
  }

  Future<void> loadAgentDashboard({bool silent = false}) async {
    if (!silent) {
      setState(() {
        loading = true;
        error = '';
      });
    }

    try {
      final name = await AuthStorage.getDisplayName();
      final id = await AuthStorage.getUserId();
      final ticketData = await TicketService.getAll();

      final assignedOnly = ticketData.where((ticket) {
        return ticket['assignedToId']?.toString() == id;
      }).toList();

      if (!mounted) return;

      setState(() {
        displayName = name.trim().isEmpty ? 'Agent' : name;
        userId = id;
        tickets = assignedOnly;
        loading = false;
        error = '';
      });
    } catch (e) {
      if (!mounted) return;

      if (silent) {
        await AppError.show(
          context,
          e,
          title: 'Could not refresh agent dashboard',
        );
        return;
      }

      setState(() {
        error = AppError.clean(e);
        loading = false;
      });
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
    final id = ticket['id']?.toString();

    if (id == null || id.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TicketDetailsPage(ticketId: id)),
    );

    await refreshDashboard();
  }

  int get openTicketsCount {
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

  int get assignedToMeCount {
    return tickets.where((ticket) {
      return ticket['assignedToId']?.toString() == userId;
    }).length;
  }

  int get urgentTicketsCount {
    return tickets.where((ticket) {
      final priority = ticket['priority']?.toString().toLowerCase();
      return priority == 'urgent' || priority == 'high';
    }).length;
  }

  int get unassignedTicketsCount {
    return 0;
  }

  int get operationalLoad {
    return openTicketsCount + inProgressTicketsCount + urgentTicketsCount;
  }

  int get completionRate {
    if (tickets.isEmpty) return 100;

    final completed = resolvedTicketsCount + closedTicketsCount;
    return ((completed / tickets.length) * 100).round().clamp(0, 100);
  }

  Color get healthColor {
    if (urgentTicketsCount > 0) return warning;
    if (openTicketsCount > 5) return warning;
    return success;
  }

  String get healthLabel {
    if (urgentTicketsCount > 0) return 'Priority work needs attention';
    if (openTicketsCount > 5) return 'Ticket queue needs monitoring';
    if (tickets.isEmpty) return 'No tickets yet';
    return 'Operations look healthy';
  }

  List<dynamic> get recentTickets {
    final copy = [...tickets];

    copy.sort((a, b) {
      return parseDate(b['createdAt']).compareTo(parseDate(a['createdAt']));
    });

    return copy.take(5).toList();
  }

  List<dynamic> get priorityTickets {
    return tickets.where((ticket) {
      final priority = ticket['priority']?.toString().toLowerCase();
      return priority == 'urgent' || priority == 'high';
    }).toList();
  }

  List<dynamic> get assignedTickets {
    return tickets.where((ticket) {
      return ticket['assignedToId']?.toString() == userId;
    }).toList();
  }

  List<dynamic> get activeWorkTickets {
    return tickets.where((ticket) {
      final status = ticket['status']?.toString();
      return status == 'OPEN' || status == 'IN_PROGRESS';
    }).toList();
  }

  List<dynamic> currentSectionTickets() {
    switch (selectedSection) {
      case 'PRIORITY':
        return priorityTickets;

      case 'ASSIGNED':
        return assignedTickets;

      case 'WORK':
        return activeWorkTickets;

      case 'OVERVIEW':
      default:
        return recentTickets;
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
        return Icons.construction;
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

  String sectionTitle() {
    switch (selectedSection) {
      case 'PRIORITY':
        return 'Priority Tickets';
      case 'ASSIGNED':
        return 'Assigned to Me';
      case 'WORK':
        return 'Active Workload';
      case 'OVERVIEW':
      default:
        return 'Latest Tickets';
    }
  }

  String sectionSubtitle() {
    switch (selectedSection) {
      case 'PRIORITY':
        return 'Urgent and high priority requests requiring attention.';
      case 'ASSIGNED':
        return 'Tickets currently assigned to your account.';
      case 'WORK':
        return 'Open and in-progress operational work.';
      case 'OVERVIEW':
      default:
        return 'Most recent maintenance requests in your organization.';
    }
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
                      child: Icon(Icons.engineering, color: primary, size: 30),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Agent Workspace',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayName,
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
                        icon: Icons.construction,
                        title: 'My Work',
                        trailing: openTicketsCount > 0
                            ? drawerBadge(openTicketsCount, warning)
                            : null,
                        onTap: () => openTickets(fromDrawer: true),
                      ),

                      drawerItem(
                        icon: Icons.apartment,
                        title: 'Properties',
                        onTap: () => openProperties(fromDrawer: true),
                      ),
                      drawerItem(
                        icon: Icons.meeting_room,
                        title: 'Leases Lookup',
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
                child: Icon(Icons.engineering, color: primary, size: 31),
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
                      'Maintenance and operations command center.',
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
                    '$healthLabel • $operationalLoad active signals',
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
                  title: 'Assigned',
                  value: assignedToMeCount.toString(),
                  icon: Icons.assignment_ind,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: heroMetric(
                  title: 'In Progress',
                  value: inProgressTicketsCount.toString(),
                  icon: Icons.sync,
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
                    onPressed: openTickets,
                    icon: const Icon(Icons.construction),
                    label: const Text('Tickets'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: openTickets,
                    icon: const Icon(Icons.assignment_ind),
                    label: const Text('My Work'),
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
                    label: const Text('Properties'),
                  ),
                ),
                const SizedBox(width: 10),
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
      _AgentKpi(
        title: 'Open',
        value: openTicketsCount.toString(),
        icon: Icons.report_problem,
        color: danger,
        onTap: () => setState(() => selectedSection = 'WORK'),
      ),
      _AgentKpi(
        title: 'In Progress',
        value: inProgressTicketsCount.toString(),
        icon: Icons.sync,
        color: warning,
        onTap: () => setState(() => selectedSection = 'WORK'),
      ),
      _AgentKpi(
        title: 'Resolved',
        value: resolvedTicketsCount.toString(),
        icon: Icons.check_circle,
        color: success,
        onTap: () => setState(() => selectedSection = 'ASSIGNED'),
      ),
      _AgentKpi(
        title: 'Priority',
        value: urgentTicketsCount.toString(),
        icon: Icons.priority_high,
        color: danger,
        onTap: () => setState(() => selectedSection = 'PRIORITY'),
      ),
      _AgentKpi(
        title: 'Unassigned',
        value: unassignedTicketsCount.toString(),
        icon: Icons.person_off,
        color: info,
        onTap: () => setState(() => selectedSection = 'WORK'),
      ),
      _AgentKpi(
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

  Widget operationsHub() {
    final actions = [
      _OperationAction(
        title: 'My Work',
        subtitle: 'View assigned maintenance tickets and update progress',
        icon: Icons.construction,
        color: primary,
        featured: true,
        onTap: openTickets,
      ),
      _OperationAction(
        title: 'Properties',
        subtitle: 'View property and unit context',
        icon: Icons.apartment,
        color: info,
        onTap: openProperties,
      ),
      _OperationAction(
        title: 'Leases Lookup',
        subtitle: 'Check lease context',
        icon: Icons.meeting_room,
        color: warning,
        onTap: openLeases,
      ),
      _OperationAction(
        title: 'My Profile',
        subtitle: 'View and update your account',
        icon: Icons.person,
        color: purple,
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

  Widget workloadCard() {
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
                  ? 'Focus on urgent and high-priority tickets first, then continue active work.'
                  : 'Your operational workload is under control. Keep ticket responses updated.',
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
                        sectionTitle(),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sectionSubtitle(),
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
      builder: (_) => _AgentInsightsSheet(
        displayName: displayName,
        totalTickets: tickets.length,
        openTickets: openTicketsCount,
        inProgressTickets: inProgressTicketsCount,
        assignedTickets: tickets.length,
        urgentTickets: urgentTicketsCount,
        unassignedTickets: 0,
        completionRate: completionRate,
        healthLabel: healthLabel,
        healthColor: healthColor,
      ),
    );
  }

  Widget bodyContent() {
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
          workloadCard(),
          const SizedBox(height: 14),
          operationsHub(),
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
                    'Could not load agent dashboard',
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
          'Agent Dashboard',
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
          : bodyContent(),
    );
  }
}

class _AgentKpi {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AgentKpi({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _OperationAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool featured;
  final VoidCallback onTap;

  const _OperationAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.featured = false,
  });
}

class _AgentInsightsSheet extends StatelessWidget {
  final String displayName;
  final int totalTickets;
  final int openTickets;
  final int inProgressTickets;
  final int assignedTickets;
  final int urgentTickets;
  final int unassignedTickets;
  final int completionRate;
  final String healthLabel;
  final Color healthColor;

  const _AgentInsightsSheet({
    required this.displayName,
    required this.totalTickets,
    required this.openTickets,
    required this.inProgressTickets,
    required this.assignedTickets,
    required this.urgentTickets,
    required this.unassignedTickets,
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
                  'Agent Intelligence',
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
                        infoRow('Assigned to Me', assignedTickets),
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
                      'Operational note',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      urgentTickets > 0
                          ? 'Start with urgent tickets, then continue in-progress work and unassigned requests.'
                          : 'Keep tickets updated with replies and status changes to maintain a clean workflow.',
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
