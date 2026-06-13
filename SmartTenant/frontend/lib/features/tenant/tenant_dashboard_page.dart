import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_storage.dart';
import '../auth/login_page.dart';
import '../invoice/invoice_details.dart';
import '../tickets/create_ticket_page.dart';
import '../tickets/ticket_details_page.dart';
import '../profile/profile_page.dart';
import '../notifications/notification_page.dart';
import '../notifications/notification_service.dart';

class TenantDashboardPage extends StatefulWidget {
  const TenantDashboardPage({super.key});

  @override
  State<TenantDashboardPage> createState() => _TenantDashboardPageState();
}

class _TenantDashboardPageState extends State<TenantDashboardPage> {
  bool loading = true;
  String error = '';
  int unreadNotifications = 0;

  String displayName = 'Tenant';

  List<dynamic> invoices = [];
  List<dynamic> tickets = [];

  String currentSection = 'DASHBOARD';

  static const primary = Color(0xFF6750A4);
  static const darkText = Color(0xFF1D1B20);
  static const softBg = Color(0xFFF8F5FF);

  @override
  void initState() {
    super.initState();
    refreshDashboard();
  }

  Future<void> refreshDashboard() async {
    await Future.wait([loadTenantData(), loadUnreadNotifications()]);
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

  Future<void> loadTenantData() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final name = await AuthStorage.getDisplayName();

      final invoicesRes = await ApiClient.get('/invoices/me');
      final ticketsRes = await ApiClient.get('/tickets/me');

      if (!mounted) return;

      setState(() {
        displayName = name;
        invoices = invoicesRes is List ? invoicesRes : [];
        tickets = ticketsRes is List ? ticketsRes : [];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void switchSection(String section) {
    Navigator.pop(context);

    setState(() {
      currentSection = section;
    });
  }

  String sectionTitle() {
    switch (currentSection) {
      case 'INVOICES':
        return 'My Invoices';
      case 'TICKETS':
        return 'My Tickets';
      default:
        return 'Tenant Dashboard';
    }
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

  Future<void> openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationPage()),
    );

    await loadUnreadNotifications();
  }

  Future<void> openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );

