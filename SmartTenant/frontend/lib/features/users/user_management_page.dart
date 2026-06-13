import 'package:flutter/material.dart';

import '../../core/ui/app_error.dart';
import 'user_management_service.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<dynamic> users = [];
  List<dynamic> organizations = [];

  bool loading = true;
  String error = '';

  String selectedRole = 'ALL';
  String selectedOrganization = 'ALL';
  String sortMode = 'Newest';

  final searchCtrl = TextEditingController();

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);
  static const darkText = Color(0xFF1D1B20);

  final roles = const ['ADMIN', 'OWNER', 'AGENT', 'ASSISTANT', 'TENANT'];

  @override
  void initState() {
    super.initState();
    searchCtrl.addListener(() => setState(() {}));
    loadData();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final usersData = await UserManagementService.getUsers();
      final orgsData = await UserManagementService.getOrganizations();

      if (!mounted) return;

      setState(() {
        users = usersData;
        organizations = orgsData;
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

  List<dynamic> get activeOrganizations {
    return organizations.where((org) => org['isActive'] == true).toList();
  }

  List<dynamic> get filteredUsers {
    final query = searchCtrl.text.trim().toLowerCase();

    final filtered = users.where((user) {
      final role = user['role']?.toString() ?? 'TENANT';
      final orgId = user['organizationId']?.toString();

      final name = displayName(user).toLowerCase();
      final email = user['email']?.toString().toLowerCase() ?? '';
      final phone = user['phone']?.toString().toLowerCase() ?? '';
      final organization = organizationName(user).toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          name.contains(query) ||
          email.contains(query) ||
          phone.contains(query) ||
          organization.contains(query) ||
          role.toLowerCase().contains(query);

      final matchesRole = selectedRole == 'ALL' || role == selectedRole;

      final matchesOrganization =
          selectedOrganization == 'ALL' ||
          (selectedOrganization == 'NONE' && orgId == null) ||
          orgId == selectedOrganization;

      return matchesSearch && matchesRole && matchesOrganization;
    }).toList();

    filtered.sort((a, b) {
      switch (sortMode) {
        case 'Name':
          return displayName(a).compareTo(displayName(b));

        case 'Role':
          return (a['role']?.toString() ?? '').compareTo(
            b['role']?.toString() ?? '',
          );

        case 'Organization':
          return organizationName(a).compareTo(organizationName(b));

        case 'Email':
          return (a['email']?.toString() ?? '').compareTo(
            b['email']?.toString() ?? '',
          );

        case 'Oldest':
          return parseDate(a['createdAt']).compareTo(parseDate(b['createdAt']));

        case 'Newest':
        default:
          return parseDate(b['createdAt']).compareTo(parseDate(a['createdAt']));
      }
    });

    return filtered;
  }

  DateTime parseDate(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);

    return DateTime.tryParse(value.toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  int roleCount(String role) {
    return users.where((user) => user['role']?.toString() == role).length;
  }

  int get adminCount => roleCount('ADMIN');

  int get ownerCount => roleCount('OWNER');

  int get agentCount => roleCount('AGENT');

  int get assistantCount => roleCount('ASSISTANT');

  int get tenantCount => roleCount('TENANT');

  String displayName(dynamic user) {
    final firstName = user['firstName'] ?? '';
    final lastName = user['lastName'] ?? '';
    final email = user['email'] ?? '';

    final fullName = '$firstName $lastName'.trim();

    if (fullName.isNotEmpty) return fullName;
    if (email.toString().isNotEmpty) return email;

    return 'User';
  }

  String initials(dynamic user) {
    final name = displayName(user).trim();

    if (name.isEmpty) return 'U';

    final parts = name.split(' ').where((p) => p.trim().isNotEmpty).toList();

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return name[0].toUpperCase();
  }

  String organizationName(dynamic user) {
    final org = user['organization'];

    if (org != null) {
      return org['name'] ?? org['slug'] ?? 'Organization';
    }

    final organizationId = user['organizationId'];

    if (organizationId != null) {
      return 'Organization attached';
    }

    return 'No organization';
  }

  String organizationLabel(dynamic organization) {
    final name = organization['name']?.toString() ?? '';
    final slug = organization['slug']?.toString() ?? '';

    if (name.isNotEmpty) return name;
    if (slug.isNotEmpty) return slug;

    return 'Organization';
  }

  String formatDate(dynamic value) {
    if (value == null) return '—';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    return parsed.toLocal().toString().split(' ')[0];
  }

  Color roleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return Colors.red;
      case 'OWNER':
        return primary;
      case 'AGENT':
        return Colors.orange;
      case 'ASSISTANT':
        return Colors.blue;
      case 'TENANT':
        return Colors.green;
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

  String roleDescription(String role) {
    switch (role) {
      case 'ADMIN':
        return 'Platform control, users, roles and organizations.';
      case 'OWNER':
        return 'Business management for properties, leases and payments.';
      case 'AGENT':
        return 'Operational access, tickets, read-only business data.';
      case 'ASSISTANT':
        return 'Support role for communication and ticket assistance.';
      case 'TENANT':
        return 'Self-service access to own invoices, payments and tickets.';
      default:
        return 'Application user.';
    }
  }

  Future<void> openCreateUserSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateUserSheet(
        roles: roles,
        organizations: activeOrganizations,
        roleColor: roleColor,
        roleIcon: roleIcon,
        roleDescription: roleDescription,
        organizationLabel: organizationLabel,
      ),
    );

    if (created == true) {
      await loadData();
    }
  }

  Future<void> changeRole(dynamic user, String newRole) async {
    final oldRole = user['role']?.toString() ?? '';

    if (newRole == oldRole) return;

    final isAdminChange = oldRole == 'ADMIN' || newRole == 'ADMIN';
    final isTenantChange = oldRole == 'TENANT' || newRole == 'TENANT';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Role'),
        content: Text(
          'Change ${displayName(user)} from $oldRole to $newRole?\n\n'
          '${roleDescription(newRole)}\n\n'
          '${isAdminChange ? 'Warning: ADMIN users have platform-level permissions.\n\n' : ''}'
          '${isTenantChange ? 'Tenant role changes may affect tenant access and rental profile logic.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check),
            label: const Text('Change Role'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await UserManagementService.changeRole(userId: user['id'], role: newRole);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${displayName(user)} is now $newRole')),
      );

      await loadData();
    } catch (e) {
      if (!mounted) return;

      await AppError.show(context, e, title: 'Could not change role');
    }
  }

  Future<void> changeOrganization(dynamic user) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangeOrganizationSheet(
        user: user,
        organizations: activeOrganizations,
        displayName: displayName(user),
        currentOrganizationId: user['organizationId']?.toString(),
        currentOrganizationName: organizationName(user),
        organizationLabel: organizationLabel,
      ),
    );

    if (selected == null) return;

    try {
      await UserManagementService.assignOrganization(
        userId: user['id'],
        organizationId: selected,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organization updated successfully')),
      );

      await loadData();
    } catch (e) {
      if (!mounted) return;

      await AppError.show(context, e, title: 'Organization change blocked');
    }
  }

  Future<void> deleteUser(dynamic user) async {
    final role = user['role']?.toString() ?? '';
    final isTenant = role == 'TENANT';
    final isAdmin = role == 'ADMIN';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Delete ${displayName(user)}?\n\n'
          '${isAdmin ? 'Warning: this is an ADMIN account.\n\n' : ''}'
          '${isTenant ? 'Warning: deleting tenant users may affect tenant profiles and rental history.\n\n' : ''}'
          'This action can affect related tenant profiles, tickets, leases, payments or messages. Backend safety rules may block unsafe deletion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await UserManagementService.deleteUser(user['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );

      await loadData();
    } catch (e) {
      if (!mounted) return;

      await AppError.show(context, e, title: 'Could not delete user');
    }
  }

  Future<void> openRoleSheet(dynamic user) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoleChangeSheet(
        userName: displayName(user),
        currentRole: user['role']?.toString() ?? 'TENANT',
        roles: roles,
        roleColor: roleColor,
        roleIcon: roleIcon,
        roleDescription: roleDescription,
      ),
    );

    if (selected != null) {
      await changeRole(user, selected);
    }
  }

  Future<void> openUserDetails(dynamic user) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailsSheet(
        user: user,
        displayName: displayName(user),
        initials: initials(user),
        organizationName: organizationName(user),
        formatDate: formatDate,
        roleColor: roleColor,
        roleIcon: roleIcon,
        roleDescription: roleDescription,
      ),
    );
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

  Widget header() {
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
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.admin_panel_settings, color: Colors.white, size: 44),
          const SizedBox(height: 18),
          const Text(
            'Users & Roles',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Control access, organizations and platform permissions.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: openCreateUserSheet,
              icon: const Icon(Icons.person_add),
              label: const Text('Create New User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: headerMetric(
                  title: 'Total Users',
                  value: users.length.toString(),
                  icon: Icons.groups,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: headerMetric(
                  title: 'Organizations',
                  value: organizations.length.toString(),
                  icon: Icons.business,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget roleSummaryStrip() {
    return Row(
      children: [
        Expanded(
          child: miniRoleCard(role: 'ADMIN', value: adminCount.toString()),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: miniRoleCard(role: 'OWNER', value: ownerCount.toString()),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: miniRoleCard(role: 'AGENT', value: agentCount.toString()),
        ),
      ],
    );
  }

  Widget secondRoleSummaryStrip() {
    return Row(
      children: [
        Expanded(
          child: miniRoleCard(
            role: 'ASSISTANT',
            value: assistantCount.toString(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: miniRoleCard(role: 'TENANT', value: tenantCount.toString()),
        ),
      ],
    );
  }

  Widget miniRoleCard({required String role, required String value}) {
    final color = roleColor(role);

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
          Icon(roleIcon(role), color: color, size: 22),
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
            role,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget searchAndFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: searchCtrl,
          decoration: InputDecoration(
            labelText: 'Search users',
            hintText: 'Name, email, phone, organization or role',
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
            children: [roleFilterChip('ALL'), ...roles.map(roleFilterChip)],
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: selectedOrganization,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Organization Filter',
            prefixIcon: Icon(Icons.business),
          ),
          items: [
            const DropdownMenuItem(
              value: 'ALL',
              child: Text('All organizations'),
            ),
            const DropdownMenuItem(
              value: 'NONE',
              child: Text('No organization'),
            ),
            ...organizations.map((org) {
              return DropdownMenuItem<String>(
                value: org['id']?.toString(),
                child: Text(
                  organizationLabel(org),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedOrganization = value);
          },
        ),
        const SizedBox(height: 14),
        Text(
          '${filteredUsers.length} result${filteredUsers.length == 1 ? '' : 's'}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 210,
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
                DropdownMenuItem(value: 'Email', child: Text('Email')),
                DropdownMenuItem(value: 'Role', child: Text('Role')),
                DropdownMenuItem(
                  value: 'Organization',
                  child: Text('Organization'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => sortMode = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget roleFilterChip(String role) {
    final active = selectedRole == role;
    final color = role == 'ALL' ? primary : roleColor(role);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: active,
        label: Text(role),
        avatar: role == 'ALL'
            ? Icon(
                Icons.all_inclusive,
                size: 18,
                color: active ? Colors.white : color,
              )
            : Icon(
                roleIcon(role),
                size: 18,
                color: active ? Colors.white : color,
              ),
        selectedColor: color,
        backgroundColor: color.withOpacity(0.10),
        labelStyle: TextStyle(
          color: active ? Colors.white : color,
          fontWeight: FontWeight.bold,
        ),
        side: BorderSide.none,
        onSelected: (_) {
          setState(() => selectedRole = role);
        },
      ),
    );
  }

  Widget roleBadge(String role) {
    final color = roleColor(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(roleIcon(role), size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            role,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget userCard(dynamic user) {
    final role = user['role']?.toString() ?? 'TENANT';
    final email = user['email']?.toString() ?? '';
    final phone = user['phone']?.toString() ?? '';
    final color = roleColor(role);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => openUserDetails(user),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: color.withOpacity(0.12),
                    child: Text(
                      initials(user),
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
                          displayName(user),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'view') openUserDetails(user);
                      if (value == 'role') openRoleSheet(user);
                      if (value == 'organization') changeOrganization(user);
                      if (value == 'delete') deleteUser(user);
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
                      PopupMenuItem(
                        value: 'role',
                        child: Row(
                          children: [
                            Icon(Icons.badge),
                            SizedBox(width: 10),
                            Text('Change role'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'organization',
                        child: Row(
                          children: [
                            Icon(Icons.business),
                            SizedBox(width: 10),
                            Text('Change organization'),
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
                            Text('Delete'),
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
                  roleBadge(role),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      organizationName(user),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
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
                child: Text(
                  roleDescription(role),
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget emptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 56, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            const Text(
              'No users found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Try changing the search text, role filter or organization filter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: openCreateUserSheet,
              icon: const Icon(Icons.person_add),
              label: const Text('Create User'),
            ),
          ],
        ),
      ),
    );
  }

  Widget loadingBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        header(),
        const SizedBox(height: 24),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget errorBody() {
    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          header(),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 42),
                  const SizedBox(height: 12),
                  const Text(
                    'Could not load users',
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
                    onPressed: loadData,
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

  Widget buildBody() {
    if (loading) return loadingBody();

    if (error.isNotEmpty) return errorBody();

    final data = filteredUsers;

    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          header(),
          const SizedBox(height: 18),
          roleSummaryStrip(),
          const SizedBox(height: 10),
          secondRoleSummaryStrip(),
          const SizedBox(height: 22),
          searchAndFilters(),
          const SizedBox(height: 14),
          if (data.isEmpty) emptyState() else ...data.map(userCard),
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
          'Users & Roles',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: openCreateUserSheet,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadData),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openCreateUserSheet,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
      body: buildBody(),
    );
  }
}

class _CreateUserSheet extends StatefulWidget {
  final List<String> roles;
  final List<dynamic> organizations;
  final Color Function(String role) roleColor;
  final IconData Function(String role) roleIcon;
  final String Function(String role) roleDescription;
  final String Function(dynamic organization) organizationLabel;

  const _CreateUserSheet({
    required this.roles,
    required this.organizations,
    required this.roleColor,
    required this.roleIcon,
    required this.roleDescription,
    required this.organizationLabel,
  });

  @override
  State<_CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends State<_CreateUserSheet> {
  final formKey = GlobalKey<FormState>();

  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  String role = 'OWNER';
  String? selectedOrganizationId;

  bool creating = false;
  bool obscurePassword = true;

  String error = '';

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  bool get organizationRequired => role != 'ADMIN';

  @override
  void initState() {
    super.initState();

    if (widget.organizations.isNotEmpty) {
      selectedOrganizationId = widget.organizations.first['id']?.toString();
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  String? emailValidator(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return 'Email is required';

    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);

    if (!valid) return 'Invalid email address';

    return null;
  }

  String? passwordValidator(String? value) {
    final text = value ?? '';

    if (text.isEmpty) return 'Password is required';
    if (text.length < 6) return 'Password must be at least 6 characters';

    return null;
  }

  String? organizationValidator(String? value) {
    if (!organizationRequired) return null;

    if (value == null || value.trim().isEmpty) {
      return 'Organization is required for this role';
    }

    return null;
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    if (organizationRequired && selectedOrganizationId == null) {
      setState(() => error = 'Organization is required for $role users');
      return;
    }

    setState(() {
      creating = true;
      error = '';
    });

    try {
      await UserManagementService.createUser(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
        role: role,
        firstName: firstNameCtrl.text.trim(),
        lastName: lastNameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        organizationId: role == 'ADMIN' ? null : selectedOrganizationId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$role user created successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = AppError.clean(e);
      });
    } finally {
      if (mounted) setState(() => creating = false);
    }
  }

  Widget organizationDropdown() {
    if (!organizationRequired) {
      return Card(
        color: primary.withOpacity(0.08),
        child: const ListTile(
          leading: Icon(Icons.info_outline, color: primary),
          title: Text(
            'Organization optional',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'ADMIN users are platform-level accounts and do not require an organization.',
          ),
        ),
      );
    }

    if (widget.organizations.isEmpty) {
      return Card(
        color: Colors.orange.withOpacity(0.10),
        child: const ListTile(
          leading: Icon(Icons.warning_amber, color: Colors.orange),
          title: Text(
            'No active organizations found',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Create or reactivate an organization before creating non-admin users.',
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: selectedOrganizationId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Organization',
        prefixIcon: Icon(Icons.business),
      ),
      items: widget.organizations.map((organization) {
        return DropdownMenuItem<String>(
          value: organization['id']?.toString(),
          child: Text(
            widget.organizationLabel(organization),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      validator: organizationValidator,
      onChanged: creating
          ? null
          : (value) {
              setState(() => selectedOrganizationId = value);
            },
    );
  }

  Widget roleOption(String item) {
    final active = role == item;
    final color = widget.roleColor(item);

    return Card(
      color: active ? color.withOpacity(0.10) : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(widget.roleIcon(item), color: color),
        ),
        title: Text(item, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(widget.roleDescription(item)),
        trailing: active
            ? Icon(Icons.check_circle, color: color)
            : const Icon(Icons.radio_button_unchecked),
        onTap: creating
            ? null
            : () {
                setState(() {
                  role = item;

                  if (role == 'ADMIN') {
                    selectedOrganizationId = null;
                  } else if (selectedOrganizationId == null &&
                      widget.organizations.isNotEmpty) {
                    selectedOrganizationId = widget.organizations.first['id']
                        ?.toString();
                  }

                  error = '';
                });
              },
      ),
    );
  }

  Widget tenantNote() {
    if (role != 'TENANT') return const SizedBox.shrink();

    return Card(
      color: Colors.green.withOpacity(0.08),
      child: const ListTile(
        leading: Icon(Icons.info_outline, color: Colors.green),
        title: Text(
          'Tenant onboarding note',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'For normal tenant onboarding, owners can create tenant accounts and profiles directly from the Tenants page.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = widget.roleColor(role);

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
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: selectedColor.withOpacity(0.12),
                        child: Icon(
                          widget.roleIcon(role),
                          color: selectedColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Create User',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: creating
                            ? null
                            : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create a platform account, assign a role, and attach it to the correct organization.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !creating,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: emailValidator,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: obscurePassword,
                    enabled: !creating,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: creating
                            ? null
                            : () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                      ),
                    ),
                    validator: passwordValidator,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: firstNameCtrl,
                          enabled: !creating,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: lastNameCtrl,
                          enabled: !creating,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    enabled: !creating,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Role',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.roles.map(roleOption),
                  const SizedBox(height: 14),
                  tenantNote(),
                  if (role == 'TENANT') const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Organization',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  organizationDropdown(),
                  const SizedBox(height: 12),
                  Card(
                    color: selectedColor.withOpacity(0.08),
                    child: ListTile(
                      leading: Icon(Icons.info_outline, color: selectedColor),
                      title: Text(
                        '$role permissions',
                        style: TextStyle(
                          color: selectedColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(widget.roleDescription(role)),
                    ),
                  ),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Card(
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
                                style: const TextStyle(color: Colors.red),
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
                      onPressed:
                          creating ||
                              (organizationRequired &&
                                  widget.organizations.isEmpty)
                          ? null
                          : submit,
                      icon: creating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_add),
                      label: Text(creating ? 'Creating...' : 'Create User'),
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
      ),
    );
  }
}

class _ChangeOrganizationSheet extends StatefulWidget {
  final dynamic user;
  final List<dynamic> organizations;
  final String displayName;
  final String? currentOrganizationId;
  final String currentOrganizationName;
  final String Function(dynamic organization) organizationLabel;

  const _ChangeOrganizationSheet({
    required this.user,
    required this.organizations,
    required this.displayName,
    required this.currentOrganizationId,
    required this.currentOrganizationName,
    required this.organizationLabel,
  });

  @override
  State<_ChangeOrganizationSheet> createState() =>
      _ChangeOrganizationSheetState();
}

class _ChangeOrganizationSheetState extends State<_ChangeOrganizationSheet> {
  String? selectedOrganizationId;

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  @override
  void initState() {
    super.initState();

    if (widget.currentOrganizationId != null) {
      selectedOrganizationId = widget.currentOrganizationId;
    } else if (widget.organizations.isNotEmpty) {
      selectedOrganizationId = widget.organizations.first['id']?.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.user['role']?.toString() ?? '';

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
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primary.withOpacity(0.12),
                    child: const Icon(Icons.business, color: primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Change Organization',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(widget.displayName),
                  subtitle: Text(
                    'Current: ${widget.currentOrganizationName}\nRole: $role',
                  ),
                  isThreeLine: true,
                ),
              ),
              const SizedBox(height: 12),
              if (role == 'TENANT')
                Card(
                  color: Colors.orange.withOpacity(0.10),
                  child: const ListTile(
                    leading: Icon(Icons.warning_amber, color: Colors.orange),
                    title: Text(
                      'Tenant movement protection',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Tenant users with rental history cannot be moved. The backend will block unsafe organization changes.',
                    ),
                  ),
                ),
              if (role == 'TENANT') const SizedBox(height: 12),
              if (widget.organizations.isEmpty)
                Card(
                  color: Colors.orange.withOpacity(0.10),
                  child: const ListTile(
                    leading: Icon(Icons.warning_amber, color: Colors.orange),
                    title: Text(
                      'No active organizations',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Create or reactivate an organization first.',
                    ),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: selectedOrganizationId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'New Organization',
                    prefixIcon: Icon(Icons.business),
                  ),
                  items: widget.organizations.map((organization) {
                    return DropdownMenuItem<String>(
                      value: organization['id']?.toString(),
                      child: Text(
                        widget.organizationLabel(organization),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedOrganizationId = value);
                  },
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      selectedOrganizationId == null ||
                          selectedOrganizationId == widget.currentOrganizationId
                      ? null
                      : () => Navigator.pop(context, selectedOrganizationId),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Change Organization'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChangeSheet extends StatelessWidget {
  final String userName;
  final String currentRole;
  final List<String> roles;
  final Color Function(String role) roleColor;
  final IconData Function(String role) roleIcon;
  final String Function(String role) roleDescription;

  const _RoleChangeSheet({
    required this.userName,
    required this.currentRole,
    required this.roles,
    required this.roleColor,
    required this.roleIcon,
    required this.roleDescription,
  });

  static const softBg = Color(0xFFF8F5FF);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.92,
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
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: roleColor(currentRole).withOpacity(0.12),
                      child: Icon(
                        roleIcon(currentRole),
                        color: roleColor(currentRole),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Change Role',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  userName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                ...roles.map((role) {
                  final active = role == currentRole;
                  final color = roleColor(role);

                  return Card(
                    color: active ? color.withOpacity(0.10) : Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.12),
                        child: Icon(roleIcon(role), color: color),
                      ),
                      title: Text(
                        role,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        roleDescription(role),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: active
                          ? Icon(Icons.check_circle, color: color)
                          : const Icon(Icons.chevron_right),
                      onTap: active ? null : () => Navigator.pop(context, role),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UserDetailsSheet extends StatelessWidget {
  final dynamic user;
  final String displayName;
  final String initials;
  final String organizationName;
  final String Function(dynamic value) formatDate;
  final Color Function(String role) roleColor;
  final IconData Function(String role) roleIcon;
  final String Function(String role) roleDescription;

  const _UserDetailsSheet({
    required this.user,
    required this.displayName,
    required this.initials,
    required this.organizationName,
    required this.formatDate,
    required this.roleColor,
    required this.roleIcon,
    required this.roleDescription,
  });

  static const softBg = Color(0xFFF8F5FF);

  Widget infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
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
    final role = user['role']?.toString() ?? 'TENANT';
    final color = roleColor(role);
    final tenant = user['tenant'];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: softBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user['email']?.toString() ?? '—',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        infoRow('Role', role),
                        infoRow('Phone', user['phone']),
                        infoRow('Organization', organizationName),
                        infoRow('Created', formatDate(user['createdAt'])),
                        infoRow('Updated', formatDate(user['updatedAt'])),
                        if (tenant != null) ...[
                          infoRow('Tenant Profile', tenant['id']),
                          infoRow('National ID', tenant['nationalId']),
                          infoRow(
                            'Tenant Since',
                            formatDate(tenant['createdAt']),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: color.withOpacity(0.08),
                  child: ListTile(
                    leading: Icon(roleIcon(role), color: color),
                    title: Text(
                      '$role permissions',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(roleDescription(role)),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
