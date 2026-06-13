import 'package:flutter/material.dart';

import '../../core/auth/auth_storage.dart';
import '../../core/ui/app_error.dart';
import 'properties_service.dart';
import '../units/units_page.dart';
import 'create_property_page.dart';

class PropertiesPage extends StatefulWidget {
  const PropertiesPage({super.key});

  @override
  State<PropertiesPage> createState() => _PropertiesPageState();
}

class _PropertiesPageState extends State<PropertiesPage> {
  List<dynamic> properties = [];

  final searchCtrl = TextEditingController();

  bool loading = true;
  bool refreshing = false;
  String error = '';
  String? role;

  String sortMode = 'Newest';
  String selectedStatus = 'ALL';
  String viewMode = 'CARDS';
  String? actionPropertyId;

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);
  static const darkText = Color(0xFF1D1B20);

  bool get canManageProperties {
    return role == 'ADMIN' || role == 'OWNER';
  }

  @override
  void initState() {
    super.initState();
    searchCtrl.addListener(() => setState(() {}));
    loadProperties();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> loadProperties({bool silent = false}) async {
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
      final data = await PropertiesService.getAll();

      if (!mounted) return;

      setState(() {
        role = userRole;
        properties = data;
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

  String propertyTitle(dynamic property) {
    return property['title']?.toString() ??
        property['name']?.toString() ??
        property['address']?.toString() ??
        'Property';
  }

  String propertyAddress(dynamic property) {
    final value = property['address']?.toString();

    if (value == null || value.trim().isEmpty) return 'No address';

    return value;
  }

  String propertyLocation(dynamic property) {
    final city = property['city']?.toString() ?? '';
    final country = property['country']?.toString() ?? '';

    final result = [
      city,
      country,
    ].where((value) => value.trim().isNotEmpty).join(', ');

    return result.isEmpty ? 'No location' : result;
  }

  bool isActive(dynamic property) {
    return property['isActive'] != false;
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

  String initials(dynamic property) {
    final title = propertyTitle(property).trim();

    if (title.isEmpty) return 'P';

    final parts = title
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return title[0].toUpperCase();
  }

  Color propertyColor(dynamic property) {
    if (!isActive(property)) return Colors.grey;

    final city = property['city']?.toString().trim() ?? '';
    final country = property['country']?.toString().trim() ?? '';

    if (city.isNotEmpty || country.isNotEmpty) return primary;

    return const Color(0xFF0EA5E9);
  }

  int get activeProperties {
    return properties.where((property) => isActive(property)).length;
  }

  int get inactiveProperties {
    return properties.length - activeProperties;
  }

  int get propertiesWithLocation {
    return properties.where((property) {
      return property['city']?.toString().trim().isNotEmpty == true ||
          property['country']?.toString().trim().isNotEmpty == true;
    }).length;
  }

  int get locationCompletionRate {
    if (properties.isEmpty) return 0;

    return ((propertiesWithLocation / properties.length) * 100).round();
  }

  List<dynamic> get filteredProperties {
    final query = searchCtrl.text.trim().toLowerCase();

    final filtered = properties.where((property) {
      final status = isActive(property) ? 'ACTIVE' : 'INACTIVE';

      final searchable = [
        propertyTitle(property),
        propertyAddress(property),
        propertyLocation(property),
        property['city']?.toString() ?? '',
        property['country']?.toString() ?? '',
        status,
      ].join(' ').toLowerCase();

      final matchesSearch = query.isEmpty || searchable.contains(query);
      final matchesStatus = selectedStatus == 'ALL' || selectedStatus == status;

      return matchesSearch && matchesStatus;
    }).toList();

    filtered.sort((a, b) {
      switch (sortMode) {
        case 'Name':
          return propertyTitle(a).compareTo(propertyTitle(b));

        case 'City':
          return (a['city']?.toString() ?? '').compareTo(
            b['city']?.toString() ?? '',
          );

        case 'Country':
          return (a['country']?.toString() ?? '').compareTo(
            b['country']?.toString() ?? '',
          );

        case 'Status':
          return isActive(b).toString().compareTo(isActive(a).toString());

        case 'Updated':
          return parseDate(b['updatedAt']).compareTo(parseDate(a['updatedAt']));

        case 'Oldest':
          return parseDate(a['createdAt']).compareTo(parseDate(b['createdAt']));

        case 'Newest':
        default:
          return parseDate(b['createdAt']).compareTo(parseDate(a['createdAt']));
      }
    });

    return filtered;
  }

  Future<void> openCreateProperty() async {
    if (!canManageProperties) return;

    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePropertyPage()),
    );

    if (created == true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property created successfully')),
      );

      await loadProperties(silent: true);
    }
  }

  Future<void> openUnits(dynamic property) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnitsPage(
          propertyId: property['id'],
          propertyTitle: propertyTitle(property),
        ),
      ),
    );

    await loadProperties(silent: true);
  }

  Future<void> openPropertyDetails(dynamic property) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PropertyDetailsSheet(
        property: property,
        title: propertyTitle(property),
        address: propertyAddress(property),
        location: propertyLocation(property),
        active: isActive(property),
        initials: initials(property),
        formatDate: formatDate,
        canManage: canManageProperties,
        onOpenUnits: () async {
          Navigator.pop(context);
          await openUnits(property);
        },
        onEdit: () async {
          Navigator.pop(context);
          await openEditProperty(property);
        },
        onDeactivate: () async {
          Navigator.pop(context);
          await deactivateProperty(property);
        },
      ),
    );
  }

  Future<void> openEditProperty(dynamic property) async {
    if (!canManageProperties) return;

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PropertyFormSheet(property: property),
    );

    if (updated == true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property updated successfully')),
      );

      await loadProperties(silent: true);
    }
  }

  Future<bool> confirmDeactivateProperty(dynamic property) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _DeactivatePropertySheet(propertyTitle: propertyTitle(property)),
    );

    return result == true;
  }

  Future<void> deactivateProperty(dynamic property) async {
    if (!canManageProperties) return;

    if (!isActive(property)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property is already inactive')),
      );
      return;
    }

    final confirmed = await confirmDeactivateProperty(property);
    if (!confirmed) return;

    final id = property['id']?.toString();

    setState(() => actionPropertyId = id);

    try {
      await PropertiesService.delete(property['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property deactivated successfully')),
      );

      await loadProperties(silent: true);
    } catch (e) {
      if (!mounted) return;

      await AppError.show(context, e, title: 'Could not deactivate property');
    } finally {
      if (mounted) setState(() => actionPropertyId = null);
    }
  }

  void resetFilters() {
    setState(() {
      searchCtrl.clear();
      selectedStatus = 'ALL';
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
                child: Icon(Icons.apartment, color: primary, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      canManageProperties
                          ? 'Property Portfolio'
                          : 'Properties View',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      canManageProperties
                          ? 'Manage rental assets, locations and units.'
                          : 'Browse property information with read-only access.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: refreshing
                    ? null
                    : () => loadProperties(silent: true),
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
                  title: 'Total',
                  value: properties.length.toString(),
                  icon: Icons.apartment,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Active',
                  value: activeProperties.toString(),
                  icon: Icons.check_circle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Inactive',
                  value: inactiveProperties.toString(),
                  icon: Icons.block,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Location Data',
                  value: '$locationCompletionRate%',
                  icon: Icons.location_on,
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
                  'Location completion: $locationCompletionRate%',
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
              value: locationCompletionRate / 100,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          if (canManageProperties) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: openCreateProperty,
                icon: const Icon(Icons.add_business),
                label: const Text('Create Property'),
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

  Widget searchAndFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                labelText: 'Search properties',
                hintText: 'Name, address, city, country or status',
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
                      DropdownMenuItem(
                        value: 'Updated',
                        child: Text('Updated'),
                      ),
                      DropdownMenuItem(value: 'Name', child: Text('Name')),
                      DropdownMenuItem(value: 'City', child: Text('City')),
                      DropdownMenuItem(
                        value: 'Country',
                        child: Text('Country'),
                      ),
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

  Widget statusFilterChip(String status, IconData icon) {
    final selected = selectedStatus == status;

    final color = status == 'ACTIVE'
        ? Colors.green
        : status == 'INACTIVE'
        ? Colors.grey
        : primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        avatar: Icon(icon, size: 18, color: selected ? Colors.white : color),
        label: Text(status),
        selectedColor: color,
        backgroundColor: color.withOpacity(0.10),
        labelStyle: TextStyle(
          color: selected ? Colors.white : color,
          fontWeight: FontWeight.bold,
        ),
        side: BorderSide.none,
        onSelected: (_) => setState(() => selectedStatus = status),
      ),
    );
  }

  Widget statusChip(bool active) {
    final color = active ? Colors.green : Colors.grey;

    return Chip(
      avatar: Icon(
        active ? Icons.check_circle : Icons.block,
        size: 16,
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

  Widget readOnlyNotice() {
    if (canManageProperties) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.withOpacity(0.12),
              child: const Icon(Icons.lock_outline, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'You can view properties and units, but property creation and editing are restricted to admins and owners.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget propertyCard(dynamic property) {
    final active = isActive(property);
    final color = propertyColor(property);
    final busy = actionPropertyId == property['id']?.toString();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: busy ? null : () => openPropertyDetails(property),
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
                            initials(property),
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
                          propertyTitle(property),
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
                          propertyAddress(property),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          propertyLocation(property),
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
                      if (value == 'details') openPropertyDetails(property);
                      if (value == 'units') openUnits(property);
                      if (value == 'edit') openEditProperty(property);
                      if (value == 'deactivate') deactivateProperty(property);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.visibility),
                            SizedBox(width: 10),
                            Text('View details'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'units',
                        child: Row(
                          children: [
                            Icon(Icons.home_work),
                            SizedBox(width: 10),
                            Text('View units'),
                          ],
                        ),
                      ),
                      if (canManageProperties)
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
                      if (canManageProperties && active)
                        const PopupMenuDivider(),
                      if (canManageProperties && active)
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
                    Icon(Icons.location_on, color: color, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${propertyAddress(property)} • ${propertyLocation(property)}',
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

              Row(
                children: [
                  statusChip(active),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: busy ? null : () => openUnits(property),
                    icon: const Icon(Icons.home_work),
                    label: const Text('Units'),
                  ),
                ],
              ),

              if (canManageProperties) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () => openPropertyDetails(property),
                        icon: const Icon(Icons.visibility),
                        label: const Text('Details'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: busy || !active
                            ? null
                            : () => openEditProperty(property),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget compactPropertyTile(dynamic property) {
    final active = isActive(property);
    final color = propertyColor(property);
    final busy = actionPropertyId == property['id']?.toString();

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
                  initials(property),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
        ),
        title: Text(
          propertyTitle(property),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${propertyAddress(property)} • ${propertyLocation(property)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: statusChip(active),
        onTap: busy ? null : () => openPropertyDetails(property),
      ),
    );
  }

  Widget emptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(Icons.apartment, size: 62, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            const Text(
              'No properties found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              searchCtrl.text.trim().isNotEmpty || selectedStatus != 'ALL'
                  ? 'Try changing your search text or status filter.'
                  : canManageProperties
                  ? 'Create your first property to start adding units and leases.'
                  : 'No properties are currently available for viewing.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            if (canManageProperties) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: openCreateProperty,
                icon: const Icon(Icons.add_business),
                label: const Text('Create Property'),
              ),
            ],
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
      onRefresh: () => loadProperties(),
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
                    'Could not load properties',
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
                    onPressed: () => loadProperties(),
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
    final data = filteredProperties;

    return RefreshIndicator(
      onRefresh: () => loadProperties(silent: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          heroHeader(),

          const SizedBox(height: 18),

          readOnlyNotice(),

          if (!canManageProperties) const SizedBox(height: 14),

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
            ...data.map(compactPropertyTile)
          else
            ...data.map(propertyCard),

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
        title: Text(
          canManageProperties ? 'Properties' : 'Properties View',
          style: const TextStyle(fontWeight: FontWeight.bold),
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
            onPressed: refreshing ? null : () => loadProperties(silent: true),
          ),
          if (canManageProperties)
            IconButton(
              icon: const Icon(Icons.add_business),
              onPressed: openCreateProperty,
            ),
        ],
      ),
      floatingActionButton: canManageProperties
          ? FloatingActionButton.extended(
              onPressed: openCreateProperty,
              icon: const Icon(Icons.add_business),
              label: const Text('Property'),
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

class _PropertyFormSheet extends StatefulWidget {
  final dynamic property;

  const _PropertyFormSheet({required this.property});

  @override
  State<_PropertyFormSheet> createState() => _PropertyFormSheetState();
}

class _PropertyFormSheetState extends State<_PropertyFormSheet> {
  final titleCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final countryCtrl = TextEditingController();

  bool saving = false;
  String error = '';

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  bool get validForm {
    return cleanText(titleCtrl.text).isNotEmpty &&
        cleanText(addressCtrl.text).isNotEmpty;
  }

  int get qualityScore {
    int score = 0;

    if (cleanText(titleCtrl.text).length >= 3) score += 35;
    if (cleanText(addressCtrl.text).length >= 6) score += 35;
    if (cleanText(cityCtrl.text).length >= 2) score += 15;
    if (cleanText(countryCtrl.text).length >= 2) score += 15;

    return score.clamp(0, 100);
  }

  @override
  void initState() {
    super.initState();

    titleCtrl.text =
        widget.property['title']?.toString() ??
        widget.property['name']?.toString() ??
        '';
    addressCtrl.text = widget.property['address']?.toString() ?? '';
    cityCtrl.text = widget.property['city']?.toString() ?? '';
    countryCtrl.text = widget.property['country']?.toString() ?? '';

    titleCtrl.addListener(() => setState(() {}));
    addressCtrl.addListener(() => setState(() {}));
    cityCtrl.addListener(() => setState(() {}));
    countryCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    countryCtrl.dispose();
    super.dispose();
  }

  String cleanText(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String previewTitle() {
    final value = cleanText(titleCtrl.text);
    return value.isEmpty ? 'Property title' : value;
  }

  String previewLocation() {
    final city = cleanText(cityCtrl.text);
    final country = cleanText(countryCtrl.text);

    final result = [
      city,
      country,
    ].where((value) => value.isNotEmpty).join(', ');

    return result.isEmpty ? 'Location optional' : result;
  }

  String initials() {
    final title = previewTitle();

    if (title.isEmpty) return 'P';

    final parts = title
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return title[0].toUpperCase();
  }

  Future<void> save() async {
    final title = cleanText(titleCtrl.text);
    final address = cleanText(addressCtrl.text);
    final city = cleanText(cityCtrl.text);
    final country = cleanText(countryCtrl.text);

    setState(() => error = '');

    if (title.isEmpty || address.isEmpty) {
      setState(() {
        error = 'Title and address are required';
      });
      return;
    }

    setState(() => saving = true);

    try {
      await PropertiesService.update(
        widget.property['id'],
        title: title,
        address: address,
        city: city,
        country: country,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = AppError.clean(e);
      });

      await AppError.show(context, e, title: 'Could not update property');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget dragHandle() {
    return Container(
      width: 42,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget previewCard() {
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
                  child: Text(
                    initials(),
                    style: const TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Property Preview',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        previewTitle(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        previewLocation(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$qualityScore%',
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
                value: qualityScore / 100,
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
    String? hint,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
  }) {
    return TextField(
      controller: controller,
      enabled: !saving,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
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
                dragHandle(),

                const SizedBox(height: 20),

                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: primary.withOpacity(0.12),
                      child: const Icon(Icons.edit, color: primary),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Edit Property',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: saving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  'Update the property identity and location details.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),

                const SizedBox(height: 18),

                previewCard(),

                const SizedBox(height: 18),

                input(
                  controller: titleCtrl,
                  label: 'Property Title',
                  hint: 'Residence Jasmine',
                  icon: Icons.apartment,
                  textCapitalization: TextCapitalization.words,
                ),

                const SizedBox(height: 14),

                input(
                  controller: addressCtrl,
                  label: 'Address',
                  hint: 'Street, building number, area...',
                  icon: Icons.location_on,
                  maxLines: 2,
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: input(
                        controller: cityCtrl,
                        label: 'City',
                        hint: 'Tunis',
                        icon: Icons.location_city,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: input(
                        controller: countryCtrl,
                        label: 'Country',
                        hint: 'Tunisia',
                        icon: Icons.public,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                  ],
                ),

                if (error.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  errorCard(),
                ],

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: saving || !validForm ? null : save,
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
                  onPressed: saving ? null : () => Navigator.pop(context),
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

class _PropertyDetailsSheet extends StatelessWidget {
  final dynamic property;
  final String title;
  final String address;
  final String location;
  final bool active;
  final String initials;
  final String Function(dynamic value) formatDate;
  final bool canManage;
  final Future<void> Function() onOpenUnits;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDeactivate;

  const _PropertyDetailsSheet({
    required this.property,
    required this.title,
    required this.address,
    required this.location,
    required this.active,
    required this.initials,
    required this.formatDate,
    required this.canManage,
    required this.onOpenUnits,
    required this.onEdit,
    required this.onDeactivate,
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
            width: 105,
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

  Widget statusChip() {
    final color = active ? Colors.green : Colors.grey;

    return Chip(
      avatar: Icon(
        active ? Icons.check_circle : Icons.block,
        color: color,
        size: 18,
      ),
      label: Text(active ? 'ACTIVE' : 'INACTIVE'),
      backgroundColor: color.withOpacity(0.12),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
      side: BorderSide.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = active ? primary : Colors.grey;

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
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  address,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),

                const SizedBox(height: 12),

                statusChip(),

                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        infoRow('Title', title),
                        infoRow('Address', address),
                        infoRow('Location', location),
                        infoRow('Status', active ? 'Active' : 'Inactive'),
                        infoRow('Created', formatDate(property['createdAt'])),
                        infoRow('Updated', formatDate(property['updatedAt'])),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  color: primary.withOpacity(0.07),
                  child: ListTile(
                    leading: const Icon(Icons.home_work, color: primary),
                    title: const Text(
                      'Units and leasing',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Open this property to manage its units, availability and leasing flow.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: onOpenUnits,
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onOpenUnits,
                    icon: const Icon(Icons.home_work),
                    label: const Text('Open Units'),
                  ),
                ),

                if (canManage) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Property'),
                    ),
                  ),
                  if (active) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onDeactivate,
                        icon: const Icon(Icons.block, color: Colors.red),
                        label: const Text(
                          'Deactivate Property',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],

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

class _DeactivatePropertySheet extends StatelessWidget {
  final String propertyTitle;

  const _DeactivatePropertySheet({required this.propertyTitle});

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
                child: const Icon(Icons.block, color: Colors.red, size: 34),
              ),

              const SizedBox(height: 16),

              const Text(
                'Deactivate Property',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                propertyTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Text(
                'This property will be hidden from active lists. Its units, leases, invoices and history will remain stored safely.',
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
                  icon: const Icon(Icons.block),
                  label: const Text('Deactivate Property'),
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