    await refreshDashboard();
  }

  Future<void> openCreateTicket() async {
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.pop(context);
      await Future.delayed(const Duration(milliseconds: 120));
    }

    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateTicketPage()),
    );

    if (created == true) {
      await refreshDashboard();

      if (!mounted) return;

      setState(() {
        currentSection = 'TICKETS';
      });
    }
  }

  num invoiceAmount(dynamic invoice) {
    final value = invoice['amount'];

    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  num invoiceRemaining(dynamic invoice) {
    final value = invoice['remainingAmount'];

    if (value is num) return value;

    final amount = invoiceAmount(invoice);
    final paid = invoice['totalPaid'];

    if (paid is num) {
      final remaining = amount - paid;
      return remaining < 0 ? 0 : remaining;
    }

    return amount;
  }

  num invoicePaid(dynamic invoice) {
    final value = invoice['totalPaid'];

    if (value is num) return value;

    final amount = invoiceAmount(invoice);
    final remaining = invoiceRemaining(invoice);

    final paid = amount - remaining;
    return paid < 0 ? 0 : paid;
  }

  num get totalUnpaid {
    return invoices.fold<num>(
      0,
      (sum, invoice) => sum + invoiceRemaining(invoice),
    );
  }

  num get totalPaid {
    return invoices.fold<num>(0, (sum, invoice) => sum + invoicePaid(invoice));
  }

  int get paidInvoices {
    return invoices.where((invoice) {
      return invoice['status']?.toString() == 'PAID';
    }).length;
  }

  int get unpaidInvoices {
    return invoices.where((invoice) {
      final remaining = invoiceRemaining(invoice);
      return remaining > 0;
    }).length;
  }

  int get openTickets {
    return tickets.where((ticket) {
      final status = ticket['status']?.toString();
      return status == 'OPEN' || status == 'IN_PROGRESS';
    }).length;
  }

  int get resolvedTickets {
    return tickets.where((ticket) {
      final status = ticket['status']?.toString();
      return status == 'RESOLVED' || status == 'CLOSED';
    }).length;
  }

  int get urgentTickets {
    return tickets.where((ticket) {
      final priority = ticket['priority']?.toString();
      return priority == 'urgent' || priority == 'high';
    }).length;
  }

  List<dynamic> get recentInvoices {
    return invoices.take(5).toList();
  }

  List<dynamic> get recentTickets {
    return tickets.take(5).toList();
  }

  String formatDate(dynamic value) {
    if (value == null) return '—';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    return parsed.toLocal().toString().split(' ')[0];
  }

  String unitName(dynamic invoiceOrTicket) {
    final unit = invoiceOrTicket['lease']?['unit'] ?? invoiceOrTicket['unit'];

    if (unit != null) {
      return unit['title'] ?? unit['number'] ?? 'Unit';
    }

    return 'Unit';
  }

  String propertyName(dynamic invoiceOrTicket) {
    final property =
        invoiceOrTicket['lease']?['unit']?['property'] ??
        invoiceOrTicket['property'];

    if (property != null) {
      return property['title'] ?? property['name'] ?? 'Property';
    }

    return 'Property';
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

  Widget drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: selected ? Colors.white : primary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : darkText,
        ),
      ),
      trailing: trailing,
      selected: selected,
      selectedTileColor: primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: onTap,
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
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.home, color: primary, size: 30),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Tenant Space',
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
                child: ListView(
                  children: [
                    drawerItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      selected: currentSection == 'DASHBOARD',
                      onTap: () => switchSection('DASHBOARD'),
                    ),
                    drawerItem(
                      icon: Icons.receipt_long,
                      title: 'My Invoices',
                      selected: currentSection == 'INVOICES',
                      trailing: unpaidInvoices > 0
                          ? Text(
                              unpaidInvoices.toString(),
                              style: TextStyle(
                                color: currentSection == 'INVOICES'
                                    ? Colors.white
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                      onTap: () => switchSection('INVOICES'),
                    ),
                    drawerItem(
                      icon: Icons.construction,
                      title: 'My Tickets',
                      selected: currentSection == 'TICKETS',
                      trailing: openTickets > 0
                          ? Text(
                              openTickets.toString(),
                              style: TextStyle(
                                color: currentSection == 'TICKETS'
                                    ? Colors.white
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                      onTap: () => switchSection('TICKETS'),
                    ),
                    drawerItem(
                      icon: Icons.add_task,
                      title: 'Create Ticket',
                      onTap: openCreateTicket,
                    ),
                    drawerItem(
                      icon: Icons.person,
                      title: 'My Profile',
                      onTap: () {
                        Navigator.pop(context);
                        openProfile();
                      },
                    ),
                  ],
                ),
              ),

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

  Widget heroHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6750A4), Color(0xFF8B7DD8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.home, color: Colors.white, size: 42),
          const SizedBox(height: 18),
          Text(
            'Hello, $displayName 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Here is your rent and maintenance overview.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: miniHeroMetric(
                  label: 'Unpaid Rent',
                  value: totalUnpaid.toStringAsFixed(2),
                  icon: Icons.warning_amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: miniHeroMetric(
                  label: 'Open Tickets',
                  value: openTickets.toString(),
                  icon: Icons.construction,
                ),
              ),
            ],
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

  Widget statsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.18,
      children: [
        statGridCard(
          title: 'Total Invoices',
          value: invoices.length.toString(),
          icon: Icons.receipt_long,
          color: primary,
        ),
        statGridCard(
          title: 'Unpaid Invoices',
          value: unpaidInvoices.toString(),
          icon: Icons.warning_amber,
          color: Colors.red,
        ),
        statGridCard(
          title: 'Paid Amount',
          value: totalPaid.toStringAsFixed(2),
          icon: Icons.payments,
          color: Colors.green,
        ),
        statGridCard(
          title: 'Urgent Tickets',
          value: urgentTickets.toString(),
          icon: Icons.priority_high,
          color: const Color(0xFF0EA5E9),
        ),
      ],
    );
  }

  Widget quickAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget sectionTitleWithAction({
    required String title,
    String? subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ],
          ),
        ),
        if (actionText != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionText)),
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

  Widget invoiceCard(dynamic invoice) {
    final status = invoice['status']?.toString() ?? 'UNPAID';
    final amount = invoiceAmount(invoice);
    final remaining = invoiceRemaining(invoice);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: invoiceStatusColor(status).withOpacity(0.12),
          child: Icon(Icons.receipt_long, color: invoiceStatusColor(status)),
        ),
        title: Text(
          'Rent invoice: ${amount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${propertyName(invoice)} • ${unitName(invoice)}\n'
          'Remaining: ${remaining.toStringAsFixed(2)} • Due: ${formatDate(invoice['dueDate'])}',
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

  Widget ticketCard(dynamic ticket) {
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
          'Priority: $priority',
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              status,
              style: TextStyle(
                color: ticketStatusColor(status),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: priorityColor(priority).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                priority,
                style: TextStyle(
                  color: priorityColor(priority),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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

  Widget dashboardSection() {
    return RefreshIndicator(
      onRefresh: refreshDashboard,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          heroHeader(),
          const SizedBox(height: 18),
          statsGrid(),
          const SizedBox(height: 26),
          sectionTitleWithAction(title: 'Quick Actions'),
          const SizedBox(height: 8),
          quickAction(
            title: 'My Invoices',
            subtitle: 'View rent, unpaid balance and due dates',
            icon: Icons.receipt_long,
            color: Colors.green,
            onTap: () => setState(() => currentSection = 'INVOICES'),
          ),
          quickAction(
            title: 'My Tickets',
            subtitle: 'View maintenance requests and replies',
            icon: Icons.construction,
            color: Colors.orange,
            onTap: () => setState(() => currentSection = 'TICKETS'),
          ),
          quickAction(
            title: 'Create Maintenance Ticket',
            subtitle: 'Report a problem in your unit',
            icon: Icons.add_task,
            color: primary,
            onTap: openCreateTicket,
          ),
          quickAction(
            title: 'My Profile',
            subtitle: 'View your account, tenant profile and leases',
            icon: Icons.person,
            color: const Color(0xFF0EA5E9),
            onTap: openProfile,
          ),
          const SizedBox(height: 26),
          sectionTitleWithAction(
            title: 'Recent Invoices',
            actionText: 'View all',
            onAction: () => setState(() => currentSection = 'INVOICES'),
          ),
          const SizedBox(height: 8),
          if (recentInvoices.isEmpty)
            emptyActivity('No invoices yet')
          else
            ...recentInvoices.map(invoiceCard),
          const SizedBox(height: 24),
          sectionTitleWithAction(
            title: 'Recent Tickets',
            actionText: 'View all',
            onAction: () => setState(() => currentSection = 'TICKETS'),
          ),
          const SizedBox(height: 8),
          if (recentTickets.isEmpty)
            emptyActivity('No tickets yet')
          else
            ...recentTickets.map(ticketCard),
        ],
      ),
    );
  }

  Widget invoicesSection() {
    return RefreshIndicator(
      onRefresh: refreshDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          sectionHero(
            icon: Icons.receipt_long,
            title: 'My Invoices',
            subtitle: '${invoices.length} invoice(s), $unpaidInvoices unpaid',
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          if (invoices.isEmpty)
            emptyActivity('No invoices yet')
          else
            ...invoices.map(invoiceCard),
        ],
      ),
    );
  }

  Widget ticketsSection() {
    return RefreshIndicator(
      onRefresh: refreshDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          sectionHero(
            icon: Icons.construction,
            title: 'My Tickets',
            subtitle: '$openTickets open, $resolvedTickets resolved',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: openCreateTicket,
            icon: const Icon(Icons.add_task),
            label: const Text('Create Ticket'),
          ),
          const SizedBox(height: 16),
          if (tickets.isEmpty)
            emptyActivity('No tickets yet')
          else
            ...tickets.map(ticketCard),
        ],
      ),
    );
  }

  Widget sectionHero({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget currentBody() {
    switch (currentSection) {
      case 'INVOICES':
        return invoicesSection();
      case 'TICKETS':
        return ticketsSection();
      default:
        return dashboardSection();
    }
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
                    'Could not load tenant dashboard',
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
        title: Text(
          sectionTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold),
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
          : currentBody(),
    );
  }
}
