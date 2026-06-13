import 'package:flutter/material.dart';

import '../../core/ui/app_error.dart';
import 'units_service.dart';

class CreateUnitPage extends StatefulWidget {
  final String propertyId;

  const CreateUnitPage({super.key, required this.propertyId});

  @override
  State<CreateUnitPage> createState() => _CreateUnitPageState();
}

class _CreateUnitPageState extends State<CreateUnitPage> {
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

  final statuses = const ['AVAILABLE', 'MAINTENANCE', 'RESERVED'];

  @override
  void initState() {
    super.initState();

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

  double rentValue() {
    return requiredDouble(rentCtrl.text) ?? 0;
  }

  String unitTitlePreview() {
    final title = cleanText(titleCtrl.text);

    if (title.isNotEmpty) return title;

    final number = cleanText(numberCtrl.text);

    if (number.isNotEmpty) return 'Unit $number';

    return 'New Unit';
  }

  String unitNumberPreview() {
    final number = cleanText(numberCtrl.text);

    if (number.isEmpty) return 'No unit number';

    return 'Unit number: $number';
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

    if (parts.isEmpty) return 'No layout details yet';

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
        return 'The unit will be ready for lease creation immediately.';
      case 'MAINTENANCE':
        return 'The unit will be blocked from leasing until it is updated to available.';
      case 'RESERVED':
        return 'The unit will be marked as reserved and should not be leased yet.';
      default:
        return 'Unit status information is unavailable.';
    }
  }

  bool get hasDraft {
    return titleCtrl.text.trim().isNotEmpty ||
        numberCtrl.text.trim().isNotEmpty ||
        rentCtrl.text.trim().isNotEmpty ||
        floorCtrl.text.trim().isNotEmpty ||
        bedroomsCtrl.text.trim().isNotEmpty ||
        bathroomsCtrl.text.trim().isNotEmpty ||
        sizeCtrl.text.trim().isNotEmpty ||
        status != 'AVAILABLE';
  }

  bool get canSave {
    return !saving && cleanText(titleCtrl.text).isNotEmpty && rentValue() > 0;
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
    if (status == 'MAINTENANCE') return 'Needs work';
    if (status == 'RESERVED') return 'Reserved';
    if (readinessScore >= 85) return 'Excellent';
    if (readinessScore >= 65) return 'Good';
    if (readinessScore >= 40) return 'Basic';

    return 'Incomplete';
  }

  Color readinessColor() {
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

  void clearForm() {
    setState(() {
      titleCtrl.clear();
      numberCtrl.clear();
      rentCtrl.clear();
      floorCtrl.clear();
      bedroomsCtrl.clear();
      bathroomsCtrl.clear();
      sizeCtrl.clear();
      status = 'AVAILABLE';
      error = '';
    });
  }

  Future<void> confirmClear() async {
    if (!hasDraft || saving) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SafeActionSheet(
        icon: Icons.cleaning_services,
        color: Colors.orange,
        title: 'Clear unit form?',
        message: 'All unit information entered in this form will be removed.',
        confirmText: 'Clear Form',
      ),
    );

    if (confirmed == true) {
      clearForm();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unit form cleared')));
    }
  }

  Future<bool> confirmBack() async {
    if (!hasDraft || saving) return true;

    final leave = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SafeActionSheet(
        icon: Icons.warning_amber,
        color: Colors.red,
        title: 'Discard unit draft?',
        message:
            'You have unsaved unit information. Leaving now will discard this draft.',
        confirmText: 'Discard and Leave',
      ),
    );

    return leave == true;
  }

  Future<void> confirmCreate() async {
    FocusScope.of(context).unfocus();

    setState(() => error = '');

    if (!formKey.currentState!.validate()) {
      setState(() {
        error = 'Please fix the highlighted unit information before creating.';
      });
      return;
    }

    if (status == 'MAINTENANCE') {
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => const _SafeActionSheet(
          icon: Icons.construction,
          color: Colors.orange,
          title: 'Create as maintenance?',
          message:
              'This unit will not be available for lease creation until its status is changed to AVAILABLE.',
          confirmText: 'Create Anyway',
        ),
      );

      if (confirmed != true) return;
    }

    await save();
  }

  Future<void> save() async {
    setState(() => saving = true);

    try {
      await UnitsService.create(
        propertyId: widget.propertyId,
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
        const SnackBar(content: Text('Unit created successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = AppError.clean(e);
      });

      await AppError.show(context, e, title: 'Could not create unit');
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Unit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Add a rentable unit with rent, layout and availability rules.',
                      style: TextStyle(color: Colors.white70),
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
                  title: 'Draft',
                  value: canSave ? 'Valid' : 'Incomplete',
                  icon: canSave ? Icons.check_circle : Icons.edit_note,
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
              'New units cannot be created as OCCUPIED. Occupancy is created by leases.',
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
              subtitle:
                  'Bedrooms, bathrooms, floor or size improve filtering and tenant matching.',
              done:
                  optionalInt(bedroomsCtrl.text) != null ||
                  optionalInt(bathroomsCtrl.text) != null ||
                  optionalInt(floorCtrl.text) != null ||
                  optionalDouble(sizeCtrl.text) != null,
              optional: true,
            ),
            const Divider(height: 18),
            checklistItem(
              title: 'Availability status',
              subtitle: 'Controls whether this unit can be leased immediately.',
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
                'After creation, available units can be selected in the lease creation flow. When a lease is created, the unit becomes occupied automatically.',
                style: TextStyle(color: Colors.grey.shade800, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget warningCard() {
    if (status != 'MAINTENANCE' && status != 'RESERVED') {
      return const SizedBox.shrink();
    }

    final color = status == 'MAINTENANCE' ? Colors.orange : Colors.blue;
    final icon = status == 'MAINTENANCE' ? Icons.construction : Icons.bookmark;

    return Card(
      color: color.withOpacity(0.10),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          status == 'MAINTENANCE' ? 'Maintenance unit' : 'Reserved unit',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          status == 'MAINTENANCE'
              ? 'This unit will be blocked from lease creation until it becomes available.'
              : 'This unit will be reserved and should not be used for a lease yet.',
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
            onPressed: canSave ? confirmCreate : null,
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_home_work),
            label: Text(saving ? 'Creating Unit...' : 'Create Unit'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: saving || !hasDraft ? null : confirmClear,
            icon: const Icon(Icons.cleaning_services),
            label: const Text('Clear Form'),
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

        statusSelectorCard(),

        const SizedBox(height: 14),

        formCard(),

        const SizedBox(height: 14),

        warningCard(),

        if (status == 'MAINTENANCE' || status == 'RESERVED')
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
      canPop: !hasDraft && !saving,
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
            'Create Unit',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              tooltip: 'Clear form',
              icon: const Icon(Icons.cleaning_services),
              onPressed: saving || !hasDraft ? null : confirmClear,
            ),
            IconButton(
              tooltip: 'Create unit',
              icon: saving
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              onPressed: canSave ? confirmCreate : null,
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
