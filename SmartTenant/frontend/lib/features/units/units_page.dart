import 'package:flutter/material.dart';

import '../../core/auth/auth_storage.dart';
import '../../core/ui/app_error.dart';
import 'create_unit_page.dart';
import 'unit_details_page.dart';
import 'units_service.dart';

class UnitsPage extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;

  const UnitsPage({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
  });

  @override
  State<UnitsPage> createState() => _UnitsPageState();
}

class _UnitsPageState extends State<UnitsPage> {
  List<dynamic> units = [];

  bool loading = true;
  bool refreshing = false;
  String error = '';
  String? role;

  String selectedStatus = 'ALL';
  String sortMode = 'Newest';
  String viewMode = 'CARDS';

  final searchCtrl = TextEditingController();

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);
  static const darkText = Color(0xFF1D1B20);

  final statuses = const [
    'ALL',
    'AVAILABLE',
    'OCCUPIED',
    'MAINTENANCE',
    'RESERVED',
  ];

  bool get canManageUnits {
    return role == 'ADMIN' || role == 'OWNER';
  }

  @override
  void initState() {
    super.initState();
    searchCtrl.addListener(() => setState(() {}));
    loadUnits();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> loadUnits({bool silent = false}) async {
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
      final data = await UnitsService.getByProperty(widget.propertyId);

      if (!mounted) return;

      setState(() {
        role = userRole;
        units = data;
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

  Future<void> openCreateUnit() async {
    if (!canManageUnits) {
      await AppError.show(
        context,
        'Only admins and owners can create units.',
        title: 'Permission required',
      );
      return;
    }

    final created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateUnitPage(propertyId: widget.propertyId),
      ),
    );

    if (created == true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unit created successfully')),
      );

      await loadUnits(silent: true);
    }
  }

  Future<void> openUnitDetails(dynamic unit) async {
    final id = unit['id']?.toString();

    if (id == null || id.isEmpty) return;

    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UnitDetailsPage(unitId: id)),
    );

    if (changed == true) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Units updated')));
    }

    await loadUnits(silent: true);
  }

  Future<void> openUnitsInsight() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UnitsInsightSheet(
        propertyTitle: widget.propertyTitle,
        totalUnits: units.length,
        availableCount: availableCount,
        occupiedCount: occupiedCount,
        maintenanceCount: maintenanceCount,
        reservedCount: reservedCount,
        occupancyRate: occupancyRate,
        readinessRate: readinessRate,
        totalPotentialRent: totalPotentialRent,
        averageRent: averageRent,
        totalBedrooms: totalBedrooms,
        totalBathrooms: totalBathrooms,
      ),
    );
  }

  void resetFilters() {
    setState(() {
      searchCtrl.clear();
      selectedStatus = 'ALL';
      sortMode = 'Newest';
    });
  }

  List<dynamic> get filteredUnits {
    final query = searchCtrl.text.trim().toLowerCase();

    final filtered = units.where((unit) {
      final searchable = [
        unitTitle(unit),
        unitNumberValue(unit),
        unit['status']?.toString() ?? '',
        rentAmount(unit).toString(),
        unitLayout(unit),
        unit['floor']?.toString() ?? '',
        unit['bedrooms']?.toString() ?? '',
        unit['bathrooms']?.toString() ?? '',
      ].join(' ').toLowerCase();

      final status = unitStatus(unit);

      final matchesSearch = query.isEmpty || searchable.contains(query);
      final matchesStatus = selectedStatus == 'ALL' || status == selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();

    filtered.sort((a, b) {
      switch (sortMode) {
        case 'Title':
          return unitTitle(a).compareTo(unitTitle(b));

        case 'Rent Low':
          return rentAmount(a).compareTo(rentAmount(b));

        case 'Rent High':
          return rentAmount(b).compareTo(rentAmount(a));

        case 'Status':
          return unitStatus(a).compareTo(unitStatus(b));

        case 'Bedrooms':
          return intValue(b, 'bedrooms').compareTo(intValue(a, 'bedrooms'));

        case 'Size':
          return sizeSqm(b).compareTo(sizeSqm(a));

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

  String formatDate(dynamic value) {
    if (value == null) return '—';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    return parsed.toLocal().toString().split(' ')[0];
  }

  String unitTitle(dynamic unit) {
    return unit['title']?.toString() ?? unit['number']?.toString() ?? 'Unit';
  }

  String unitNumberValue(dynamic unit) {
    final value = unit['number']?.toString();

    if (value == null || value.trim().isEmpty) return '';

    return value;
  }

  String unitNumber(dynamic unit) {
    final value = unitNumberValue(unit);

    if (value.isEmpty) return 'No unit number';

    return 'Unit number: $value';
  }

  String unitStatus(dynamic unit) {
    return unit['status']?.toString() ?? 'AVAILABLE';
  }

  num rentAmount(dynamic unit) {
    final value = unit['rentAmount'];

    if (value is num) return value;

    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  num sizeSqm(dynamic unit) {
    final value = unit['sizeSqm'];

    if (value is num) return value;

    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  int intValue(dynamic unit, String key) {
    final value = unit[key];

    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String rentPreview(dynamic unit) {
    final rent = rentAmount(unit);

    if (rent <= 0) return 'Rent not set';

    return '${rent.toStringAsFixed(2)} / period';
  }

  String unitLayout(dynamic unit) {
    final bedrooms = unit['bedrooms'];
    final bathrooms = unit['bathrooms'];
    final floor = unit['floor'];
    final size = unit['sizeSqm'];

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

  String initials(dynamic unit) {
    final clean = unitTitle(unit).trim();

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

  int statusCount(String status) {
    return units.where((unit) => unitStatus(unit) == status).length;
  }

  int get availableCount => statusCount('AVAILABLE');
  int get occupiedCount => statusCount('OCCUPIED');
  int get maintenanceCount => statusCount('MAINTENANCE');
  int get reservedCount => statusCount('RESERVED');

  num get totalPotentialRent {
    return units.fold<num>(0, (sum, unit) => sum + rentAmount(unit));
  }

  num get averageRent {
    if (units.isEmpty) return 0;

    return totalPotentialRent / units.length;
  }

  int get totalBedrooms {
    return units.fold<int>(0, (sum, unit) {
      return sum + intValue(unit, 'bedrooms');
    });
  }

  int get totalBathrooms {
    return units.fold<int>(0, (sum, unit) {
      return sum + intValue(unit, 'bathrooms');
    });
  }

  int get unitsWithRent {
    return units.where((unit) => rentAmount(unit) > 0).length;
  }

  int get unitsWithLayout {
    return units.where((unit) {
      return intValue(unit, 'bedrooms') > 0 ||
          intValue(unit, 'bathrooms') > 0 ||
          intValue(unit, 'floor') > 0 ||
          sizeSqm(unit) > 0;
    }).length;
  }

  double get occupancyRate {
    if (units.isEmpty) return 0;

    return (occupiedCount / units.length) * 100;
  }

  double get readinessRate {
    if (units.isEmpty) return 0;

    final ready = units.where((unit) {
      return unitStatus(unit) == 'AVAILABLE' && rentAmount(unit) > 0;
    }).length;

    return (ready / units.length) * 100;
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

  String statusDescription(String status) {
    switch (status) {
      case 'AVAILABLE':
        return 'Ready for leasing';
      case 'OCCUPIED':
        return 'Currently leased';
      case 'MAINTENANCE':
        return 'Needs attention';
      case 'RESERVED':
        return 'Reserved unit';
      default:
        return 'All unit statuses';
    }
  }

  int unitReadinessScore(dynamic unit) {
    int score = 0;

    if (unitTitle(unit).trim().isNotEmpty) score += 15;
    if (rentAmount(unit) > 0) score += 25;
    if (intValue(unit, 'bedrooms') > 0) score += 10;
    if (intValue(unit, 'bathrooms') > 0) score += 10;
    if (sizeSqm(unit) > 0) score += 10;
    if (unitStatus(unit) == 'AVAILABLE') score += 30;

    return score.clamp(0, 100);
  }

  String unitReadinessLabel(dynamic unit) {
    final status = unitStatus(unit);

    if (status == 'OCCUPIED') return 'Occupied';
    if (status == 'MAINTENANCE') return 'Needs work';
    if (status == 'RESERVED') return 'Reserved';

    final score = unitReadinessScore(unit);

    if (score >= 85) return 'Excellent';
    if (score >= 65) return 'Good';
    if (score >= 40) return 'Basic';

    return 'Incomplete';
  }

  Color unitReadinessColor(dynamic unit) {
    final status = unitStatus(unit);

    if (status == 'OCCUPIED') return Colors.orange;
    if (status == 'MAINTENANCE') return Colors.red;
    if (status == 'RESERVED') return Colors.blue;

    final score = unitReadinessScore(unit);

    if (score >= 85) return Colors.green;
    if (score >= 65) return primary;
    if (score >= 40) return Colors.orange;

    return Colors.grey;
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
                radius: 29,
                backgroundColor: Colors.white,
                child: Icon(Icons.home_work, color: primary, size: 31),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      canManageUnits ? 'Units Control Center' : 'Units View',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.propertyTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: refreshing ? null : () => loadUnits(silent: true),
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
                  title: 'Total Units',
                  value: units.length.toString(),
                  icon: Icons.home_work,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Available',
                  value: availableCount.toString(),
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
                  title: 'Occupied',
                  value: occupiedCount.toString(),
                  icon: Icons.key,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Potential Rent',
                  value: totalPotentialRent.toStringAsFixed(2),
                  icon: Icons.payments,
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
                  value: '${readinessRate.round()}%',
                  icon: Icons.workspace_premium,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Avg Rent',
                  value: averageRent.toStringAsFixed(2),
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              const Icon(Icons.pie_chart, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Occupancy rate: ${occupancyRate.round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                maintenanceCount > 0 ? 'Needs attention' : 'Healthy',
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
              value: (occupancyRate / 100).clamp(0, 1),
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          if (canManageUnits) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: openCreateUnit,
                icon: const Icon(Icons.add_home_work),
                label: const Text('Create Unit'),
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
                    onPressed: openUnitsInsight,
                    icon: const Icon(Icons.insights),
                    label: const Text('Insights'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: refreshing
                        ? null
                        : () => loadUnits(silent: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ),
              ],
            ),
            if (canManageUnits) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: openCreateUnit,
                  icon: const Icon(Icons.add_home_work),
                  label: const Text('Add New Unit'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget summaryStrip() {
    return Row(
      children: [
        Expanded(
          child: miniSummaryCard(
            title: 'Maintenance',
            value: maintenanceCount.toString(),
            icon: Icons.construction,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: miniSummaryCard(
            title: 'Reserved',
            value: reservedCount.toString(),
            icon: Icons.bookmark,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: miniSummaryCard(
            title: 'Bedrooms',
            value: totalBedrooms.toString(),
            icon: Icons.bed,
            color: primary,
          ),
        ),
      ],
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

  Widget searchAndFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                labelText: 'Search units',
                hintText: 'Title, number, rent, layout or status',
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
                      DropdownMenuItem(value: 'Title', child: Text('Title')),
                      DropdownMenuItem(
                        value: 'Rent Low',
                        child: Text('Rent Low'),
                      ),
                      DropdownMenuItem(
                        value: 'Rent High',
                        child: Text('Rent High'),
                      ),
                      DropdownMenuItem(value: 'Status', child: Text('Status')),
                      DropdownMenuItem(
                        value: 'Bedrooms',
                        child: Text('Bedrooms'),
                      ),
                      DropdownMenuItem(value: 'Size', child: Text('Size')),
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
    final active = selectedStatus == status;
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
        onSelected: (_) {
          setState(() => selectedStatus = status);
        },
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

  Widget readinessBadge(dynamic unit) {
    final color = unitReadinessColor(unit);
    final score = unitReadinessScore(unit);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${unitReadinessLabel(unit)} • $score% setup quality',
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

  Widget unitCard(dynamic unit) {
    final status = unitStatus(unit);
    final color = statusColor(status);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => openUnitDetails(unit),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: color.withOpacity(0.12),
                    child: Text(
                      initials(unit),
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
                          unitTitle(unit),
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
                          unitNumber(unit),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          rentPreview(unit),
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
                      if (value == 'details') openUnitDetails(unit);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.visibility),
                            SizedBox(width: 10),
                            Text('View details'),
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
                    Icon(Icons.space_dashboard, size: 18, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        unitLayout(unit),
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

              readinessBadge(unit),

              const SizedBox(height: 12),

              Row(
                children: [
                  statusChip(status),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => openUnitDetails(unit),
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

  Widget compactUnitTile(dynamic unit) {
    final status = unitStatus(unit);
    final color = statusColor(status);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Text(
            initials(unit),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          unitTitle(unit),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${rentPreview(unit)} • ${unitLayout(unit)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: statusChip(status),
        onTap: () => openUnitDetails(unit),
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
                'You can view units, availability and occupancy information. Creating, editing and deleting units are restricted to admins and owners.',
                style: TextStyle(color: Colors.grey.shade700, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget emptyState() {
    final hasFilters =
        searchCtrl.text.trim().isNotEmpty || selectedStatus != 'ALL';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(Icons.home_work, size: 62, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            const Text(
              'No units found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters
                  ? 'Try changing the search text or status filter.'
                  : canManageUnits
                  ? 'Create the first rentable unit for this property.'
                  : 'No units are currently available for viewing.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            if (hasFilters)
              OutlinedButton.icon(
                onPressed: resetFilters,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset Filters'),
              )
            else if (canManageUnits)
              ElevatedButton.icon(
                onPressed: openCreateUnit,
                icon: const Icon(Icons.add_home_work),
                label: const Text('Create Unit'),
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
      onRefresh: () => loadUnits(),
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
                    'Could not load units',
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
                    onPressed: () => loadUnits(),
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
    final data = filteredUnits;

    return RefreshIndicator(
      onRefresh: () => loadUnits(silent: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          heroHeader(),

          const SizedBox(height: 18),

          quickActions(),

          const SizedBox(height: 14),

          summaryStrip(),

          const SizedBox(height: 14),

          readOnlyNotice(),

          if (!canManageUnits) const SizedBox(height: 14),

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
            ...data.map(compactUnitTile)
          else
            ...data.map(unitCard),

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
          'Units',
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
            onPressed: refreshing ? null : () => loadUnits(silent: true),
          ),
          if (canManageUnits)
            IconButton(
              icon: const Icon(Icons.add_home_work),
              onPressed: openCreateUnit,
            ),
        ],
      ),
      floatingActionButton: canManageUnits
          ? FloatingActionButton.extended(
              onPressed: openCreateUnit,
              icon: const Icon(Icons.add_home_work),
              label: const Text('Unit'),
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

class _UnitsInsightSheet extends StatelessWidget {
  final String propertyTitle;
  final int totalUnits;
  final int availableCount;
  final int occupiedCount;
  final int maintenanceCount;
  final int reservedCount;
  final double occupancyRate;
  final double readinessRate;
  final num totalPotentialRent;
  final num averageRent;
  final int totalBedrooms;
  final int totalBathrooms;

  const _UnitsInsightSheet({
    required this.propertyTitle,
    required this.totalUnits,
    required this.availableCount,
    required this.occupiedCount,
    required this.maintenanceCount,
    required this.reservedCount,
    required this.occupancyRate,
    required this.readinessRate,
    required this.totalPotentialRent,
    required this.averageRent,
    required this.totalBedrooms,
    required this.totalBathrooms,
  });

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  Color healthColor() {
    if (maintenanceCount > 0) return Colors.orange;
    if (availableCount == 0 && totalUnits > 0) return Colors.blue;
    if (readinessRate >= 70) return Colors.green;

    return primary;
  }

  String healthLabel() {
    if (totalUnits == 0) return 'No units yet';
    if (maintenanceCount > 0) return 'Needs attention';
    if (availableCount == 0) return 'Fully occupied';
    if (readinessRate >= 70) return 'Lease ready';

    return 'Needs setup';
  }

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
            width: 128,
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
    final color = healthColor();

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
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(Icons.insights, color: color, size: 36),
                ),

                const SizedBox(height: 14),

                Text(
                  propertyTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Unit portfolio intelligence',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),

                const SizedBox(height: 16),

                Chip(
                  avatar: Icon(Icons.health_and_safety, color: color, size: 18),
                  label: Text(healthLabel()),
                  backgroundColor: color.withOpacity(0.12),
                  labelStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  side: BorderSide.none,
                ),

                const SizedBox(height: 18),

                scoreCard(
                  title: 'Occupancy Rate',
                  value: occupancyRate,
                  icon: Icons.key,
                  color: Colors.orange,
                ),

                const SizedBox(height: 10),

                scoreCard(
                  title: 'Lease Readiness',
                  value: readinessRate,
                  icon: Icons.workspace_premium,
                  color: Colors.green,
                ),

                const SizedBox(height: 14),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        infoRow('Total Units', totalUnits),
                        infoRow(
                          'Potential Rent',
                          totalPotentialRent.toStringAsFixed(2),
                        ),
                        infoRow('Average Rent', averageRent.toStringAsFixed(2)),
                        infoRow('Bedrooms', totalBedrooms),
                        infoRow('Bathrooms', totalBathrooms),
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
                          title: 'Available',
                          value: availableCount,
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                        statusRow(
                          title: 'Occupied',
                          value: occupiedCount,
                          icon: Icons.key,
                          color: Colors.orange,
                        ),
                        statusRow(
                          title: 'Maintenance',
                          value: maintenanceCount,
                          icon: Icons.construction,
                          color: Colors.red,
                        ),
                        statusRow(
                          title: 'Reserved',
                          value: reservedCount,
                          icon: Icons.bookmark,
                          color: Colors.blue,
                        ),
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
                      'A strong unit portfolio has clear rent data, complete layout details, available units ready for leasing, and minimal maintenance blockers.',
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
