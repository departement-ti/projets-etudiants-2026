import 'package:flutter/material.dart';

import '../../core/auth/auth_storage.dart';
import '../../core/ui/app_error.dart';
import '../auth/login_page.dart';
import '../properties/properties_page.dart';
import '../leases/lease_list_page.dart';
import '../leases/lease_details_page.dart';
import '../invoice/invoice_list_page.dart';
import '../invoice/invoice_details.dart';
import '../tickets/ticket_list_page.dart';
import '../tickets/ticket_details_page.dart';
import '../profile/profile_page.dart';
import '../users/user_management_page.dart';
import '../organizations/organization_management_page.dart';
import '../ai/ai_assistant_page.dart';
import 'dashboard_service.dart';
import '../audit/audit_log_page.dart';
import '../notifications/notification_page.dart';
import '../notifications/notification_service.dart';
import '../reports/financial_report_page.dart';
import '../copilot/copilot_page.dart';
import '../tenants/tenants_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? stats;
  bool loading = true;
  String error = '';
  String? role;
  int unreadNotifications = 0;

  bool get isAdmin => role == 'ADMIN';
  bool get isOwner => role == 'OWNER';
  bool get canSeeBusinessTools => role == 'ADMIN' || role == 'OWNER';

  static const primary = Color(0xFF6750A4);
  static const darkText = Color(0xFF1D1B20);
  static const softBg = Color(0xFFF8F5FF);

  @override
  void initState() {
    super.initState();
    loadStats();
    loadUnreadNotifications();
  }

  Future<void> loadUnreadNotifications() async {
    try {
      final count = await NotificationService.unreadCount();

      if (!mounted) return;

      setState(() {
        unreadNotifications = count;
      });
    } catch (_) {}
  }

  Future<void> openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationPage()),
    );

    await loadUnreadNotifications();
  }

  Future<void> loadStats() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final userRole = await AuthStorage.getUserRole();
      final data = await DashboardService.getStats();

      if (!mounted) return;

      setState(() {
        role = userRole;
        stats = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = AppError.clean(e);
        loading = false;
      });
    }
  }

  Future<void> refreshDashboard() async {
    await loadStats();
    await loadUnreadNotifications();
  }

  Future<void> logout() async {
    await AuthStorage.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  num value(String key) {
    final v = stats?[key];

    if (v is int) return v;
    if (v is double) return v;
    if (v is num) return v;

    return 0;
  }

  List<dynamic> listValue(String key) {
    final v = stats?[key];

    if (v is List) return v;

    return [];
  }

  String formatDate(dynamic value) {
    if (value == null) return '—';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    return parsed.toLocal().toString().split(' ')[0];
  }

  String tenantName(dynamic item) {
    final user = item['tenant']?['user'] ?? item['lease']?['tenant']?['user'];

    if (user != null) {
      final firstName = user['firstName'] ?? '';
      final lastName = user['lastName'] ?? '';
      final email = user['email'] ?? '';

      final fullName = '$firstName $lastName'.trim();

      if (fullName.isNotEmpty) return fullName;
      if (email.toString().isNotEmpty) return email;
    }

    return 'Tenant';
  }

  String unitName(dynamic item) {
    final unit = item['unit'] ?? item['lease']?['unit'];

    if (unit != null) {
      return unit['title'] ?? unit['number'] ?? 'Unit';
    }

    return 'Unit';
  }

  String propertyName(dynamic item) {
    final property =
        item['unit']?['property'] ??
        item['lease']?['unit']?['property'] ??
        item['property'];

    if (property != null) {
      return property['title'] ?? property['name'] ?? 'Property';
    }

    return 'Property';
  }

  String ticketUserName(dynamic ticket) {
    final user = ticket['createdBy'];

    if (user != null) {
      final firstName = user['firstName'] ?? '';
      final lastName = user['lastName'] ?? '';
      final email = user['email'] ?? '';

      final fullName = '$firstName $lastName'.trim();

      if (fullName.isNotEmpty) return fullName;
      if (email.toString().isNotEmpty) return email;
    }

    return 'User';
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

  Color ticketStatusColor(String? status) {
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

  void closeRootThenOpen(Widget page) {
    Navigator.popUntil(context, (route) => route.isFirst);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) => refreshDashboard());
  }

  void openReports() {
    closeRootThenOpen(const FinancialReportPage());
  }

  void openCopilot() {
    closeRootThenOpen(const CopilotPage());
  }

  void openAuditLogs() {
    closeRootThenOpen(const AuditLogPage());
  }

  void openProperties() {
    closeRootThenOpen(const PropertiesPage());
  }

  void openTenants() {
    closeRootThenOpen(const TenantsPage());
  }

  void openLeases() {
    closeRootThenOpen(const LeaseListPage());
  }

  void openInvoices() {
    closeRootThenOpen(const InvoiceListPage());
  }

  void openTickets() {
    closeRootThenOpen(const TicketListPage());
  }

  void openProfile() {
    closeRootThenOpen(const ProfilePage());
  }

  void openUsersManagement() {
    closeRootThenOpen(const UserManagementPage());
  }

  void openOrganizationsManagement() {
    closeRootThenOpen(const OrganizationManagementPage());
  }

  void openAiAssistant() {
    closeRootThenOpen(const AiAssistantPage());
  }

  Widget drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
    Widget? trailing,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
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
        color: selected ? null : Colors.transparent,
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
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
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
                    colors: [Color(0xFF6750A4), Color(0xFF8B7DD8)],
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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.apartment, color: primary, size: 30),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'SmartTenant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Property Management',
                      style: TextStyle(color: Colors.white70),
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
                      if (isAdmin)
                        drawerItem(
                          icon: Icons.business,
                          title: 'Organizations',
                          onTap: openOrganizationsManagement,
                        ),
                      if (isAdmin)
                        drawerItem(
                          icon: Icons.admin_panel_settings,
                          title: 'Users & Roles',
                          onTap: openUsersManagement,
                        ),
                      drawerItem(
                        icon: Icons.apartment,
                        title: 'Properties',
                        onTap: openProperties,
                      ),
                      if (canSeeBusinessTools)
                        drawerItem(
                          icon: Icons.home_work,
                          title: 'Tenants',
                          onTap: openTenants,
                        ),
                      drawerItem(
                        icon: Icons.description,
                        title: 'Leases',
                        onTap: openLeases,
                      ),
                      drawerItem(
                        icon: Icons.receipt_long,
                        title: 'Invoices',
                        onTap: openInvoices,
                      ),
                      drawerItem(
                        icon: Icons.construction,
                        title: 'Maintenance Tickets',
                        onTap: openTickets,
                      ),
                      if (canSeeBusinessTools)
                        drawerItem(
                          icon: Icons.auto_awesome,
                          title: 'SmartTenant Copilot',
                          onTap: openCopilot,
                        ),
                      drawerItem(
                        icon: Icons.auto_fix_high,
                        title: 'AI Assistant',
                        onTap: openAiAssistant,
                      ),
                      if (canSeeBusinessTools)
                        drawerItem(
                          icon: Icons.bar_chart,
                          title: 'Reports',
                          onTap: openReports,
                        ),
                      if (canSeeBusinessTools)
                        drawerItem(
                          icon: Icons.history,
                          title: 'Activity Logs',
                          onTap: openAuditLogs,
                        ),
                      drawerItem(
                        icon: Icons.person,
                        title: 'My Profile',
                        onTap: openProfile,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: logout,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget heroHeader({
    required num revenue,
    required num unpaid,
    required int occupancyRate,
  }) {
    final safeOccupancy = occupancyRate.clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6750A4), Color(0xFF8B7DD8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
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
                child: Icon(Icons.apartment, color: primary, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAdmin ? 'Platform Overview' : 'Owner Overview',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Welcome back 👋',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'A clean snapshot of revenue, occupancy, rent collection and maintenance activity.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.35),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: miniHeroMetric(
                  label: 'Revenue',
                  value: revenue.toStringAsFixed(2),
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: miniHeroMetric(
                  label: 'Unpaid',
                  value: unpaid.toStringAsFixed(2),
                  icon: Icons.warning_amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.pie_chart, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Occupancy rate: $safeOccupancy%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                safeOccupancy >= 80 ? 'Healthy' : 'Needs attention',
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
              value: safeOccupancy / 100,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget miniHeroMetric({
    required String label,
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget insightStrip({
    required num unpaid,
    required int openTickets,
    required int occupancyRate,
  }) {
    final items = <Map<String, dynamic>>[
      {
        'title': 'Collection Risk',
        'value': unpaid > 0 ? '${unpaid.toStringAsFixed(2)} unpaid' : 'Clear',
        'icon': Icons.account_balance_wallet,
        'color': unpaid > 0 ? Colors.orange : Colors.green,
      },
      {
        'title': 'Maintenance Load',
        'value': '$openTickets open',
        'icon': Icons.construction,
        'color': openTickets > 0 ? Colors.red : Colors.green,
      },
      {
        'title': 'Occupancy Health',
        'value': '$occupancyRate%',
        'icon': Icons.home_work,
        'color': occupancyRate >= 80 ? Colors.green : Colors.orange,
      },
    ];

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final item = items[index];
          final color = item['color'] as Color;

          return Container(
            width: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black.withOpacity(0.04)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.035),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(item['icon'] as IconData, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['value'].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: darkText,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['title'].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget statGridCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget statsGrid({
    required num properties,
    required num units,
    required num occupiedUnits,
    required num activeLeases,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.18,
      children: [
        statGridCard(
          title: 'Properties',
          value: properties.toString(),
          icon: Icons.apartment,
          color: primary,
        ),
        statGridCard(
          title: 'Units',
          value: units.toString(),
          icon: Icons.home_work,
          color: const Color(0xFF0EA5E9),
        ),
        statGridCard(
          title: 'Occupied',
          value: occupiedUnits.toString(),
          icon: Icons.key,
          color: const Color(0xFF22C55E),
        ),
        statGridCard(
          title: 'Active Leases',
          value: activeLeases.toString(),
          icon: Icons.description,
          color: const Color(0xFFF97316),
        ),
      ],
    );
  }

  Widget commandAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool featured = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
        width: featured ? 245 : 210,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: featured
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.72)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: featured ? null : Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: featured
                ? Colors.transparent
                : Colors.black.withOpacity(0.04),
          ),
          boxShadow: [
            BoxShadow(
              color: featured
                  ? color.withOpacity(0.25)
                  : Colors.black.withOpacity(0.035),
              blurRadius: 20,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: featured
                  ? Colors.white.withOpacity(0.18)
                  : color.withOpacity(0.12),
              child: Icon(icon, color: featured ? Colors.white : color),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: featured ? Colors.white : darkText,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: featured ? Colors.white70 : Colors.grey.shade700,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget commandCenter() {
    final actions = <Widget>[];

    if (isAdmin) {
      actions.addAll([
        commandAction(
          title: 'Users & Roles',
          subtitle: 'Create users and control permissions',
          icon: Icons.admin_panel_settings,
          color: Colors.red,
          featured: true,
          onTap: openUsersManagement,
        ),
        commandAction(
          title: 'Organizations',
          subtitle: 'Manage workspaces and status',
          icon: Icons.business,
          color: Colors.deepPurple,
          onTap: openOrganizationsManagement,
        ),
        commandAction(
          title: 'Activity Logs',
          subtitle: 'Review system actions and changes',
          icon: Icons.history,
          color: const Color(0xFF64748B),
          onTap: openAuditLogs,
        ),
        commandAction(
          title: 'Financial Reports',
          subtitle: 'Revenue, unpaid and PDF export',
          icon: Icons.bar_chart,
          color: const Color(0xFF14B8A6),
          onTap: openReports,
        ),
        commandAction(
          title: 'Tenants',
          subtitle: 'Create tenant accounts and rental profiles',
          icon: Icons.home_work,
          color: Colors.green,
          onTap: openTenants,
        ),
      ]);
    } else {
      actions.addAll([
        commandAction(
          title: 'SmartTenant Copilot',
          subtitle: 'AI briefing, risks and next actions',
          icon: Icons.auto_awesome,
          color: const Color(0xFF8B5CF6),
          featured: true,
          onTap: openCopilot,
        ),
        commandAction(
          title: 'Properties',
          subtitle: 'Manage buildings and units',
          icon: Icons.apartment,
          color: primary,
          onTap: openProperties,
        ),
        commandAction(
          title: 'Leases',
          subtitle: 'Create and manage occupancy',
          icon: Icons.description,
          color: const Color(0xFFF97316),
          onTap: openLeases,
        ),
        commandAction(
          title: 'Reports',
          subtitle: 'Financial summaries and PDF export',
          icon: Icons.bar_chart,
          color: const Color(0xFF14B8A6),
          onTap: openReports,
        ),
        commandAction(
          title: 'Tenants',
          subtitle: 'Create tenant accounts and prepare leases',
          icon: Icons.home_work,
          color: Colors.green,
          onTap: openTenants,
        ),
      ]);
    }

    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) => actions[index],
      ),
    );
  }

  Widget sectionTitle(String title, {VoidCallback? onViewAll}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
        ),
        if (onViewAll != null)
          TextButton(onPressed: onViewAll, child: const Text('View all')),
      ],
    );
  }

  Widget emptyActivity(String message) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text(message),
      ),
    );
  }

  Widget recentLeaseCard(dynamic lease) {
    final status = lease['status']?.toString() ?? '—';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: status == 'ACTIVE'
              ? Colors.green.withOpacity(0.12)
              : Colors.red.withOpacity(0.12),
          child: Icon(
            Icons.description,
            color: status == 'ACTIVE' ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          unitName(lease),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${propertyName(lease)}\n'
          'Tenant: ${tenantName(lease)} • Rent: ${lease['rentAmount'] ?? 0}',
        ),
        isThreeLine: true,
        trailing: Text(
          status,
          style: TextStyle(
            color: status == 'ACTIVE' ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LeaseDetailsPage(leaseId: lease['id']),
            ),
          ).then((_) => refreshDashboard());
        },
      ),
    );
  }

  Widget recentInvoiceCard(dynamic invoice) {
    final status = invoice['status']?.toString() ?? 'UNPAID';
    final amount = invoice['amount'] ?? 0;
    final remaining = invoice['remainingAmount'] ?? amount;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: invoiceStatusColor(status).withOpacity(0.12),
          child: Icon(Icons.receipt_long, color: invoiceStatusColor(status)),
        ),
        title: Text(
          'Invoice: $amount',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${propertyName(invoice)} • ${unitName(invoice)}\n'
          'Remaining: $remaining • Due: ${formatDate(invoice['dueDate'])}',
        ),
        isThreeLine: true,
        trailing: Text(
          status,
          style: TextStyle(
            color: invoiceStatusColor(status),
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvoiceDetailsPage(invoiceId: invoice['id']),
            ),
          ).then((_) => refreshDashboard());
        },
      ),
    );
  }

  Widget recentTicketCard(dynamic ticket) {
    final status = ticket['status']?.toString() ?? 'OPEN';
    final priority = ticket['priority']?.toString() ?? 'medium';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ticketStatusColor(status).withOpacity(0.12),
          child: Icon(Icons.construction, color: ticketStatusColor(status)),
        ),
        title: Text(
          ticket['title'] ?? 'Ticket',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${propertyName(ticket)} • ${unitName(ticket)}\n'
          'By: ${ticketUserName(ticket)} • Priority: $priority',
        ),
        isThreeLine: true,
        trailing: Text(
          status,
          style: TextStyle(
            color: ticketStatusColor(status),
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TicketDetailsPage(ticketId: ticket['id']),
            ),
          ).then((_) => refreshDashboard());
        },
      ),
    );
  }

  Widget recentActivityBlock({
    required List<dynamic> recentLeases,
    required List<dynamic> recentInvoices,
    required List<dynamic> recentTickets,
  }) {
    return Column(
      children: [
        sectionTitle('Recent Leases', onViewAll: openLeases),
        if (recentLeases.isEmpty)
          emptyActivity('No recent leases yet')
        else
          ...recentLeases.map(recentLeaseCard),
        const SizedBox(height: 22),
        sectionTitle('Recent Invoices', onViewAll: openInvoices),
        if (recentInvoices.isEmpty)
          emptyActivity('No recent invoices yet')
        else
          ...recentInvoices.map(recentInvoiceCard),
        const SizedBox(height: 22),
        sectionTitle('Recent Tickets', onViewAll: openTickets),
        if (recentTickets.isEmpty)
          emptyActivity('No recent tickets yet')
        else
          ...recentTickets.take(3).map(recentTicketCard),
      ],
    );
  }

  Widget dashboardBody() {
    final properties = value('properties');
    final units = value('units');
    final occupiedUnits = value('occupiedUnits');
    final activeLeases = value('activeLeases');
    final revenue = value('revenue');
    final unpaid = value('unpaid');

    final recentLeases = listValue('recentLeases');
    final recentInvoices = listValue('recentInvoices');
    final recentTickets = listValue('recentTickets');

    final occupancyRate = units == 0
        ? 0
        : ((occupiedUnits / units) * 100).round().clamp(0, 100);

    final openTickets = recentTickets.where((ticket) {
      final status = ticket['status']?.toString();
      return status == 'OPEN' || status == 'IN_PROGRESS';
    }).length;

    return RefreshIndicator(
      onRefresh: refreshDashboard,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          heroHeader(
            revenue: revenue,
            unpaid: unpaid,
            occupancyRate: occupancyRate,
          ),
          const SizedBox(height: 18),
          insightStrip(
            unpaid: unpaid,
            openTickets: openTickets,
            occupancyRate: occupancyRate,
          ),
          const SizedBox(height: 22),
          statsGrid(
            properties: properties,
            units: units,
            occupiedUnits: occupiedUnits,
            activeLeases: activeLeases,
          ),
          const SizedBox(height: 28),
          sectionTitle('Command Center'),
          const SizedBox(height: 10),
          commandCenter(),
          const SizedBox(height: 28),
          recentActivityBlock(
            recentLeases: recentLeases,
            recentInvoices: recentInvoices,
            recentTickets: recentTickets,
          ),
        ],
      ),
    );
  }

  Widget errorBody() {
    return RefreshIndicator(
      onRefresh: refreshDashboard,
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
                    'Could not load dashboard',
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
                    onPressed: refreshDashboard,
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
      backgroundColor: softBg,
      drawer: appDrawer(),
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
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
                      color: Colors.red,
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
            icon: const Icon(Icons.refresh),
            onPressed: refreshDashboard,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? errorBody()
          : dashboardBody(),
    );
  }
}
