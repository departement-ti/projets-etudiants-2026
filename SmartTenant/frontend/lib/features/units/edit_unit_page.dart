import 'package:flutter/material.dart';

import '../../core/ui/app_error.dart';
import 'units_service.dart';

class EditUnitPage extends StatefulWidget {
  final Map<String, dynamic> unit;

  const EditUnitPage({super.key, required this.unit});

  @override
  State<EditUnitPage> createState() => _EditUnitPageState();
}

class _EditUnitPageState extends State<EditUnitPage> {
  final formKey = GlobalKey<FormState>();

  final titleCtrl = TextEditingController();
  final numberCtrl = TextEditingController();
  final rentCtrl = TextEditingController();
  final floorCtrl = TextEditingController();
  final bedroomsCtrl = TextEditingController();
  final bathroomsCtrl = TextEditingController();
  final sizeCtrl = TextEditingController();

  bool saving = false;
  String error = '';

  String status = 'AVAILABLE';

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);
  static const darkText = Color(0xFF1D1B20);

  final statuses = const ['AVAILABLE', 'MAINTENANCE', 'RESERVED', 'OCCUPIED'];

  @override
  void initState() {
    super.initState();

    titleCtrl.text = widget.unit['title']?.toString() ?? '';
    numberCtrl.text = widget.unit['number']?.toString() ?? '';
    rentCtrl.text = money(widget.unit['rentAmount']) > 0
        ? money(widget.unit['rentAmount']).toStringAsFixed(2)
        : '';
    floorCtrl.text = widget.unit['floor']?.toString() ?? '';
    bedroomsCtrl.text = widget.unit['bedrooms']?.toString() ?? '';
    bathroomsCtrl.text = widget.unit['bathrooms']?.toString() ?? '';
    sizeCtrl.text = widget.unit['sizeSqm']?.toString() ?? '';
    status = widget.unit['status']?.toString() ?? 'AVAILABLE';

    titleCtrl.addListener(refresh);
    numberCtrl.addListener(refresh);
    rentCtrl.addListener(refresh);
    floorCtrl.addListener(refresh);
    bedroomsCtrl.addListener(refresh);
    bathroomsCtrl.addListener(refresh);
    sizeCtrl.addListener(refresh);
  }

  @override
  void dispose() {
    titleCtrl.removeListener(refresh);
    numberCtrl.removeListener(refresh);
    rentCtrl.removeListener(refresh);
    floorCtrl.removeListener(refresh);
    bedroomsCtrl.removeListener(refresh);
    bathroomsCtrl.removeListener(refresh);
    sizeCtrl.removeListener(refresh);

    titleCtrl.dispose();
    numberCtrl.dispose();
    rentCtrl.dispose();
    floorCtrl.dispose();
    bedroomsCtrl.dispose();
    bathroomsCtrl.dispose();
    sizeCtrl.dispose();

    super.dispose();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  String cleanText(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  num money(dynamic value) {
    if (value is num) return value;

    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  int? optionalInt(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;

    return int.tryParse(text);
  }

  double? optionalDouble(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;

    return double.tryParse(text);
  }

  double? requiredDouble(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;

    return double.tryParse(text);
  }

  String propertyName() {
    final property = widget.unit['property'];

    if (property is Map<String, dynamic>) {
      return property['title']?.toString() ??
          property['name']?.toString() ??
          property['address']?.toString() ??
          'Property';
    }

    return 'Property';
  }

  String propertyAddress() {
    final property = widget.unit['property'];

    if (property is Map<String, dynamic>) {
      final address = property['address']?.toString();

      if (address != null && address.trim().isNotEmpty) return address;
    }

    return 'No property address';
  }

  String unitTitlePreview() {
    final title = cleanText(titleCtrl.text);

    if (title.isNotEmpty) return title;

    final number = cleanText(numberCtrl.text);

    if (number.isNotEmpty) return 'Unit $number';

    return 'Unit';
  }

  String unitNumberPreview() {
    final number = cleanText(numberCtrl.text);

    if (number.isEmpty) return 'No unit number';

    return 'Unit number: $number';
  }

  double rentValue() {
    return requiredDouble(rentCtrl.text) ?? 0;
  }

  String rentPreview() {
    final rent = rentValue();

    if (rent <= 0) return 'Rent not set';

    return '${rent.toStringAsFixed(2)} / period';
  }

  String layoutPreview() {
    final bedrooms = optionalInt(bedroomsCtrl.text);
    final bathrooms = optionalInt(bathroomsCtrl.text);
    final floor = optionalInt(floorCtrl.text);
    final size = optionalDouble(sizeCtrl.text);

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
      parts.add('${size.toStringAsFixed(size % 1 == 0 ? 0 : 1)} sqm');
    }

    if (parts.isEmpty) return 'No layout details';

    return parts.join(' • ');
  }

  String initials() {
    final clean = unitTitlePreview().trim();

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

  Color statusColor(String value) {
    switch (value) {
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

  IconData statusIcon(String value) {
    switch (value) {
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

  String statusDescription(String value) {
    switch (value) {
      case 'AVAILABLE':
        return 'Available units can be used to create new leases.';
      case 'OCCUPIED':
        return 'Occupied status should normally be controlled by an active lease.';
      case 'MAINTENANCE':
        return 'Maintenance units are blocked from leasing until fixed.';
      case 'RESERVED':
        return 'Reserved units should not be leased until released.';
      default:
        return 'Unit status information is unavailable.';
    }
  }

  bool get hasChanges {
    return cleanText(titleCtrl.text) !=
            cleanText(widget.unit['title']?.toString() ?? '') ||
        cleanText(numberCtrl.text) !=
            cleanText(widget.unit['number']?.toString() ?? '') ||
        rentCtrl.text.trim() !=
            (money(widget.unit['rentAmount']) > 0
                ? money(widget.unit['rentAmount']).toStringAsFixed(2)
                : '') ||
        floorCtrl.text.trim() != (widget.unit['floor']?.toString() ?? '') ||
        bedroomsCtrl.text.trim() !=
            (widget.unit['bedrooms']?.toString() ?? '') ||
        bathroomsCtrl.text.trim() !=
            (widget.unit['bathrooms']?.toString() ?? '') ||
        sizeCtrl.text.trim() != (widget.unit['sizeSqm']?.toString() ?? '') ||
        status != (widget.unit['status']?.toString() ?? 'AVAILABLE');
  }

  bool get canSave {
    return !saving &&
        cleanText(titleCtrl.text).isNotEmpty &&
        rentValue() > 0 &&
        hasChanges;
  }

  int get readinessScore {
    int score = 0;

    if (cleanText(titleCtrl.text).isNotEmpty) score += 20;
    if (rentValue() > 0) score += 30;
    if (optionalInt(bedroomsCtrl.text) != null) score += 10;
    if (optionalInt(bathroomsCtrl.text) != null) score += 10;
    if (optionalInt(floorCtrl.text) != null) score += 10;
    if (optionalDouble(sizeCtrl.text) != null) score += 10;
    if (status == 'AVAILABLE') score += 10;

    return score.clamp(0, 100);
  }

  String readinessLabel() {
    if (status == 'OCCUPIED') return 'Occupied';
    if (status == 'MAINTENANCE') return 'Needs work';
    if (status == 'RESERVED') return 'Reserved';
    if (readinessScore >= 85) return 'Excellent';
    if (readinessScore >= 65) return 'Good';
    if (readinessScore >= 40) return 'Basic';

    return 'Incomplete';
  }

  Color readinessColor() {
    if (status == 'OCCUPIED') return Colors.orange;
    if (status == 'MAINTENANCE') return Colors.red;
    if (status == 'RESERVED') return Colors.blue;
    if (readinessScore >= 85) return Colors.green;
    if (readinessScore >= 65) return primary;
    if (readinessScore >= 40) return Colors.orange;

    return Colors.grey;
  }

  String? titleValidator(String? value) {
    final text = cleanText(value ?? '');

    if (text.isEmpty) return 'Unit title is required';
    if (text.length < 2) return 'Title is too short';

    return null;
  }

  String? rentValidator(String? value) {
    final parsed = requiredDouble(value ?? '');

    if (parsed == null) return 'Rent amount is required';
    if (parsed <= 0) return 'Rent amount must be positive';

    return null;
  }

  String? optionalNumberValidator(String? value, {bool allowZero = true}) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return null;

    final parsed = num.tryParse(text);

    if (parsed == null) return 'Invalid number';

    if (!allowZero && parsed <= 0) return 'Must be positive';
    if (allowZero && parsed < 0) return 'Cannot be negative';

    return null;
  }

  void restoreOriginal() {
    setState(() {
      titleCtrl.text = widget.unit['title']?.toString() ?? '';
      numberCtrl.text = widget.unit['number']?.toString() ?? '';
      rentCtrl.text = money(widget.unit['rentAmount']) > 0
          ? money(widget.unit['rentAmount']).toStringAsFixed(2)
          : '';
      floorCtrl.text = widget.unit['floor']?.toString() ?? '';
      bedroomsCtrl.text = widget.unit['bedrooms']?.toString() ?? '';
      bathroomsCtrl.text = widget.unit['bathrooms']?.toString() ?? '';
      sizeCtrl.text = widget.unit['sizeSqm']?.toString() ?? '';
      status = widget.unit['status']?.toString() ?? 'AVAILABLE';
      error = '';
    });
  }

  Future<void> confirmRestore() async {
    if (!hasChanges || saving) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SafeActionSheet(
        icon: Icons.restore,
        color: Colors.orange,
        title: 'Restore original values?',
        message:
            'All unsaved edits will be replaced with the current saved unit data.',
        confirmText: 'Restore Values',
      ),
    );

    if (confirmed == true) {
      restoreOriginal();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Original unit values restored')),
      );
    }
  }

  Future<bool> confirmBack() async {
    if (!hasChanges || saving) return true;

    final leave = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SafeActionSheet(
        icon: Icons.warning_amber,
        color: Colors.red,
        title: 'Discard unit edits?',
        message:
            'You have unsaved unit changes. Leaving now will discard them.',
        confirmText: 'Discard and Leave',
      ),
    );

    return leave == true;
  }

  Future<void> save() async {
    FocusScope.of(context).unfocus();

    setState(() => error = '');

    if (!formKey.currentState!.validate()) {
      setState(() {
        error = 'Please fix the highlighted unit information before saving.';
      });
      return;
    }

    if (status == 'OCCUPIED' &&
        (widget.unit['currentLease'] == null &&
            widget.unit['status']?.toString() != 'OCCUPIED')) {
      await AppError.show(
        context,
        'Occupied status is usually controlled by active leases. Create a lease instead of manually setting the unit as occupied.',
        title: 'Status rule',
      );
      return;
    }

    if (!hasChanges) {
      Navigator.pop(context, false);
      return;
    }

    setState(() => saving = true);

    try {
      await UnitsService.update(
        widget.unit['id'],
        title: cleanText(titleCtrl.text),
        number: cleanText(numberCtrl.text),
        rentAmount: rentValue(),
        floor: optionalInt(floorCtrl.text),
        bedrooms: optionalInt(bedroomsCtrl.text),
        bathrooms: optionalInt(bathroomsCtrl.text),
        sizeSqm: optionalDouble(sizeCtrl.text),
        status: status,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unit updated successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = AppError.clean(e);
      });

      await AppError.show(context, e, title: 'Could not update unit');
    } finally {
      if (mounted) {
        setState(() => saving = false);
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
                      'Edit Unit',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      propertyName(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
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
                  value: rentPreview(),
                  icon: Icons.payments,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Readiness',
                  value: '$readinessScore%',
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
                  title: 'Status',
                  value: status,
                  icon: statusIcon(status),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Changes',
                  value: hasChanges ? 'Unsaved' : 'Saved',
                  icon: hasChanges ? Icons.edit_note : Icons.check_circle,
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
        ],
      ),
    );
  }

  Widget previewCard() {
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
                        unitTitlePreview(),
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
                        unitNumberPreview(),
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
                      'Setup quality: ${readinessLabel()} • $readinessScore%',
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

  Widget propertyCard() {
    return Card(
      color: primary.withOpacity(0.07),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(height: 5),
                  Text(propertyName()),
                  const SizedBox(height: 3),
                  Text(
                    propertyAddress(),
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statusSelectorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unit Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 5),
            Text(
              'Choose the operational state of this unit.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: statuses.map((item) {
                final selected = status == item;
                final color = statusColor(item);

                return ChoiceChip(
                  selected: selected,
                  label: Text(item),
                  avatar: Icon(
                    statusIcon(item),
                    size: 18,
                    color: selected ? Colors.white : color,
                  ),
                  selectedColor: color,
                  backgroundColor: color.withOpacity(0.10),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  side: BorderSide.none,
                  onSelected: saving
                      ? null
                      : (_) {
                          setState(() => status = item);
                        },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget formCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              inputField(
                controller: titleCtrl,
                label: 'Unit Title',
                hint: 'Apartment A1',
                icon: Icons.home_work,
                validator: titleValidator,
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 14),

              inputField(
                controller: numberCtrl,
                label: 'Unit Number',
                hint: 'A1 / 101',
                icon: Icons.numbers,
                textCapitalization: TextCapitalization.characters,
              ),

              const SizedBox(height: 14),

              inputField(
                controller: rentCtrl,
                label: 'Rent Amount',
                hint: '850.00',
                icon: Icons.payments,
                keyboardType: TextInputType.number,
                validator: rentValidator,
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: inputField(
                      controller: bedroomsCtrl,
                      label: 'Bedrooms',
                      icon: Icons.bed,
                      keyboardType: TextInputType.number,
                      validator: optionalNumberValidator,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: inputField(
                      controller: bathroomsCtrl,
                      label: 'Bathrooms',
                      icon: Icons.bathtub,
                      keyboardType: TextInputType.number,
                      validator: optionalNumberValidator,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: inputField(
                      controller: floorCtrl,
                      label: 'Floor',
                      icon: Icons.layers,
                      keyboardType: TextInputType.number,
                      validator: optionalNumberValidator,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: inputField(
                      controller: sizeCtrl,
                      label: 'Size sqm',
                      icon: Icons.square_foot,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          optionalNumberValidator(value, allowZero: false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !saving,
      keyboardType: keyboardType,
      validator: validator,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
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
              title: 'Title',
              subtitle: 'Needed to clearly identify the unit.',
              done: cleanText(titleCtrl.text).isNotEmpty,
            ),
            const Divider(height: 18),
            checklistItem(
              title: 'Rent amount',
              subtitle: 'Required for lease creation and invoice generation.',
              done: rentValue() > 0,
            ),
            const Divider(height: 18),
            checklistItem(
              title: 'Layout details',
              subtitle: 'Bedrooms, bathrooms, floor or size improve filtering.',
              done:
                  optionalInt(bedroomsCtrl.text) != null ||
                  optionalInt(bathroomsCtrl.text) != null ||
                  optionalInt(floorCtrl.text) != null ||
                  optionalDouble(sizeCtrl.text) != null,
              optional: true,
            ),
            const Divider(height: 18),
            checklistItem(
              title: 'Operational status',
              subtitle: 'Controls availability and leasing flow.',
              done: status.isNotEmpty,
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
    bool optional = false,
  }) {
    final color = done
        ? Colors.green
        : optional
        ? Colors.orange
        : Colors.grey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: color.withOpacity(0.12),
          child: Icon(
            done
                ? Icons.check
                : optional
                ? Icons.info_outline
                : Icons.circle_outlined,
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

  Widget warningCard() {
    if (status != 'OCCUPIED') return const SizedBox.shrink();

    return Card(
      color: Colors.orange.withOpacity(0.10),
      child: const ListTile(
        leading: Icon(Icons.warning_amber, color: Colors.orange),
        title: Text(
          'Occupied status warning',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Occupied units should normally be created by an active lease. The backend may block manual changes depending on lease history.',
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
            onPressed: canSave ? save : null,
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(saving ? 'Saving Changes...' : 'Save Changes'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: saving || !hasChanges ? null : confirmRestore,
            icon: const Icon(Icons.restore),
            label: const Text('Restore Original Values'),
          ),
        ),
      ],
    );
  }

  Widget bodyContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        heroHeader(),

        const SizedBox(height: 18),

        previewCard(),

        const SizedBox(height: 14),

        propertyCard(),

        const SizedBox(height: 14),

        statusSelectorCard(),

        const SizedBox(height: 14),

        formCard(),

        const SizedBox(height: 14),

        warningCard(),

        if (status == 'OCCUPIED') const SizedBox(height: 14),

        checklistCard(),

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
      canPop: !hasChanges && !saving,
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
            'Edit Unit',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              tooltip: 'Restore original',
              icon: const Icon(Icons.restore),
              onPressed: saving || !hasChanges ? null : confirmRestore,
            ),
            IconButton(
              tooltip: 'Save',
              icon: saving
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              onPressed: canSave ? save : null,
            ),
          ],
        ),
        body: bodyContent(),
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
