import 'package:flutter/material.dart';

import '../../core/auth/auth_storage.dart';
import '../../core/ui/app_error.dart';
import '../tenants/tenants_page.dart';
import 'lease_service.dart';

class CreateLeasePage extends StatefulWidget {
  final String? preselectedUnitId;

  const CreateLeasePage({super.key, this.preselectedUnitId});

  @override
  State<CreateLeasePage> createState() => _CreateLeasePageState();
}

class _CreateLeasePageState extends State<CreateLeasePage> {
  final rentCtrl = TextEditingController();
  final depositCtrl = TextEditingController();

  bool loading = true;
  bool submitting = false;
  bool loadingUnits = false;

  String error = '';
  String? role;

  List<dynamic> tenants = [];
  List<dynamic> properties = [];
  List<dynamic> units = [];

  String? selectedTenantId;
  String? selectedPropertyId;
  String? selectedUnitId;

  DateTime? startDate;
  DateTime? endDate;

  String frequency = 'MONTHLY';

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);
  static const darkText = Color(0xFF1D1B20);

  bool get canCreateLease {
    return role == 'ADMIN' || role == 'OWNER';
  }

  bool get hasDraft {
    return selectedTenantId != null ||
        selectedPropertyId != null ||
        selectedUnitId != null ||
        rentCtrl.text.trim().isNotEmpty ||
        depositCtrl.text.trim().isNotEmpty ||
        startDate != null ||
        endDate != null ||
        frequency != 'MONTHLY';
  }

  bool get hasTenants => tenants.isNotEmpty;

  bool get hasProperties => properties.isNotEmpty;

  bool get hasUnits => units.isNotEmpty;

  bool get canSubmit {
    return !submitting &&
        !loading &&
        canCreateLease &&
        selectedTenantId != null &&
        selectedUnitId != null &&
        startDate != null &&
        endDate != null &&
        rentAmount() > 0 &&
        datesValid();
  }

  int get completedSteps {
    int count = 0;

    if (selectedTenantId != null) count++;
    if (selectedPropertyId != null) count++;
    if (selectedUnitId != null) count++;
    if (rentAmount() > 0) count++;
    if (startDate != null && endDate != null && datesValid()) count++;

    return count;
  }

  double get setupProgress {
    return completedSteps / 5;
  }

  String get setupLabel {
    return '${(setupProgress * 100).round()}% ready';
  }

  @override
  void initState() {
    super.initState();

    rentCtrl.addListener(refresh);
    depositCtrl.addListener(refresh);

    loadInitialData();
  }

  @override
  void dispose() {
    rentCtrl.removeListener(refresh);
    depositCtrl.removeListener(refresh);

    rentCtrl.dispose();
    depositCtrl.dispose();

    super.dispose();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  Future<void> loadInitialData() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final userRole = await AuthStorage.getUserRole();

      final loadedTenants = await LeaseService.getTenants();
      final loadedProperties = await LeaseService.getProperties();

      if (!mounted) return;

      setState(() {
        role = userRole;
        tenants = loadedTenants;
        properties = loadedProperties;
        loading = false;
      });

      if (widget.preselectedUnitId != null) {
        await loadPreselectedUnit(widget.preselectedUnitId!);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = AppError.clean(e);
        loading = false;
      });
    }
  }

  Future<void> loadPreselectedUnit(String unitId) async {
    try {
      final unit = await LeaseService.getUnit(unitId);
      final propertyId =
          unit['propertyId']?.toString() ?? unit['property']?['id']?.toString();

      if (propertyId == null || propertyId.isEmpty) return;

      if (!mounted) return;

      setState(() {
        selectedPropertyId = propertyId;
      });

      await loadUnitsForProperty(propertyId);

      if (!mounted) return;

      final exists = units.any((item) => item['id']?.toString() == unitId);

      setState(() {
        selectedUnitId = exists ? unitId : null;
      });

      if (exists) {
        applyUnitRent(unit);
      }
    } catch (e) {
      if (!mounted) return;

      await AppError.show(context, e, title: 'Could not load selected unit');
    }
  }

  Future<void> loadUnitsForProperty(String propertyId) async {
    setState(() {
      loadingUnits = true;
      units = [];
      selectedUnitId = null;
    });

    try {
      final data = await LeaseService.getUnitsByProperty(propertyId);

      if (!mounted) return;

      setState(() {
        units = data;
        loadingUnits = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingUnits = false;
      });

      await AppError.show(context, e, title: 'Could not load units');
    }
  }

  void onPropertyChanged(String? propertyId) {
    if (propertyId == null) return;

    setState(() {
      selectedPropertyId = propertyId;
      selectedUnitId = null;
      units = [];
    });

    loadUnitsForProperty(propertyId);
  }

  void onUnitChanged(String? unitId) {
    if (unitId == null) return;

    setState(() {
      selectedUnitId = unitId;
    });

    final unit = selectedUnit();
    if (unit != null) {
      applyUnitRent(unit);
    }
  }

  void applyUnitRent(dynamic unit) {
    final rent = money(unit['rentAmount']);

    if (rent > 0) {
      rentCtrl.text = rent.toStringAsFixed(2);
      rentCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: rentCtrl.text.length),
      );
    }
  }

  dynamic selectedTenant() {
    for (final tenant in tenants) {
      if (tenant['id']?.toString() == selectedTenantId) {
        return tenant;
      }
    }

    return null;
  }

  dynamic selectedProperty() {
    for (final property in properties) {
      if (property['id']?.toString() == selectedPropertyId) {
        return property;
      }
    }

    return null;
  }

  dynamic selectedUnit() {
    for (final unit in units) {
      if (unit['id']?.toString() == selectedUnitId) {
        return unit;
      }
    }

    return null;
  }

  String tenantName(dynamic tenant) {
    if (tenant == null) return 'Select tenant';

    final user = tenant['user'];

    if (user != null) {
      final firstName = user['firstName']?.toString() ?? '';
      final lastName = user['lastName']?.toString() ?? '';
      final email = user['email']?.toString() ?? '';

      final fullName = '$firstName $lastName'.trim();

      if (fullName.isNotEmpty) return fullName;
      if (email.isNotEmpty) return email;
    }

    return 'Tenant';
  }

  String tenantEmail(dynamic tenant) {
    return tenant?['user']?['email']?.toString() ?? '—';
  }

  String propertyTitle(dynamic property) {
    if (property == null) return 'Select property';

    return property['title']?.toString() ??
        property['name']?.toString() ??
        property['address']?.toString() ??
        'Property';
  }

  String propertyAddress(dynamic property) {
    final address = property?['address']?.toString();

    if (address == null || address.trim().isEmpty) return 'No address';

    return address;
  }

  String unitTitle(dynamic unit) {
    if (unit == null) return 'Select unit';

    return unit['title']?.toString() ?? unit['number']?.toString() ?? 'Unit';
  }

  String unitStatus(dynamic unit) {
    return unit?['status']?.toString() ?? '—';
  }

  bool unitAvailable(dynamic unit) {
    return unitStatus(unit) == 'AVAILABLE';
  }

  num money(dynamic value) {
    if (value is num) return value;

    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  num rentAmount() {
    return money(rentCtrl.text);
  }

  num depositAmount() {
    return money(depositCtrl.text);
  }

  String moneyText(num value) {
    return value.toStringAsFixed(2);
  }

  String formatDate(dynamic value) {
    if (value == null) return '—';

    final parsed = value is DateTime
        ? value
        : DateTime.tryParse(value.toString());

    if (parsed == null) return value.toString();

    return parsed.toLocal().toString().split(' ')[0];
  }

  bool datesValid() {
    if (startDate == null || endDate == null) return false;

    return endDate!.isAfter(startDate!);
  }

  int leaseDurationDays() {
    if (startDate == null || endDate == null) return 0;

    return endDate!.difference(startDate!).inDays;
  }

  String durationLabel() {
    final days = leaseDurationDays();

    if (days <= 0) return 'Invalid dates';

    if (days < 30) return '$days day${days == 1 ? '' : 's'}';

    final months = (days / 30).round();

    if (months < 12) return '$months month${months == 1 ? '' : 's'}';

    final years = (days / 365).toStringAsFixed(1);

    return '$years year${years == '1.0' ? '' : 's'}';
  }

  String firstInvoiceLabel() {
    if (startDate == null) return 'Select start date';

    return formatDate(startDate);
  }

  String nextStepMessage() {
    if (!hasTenants) {
      return 'Create at least one tenant profile before creating a lease.';
    }

    if (!hasProperties) {
      return 'Create a property and available units before creating a lease.';
    }

    if (selectedPropertyId == null) {
      return 'Select the property where the lease will be created.';
    }

    if (selectedUnitId == null) {
      return 'Select an available unit to occupy.';
    }

    if (selectedTenantId == null) {
      return 'Select the tenant who will occupy this unit.';
    }

    if (rentAmount() <= 0) {
      return 'Set a valid rent amount.';
    }

    if (startDate == null || endDate == null) {
      return 'Choose the lease start and end dates.';
    }

    if (!datesValid()) {
      return 'End date must be after start date.';
    }

    return 'Ready to create lease. The first invoice will be generated at lease start.';
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

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      startDate = picked;

      if (endDate == null || !endDate!.isAfter(startDate!)) {
        endDate = DateTime(picked.year + 1, picked.month, picked.day);
      }
    });
  }

  Future<void> pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          endDate ??
          (startDate == null
              ? DateTime.now().add(const Duration(days: 365))
              : DateTime(
                  startDate!.year + 1,
                  startDate!.month,
                  startDate!.day,
                )),
      firstDate: startDate ?? DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      endDate = picked;
    });
  }

  Future<void> openTenantsPage() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TenantsPage()),
    );

    if (changed == true || mounted) {
      await loadInitialData();
    }
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();

    setState(() => error = '');

    if (!canCreateLease) {
      await AppError.show(
        context,
        'Only admins and owners can create leases.',
        title: 'Permission required',
      );
      return;
    }

    if (!hasTenants) {
      setState(() => error = 'No tenant profiles found');
      await AppError.show(
        context,
        'Create a tenant profile first, then return to create the lease.',
        title: 'Tenant profile required',
      );
      return;
    }

    if (selectedTenantId == null) {
      setState(() => error = 'Please select a tenant');
      return;
    }

    if (selectedPropertyId == null) {
      setState(() => error = 'Please select a property');
      return;
    }

    if (selectedUnitId == null) {
      setState(() => error = 'Please select an available unit');
      return;
    }

    final unit = selectedUnit();

    if (unit != null && !unitAvailable(unit)) {
      setState(() => error = 'Selected unit is not available');
      await AppError.show(
        context,
        'Only AVAILABLE units can be used to create a lease.',
        title: 'Unit not available',
      );
      return;
    }

    if (rentAmount() <= 0) {
      setState(() => error = 'Rent amount must be positive');
      return;
    }

    if (depositCtrl.text.trim().isNotEmpty && depositAmount() < 0) {
      setState(() => error = 'Deposit amount cannot be negative');
      return;
    }

    if (startDate == null || endDate == null) {
      setState(() => error = 'Start date and end date are required');
      return;
    }

    if (!datesValid()) {
      setState(() => error = 'End date must be after start date');
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateLeaseConfirmSheet(
        tenantName: tenantName(selectedTenant()),
        propertyTitle: propertyTitle(selectedProperty()),
        unitTitle: unitTitle(selectedUnit()),
        rent: moneyText(rentAmount()),
        deposit: moneyText(depositAmount()),
        frequency: frequency,
        startDate: formatDate(startDate),
        endDate: formatDate(endDate),
        firstInvoiceDate: firstInvoiceLabel(),
      ),
    );

    if (confirmed != true) return;

    setState(() => submitting = true);

    try {
      await LeaseService.createLease(
        tenantId: selectedTenantId!,
        unitId: selectedUnitId!,
        rentAmount: rentAmount().toDouble(),
        startDate: startDate!.toIso8601String(),
        endDate: endDate!.toIso8601String(),
        frequency: frequency,
        depositAmount: depositCtrl.text.trim().isEmpty
            ? null
            : depositAmount().toDouble(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lease created successfully. First invoice was generated.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      await AppError.show(context, e, title: 'Could not create lease');
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  void clearForm() {
    setState(() {
      selectedTenantId = null;
      selectedPropertyId = null;
      selectedUnitId = null;
      units = [];
      startDate = null;
      endDate = null;
      frequency = 'MONTHLY';
      error = '';
      rentCtrl.clear();
      depositCtrl.clear();
    });
  }

  Future<void> confirmClear() async {
    if (!hasDraft || submitting) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SafeActionSheet(
        icon: Icons.cleaning_services,
        color: Colors.orange,
        title: 'Clear lease form?',
        message: 'All selected lease information will be removed.',
        confirmText: 'Clear Form',
      ),
    );

    if (confirmed == true) {
      clearForm();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lease form cleared')));
    }
  }

  Future<bool> confirmBack() async {
    if (!hasDraft || submitting) return true;

    final leave = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SafeActionSheet(
        icon: Icons.warning_amber,
        color: Colors.red,
        title: 'Discard lease draft?',
        message:
            'You have unsaved lease information. Leaving now will discard your draft.',
        confirmText: 'Discard and Leave',
      ),
    );

    return leave == true;
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
          const Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: Colors.white,
                child: Icon(Icons.description, color: primary, size: 30),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Lease',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Assign a tenant to an available unit and generate the first invoice.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Status',
                  value: canSubmit ? 'Ready' : 'Draft',
                  icon: canSubmit ? Icons.check_circle : Icons.edit_note,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Setup',
                  value: setupLabel,
                  icon: Icons.auto_graph,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Rent',
                  value: moneyText(rentAmount()),
                  icon: Icons.payments,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'First Invoice',
                  value: firstInvoiceLabel(),
                  icon: Icons.receipt_long,
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
                  nextStepMessage(),
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
              value: setupProgress,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget noTenantsCard() {
    if (hasTenants) return const SizedBox.shrink();

    return Card(
      color: Colors.orange.withOpacity(0.10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.info_outline, color: Colors.orange),
              title: Text(
                'No tenant profiles found',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Create a tenant account and profile before creating a lease.',
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: openTenantsPage,
                icon: const Icon(Icons.person_add),
                label: const Text('Open Tenants Page'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget readOnlyNotice() {
    if (canCreateLease) return const SizedBox.shrink();

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
                'Lease creation is restricted to admins and owners.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget previewCard() {
    final tenant = selectedTenant();
    final property = selectedProperty();
    final unit = selectedUnit();

    final unitColor = statusColor(unitStatus(unit));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: primary.withOpacity(0.12),
                  child: const Icon(
                    Icons.description,
                    color: primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
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
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        propertyTitle(property),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tenant: ${tenantName(tenant)}',
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
                  label: Text(canSubmit ? 'READY' : 'DRAFT'),
                  backgroundColor: (canSubmit ? Colors.green : Colors.grey)
                      .withOpacity(0.12),
                  labelStyle: TextStyle(
                    color: canSubmit ? Colors.green : Colors.grey,
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
                  Icon(Icons.home_work, color: unitColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      unit == null
                          ? 'Select an available unit to continue.'
                          : 'Unit status: ${unitStatus(unit)} • Rent: ${moneyText(rentAmount())} • $frequency',
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
                color: primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'First invoice due date: ${firstInvoiceLabel()}',
                      style: const TextStyle(
                        color: primary,
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

  Widget selectorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedTenantId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Tenant',
                prefixIcon: Icon(Icons.person),
              ),
              items: tenants.map((tenant) {
                return DropdownMenuItem<String>(
                  value: tenant['id']?.toString(),
                  child: Text(
                    '${tenantName(tenant)} • ${tenantEmail(tenant)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: submitting || !canCreateLease
                  ? null
                  : (value) {
                      setState(() => selectedTenantId = value);
                    },
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: selectedPropertyId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Property',
                prefixIcon: Icon(Icons.apartment),
              ),
              items: properties.map((property) {
                return DropdownMenuItem<String>(
                  value: property['id']?.toString(),
                  child: Text(
                    '${propertyTitle(property)} • ${propertyAddress(property)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: submitting || !canCreateLease
                  ? null
                  : onPropertyChanged,
            ),

            const SizedBox(height: 14),

            if (loadingUnits)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: selectedUnitId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Available Unit',
                  prefixIcon: Icon(Icons.home_work),
                ),
                items: units.map((unit) {
                  final status = unitStatus(unit);
                  final available = unitAvailable(unit);

                  return DropdownMenuItem<String>(
                    value: unit['id']?.toString(),
                    enabled: available,
                    child: Text(
                      '${unitTitle(unit)} • $status • ${moneyText(money(unit['rentAmount']))}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: available ? null : Colors.grey),
                    ),
                  );
                }).toList(),
                onChanged: submitting || !canCreateLease || !hasUnits
                    ? null
                    : onUnitChanged,
              ),

            if (selectedPropertyId != null &&
                !loadingUnits &&
                units.isEmpty) ...[
              const SizedBox(height: 12),
              Card(
                color: Colors.orange.withOpacity(0.10),
                child: const ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.orange),
                  title: Text(
                    'No units found',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'This property has no units available for lease creation.',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget financialCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: rentCtrl,
              enabled: !submitting && canCreateLease,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Rent Amount',
                prefixIcon: Icon(Icons.payments),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: depositCtrl,
              enabled: !submitting && canCreateLease,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Deposit Amount',
                hintText: 'Optional',
                prefixIcon: Icon(Icons.savings),
              ),
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: frequency,
              decoration: const InputDecoration(
                labelText: 'Payment Frequency',
                prefixIcon: Icon(Icons.calendar_month),
              ),
              items: const [
                DropdownMenuItem(value: 'DAILY', child: Text('Daily')),
                DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
                DropdownMenuItem(value: 'YEARLY', child: Text('Yearly')),
              ],
              onChanged: submitting || !canCreateLease
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => frequency = value);
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget datesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: submitting || !canCreateLease
                        ? null
                        : pickStartDate,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      startDate == null ? 'Start Date' : formatDate(startDate),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: submitting || !canCreateLease
                        ? null
                        : pickEndDate,
                    icon: const Icon(Icons.event),
                    label: Text(
                      endDate == null ? 'End Date' : formatDate(endDate),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: datesValid()
                    ? Colors.green.withOpacity(0.08)
                    : Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    datesValid() ? Icons.check_circle : Icons.info_outline,
                    color: datesValid() ? Colors.green : Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      datesValid()
                          ? 'Lease duration: ${durationLabel()}'
                          : 'Choose valid start and end dates.',
                      style: TextStyle(
                        color: datesValid() ? Colors.green : Colors.orange,
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

  Widget checklistCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            checklistItem(
              title: 'Tenant selected',
              subtitle: 'The tenant profile receiving this lease.',
              done: selectedTenantId != null,
            ),
            const Divider(height: 18),
            checklistItem(
              title: 'Property selected',
              subtitle: 'The property containing the rental unit.',
              done: selectedPropertyId != null,
            ),
            const Divider(height: 18),
            checklistItem(
              title: 'Available unit selected',
              subtitle: 'Only AVAILABLE units can be leased.',
              done:
                  selectedUnitId != null &&
                  selectedUnit() != null &&
                  unitAvailable(selectedUnit()),
            ),
            const Divider(height: 18),
            checklistItem(
              title: 'Rent and frequency ready',
              subtitle: 'Used to generate the first invoice automatically.',
              done: rentAmount() > 0,
            ),
            const Divider(height: 18),
            checklistItem(
              title: 'Lease dates valid',
              subtitle: 'First invoice due date is the lease start date.',
              done: startDate != null && endDate != null && datesValid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget checklistItem({
    required String title,
    required String subtitle,
    required bool done,
  }) {
    final color = done ? Colors.green : Colors.grey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: color.withOpacity(0.12),
          child: Icon(
            done ? Icons.check : Icons.circle_outlined,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget helperCard() {
    return Card(
      color: primary.withOpacity(0.07),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: primary.withOpacity(0.12),
              child: const Icon(Icons.lightbulb_outline, color: primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'After creation, the unit becomes occupied, the lease becomes active, and the first invoice is generated with due date equal to the lease start date.',
                style: TextStyle(color: Colors.grey.shade800, height: 1.4),
              ),
            ),
          ],
        ),
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

  Widget actionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canSubmit ? submit : null,
            icon: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(submitting ? 'Creating Lease...' : 'Create Lease'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: submitting || !hasDraft ? null : confirmClear,
            icon: const Icon(Icons.cleaning_services),
            label: const Text('Clear Form'),
          ),
        ),
      ],
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

  Widget loadErrorBody() {
    return RefreshIndicator(
      onRefresh: loadInitialData,
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
                    'Could not load lease setup data',
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
                    onPressed: loadInitialData,
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        heroHeader(),

        const SizedBox(height: 18),

        readOnlyNotice(),

        if (!canCreateLease) const SizedBox(height: 14),

        noTenantsCard(),

        if (!hasTenants) const SizedBox(height: 14),

        previewCard(),

        const SizedBox(height: 14),

        selectorCard(),

        const SizedBox(height: 14),

        financialCard(),

        const SizedBox(height: 14),

        datesCard(),

        const SizedBox(height: 14),

        checklistCard(),

        const SizedBox(height: 14),

        helperCard(),

        const SizedBox(height: 14),

        errorCard(),

        const SizedBox(height: 22),

        actionButtons(),

        const SizedBox(height: 80),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !hasDraft && !submitting,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final leave = await confirmBack();

        if (!mounted) return;

        if (leave) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: softBg,
        appBar: AppBar(
          title: const Text(
            'Create Lease',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: submitting ? null : loadInitialData,
            ),
            IconButton(
              icon: const Icon(Icons.cleaning_services),
              onPressed: submitting || !hasDraft ? null : confirmClear,
            ),
          ],
        ),
        body: loading
            ? loadingBody()
            : error.isNotEmpty && tenants.isEmpty && properties.isEmpty
            ? loadErrorBody()
            : contentBody(),
      ),
    );
  }
}

class _CreateLeaseConfirmSheet extends StatelessWidget {
  final String tenantName;
  final String propertyTitle;
  final String unitTitle;
  final String rent;
  final String deposit;
  final String frequency;
  final String startDate;
  final String endDate;
  final String firstInvoiceDate;

  const _CreateLeaseConfirmSheet({
    required this.tenantName,
    required this.propertyTitle,
    required this.unitTitle,
    required this.rent,
    required this.deposit,
    required this.frequency,
    required this.startDate,
    required this.endDate,
    required this.firstInvoiceDate,
  });

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  Widget infoRow(String label, String value) {
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
              value.isNotEmpty ? value : '—',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

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
                backgroundColor: primary.withOpacity(0.12),
                child: const Icon(Icons.description, color: primary, size: 34),
              ),

              const SizedBox(height: 16),

              const Text(
                'Create Lease?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                'Please review the lease information before creating it.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),

              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      infoRow('Tenant', tenantName),
                      infoRow('Property', propertyTitle),
                      infoRow('Unit', unitTitle),
                      infoRow('Rent', rent),
                      infoRow('Deposit', deposit),
                      infoRow('Frequency', frequency),
                      infoRow('Start', startDate),
                      infoRow('End', endDate),
                      infoRow('First Invoice', firstInvoiceDate),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Card(
                color: Colors.green.withOpacity(0.10),
                child: const ListTile(
                  leading: Icon(Icons.receipt_long, color: Colors.green),
                  title: Text(
                    'Automatic first invoice',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'The first invoice will be generated immediately with due date equal to the lease start date.',
                  ),
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Create Lease'),
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
