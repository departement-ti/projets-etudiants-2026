import 'package:flutter/material.dart';

import '../../core/auth/auth_storage.dart';
import '../../core/ui/app_error.dart';
import '../leases/create_lease_page.dart';
import 'edit_unit_page.dart';
import 'units_service.dart';

class UnitDetailsPage extends StatefulWidget {
  final String unitId;

  const UnitDetailsPage({super.key, required this.unitId});

  @override
  State<UnitDetailsPage> createState() => _UnitDetailsPageState();
}

class _UnitDetailsPageState extends State<UnitDetailsPage> {
  Map<String, dynamic>? unit;

  bool loading = true;
  bool refreshing = false;
  bool deleting = false;

  String error = '';
  String? role;

  String selectedSection = 'OVERVIEW';

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);
  static const darkText = Color(0xFF1D1B20);

  bool get canManageUnits {
    return role == 'ADMIN' || role == 'OWNER';
  }

  bool get canCreateLease {
    return canManageUnits && unitStatus() == 'AVAILABLE';
  }

  bool get hasActiveLease {
    return currentLease() != null || unitStatus() == 'OCCUPIED';
  }

  @override
  void initState() {
    super.initState();
    loadUnit();
  }

  Future<void> loadUnit({bool silent = false}) async {
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
      final data = await UnitsService.getOne(widget.unitId);

      if (!mounted) return;

      setState(() {
        role = userRole;
        unit = data;
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

  String unitTitle() {
    return unit?['title']?.toString() ?? unit?['number']?.toString() ?? 'Unit';
  }

  String unitNumber() {
    final value = unit?['number']?.toString();

    if (value == null || value.trim().isEmpty) return 'No unit number';

    return value;
  }

  String unitStatus() {
    return unit?['status']?.toString() ?? 'UNKNOWN';
  }

  String propertyName() {
    final property = unit?['property'];

    if (property != null) {
      return property['title']?.toString() ??
          property['name']?.toString() ??
          property['address']?.toString() ??
          'Property';
    }

    return 'Property';
  }

  String propertyAddress() {
    final property = unit?['property'];

    if (property != null) {
      final address = property['address']?.toString();

      if (address != null && address.trim().isNotEmpty) return address;
    }

    return 'No property address';
  }

  num money(dynamic value) {
    if (value is num) return value;

    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  num rentAmount() {
    return money(unit?['rentAmount']);
  }

  num sizeSqm() {
    return money(unit?['sizeSqm']);
  }

  int intValue(String key) {
    final value = unit?[key];

    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<dynamic> leases() {
    final data = unit?['leases'];

    if (data is List) return data;

    return [];
  }

  List<dynamic> tickets() {
    final data = unit?['tickets'];

    if (data is List) return data;

    return [];
  }

  Map<String, dynamic>? currentLease() {
    final current = unit?['currentLease'];
    if (current is Map<String, dynamic>) return current;

    final active = unit?['activeLease'];
    if (active is Map<String, dynamic>) return active;

    for (final lease in leases()) {
      if (lease is Map<String, dynamic> &&
          lease['status']?.toString() == 'ACTIVE') {
        return lease;
      }
    }

    return null;
  }

  String tenantName() {
    final lease = currentLease();
    final user = lease?['tenant']?['user'];

    if (user != null) {
      final firstName = user['firstName']?.toString() ?? '';
      final lastName = user['lastName']?.toString() ?? '';
      final email = user['email']?.toString() ?? '';

      final fullName = '$firstName $lastName'.trim();

      if (fullName.isNotEmpty) return fullName;
      if (email.isNotEmpty) return email;
    }

    final direct = unit?['currentTenantName']?.toString();

    if (direct != null && direct.trim().isNotEmpty) return direct;

    return 'No current tenant';
  }

  String tenantEmail() {
    final lease = currentLease();

    return lease?['tenant']?['user']?['email']?.toString() ?? '—';
  }

  String tenantPhone() {
    final lease = currentLease();
    final value = lease?['tenant']?['user']?['phone']?.toString();

    if (value == null || value.trim().isEmpty) return 'No phone';

    return value;
  }

  DateTime? parseDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }

  String formatDate(dynamic value) {
    if (value == null) return '—';

    final parsed = parseDate(value);
    if (parsed == null) return value.toString();

    return parsed.toLocal().toString().split(' ')[0];
  }

  String formatDateTime(dynamic value) {
    if (value == null) return '—';

    final parsed = parseDate(value);
    if (parsed == null) return value.toString();

    return parsed.toLocal().toString().split('.')[0];
  }

  String rentPreview() {
    final rent = rentAmount();

    if (rent <= 0) return 'Rent not set';

    return '${rent.toStringAsFixed(2)} / period';
  }

  String layoutPreview() {
    final bedrooms = unit?['bedrooms'];
    final bathrooms = unit?['bathrooms'];
    final floor = unit?['floor'];
    final size = unit?['sizeSqm'];

    final parts = <String>[];

    if (bedrooms != null) {
      parts.add('$bedrooms bed${bedrooms == 1 ? '' : 's'}');
    }

    if (bathrooms != null) {
      parts.add('$bathrooms bath${bathrooms == 1 ? '' : 's'}');
    }

    if (floor != null) {
      parts.add('Floor $floor');
    }

    if (size != null) {
      final parsed = double.tryParse(size.toString());

      if (parsed != null) {
        parts.add('${parsed.toStringAsFixed(parsed % 1 == 0 ? 0 : 1)} sqm');
      } else {
        parts.add('$size sqm');
      }
    }

    if (parts.isEmpty) return 'No layout details';

    return parts.join(' • ');
  }

  String initials() {
    final clean = unitTitle().trim();

    if (clean.isEmpty) return 'U';

    final parts = clean
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return clean[0].toUpperCase();
  }

  Color statusColor(String? status) {
    switch (status) {
      case 'AVAILABLE':
        return Colors.green;
      case 'OCCUPIED':
        return Colors.orange;
      case 'MAINTENANCE':
        return Colors.red;
      case 'RESERVED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData statusIcon(String? status) {
    switch (status) {
      case 'AVAILABLE':
        return Icons.check_circle;
      case 'OCCUPIED':
        return Icons.key;
      case 'MAINTENANCE':
        return Icons.construction;
      case 'RESERVED':
        return Icons.bookmark;
      default:
        return Icons.info;
    }
  }

  String statusDescription(String? status) {
    switch (status) {
      case 'AVAILABLE':
        return 'This unit is available and can be used to create a new lease.';
      case 'OCCUPIED':
        return 'This unit is occupied by an active lease.';
      case 'MAINTENANCE':
        return 'This unit is under maintenance and should not be leased.';
      case 'RESERVED':
        return 'This unit is reserved and should not be leased until released.';
      default:
        return 'Unit status information is unavailable.';
    }
  }

  String availabilityLabel() {
    final status = unitStatus();

    if (status == 'AVAILABLE') return 'Ready for lease';
    if (status == 'OCCUPIED') return 'Occupied';
    if (status == 'MAINTENANCE') return 'Blocked';
    if (status == 'RESERVED') return 'Reserved';

    return 'Unknown';
  }

  int get leaseHistoryCount {
    final value = unit?['leaseHistoryCount'];

    if (value is num) return value.toInt();

    return leases().length;
  }

  int get ticketHistoryCount {
    final value = unit?['ticketHistoryCount'];

    if (value is num) return value.toInt();

    return tickets().length;
  }

  int get activeTicketCount {
    return tickets().where((ticket) {
      final status = ticket['status']?.toString();
      return status == 'OPEN' || status == 'IN_PROGRESS';
    }).length;
  }

  int get occupancyScore {
    final status = unitStatus();

    if (status == 'OCCUPIED') return 100;
    if (status == 'RESERVED') return 70;
    if (status == 'MAINTENANCE') return 35;
    if (status == 'AVAILABLE') return 0;

    return 0;
  }

  int get readinessScore {
    int score = 0;

    if (unitTitle().trim().isNotEmpty) score += 15;
    if (rentAmount() > 0) score += 25;
    if (propertyName().trim().isNotEmpty) score += 15;
    if (intValue('bedrooms') > 0) score += 10;
    if (intValue('bathrooms') > 0) score += 10;
    if (sizeSqm() > 0) score += 10;
    if (unitStatus() == 'AVAILABLE') score += 15;

    return score.clamp(0, 100);
  }

  String readinessLabel() {
    if (unitStatus() == 'OCCUPIED') return 'Occupied';
    if (unitStatus() == 'MAINTENANCE') return 'Needs work';
    if (readinessScore >= 80) return 'Excellent';
    if (readinessScore >= 55) return 'Good';
    if (readinessScore >= 30) return 'Basic';

    return 'Incomplete';
  }

  Color readinessColor() {
    if (unitStatus() == 'OCCUPIED') return Colors.orange;
    if (unitStatus() == 'MAINTENANCE') return Colors.red;
    if (readinessScore >= 80) return Colors.green;
    if (readinessScore >= 55) return primary;
    if (readinessScore >= 30) return Colors.orange;

    return Colors.grey;
  }

  DateTime? availableFromDate() {
    final raw = unit?['availableFrom'];
    if (raw != null) return parseDate(raw);

    final lease = currentLease();
    if (lease != null) return parseDate(lease['endDate']);

    return null;
  }

  String availableFromText() {
    final status = unitStatus();

    if (status == 'AVAILABLE') return 'Available now';

    final available = availableFromDate();

    if (available != null) return formatDate(available);

    if (status == 'MAINTENANCE') return 'After maintenance';
    if (status == 'RESERVED') return 'Pending reservation release';

    return 'Unknown';
  }

  int? daysUntilAvailable() {
    final available = availableFromDate();

    if (available == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final availableDay = DateTime(
      available.year,
      available.month,
      available.day,
    );

    return availableDay.difference(today).inDays;
  }

  List<dynamic> availabilityTimeline() {
    final serverData = unit?['availabilityTimeline'];

    if (serverData is List) return serverData;

    final items = <dynamic>[];

    final createdAt = unit?['createdAt'];
    if (createdAt != null) {
      items.add({
        'type': 'UNIT_CREATED',
        'title': 'Unit created',
        'description': 'The unit was added to ${propertyName()}.',
        'date': createdAt,
        'status': unitStatus(),
      });
    }

    for (final lease in leases()) {
      items.add({
        'type': lease['status'] == 'TERMINATED'
            ? 'LEASE_TERMINATED'
            : 'LEASE_PERIOD',
        'title': 'Lease ${lease['status'] ?? ''}',
        'description':
            '${formatDate(lease['startDate'])} → ${formatDate(lease['endDate'])}',
        'date': lease['startDate'],
        'status': lease['status'],
        'rentAmount': lease['rentAmount'],
      });
    }

    if (unitStatus() == 'AVAILABLE') {
      items.add({
        'type': 'AVAILABLE',
        'title': 'Available now',
        'description': 'This unit is ready for a new lease.',
        'date': DateTime.now().toIso8601String(),
        'status': 'AVAILABLE',
      });
    }

    items.sort((a, b) {
      final aDate =
          parseDate(a['date']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          parseDate(b['date']) ?? DateTime.fromMillisecondsSinceEpoch(0);

      return bDate.compareTo(aDate);
    });

    return items;
  }

  Color timelineColor(String? type) {
    switch (type) {
      case 'CURRENT_OCCUPANCY':
      case 'LEASE_PERIOD':
        return Colors.orange;
      case 'LEASE_TERMINATED':
        return Colors.red;
      case 'UNIT_CREATED':
        return primary;
      case 'AVAILABLE':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData timelineIcon(String? type) {
    switch (type) {
      case 'CURRENT_OCCUPANCY':
        return Icons.key;
      case 'LEASE_PERIOD':
        return Icons.date_range;
      case 'LEASE_TERMINATED':
        return Icons.cancel;
      case 'UNIT_CREATED':
        return Icons.home_work;
      case 'AVAILABLE':
        return Icons.check_circle;
      default:
        return Icons.history;
    }
  }

  Future<void> openEditUnit() async {
    if (!canManageUnits || unit == null || deleting) return;

    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditUnitPage(unit: unit!)),
    );

    if (updated == true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unit updated successfully')),
      );

      await loadUnit(silent: true);
    }
  }

  Future<void> openCreateLease() async {
    if (!canManageUnits) {
      await AppError.show(
        context,
        'Only admins and owners can create leases.',
        title: 'Permission required',
      );
      return;
    }

    if (unitStatus() != 'AVAILABLE') {
      await AppError.show(
        context,
        'Only AVAILABLE units can be used to create a lease.',
        title: 'Unit not available',
      );
      return;
    }

    final created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateLeasePage(preselectedUnitId: widget.unitId),
      ),
    );

    if (created == true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lease created successfully')),
      );

      await loadUnit(silent: true);
    }
  }

  Future<void> openUnitIntelligenceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UnitIntelligenceSheet(
        unitTitle: unitTitle(),
        status: unitStatus(),
        readinessScore: readinessScore,
        readinessLabel: readinessLabel(),
        readinessColor: readinessColor(),
        occupancyScore: occupancyScore,
        rent: rentAmount().toStringAsFixed(2),
        layout: layoutPreview(),
        property: propertyName(),
        tenant: tenantName(),
        leaseHistoryCount: leaseHistoryCount,
        ticketHistoryCount: ticketHistoryCount,
        activeTicketCount: activeTicketCount,
        availableFrom: availableFromText(),
      ),
    );
  }

  Future<bool> confirmDeleteUnit() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeleteUnitSheet(
        unitTitle: unitTitle(),
        status: unitStatus(),
        hasLeaseHistory: leaseHistoryCount > 0,
        hasTicketHistory: ticketHistoryCount > 0,
        hasActiveLease: hasActiveLease,
      ),
    );

    return confirmed == true;
  }

  Future<void> deleteUnit() async {
    if (!canManageUnits || unit == null || deleting) return;

    final confirmed = await confirmDeleteUnit();

    if (!confirmed) return;

    setState(() => deleting = true);

    try {
      await UnitsService.delete(widget.unitId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unit deleted successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      await AppError.show(context, e, title: 'Could not delete unit');
    } finally {
      if (mounted) {
        setState(() => deleting = false);
      }
    }
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
    final status = unitStatus();
    final color = statusColor(status);

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
              CircleAvatar(
                radius: 31,
                backgroundColor: Colors.white,
                child: Text(
                  initials(),
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unitTitle(),
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
                      '${propertyName()} • ${unitNumber()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: refreshing ? null : () => loadUnit(silent: true),
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
                avatar: Icon(statusIcon(status), color: color, size: 18),
                label: Text(status),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                side: BorderSide.none,
              ),
              Chip(
                avatar: Icon(
                  Icons.workspace_premium,
                  color: readinessColor(),
                  size: 18,
                ),
                label: Text(readinessLabel()),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: readinessColor(),
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
                  title: 'Rent',
                  value: rentAmount().toStringAsFixed(2),
                  icon: Icons.payments,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Availability',
                  value: availabilityLabel(),
                  icon: statusIcon(status),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Readiness',
                  value: '$readinessScore%',
                  icon: Icons.auto_graph,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'History',
                  value: '${leaseHistoryCount + ticketHistoryCount}',
                  icon: Icons.history,
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
                  statusDescription(status),
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
              value: readinessScore / 100,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          if (canCreateLease) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: deleting ? null : openCreateLease,
                icon: const Icon(Icons.description),
                label: const Text('Create Lease from this Unit'),
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

  Widget sectionSwitch() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            sectionChip('OVERVIEW', 'Overview', Icons.dashboard_customize),
            const SizedBox(width: 8),
            sectionChip('AVAILABILITY', 'Availability', Icons.event_available),
            const SizedBox(width: 8),
            sectionChip('HISTORY', 'History', Icons.history),
          ],
        ),
      ),
    );
  }

  Widget sectionChip(String value, String label, IconData icon) {
    final selected = selectedSection == value;

    return Expanded(
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        avatar: Icon(icon, size: 18, color: selected ? Colors.white : primary),
        selectedColor: primary,
        backgroundColor: primary.withOpacity(0.08),
        labelStyle: TextStyle(
          color: selected ? Colors.white : primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        side: BorderSide.none,
        onSelected: (_) => setState(() => selectedSection = value),
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
                    onPressed: openUnitIntelligenceSheet,
                    icon: const Icon(Icons.insights),
                    label: const Text('Insights'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: refreshing ? null : () => loadUnit(silent: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ),
              ],
            ),
            if (canManageUnits) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: deleting ? null : openEditUnit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: canCreateLease && !deleting
                          ? openCreateLease
                          : null,
                      icon: const Icon(Icons.description),
                      label: const Text('Lease'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 7),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: darkText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget metricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.24,
      children: [
        metricCard(
          title: 'Bedrooms',
          value: intValue('bedrooms').toString(),
          icon: Icons.bed,
          color: primary,
        ),
        metricCard(
          title: 'Bathrooms',
          value: intValue('bathrooms').toString(),
          icon: Icons.bathtub,
          color: const Color(0xFF0EA5E9),
        ),
        metricCard(
          title: 'Floor',
          value: unit?['floor']?.toString() ?? '—',
          icon: Icons.layers,
          color: Colors.orange,
        ),
        metricCard(
          title: 'Size',
          value: sizeSqm() > 0 ? '${sizeSqm().toStringAsFixed(0)} sqm' : '—',
          icon: Icons.square_foot,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget previewCard() {
    final status = unitStatus();
    final color = statusColor(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: color.withOpacity(0.12),
                  child: Text(
                    initials(),
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unitTitle(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Unit number: ${unitNumber()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rentPreview(),
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
                  label: Text(status),
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
                  Icon(Icons.space_dashboard, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      layoutPreview(),
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

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: readinessColor().withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: readinessColor(),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Readiness: $readinessLabel • $readinessScore%',
                      style: TextStyle(
                        color: readinessColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statusCard() {
    final status = unitStatus();
    final color = statusColor(status);

    return Card(
      color: color.withOpacity(0.07),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(statusIcon(status), color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    availabilityLabel(),
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    statusDescription(status),
                    style: TextStyle(color: Colors.grey.shade800, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget availabilityCard() {
    final status = unitStatus();
    final color = statusColor(status);
    final days = daysUntilAvailable();
    final lease = currentLease();

    String message;

    if (status == 'AVAILABLE') {
      message = 'This unit is available now and can be assigned to a tenant.';
    } else if (status == 'OCCUPIED' && lease != null) {
      message =
          'Occupied by ${tenantName()} until ${formatDate(lease['endDate'])}.';
    } else if (status == 'MAINTENANCE') {
      message =
          'This unit is blocked for maintenance and should not be leased.';
    } else if (status == 'RESERVED') {
      message =
          'This unit is reserved. It should be released before creating a lease.';
    } else {
      message = 'Availability information is not available.';
    }

    return Card(
      color: color.withOpacity(0.07),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(statusIcon(status), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Availability Control',
                    style: TextStyle(
                      color: color,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            infoRow('Status', status),
            infoRow('Available From', availableFromText()),
            if (days != null && status != 'AVAILABLE')
              infoRow(
                'Countdown',
                days >= 0
                    ? '$days day${days == 1 ? '' : 's'}'
                    : 'Date passed ${days.abs()} day${days.abs() == 1 ? '' : 's'} ago',
              ),
            infoRow('Current Tenant', tenantName()),
            infoRow(
              'Lease Period',
              lease == null
                  ? null
                  : '${formatDate(lease['startDate'])} → ${formatDate(lease['endDate'])}',
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.70),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget currentTenantCard() {
    final lease = currentLease();

    if (lease == null) {
      return Card(
        color: unitStatus() == 'AVAILABLE'
            ? Colors.green.withOpacity(0.07)
            : Colors.orange.withOpacity(0.07),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: statusColor(unitStatus()).withOpacity(0.12),
                child: Icon(
                  unitStatus() == 'AVAILABLE'
                      ? Icons.event_available
                      : Icons.info_outline,
                  color: statusColor(unitStatus()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  unitStatus() == 'AVAILABLE'
                      ? 'No current tenant. This unit is ready for lease creation.'
                      : 'No active tenant details are attached to this unit.',
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
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: primary.withOpacity(0.12),
              child: const Icon(Icons.person, color: primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Tenant',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  infoRow('Name', tenantName()),
                  infoRow('Email', tenantEmail()),
                  infoRow('Phone', tenantPhone()),
                  infoRow('Lease Start', formatDate(lease['startDate'])),
                  infoRow('Lease End', formatDate(lease['endDate'])),
                  infoRow(
                    'Rent',
                    money(lease['rentAmount']).toStringAsFixed(2),
                  ),
                  infoRow('Frequency', lease['frequency']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget propertyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: primary.withOpacity(0.12),
              child: const Icon(Icons.apartment, color: primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Related Property',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  infoRow('Name', propertyName()),
                  infoRow('Address', propertyAddress()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget detailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unit Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            infoRow('Title', unit?['title']),
            infoRow('Number', unit?['number']),
            infoRow('Rent', rentAmount().toStringAsFixed(2)),
            infoRow('Floor', unit?['floor']),
            infoRow('Bedrooms', unit?['bedrooms']),
            infoRow('Bathrooms', unit?['bathrooms']),
            infoRow(
              'Size',
              unit?['sizeSqm'] == null ? null : '${unit!['sizeSqm']} sqm',
            ),
            infoRow('Status', unit?['status']),
            infoRow('Created', formatDateTime(unit?['createdAt'])),
            infoRow('Updated', formatDateTime(unit?['updatedAt'])),
          ],
        ),
      ),
    );
  }

  Widget historySnapshotCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'History Snapshot',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            infoRow('Lease Records', leaseHistoryCount),
            infoRow('Ticket Records', ticketHistoryCount),
            infoRow('Active Tickets', activeTicketCount),
          ],
        ),
      ),
    );
  }

  Widget availabilityTimelineCard() {
    final items = availabilityTimeline();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Availability Timeline',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              'Occupancy, lease periods and availability events.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.info_outline),
                title: Text('No availability events yet'),
              )
            else
              ...items.map(availabilityTimelineTile),
          ],
        ),
      ),
    );
  }

  Widget availabilityTimelineTile(dynamic item) {
    final type = item['type']?.toString();
    final color = timelineColor(type);

    final rent = money(item['rentAmount']);
    final totalInvoiced = money(item['totalInvoiced']);
    final totalPaid = money(item['totalPaid']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(timelineIcon(type), color: color, size: 18),
              ),
              Container(width: 2, height: 44, color: color.withOpacity(0.18)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: softBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['title']?.toString() ?? 'Availability event',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        formatDate(item['date']),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item['description']?.toString() ?? '—',
                    style: TextStyle(color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (item['status'] != null)
                        Chip(
                          label: Text(item['status'].toString()),
                          backgroundColor: color.withOpacity(0.12),
                          labelStyle: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          side: BorderSide.none,
                        ),
                      if (rent > 0)
                        Chip(
                          label: Text('Rent ${rent.toStringAsFixed(2)}'),
                          backgroundColor: Colors.white,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          side: BorderSide.none,
                        ),
                      if (totalInvoiced > 0)
                        Chip(
                          label: Text(
                            'Invoiced ${totalInvoiced.toStringAsFixed(2)}',
                          ),
                          backgroundColor: Colors.white,
                          labelStyle: const TextStyle(fontSize: 11),
                          side: BorderSide.none,
                        ),
                      if (totalPaid > 0)
                        Chip(
                          label: Text('Paid ${totalPaid.toStringAsFixed(2)}'),
                          backgroundColor: Colors.white,
                          labelStyle: const TextStyle(fontSize: 11),
                          side: BorderSide.none,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget readOnlyNotice() {
    if (canManageUnits) return const SizedBox.shrink();

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
                'You can view unit information, availability and current tenant details. Editing, deleting and lease creation are restricted to admins and owners.',
                style: TextStyle(color: Colors.grey.shade700, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget managementActions() {
    if (!canManageUnits) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Management Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit Unit'),
                onPressed: deleting ? null : openEditUnit,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.description),
                label: const Text('Create Lease'),
                onPressed: canCreateLease && !deleting ? openCreateLease : null,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: deleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete, color: Colors.red),
                label: Text(
                  deleting ? 'Deleting...' : 'Delete Unit',
                  style: const TextStyle(color: Colors.red),
                ),
                onPressed: deleting ? null : deleteUnit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget overviewSection() {
    return Column(
      children: [
        metricsGrid(),
        const SizedBox(height: 14),
        previewCard(),
        const SizedBox(height: 14),
        statusCard(),
        const SizedBox(height: 14),
        propertyCard(),
        const SizedBox(height: 14),
        detailsCard(),
      ],
    );
  }

  Widget availabilitySection() {
    return Column(
      children: [
        availabilityCard(),
        const SizedBox(height: 14),
        currentTenantCard(),
        const SizedBox(height: 14),
        availabilityTimelineCard(),
      ],
    );
  }

  Widget historySection() {
    return Column(
      children: [
        historySnapshotCard(),
        const SizedBox(height: 14),
        availabilityTimelineCard(),
      ],
    );
  }

  Widget selectedSectionBody() {
    if (selectedSection == 'AVAILABILITY') return availabilitySection();
    if (selectedSection == 'HISTORY') return historySection();

    return overviewSection();
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
      onRefresh: () => loadUnit(),
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
                    'Could not load unit',
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
                    onPressed: () => loadUnit(),
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
      onRefresh: () => loadUnit(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 150),
          Icon(Icons.home_work, size: 64, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Unit not found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget contentBody() {
    return RefreshIndicator(
      onRefresh: () => loadUnit(silent: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          heroHeader(),

          const SizedBox(height: 18),

          quickActions(),

          const SizedBox(height: 14),

          sectionSwitch(),

          const SizedBox(height: 14),

          selectedSectionBody(),

          const SizedBox(height: 14),

          readOnlyNotice(),

          if (!canManageUnits) const SizedBox(height: 14),

          managementActions(),

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
          canManageUnits ? 'Unit Details' : 'Unit View',
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
            onPressed: refreshing ? null : () => loadUnit(silent: true),
          ),
          if (canManageUnits && unit != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: deleting ? null : openEditUnit,
            ),
        ],
      ),
      body: loading
          ? loadingBody()
          : error.isNotEmpty
          ? errorBody()
          : unit == null
          ? emptyBody()
          : contentBody(),
    );
  }
}

class _UnitIntelligenceSheet extends StatelessWidget {
  final String unitTitle;
  final String status;
  final int readinessScore;
  final String readinessLabel;
  final Color readinessColor;
  final int occupancyScore;
  final String rent;
  final String layout;
  final String property;
  final String tenant;
  final int leaseHistoryCount;
  final int ticketHistoryCount;
  final int activeTicketCount;
  final String availableFrom;

  const _UnitIntelligenceSheet({
    required this.unitTitle,
    required this.status,
    required this.readinessScore,
    required this.readinessLabel,
    required this.readinessColor,
    required this.occupancyScore,
    required this.rent,
    required this.layout,
    required this.property,
    required this.tenant,
    required this.leaseHistoryCount,
    required this.ticketHistoryCount,
    required this.activeTicketCount,
    required this.availableFrom,
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
            width: 122,
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

  Widget scoreCard({
    required String title,
    required int value,
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
                  '$value%',
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
                value: value / 100,
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

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.55,
      maxChildSize: 0.95,
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
                  radius: 34,
                  backgroundColor: primary.withOpacity(0.12),
                  child: const Icon(Icons.insights, color: primary, size: 34),
                ),

                const SizedBox(height: 14),

                Text(
                  unitTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Unit intelligence and readiness overview',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),

                const SizedBox(height: 18),

                scoreCard(
                  title: 'Readiness Score • $readinessLabel',
                  value: readinessScore,
                  icon: Icons.workspace_premium,
                  color: readinessColor,
                ),

                const SizedBox(height: 10),

                scoreCard(
                  title: 'Occupancy Score',
                  value: occupancyScore,
                  icon: Icons.key,
                  color: status == 'OCCUPIED' ? Colors.orange : Colors.green,
                ),

                const SizedBox(height: 14),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        infoRow('Status', status),
                        infoRow('Rent', rent),
                        infoRow('Layout', layout),
                        infoRow('Property', property),
                        infoRow('Tenant', tenant),
                        infoRow('Available From', availableFrom),
                        infoRow('Lease Records', leaseHistoryCount),
                        infoRow('Ticket Records', ticketHistoryCount),
                        infoRow('Active Tickets', activeTicketCount),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  color: primary.withOpacity(0.07),
                  child: const ListTile(
                    leading: Icon(Icons.lightbulb_outline, color: primary),
                    title: Text(
                      'Operational note',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'A unit is safest to lease when it is available, has clean rent data, clear layout details and no active maintenance issues.',
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

class _DeleteUnitSheet extends StatelessWidget {
  final String unitTitle;
  final String status;
  final bool hasLeaseHistory;
  final bool hasTicketHistory;
  final bool hasActiveLease;

  const _DeleteUnitSheet({
    required this.unitTitle,
    required this.status,
    required this.hasLeaseHistory,
    required this.hasTicketHistory,
    required this.hasActiveLease,
  });

  static const softBg = Color(0xFFF8F5FF);

  @override
  Widget build(BuildContext context) {
    final likelyBlocked =
        status == 'OCCUPIED' ||
        hasActiveLease ||
        hasLeaseHistory ||
        hasTicketHistory;

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
                child: const Icon(Icons.delete, color: Colors.red, size: 34),
              ),

              const SizedBox(height: 16),

              const Text(
                'Delete Unit?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                unitTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Text(
                likelyBlocked
                    ? 'This unit may have occupancy, lease history or maintenance history. The backend will block deletion if related records exist.'
                    : 'This action permanently removes the unit. Only delete units that have no important history.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, height: 1.45),
              ),

              const SizedBox(height: 16),

              Card(
                color: Colors.orange.withOpacity(0.10),
                child: ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.orange),
                  title: const Text(
                    'Safe deletion rules',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Status: $status\n'
                    'Active lease: ${hasActiveLease ? 'Yes' : 'No'}\n'
                    'Lease history: ${hasLeaseHistory ? 'Yes' : 'No'}\n'
                    'Ticket history: ${hasTicketHistory ? 'Yes' : 'No'}',
                  ),
                ),
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
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete Unit'),
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
