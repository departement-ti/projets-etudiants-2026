import 'package:flutter/material.dart';

import '../../core/auth/auth_storage.dart';
import '../../core/ui/app_error.dart';
import '../auth/login_page.dart';
import '../invoice/invoice_details.dart';
import 'profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? user;
  Map<String, dynamic>? tenantProfile;

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
  static const teal = Color(0xFF14B8A6);
  static const purple = Color(0xFF8B5CF6);

  final sections = const [
    {'id': 'OVERVIEW', 'label': 'Overview', 'icon': Icons.dashboard_customize},
    {'id': 'ACCOUNT', 'label': 'Account', 'icon': Icons.person},
    {'id': 'SECURITY', 'label': 'Security', 'icon': Icons.security},
    {'id': 'TENANT', 'label': 'Tenant', 'icon': Icons.home},
  ];

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  bool get isTenant => user?['role']?.toString() == 'TENANT';

  bool get hasOrganization => user?['organization'] != null;

  bool get hasTenantProfile {
    return tenantProfile != null || user?['tenant'] != null;
  }

  List<dynamic> get tenantLeases {
    final data = tenantProfile?['leases'] ?? user?['tenant']?['leases'];

    if (data is List) return data;

    return [];
  }

  List<dynamic> get allTenantInvoices {
    final invoices = <dynamic>[];

    for (final lease in tenantLeases) {
      final leaseInvoices = lease['invoices'];
      if (leaseInvoices is List) {
        invoices.addAll(leaseInvoices);
      }
    }

    invoices.sort((a, b) {
      return parseDate(b['dueDate']).compareTo(parseDate(a['dueDate']));
    });

    return invoices;
  }

  dynamic get activeLease {
    for (final lease in tenantLeases) {
      if (lease['status']?.toString() == 'ACTIVE') return lease;
    }

    return null;
  }

  int get openInvoiceCount {
    return allTenantInvoices.where((invoice) {
      final status = invoice['status']?.toString();
      return status == 'UNPAID' || status == 'PARTIALLY_PAID';
    }).length;
  }

  num get totalInvoiceAmount {
    return allTenantInvoices.fold<num>(0, (sum, invoice) {
      return sum + asNum(invoice['amount']);
    });
  }

  num get totalOutstanding {
    return allTenantInvoices.fold<num>(0, (sum, invoice) {
      final status = invoice['status']?.toString();
      if (status == 'PAID') return sum;

      final remaining = invoice['remainingAmount'];
      if (remaining != null) return sum + asNum(remaining);

      return sum + asNum(invoice['amount']);
    });
  }

  int get profileCompletion {
    int completed = 0;
    const total = 6;

    if ((user?['firstName']?.toString() ?? '').trim().isNotEmpty) completed++;
    if ((user?['lastName']?.toString() ?? '').trim().isNotEmpty) completed++;
    if ((user?['email']?.toString() ?? '').trim().isNotEmpty) completed++;
    if ((user?['phone']?.toString() ?? '').trim().isNotEmpty) completed++;
    if ((user?['role']?.toString() ?? '').trim().isNotEmpty) completed++;
    if (hasOrganization || isTenant) completed++;

    return ((completed / total) * 100).round();
  }

  Color get profileHealthColor {
    if (profileCompletion >= 85) return success;
    if (profileCompletion >= 60) return warning;

    return danger;
  }

  String get profileHealthLabel {
    if (profileCompletion >= 85) return 'Profile looks excellent';
    if (profileCompletion >= 60) return 'Profile needs a few details';

    return 'Profile needs completion';
  }

  Future<void> loadProfile({bool silent = false}) async {
    if (silent) {
      setState(() => refreshing = true);
    } else {
      setState(() {
        loading = true;
        error = '';
      });
    }

    try {
      final userData = await ProfileService.getMe();

      Map<String, dynamic>? tenantData;

      if (userData['role'] == 'TENANT') {
        try {
          tenantData = await ProfileService.getTenantProfile();
        } catch (_) {
          tenantData = null;
        }
      }

      if (!mounted) return;

      setState(() {
        user = userData;
        tenantProfile = tenantData;
        loading = false;
        refreshing = false;
        error = '';
      });
    } catch (e) {
      if (!mounted) return;

      if (silent) {
        setState(() => refreshing = false);

        await AppError.show(context, e, title: 'Could not refresh profile');

        return;
      }

      setState(() {
        error = AppError.clean(e);
        loading = false;
        refreshing = false;
      });
    }
  }

  Future<void> openEditProfile() async {
    if (user == null) return;

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(user: user!),
    );

    if (updated == true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      await loadProfile(silent: true);
    }
  }

  Future<void> openChangePassword() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChangePasswordSheet(),
    );

    if (changed == true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
    }
  }

  Future<void> confirmLogout() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SafeActionSheet(
        icon: Icons.logout,
        color: danger,
        title: 'Logout from SmartTenant?',
        message:
            'You will return to the login screen. Your local session will be cleared from this device.',
        confirmText: 'Logout',
      ),
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

  Future<void> openProfileDetails() async {
    if (user == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileDetailsSheet(
        user: user!,
        tenantProfile: tenantProfile,
        displayName: displayName(),
        initials: initials(),
        roleColor: roleColor,
        roleIcon: roleIcon,
        formatDate: formatDate,
        money: money,
        totalOutstanding: totalOutstanding,
        totalInvoiceAmount: totalInvoiceAmount,
        openInvoiceCount: openInvoiceCount,
        profileCompletion: profileCompletion,
        profileHealthLabel: profileHealthLabel,
        profileHealthColor: profileHealthColor,
      ),
    );
  }

  DateTime parseDate(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);

    return DateTime.tryParse(value.toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  num asNum(dynamic value) {
    if (value is num) return value;

    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  String money(dynamic value) {
    return asNum(value).toStringAsFixed(2);
  }

  String formatDate(dynamic value) {
    if (value == null) return '—';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    return parsed.toLocal().toString().split(' ')[0];
  }

  String displayName() {
    final firstName = user?['firstName']?.toString() ?? '';
    final lastName = user?['lastName']?.toString() ?? '';
    final email = user?['email']?.toString() ?? '';

    final fullName = '$firstName $lastName'.trim();

    if (fullName.isNotEmpty) return fullName;
    if (email.isNotEmpty) return email;

    return 'SmartTenant User';
  }

  String initials() {
    final name = displayName().trim();

    if (name.isEmpty) return 'U';

    final parts = name
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return name[0].toUpperCase();
  }

  String organizationName() {
    final org = user?['organization'];

    if (org is Map) {
      return org['name']?.toString() ??
          org['slug']?.toString() ??
          'Organization';
    }

    return 'No organization';
  }

  String organizationStatus() {
    final org = user?['organization'];

    if (org is Map && org['isActive'] == true) return 'Active workspace';
    if (org is Map && org['isActive'] == false) return 'Inactive workspace';

    return isTenant ? 'Tenant workspace' : 'No workspace attached';
  }

  String roleDescription(String role) {
    switch (role) {
      case 'ADMIN':
        return 'Platform administrator with SaaS control.';
      case 'OWNER':
        return 'Business owner managing properties, leases and payments.';
      case 'AGENT':
        return 'Operational user for tickets, leases and property workflows.';
      case 'ASSISTANT':
        return 'Support user with limited operational access.';
      case 'TENANT':
        return 'Tenant self-service profile for invoices, payments and tickets.';
      default:
        return 'SmartTenant application user.';
    }
  }

  Color roleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return danger;
      case 'OWNER':
        return primary;
      case 'AGENT':
        return warning;
      case 'ASSISTANT':
        return info;
      case 'TENANT':
        return success;
      default:
        return Colors.grey;
    }
  }

  IconData roleIcon(String role) {
    switch (role) {
      case 'ADMIN':
        return Icons.admin_panel_settings;
      case 'OWNER':
        return Icons.workspace_premium;
      case 'AGENT':
        return Icons.engineering;
      case 'ASSISTANT':
        return Icons.support_agent;
      case 'TENANT':
        return Icons.home;
      default:
        return Icons.person;
    }
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

  String unitName(dynamic lease) {
    final unit = lease['unit'];

    if (unit != null) {
      return unit['title']?.toString() ?? unit['number']?.toString() ?? 'Unit';
    }

    return 'Unit';
  }

  Color invoiceStatusColor(String? status) {
    switch (status) {
      case 'PAID':
        return success;
      case 'PARTIALLY_PAID':
        return warning;
      case 'UNPAID':
        return danger;
      default:
        return Colors.grey;
    }
  }

  IconData invoiceStatusIcon(String? status) {
    switch (status) {
      case 'PAID':
        return Icons.check_circle;
      case 'PARTIALLY_PAID':
        return Icons.timelapse;
      case 'UNPAID':
        return Icons.warning_amber;
      default:
        return Icons.receipt_long;
    }
  }

  Widget heroHeader() {
    final role = user?['role']?.toString() ?? 'USER';
    final email = user?['email']?.toString() ?? '';
    final color = roleColor(role);

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
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                child: Text(
                  initials(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName(),
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
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: Icon(roleIcon(role), color: color, size: 18),
                          label: Text(role),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                          side: BorderSide.none,
                        ),
                        Chip(
                          avatar: Icon(
                            hasOrganization ? Icons.apartment : Icons.info,
                            color: primary,
                            size: 18,
                          ),
                          label: Text(organizationName()),
                          backgroundColor: Colors.white,
                          labelStyle: const TextStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                          ),
                          side: BorderSide.none,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Refresh',
                onPressed: refreshing || loading
                    ? null
                    : () => loadProfile(silent: true),
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
                Icon(Icons.health_and_safety, color: profileHealthColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$profileHealthLabel • $profileCompletion% complete',
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
              value: profileCompletion / 100,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: heroButton(
                  icon: Icons.edit,
                  label: 'Edit',
                  onTap: openEditProfile,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: heroButton(
                  icon: Icons.lock_reset,
                  label: 'Security',
                  onTap: openChangePassword,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: heroButton(
                  icon: Icons.insights,
                  label: 'Details',
                  onTap: openProfileDetails,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget heroButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget compactKpis() {
    final role = user?['role']?.toString() ?? 'USER';

    final items = [
      _ProfileKpi(
        title: 'Role',
        value: role,
        icon: roleIcon(role),
        color: roleColor(role),
      ),
      _ProfileKpi(
        title: 'Completion',
        value: '$profileCompletion%',
        icon: Icons.auto_graph,
        color: profileHealthColor,
      ),
      _ProfileKpi(
        title: 'Leases',
        value: tenantLeases.length.toString(),
        icon: Icons.description,
        color: info,
      ),
      _ProfileKpi(
        title: 'Open Invoices',
        value: openInvoiceCount.toString(),
        icon: Icons.receipt_long,
        color: openInvoiceCount > 0 ? warning : success,
      ),
      _ProfileKpi(
        title: 'Outstanding',
        value: money(totalOutstanding),
        icon: Icons.warning_amber,
        color: totalOutstanding > 0 ? danger : success,
      ),
      _ProfileKpi(
        title: 'Workspace',
        value: hasOrganization ? 'Attached' : '—',
        icon: Icons.apartment,
        color: hasOrganization ? primary : Colors.grey,
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
                onTap: openProfileDetails,
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
    final visibleSections = sections.where((item) {
      if (item['id'] == 'TENANT' && !isTenant) return false;
      return true;
    }).toList();

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleSections.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final item = visibleSections[index];
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

  Widget overviewSection() {
    final role = user?['role']?.toString() ?? 'USER';

    return Column(
      children: [
        profileSnapshotCard(),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: miniActionCard(
                title: 'Edit',
                value: 'Profile',
                icon: Icons.edit,
                color: primary,
                onTap: openEditProfile,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: miniActionCard(
                title: 'Password',
                value: 'Security',
                icon: Icons.lock_reset,
                color: warning,
                onTap: openChangePassword,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: miniActionCard(
                title: 'Details',
                value: 'View',
                icon: Icons.open_in_new,
                color: info,
                onTap: openProfileDetails,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Card(
          color: roleColor(role).withOpacity(0.07),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: roleColor(role).withOpacity(0.12),
              child: Icon(roleIcon(role), color: roleColor(role)),
            ),
            title: Text(
              role,
              style: TextStyle(
                color: roleColor(role),
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(roleDescription(role)),
          ),
        ),

        const SizedBox(height: 14),

        organizationMiniCard(),

        if (isTenant) ...[const SizedBox(height: 14), tenantQuickSummaryCard()],
      ],
    );
  }

  Widget profileSnapshotCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            snapshotRow(
              title: 'Profile completion',
              value: '$profileCompletion%',
              icon: Icons.auto_graph,
              color: profileHealthColor,
            ),
            const Divider(height: 20),
            snapshotRow(
              title: 'Organization',
              value: hasOrganization ? 'Attached' : 'Not attached',
              icon: Icons.apartment,
              color: hasOrganization ? success : warning,
            ),
            const Divider(height: 20),
            snapshotRow(
              title: 'Account status',
              value: 'Active',
              icon: Icons.verified_user,
              color: success,
            ),
          ],
        ),
      ),
    );
  }

  Widget snapshotRow({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget miniActionCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 25),
              const SizedBox(height: 8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget organizationMiniCard() {
    final org = user?['organization'];

    if (org == null) {
      return Card(
        color: warning.withOpacity(0.08),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: warning.withOpacity(0.12),
            child: const Icon(Icons.info_outline, color: warning),
          ),
          title: const Text(
            'No organization attached',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            isTenant
                ? 'Tenant data is shown through your tenant profile.'
                : 'Organization access is managed by an administrator.',
          ),
        ),
      );
    }

    final active = org['isActive'] == true;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (active ? success : danger).withOpacity(0.12),
          child: Icon(Icons.apartment, color: active ? success : danger),
        ),
        title: Text(
          org['name']?.toString() ?? 'Organization',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${org['slug'] ?? 'workspace'} • ${organizationStatus()}',
        ),
        trailing: Icon(
          active ? Icons.check_circle : Icons.block,
          color: active ? success : danger,
        ),
      ),
    );
  }

  Widget accountSection() {
    return Column(
      children: [
        accountInfoCard(),
        const SizedBox(height: 14),
        organizationDetailsCard(),
        const SizedBox(height: 14),
        Card(
          color: primary.withOpacity(0.07),
          child: ListTile(
            leading: const Icon(Icons.lock_outline, color: primary),
            title: const Text(
              'Protected account fields',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Email, role and organization are managed by administrators and cannot be changed from this page.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ),
      ],
    );
  }

  Widget accountInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            sectionTitleRow(
              title: 'Account Information',
              icon: Icons.person,
              color: primary,
              actionText: 'Edit',
              onAction: openEditProfile,
            ),
            const SizedBox(height: 10),
            infoRow('First Name', user?['firstName']),
            infoRow('Last Name', user?['lastName']),
            infoRow('Email', user?['email']),
            infoRow('Phone', user?['phone']),
            infoRow('Role', user?['role']),
            infoRow('Created', formatDate(user?['createdAt'])),
            infoRow('Updated', formatDate(user?['updatedAt'])),
          ],
        ),
      ),
    );
  }

  Widget organizationDetailsCard() {
    final organization = user?['organization'];

    if (organization == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            sectionTitleRow(
              title: 'Organization',
              icon: Icons.apartment,
              color: primary,
            ),
            const SizedBox(height: 10),
            infoRow('Name', organization['name']),
            infoRow('Slug', organization['slug']),
            infoRow(
              'Status',
              organization['isActive'] == true ? 'Active' : 'Inactive',
            ),
          ],
        ),
      ),
    );
  }

  Widget securitySection() {
    return Column(
      children: [
        Card(
          color: success.withOpacity(0.07),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                sectionTitleRow(
                  title: 'Security Center',
                  icon: Icons.security,
                  color: success,
                ),
                const SizedBox(height: 12),
                snapshotRow(
                  title: 'Authentication',
                  value: 'Password protected',
                  icon: Icons.lock,
                  color: success,
                ),
                const Divider(height: 20),
                snapshotRow(
                  title: 'Session',
                  value: 'Active',
                  icon: Icons.verified_user,
                  color: success,
                ),
                const Divider(height: 20),
                snapshotRow(
                  title: 'Role access',
                  value: user?['role']?.toString() ?? 'USER',
                  icon: roleIcon(user?['role']?.toString() ?? 'USER'),
                  color: roleColor(user?['role']?.toString() ?? 'USER'),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                actionTile(
                  icon: Icons.lock_reset,
                  color: warning,
                  title: 'Change Password',
                  subtitle: 'Update your account password securely.',
                  onTap: openChangePassword,
                ),
                const Divider(height: 18),
                actionTile(
                  icon: Icons.refresh,
                  color: info,
                  title: 'Refresh Profile',
                  subtitle: 'Reload your latest account and workspace data.',
                  onTap: () => loadProfile(silent: true),
                ),
                const Divider(height: 18),
                actionTile(
                  icon: Icons.logout,
                  color: danger,
                  title: loggingOut ? 'Logging out...' : 'Logout',
                  subtitle: 'Clear your local session and return to login.',
                  onTap: loggingOut ? null : confirmLogout,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget tenantSection() {
    if (!isTenant) return const SizedBox.shrink();

    return Column(
      children: [
        tenantQuickSummaryCard(),
        const SizedBox(height: 14),
        tenantProfileCard(),
        const SizedBox(height: 14),
        tenantLeasesCompactCard(),
        const SizedBox(height: 14),
        tenantInvoicesCompactCard(),
      ],
    );
  }

  Widget tenantQuickSummaryCard() {
    final lease = activeLease;

    return Card(
      color: primary.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            sectionTitleRow(
              title: 'Tenant Snapshot',
              icon: Icons.home,
              color: primary,
              actionText: 'Open',
              onAction: () => setState(() => selectedSection = 'TENANT'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: compactMetric(
                    title: 'Leases',
                    value: tenantLeases.length.toString(),
                    icon: Icons.description,
                    color: info,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: compactMetric(
                    title: 'Open Invoices',
                    value: openInvoiceCount.toString(),
                    icon: Icons.receipt_long,
                    color: openInvoiceCount > 0 ? warning : success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: compactMetric(
                    title: 'Outstanding',
                    value: money(totalOutstanding),
                    icon: Icons.warning_amber,
                    color: totalOutstanding > 0 ? danger : success,
                  ),
                ),
              ],
            ),
            if (lease != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'Current unit: ${unitName(lease)} • ${propertyName(lease)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget compactMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
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

  Widget tenantProfileCard() {
    final tenant = tenantProfile ?? user?['tenant'];

    if (tenant == null) {
      return Card(
        color: warning.withOpacity(0.08),
        child: const ListTile(
          leading: Icon(Icons.info_outline, color: warning),
          title: Text(
            'Tenant profile not found',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Your account exists, but no tenant profile was found.',
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            sectionTitleRow(
              title: 'Tenant Profile',
              icon: Icons.badge,
              color: success,
            ),
            const SizedBox(height: 10),
            infoRow('Tenant ID', tenant['id']),
            infoRow('National ID', tenant['nationalId']),
            infoRow('Risk Score', tenant['riskScore']),
            infoRow('Created', formatDate(tenant['createdAt'])),
          ],
        ),
      ),
    );
  }

  Widget tenantLeasesCompactCard() {
    final leases = tenantLeases.take(4).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            sectionTitleRow(
              title: 'My Leases',
              icon: Icons.description,
              color: info,
            ),
            const SizedBox(height: 10),
            if (leases.isEmpty)
              emptyInline('No leases yet')
            else
              ...leases.map(leaseTile),
          ],
        ),
      ),
    );
  }

  Widget leaseTile(dynamic lease) {
    final status = lease['status']?.toString() ?? '—';
    final color = status == 'ACTIVE' ? success : danger;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.12),
        child: Icon(Icons.description, color: color),
      ),
      title: Text(
        unitName(lease),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${propertyName(lease)}\nRent: ${lease['rentAmount'] ?? '—'} • ${lease['frequency'] ?? '—'}',
      ),
      isThreeLine: true,
      trailing: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget tenantInvoicesCompactCard() {
    final invoices = allTenantInvoices.take(6).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            sectionTitleRow(
              title: 'Lease Invoices',
              icon: Icons.receipt_long,
              color: warning,
            ),
            const SizedBox(height: 10),
            if (invoices.isEmpty)
              emptyInline('No lease invoices yet')
            else
              ...invoices.map(invoiceTile),
          ],
        ),
      ),
    );
  }

  Widget invoiceTile(dynamic invoice) {
    final status = invoice['status']?.toString() ?? 'UNPAID';
    final color = invoiceStatusColor(status);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.12),
        child: Icon(invoiceStatusIcon(status), color: color),
      ),
      title: Text(
        'Amount: ${money(invoice['amount'])}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Status: $status • Due: ${formatDate(invoice['dueDate'])}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        final id = invoice['id']?.toString();
        if (id == null || id.isEmpty) return;

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => InvoiceDetailsPage(invoiceId: id)),
        ).then((_) => loadProfile(silent: true));
      },
    );
  }

  Widget selectedSectionBody() {
    switch (selectedSection) {
      case 'ACCOUNT':
        return accountSection();

      case 'SECURITY':
        return securitySection();

      case 'TENANT':
        return tenantSection();

      case 'OVERVIEW':
      default:
        return overviewSection();
    }
  }

  Widget sectionTitleRow({
    required String title,
    required IconData icon,
    required Color color,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
        ),
        if (actionText != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionText)),
      ],
    );
  }

  Widget actionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.12),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget infoRow(String label, dynamic value) {
    final text = value?.toString();

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
              text == null || text.trim().isEmpty ? '—' : text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
      onRefresh: () => loadProfile(),
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
                    'Could not load profile',
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
                    onPressed: () => loadProfile(),
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
      onRefresh: () => loadProfile(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 120),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Icon(Icons.person_off, size: 60, color: Colors.grey.shade500),
                  const SizedBox(height: 12),
                  const Text(
                    'Profile not found',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Refresh the page or login again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => loadProfile(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
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
      onRefresh: () => loadProfile(silent: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          heroHeader(),

          const SizedBox(height: 16),

          compactKpis(),

          const SizedBox(height: 16),

          sectionSelector(),

          const SizedBox(height: 16),

          selectedSectionBody(),

          const SizedBox(height: 16),

          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: danger.withOpacity(0.12),
                child: loggingOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout, color: danger),
              ),
              title: const Text(
                'Logout',
                style: TextStyle(color: danger, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('End this session on this device.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: loggingOut ? null : confirmLogout,
            ),
          ),

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
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Details',
            icon: const Icon(Icons.insights),
            onPressed: user == null ? null : openProfileDetails,
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
            onPressed: loading || refreshing
                ? null
                : () => loadProfile(silent: true),
          ),
        ],
      ),
      body: loading
          ? loadingBody()
          : error.isNotEmpty
          ? errorBody()
          : user == null
          ? emptyBody()
          : bodyContent(),
    );
  }
}

class _ProfileKpi {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ProfileKpi({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> user;

  const _EditProfileSheet({required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController firstNameCtrl;
  late final TextEditingController lastNameCtrl;
  late final TextEditingController phoneCtrl;

  bool saving = false;
  String error = '';

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  @override
  void initState() {
    super.initState();

    firstNameCtrl = TextEditingController(
      text: widget.user['firstName']?.toString() ?? '',
    );
    lastNameCtrl = TextEditingController(
      text: widget.user['lastName']?.toString() ?? '',
    );
    phoneCtrl = TextEditingController(
      text: widget.user['phone']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  String clean(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> save() async {
    FocusScope.of(context).unfocus();

    setState(() => error = '');

    if (!formKey.currentState!.validate()) {
      setState(() => error = 'Please complete the required fields.');
      return;
    }

    setState(() => saving = true);

    try {
      final updatedUser = await ProfileService.updateMe(
        firstName: clean(firstNameCtrl.text),
        lastName: clean(lastNameCtrl.text),
        phone: clean(phoneCtrl.text),
      );

      await AuthStorage.updateCachedUser(
        firstName: updatedUser['firstName']?.toString() ?? '',
        lastName: updatedUser['lastName']?.toString() ?? '',
        email: updatedUser['email']?.toString(),
        role: updatedUser['role']?.toString(),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = AppError.clean(e);
        saving = false;
      });

      await AppError.show(context, e, title: 'Could not update profile');
    }
  }

  String? nameValidator(String? value) {
    final text = clean(value ?? '');

    if (text.isEmpty) return 'Required';
    if (text.length < 2) return 'Too short';

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.user['email']?.toString() ?? '—';
    final role = widget.user['role']?.toString() ?? 'USER';

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
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dragHandle(),

                  const SizedBox(height: 20),

                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: Color(0xFFEDE9FE),
                    child: Icon(Icons.edit, color: primary, size: 34),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Update your personal information.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),

                  const SizedBox(height: 22),

                  TextFormField(
                    controller: firstNameCtrl,
                    enabled: !saving,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: nameValidator,
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: lastNameCtrl,
                    enabled: !saving,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: nameValidator,
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: phoneCtrl,
                    enabled: !saving,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Card(
                    color: primary.withOpacity(0.07),
                    child: ListTile(
                      leading: const Icon(Icons.lock_outline, color: primary),
                      title: const Text(
                        'Protected fields',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Email: $email\nRole: $role',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ),

                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Card(
                      color: Colors.red.withOpacity(0.08),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
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
                    ),
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
                          : const Icon(Icons.save),
                      label: Text(saving ? 'Saving...' : 'Save Changes'),
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final currentPasswordCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  bool saving = false;
  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  String error = '';

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF97316);
  static const danger = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();

    currentPasswordCtrl.addListener(() => setState(() {}));
    newPasswordCtrl.addListener(() => setState(() {}));
    confirmPasswordCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    currentPasswordCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.dispose();
  }

  bool get hasCurrent => currentPasswordCtrl.text.trim().isNotEmpty;

  bool get hasMinLength => newPasswordCtrl.text.trim().length >= 6;

  bool get hasDifferent {
    final current = currentPasswordCtrl.text.trim();
    final next = newPasswordCtrl.text.trim();

    return current.isNotEmpty && next.isNotEmpty && current != next;
  }

  bool get matchesConfirm {
    final next = newPasswordCtrl.text.trim();
    final confirm = confirmPasswordCtrl.text.trim();

    return next.isNotEmpty && confirm.isNotEmpty && next == confirm;
  }

  int get strengthScore {
    final password = newPasswordCtrl.text.trim();

    int score = 0;

    if (password.length >= 6) score += 25;
    if (password.length >= 10) score += 20;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 15;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 15;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score += 15;
    if (hasDifferent) score += 10;

    return score.clamp(0, 100);
  }

  Color get strengthColor {
    if (strengthScore >= 75) return success;
    if (strengthScore >= 45) return warning;

    return danger;
  }

  String get strengthLabel {
    if (strengthScore >= 75) return 'Strong password';
    if (strengthScore >= 45) return 'Medium password';

    return 'Weak password';
  }

  Future<void> save() async {
    FocusScope.of(context).unfocus();

    final currentPassword = currentPasswordCtrl.text.trim();
    final newPassword = newPasswordCtrl.text.trim();
    final confirmPassword = confirmPasswordCtrl.text.trim();

    setState(() => error = '');

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() => error = 'All fields are required');
      return;
    }

    if (newPassword.length < 6) {
      setState(() => error = 'New password must be at least 6 characters');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => error = 'Passwords do not match');
      return;
    }

    if (currentPassword == newPassword) {
      setState(
        () => error = 'New password must be different from current password',
      );
      return;
    }

    setState(() => saving = true);

    try {
      await ProfileService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = AppError.clean(e);
        saving = false;
      });

      await AppError.show(context, e, title: 'Could not change password');
    }
  }

  Widget passwordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      enabled: !saving,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: saving ? null : onToggle,
        ),
      ),
    );
  }

  Widget ruleItem(String title, bool done) {
    return Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: (done ? success : Colors.grey).withOpacity(0.12),
          child: Icon(
            done ? Icons.check : Icons.circle_outlined,
            color: done ? success : Colors.grey,
            size: 17,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: done ? Colors.grey.shade900 : Colors.grey.shade700,
              fontWeight: done ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
                _dragHandle(),

                const SizedBox(height: 20),

                CircleAvatar(
                  radius: 34,
                  backgroundColor: strengthColor.withOpacity(0.12),
                  child: Icon(Icons.lock_reset, color: strengthColor, size: 34),
                ),

                const SizedBox(height: 14),

                const Text(
                  'Change Password',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                Text(
                  'Protect your account with a secure password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),

                const SizedBox(height: 22),

                passwordField(
                  controller: currentPasswordCtrl,
                  label: 'Current Password',
                  icon: Icons.lock,
                  obscure: obscureCurrent,
                  onToggle: () =>
                      setState(() => obscureCurrent = !obscureCurrent),
                ),

                const SizedBox(height: 14),

                passwordField(
                  controller: newPasswordCtrl,
                  label: 'New Password',
                  icon: Icons.lock_outline,
                  obscure: obscureNew,
                  onToggle: () => setState(() => obscureNew = !obscureNew),
                ),

                const SizedBox(height: 14),

                passwordField(
                  controller: confirmPasswordCtrl,
                  label: 'Confirm New Password',
                  icon: Icons.verified_user,
                  obscure: obscureConfirm,
                  onToggle: () =>
                      setState(() => obscureConfirm = !obscureConfirm),
                ),

                const SizedBox(height: 16),

                Card(
                  color: strengthColor.withOpacity(0.07),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: strengthColor.withOpacity(0.12),
                              child: Icon(Icons.security, color: strengthColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                strengthLabel,
                                style: TextStyle(
                                  color: strengthColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              '$strengthScore%',
                              style: TextStyle(
                                color: strengthColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: strengthScore / 100,
                            minHeight: 8,
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              strengthColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ruleItem('Current password entered', hasCurrent),
                        const SizedBox(height: 8),
                        ruleItem('At least 6 characters', hasMinLength),
                        const SizedBox(height: 8),
                        ruleItem(
                          'Different from current password',
                          hasDifferent,
                        ),
                        const SizedBox(height: 8),
                        ruleItem('Confirmation matches', matchesConfirm),
                      ],
                    ),
                  ),
                ),

                if (error.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Card(
                    color: danger.withOpacity(0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: danger),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              error,
                              style: const TextStyle(
                                color: danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                        : const Icon(Icons.save),
                    label: Text(saving ? 'Updating...' : 'Update Password'),
                  ),
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.of(context).pop(false),
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

class _ProfileDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic>? tenantProfile;
  final String displayName;
  final String initials;
  final Color Function(String role) roleColor;
  final IconData Function(String role) roleIcon;
  final String Function(dynamic value) formatDate;
  final String Function(dynamic value) money;
  final num totalOutstanding;
  final num totalInvoiceAmount;
  final int openInvoiceCount;
  final int profileCompletion;
  final String profileHealthLabel;
  final Color profileHealthColor;

  const _ProfileDetailsSheet({
    required this.user,
    required this.tenantProfile,
    required this.displayName,
    required this.initials,
    required this.roleColor,
    required this.roleIcon,
    required this.formatDate,
    required this.money,
    required this.totalOutstanding,
    required this.totalInvoiceAmount,
    required this.openInvoiceCount,
    required this.profileCompletion,
    required this.profileHealthLabel,
    required this.profileHealthColor,
  });

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  @override
  Widget build(BuildContext context) {
    final role = user['role']?.toString() ?? 'USER';
    final color = roleColor(role);
    final organization = user['organization'];
    final tenant = tenantProfile ?? user['tenant'];

    return DraggableScrollableSheet(
      initialChildSize: 0.86,
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
                  radius: 40,
                  backgroundColor: color.withOpacity(0.12),
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: color,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  user['email']?.toString() ?? '',
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
                      avatar: Icon(roleIcon(role), color: color, size: 18),
                      label: Text(role),
                      backgroundColor: color.withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide.none,
                    ),
                    Chip(
                      avatar: Icon(
                        Icons.health_and_safety,
                        color: profileHealthColor,
                        size: 18,
                      ),
                      label: Text('$profileCompletion% complete'),
                      backgroundColor: profileHealthColor.withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: profileHealthColor,
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide.none,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Card(
                  color: profileHealthColor.withOpacity(0.07),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: profileHealthColor.withOpacity(
                                0.12,
                              ),
                              child: Icon(
                                Icons.monitor_heart,
                                color: profileHealthColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                profileHealthLabel,
                                style: TextStyle(
                                  color: profileHealthColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              '$profileCompletion%',
                              style: TextStyle(
                                color: profileHealthColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: profileCompletion / 100,
                            minHeight: 8,
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              profileHealthColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                detailsCard('Account', {
                  'First Name': user['firstName'],
                  'Last Name': user['lastName'],
                  'Email': user['email'],
                  'Phone': user['phone'],
                  'Role': user['role'],
                  'Created': formatDate(user['createdAt']),
                  'Updated': formatDate(user['updatedAt']),
                }),

                if (organization != null) ...[
                  const SizedBox(height: 12),
                  detailsCard('Organization', {
                    'Name': organization['name'],
                    'Slug': organization['slug'],
                    'Status': organization['isActive'] == true
                        ? 'Active'
                        : 'Inactive',
                  }),
                ],

                if (tenant != null) ...[
                  const SizedBox(height: 12),
                  detailsCard('Tenant Profile', {
                    'Tenant ID': tenant['id'],
                    'National ID': tenant['nationalId'],
                    'Risk Score': tenant['riskScore'],
                    'Created': formatDate(tenant['createdAt']),
                    'Total Invoiced': money(totalInvoiceAmount),
                    'Total Outstanding': money(totalOutstanding),
                    'Open Invoices': openInvoiceCount,
                  }),
                ],

                const SizedBox(height: 12),

                Card(
                  color: primary.withOpacity(0.07),
                  child: const ListTile(
                    leading: Icon(Icons.privacy_tip, color: primary),
                    title: Text(
                      'Privacy note',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Profile details are used inside SmartTenant for access control, organization ownership and tenant self-service workflows.',
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

  Widget detailsCard(String title, Map<String, dynamic> values) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primary.withOpacity(0.12),
                  child: const Icon(Icons.info_outline, color: primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...values.entries.map((entry) {
              final value = entry.value?.toString();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        '${entry.key}:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        value == null || value.trim().isEmpty ? '—' : value,
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
}

class _SafeActionSheet extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String confirmText;

  const _SafeActionSheet({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.confirmText,
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
              _dragHandle(),

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
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, height: 1.45),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  icon: Icon(icon),
                  label: Text(confirmText),
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
