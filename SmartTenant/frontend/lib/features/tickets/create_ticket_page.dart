import 'package:flutter/material.dart';

import '../../core/auth/auth_storage.dart';
import '../../core/ui/app_error.dart';
import '../properties/properties_service.dart';
import '../units/units_service.dart';
import 'ticket_service.dart';

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({super.key});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final formKey = GlobalKey<FormState>();

  final titleCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();

  final titleFocus = FocusNode();
  final descriptionFocus = FocusNode();

  List<dynamic> properties = [];
  List<dynamic> units = [];

  String? selectedPropertyId;
  String? selectedUnitId;

  String priority = 'medium';
  String category = 'General';
  String selectedSection = 'DETAILS';
  String? role;

  bool loading = true;
  bool loadingUnits = false;
  bool submitting = false;
  bool refreshing = false;

  String error = '';

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);
  static const darkText = Color(0xFF1D1B20);

  final categories = const [
    'General',
    'Plumbing',
    'Electrical',
    'HVAC',
    'Cleaning',
    'Security',
    'Appliance',
    'Noise',
    'Other',
  ];

  final priorities = const ['low', 'medium', 'high', 'urgent'];

  bool get isTenant => role == 'TENANT';

  bool get isAgent => role == 'AGENT';

  bool get canCreateTicket {
    return role == 'ADMIN' ||
        role == 'OWNER' ||
        role == 'ASSISTANT' ||
        role == 'TENANT';
  }

  bool get hasTitle => cleanText(titleCtrl.text).isNotEmpty;

  bool get hasDescription => cleanText(descriptionCtrl.text).isNotEmpty;

  bool get hasLocation {
    if (isTenant) return true;
    return selectedPropertyId != null && selectedUnitId != null;
  }

  bool get hasData {
    if (!canCreateTicket) return false;

    return titleCtrl.text.trim().isNotEmpty ||
        descriptionCtrl.text.trim().isNotEmpty ||
        selectedPropertyId != null ||
        selectedUnitId != null ||
        priority != 'medium' ||
        category != 'General';
  }

  bool get canSubmit {
    if (!canCreateTicket) return false;
    if (submitting || loadingUnits || !hasTitle) return false;

    if (isTenant) return true;

    return selectedPropertyId != null && selectedUnitId != null;
  }

  double get setupProgress {
    int completed = 0;
    const total = 5;

    if (hasTitle) completed++;
    if (hasDescription) completed++;
    if (priority.trim().isNotEmpty) completed++;
    if (category.trim().isNotEmpty) completed++;
    if (hasLocation) completed++;

    return completed / total;
  }

  String get setupProgressLabel {
    return '${(setupProgress * 100).round()}% complete';
  }

  int get ticketQualityScore {
    int score = 0;

    if (hasTitle) score += 25;
    if (hasDescription) score += 25;
    if (category != 'General') score += 15;
    if (priority == 'medium' || priority == 'high') score += 10;
    if (priority == 'urgent') score += 15;
    if (hasLocation) score += 25;

    return score.clamp(0, 100);
  }

  String get ticketQualityLabel {
    if (ticketQualityScore >= 85) return 'Excellent';
    if (ticketQualityScore >= 65) return 'Good';
    if (ticketQualityScore >= 40) return 'Basic';

    return 'Incomplete';
  }

  Color get ticketQualityColor {
    if (ticketQualityScore >= 85) return Colors.green;
    if (ticketQualityScore >= 65) return primary;
    if (ticketQualityScore >= 40) return Colors.orange;

    return Colors.grey;
  }

  @override
  void initState() {
    super.initState();

    titleCtrl.addListener(refresh);
    descriptionCtrl.addListener(refresh);

    loadInitialData();
  }

  @override
  void dispose() {
    titleCtrl.removeListener(refresh);
    descriptionCtrl.removeListener(refresh);

    titleCtrl.dispose();
    descriptionCtrl.dispose();

    titleFocus.dispose();
    descriptionFocus.dispose();

    super.dispose();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  String cleanText(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> loadInitialData({bool silent = false}) async {
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

      if (userRole == 'TENANT') {
        if (!mounted) return;

        setState(() {
          role = userRole;
          loading = false;
          refreshing = false;
          error = '';
        });

        return;
      }
      if (userRole == 'AGENT') {
        if (!mounted) return;

        setState(() {
          role = userRole;
          loading = false;
          refreshing = false;
          error = '';
        });

        return;
      }

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

      if (silent) {
        await AppError.show(context, e, title: 'Could not refresh ticket form');
      }
    }
  }

  Future<void> loadUnits(String propertyId) async {
    setState(() {
      loadingUnits = true;
      error = '';
      units = [];
      selectedUnitId = null;
    });

    try {
      final data = await UnitsService.getByProperty(propertyId);

      if (!mounted) return;

      setState(() {
        units = data;
        loadingUnits = false;
        error = '';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingUnits = false;
        error = AppError.clean(e);
      });

      await AppError.show(context, e, title: 'Could not load units');
    }
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();

    setState(() => error = '');

    if (!formKey.currentState!.validate()) {
      setState(() {
        error = isTenant
            ? 'Please add a clear request title.'
            : 'Please complete the required ticket information.';
      });
      return;
    }

    if (!isTenant && selectedPropertyId == null) {
      setState(() {
        error = 'Please select the related property.';
        selectedSection = 'LOCATION';
      });

      await AppError.show(
        context,
        'Please select the related property before creating the ticket.',
        title: 'Property is required',
      );

      return;
    }

    if (!isTenant && selectedUnitId == null) {
      setState(() {
        error = 'Please select the related unit.';
        selectedSection = 'LOCATION';
      });

      await AppError.show(
        context,
        'Please select the related unit before creating the ticket.',
        title: 'Unit is required',
      );

      return;
    }

    if (priority == 'urgent') {
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SafeActionSheet(
          icon: Icons.priority_high,
          color: Colors.red,
          title: 'Create urgent ticket?',
          message:
              'Urgent tickets should be used for critical issues that need immediate attention.',
          confirmText: isTenant
              ? 'Submit Urgent Request'
              : 'Create Urgent Ticket',
        ),
      );

      if (confirmed != true) return;
    }

    setState(() {
      submitting = true;
      error = '';
    });

    try {
      await TicketService.create(
        title: cleanText(titleCtrl.text),
        description: cleanText(descriptionCtrl.text),
        priority: priority,
        propertyId: isTenant ? null : selectedPropertyId,
        unitId: isTenant ? null : selectedUnitId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isTenant
                ? 'Request submitted successfully'
                : 'Ticket created successfully',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = AppError.clean(e);
      });

      await AppError.show(
        context,
        e,
        title: isTenant
            ? 'Could not submit request'
            : 'Could not create ticket',
      );
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  String? requiredValidator(String? value) {
    final text = cleanText(value ?? '');

    if (text.isEmpty) return 'This field is required';
    if (text.length < 3) return 'Must be at least 3 characters';

    return null;
  }

  String propertyLabel(dynamic property) {
    return property['title']?.toString() ??
        property['name']?.toString() ??
        property['address']?.toString() ??
        'Property';
  }

  String unitLabel(dynamic unit) {
    final title =
        unit['title']?.toString() ?? unit['number']?.toString() ?? 'Unit';

    final status = unit['status']?.toString() ?? '';

    return status.isEmpty ? title : '$title • $status';
  }

  String selectedPropertyName() {
    if (isTenant) return 'Management team';

    for (final property in properties) {
      if (property['id']?.toString() == selectedPropertyId) {
        return propertyLabel(property);
      }
    }

    return 'No property selected';
  }

  String selectedUnitName() {
    if (isTenant) return 'Tenant request';

    for (final unit in units) {
      if (unit['id']?.toString() == selectedUnitId) {
        return unitLabel(unit);
      }
    }

    return 'No unit selected';
  }

  Color priorityColor(String value) {
    switch (value) {
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

  IconData priorityIcon(String value) {
    switch (value) {
      case 'urgent':
        return Icons.priority_high;
      case 'high':
        return Icons.keyboard_double_arrow_up;
      case 'medium':
        return Icons.remove_circle_outline;
      case 'low':
        return Icons.keyboard_arrow_down;
      default:
        return Icons.flag;
    }
  }

  String priorityDescription(String value) {
    switch (value) {
      case 'urgent':
        return 'Critical issue that needs immediate attention.';
      case 'high':
        return 'Important issue that should be handled soon.';
      case 'medium':
        return 'Normal maintenance request.';
      case 'low':
        return 'Minor issue with no immediate risk.';
      default:
        return 'Ticket priority.';
    }
  }

  IconData categoryIcon(String value) {
    switch (value) {
      case 'Plumbing':
        return Icons.water_damage;
      case 'Electrical':
        return Icons.electrical_services;
      case 'HVAC':
        return Icons.ac_unit;
      case 'Cleaning':
        return Icons.cleaning_services;
      case 'Security':
        return Icons.security;
      case 'Appliance':
        return Icons.kitchen;
      case 'Noise':
        return Icons.volume_up;
      case 'Other':
        return Icons.more_horiz;
      case 'General':
      default:
        return Icons.construction;
    }
  }

  Color categoryColor(String value) {
    switch (value) {
      case 'Plumbing':
        return Colors.blue;
      case 'Electrical':
        return Colors.orange;
      case 'HVAC':
        return Colors.cyan;
      case 'Cleaning':
        return Colors.green;
      case 'Security':
        return Colors.red;
      case 'Appliance':
        return Colors.deepPurple;
      case 'Noise':
        return Colors.pink;
      case 'Other':
        return Colors.grey;
      case 'General':
      default:
        return primary;
    }
  }

  String categoryDescription(String value) {
    switch (value) {
      case 'Plumbing':
        return 'Leaks, water pressure, drains, toilets, sinks and bathrooms.';
      case 'Electrical':
        return 'Lights, outlets, switches, breakers and electrical safety.';
      case 'HVAC':
        return 'Heating, cooling, ventilation and air conditioning.';
      case 'Cleaning':
        return 'Common areas, hygiene, waste or cleanliness issues.';
      case 'Security':
        return 'Locks, access, cameras, doors or safety concerns.';
      case 'Appliance':
        return 'Kitchen, laundry or installed appliance problems.';
      case 'Noise':
        return 'Noise complaints or disturbance reports.';
      case 'Other':
        return 'Issue does not fit a standard category.';
      case 'General':
      default:
        return 'General maintenance or support request.';
    }
  }

  String titlePreview() {
    final text = cleanText(titleCtrl.text);
    return text.isEmpty ? 'New Ticket' : text;
  }

  String descriptionPreview() {
    final text = cleanText(descriptionCtrl.text);

    return text.isEmpty
        ? 'Add details so the team understands the issue.'
        : text;
  }

  void applyTemplate({
    required String title,
    required String description,
    required String templateCategory,
    required String templatePriority,
  }) {
    setState(() {
      titleCtrl.text = title;
      descriptionCtrl.text = description;
      category = templateCategory;
      priority = templatePriority;
      selectedSection = 'DETAILS';
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Template applied')));
  }

  Future<void> confirmClearDraft() async {
    if (!hasData || submitting) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SafeActionSheet(
        icon: Icons.cleaning_services,
        color: Colors.orange,
        title: 'Clear ticket draft?',
        message:
            'This will remove all information entered in this ticket form.',
        confirmText: 'Clear Draft',
      ),
    );

    if (confirmed != true) return;

    setState(() {
      titleCtrl.clear();
      descriptionCtrl.clear();
      selectedPropertyId = null;
      selectedUnitId = null;
      units = [];
      priority = 'medium';
      category = 'General';
      error = '';
      selectedSection = 'DETAILS';
    });

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ticket draft cleared')));
  }

  Future<bool> confirmBack() async {
    if (!hasData || submitting) return true;

    final leave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SafeActionSheet(
        icon: Icons.warning_amber,
        color: Colors.red,
        title: isTenant ? 'Discard request draft?' : 'Discard ticket draft?',
        message:
            'You have unsaved ticket information. Leaving now will discard your changes.',
        confirmText: 'Discard and Leave',
      ),
    );

    return leave == true;
  }

  Future<void> openPreviewSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TicketPreviewSheet(
        title: titlePreview(),
        description: descriptionPreview(),
        priority: priority,
        category: category,
        property: selectedPropertyName(),
        unit: selectedUnitName(),
        qualityScore: ticketQualityScore,
        qualityLabel: ticketQualityLabel,
        qualityColor: ticketQualityColor,
        isTenant: isTenant,
        canSubmit: canSubmit,
        priorityColor: priorityColor,
        priorityIcon: priorityIcon,
        categoryColor: categoryColor,
        categoryIcon: categoryIcon,
        onSubmit: () async {
          Navigator.pop(context);
          await submit();
        },
      ),
    );
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
              fontSize: 17,
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
    final pColor = priorityColor(priority);

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
                child: Icon(
                  isTenant ? Icons.report_problem : Icons.add_task,
                  color: pColor,
                  size: 31,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTenant ? 'Report an Issue' : 'Create Ticket',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTenant
                          ? 'Send a clear request to your property team.'
                          : 'Create, locate and prioritize a maintenance request.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: submitting || refreshing
                    ? null
                    : () => loadInitialData(silent: true),
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
                avatar: Icon(priorityIcon(priority), color: pColor, size: 18),
                label: Text(priority),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: pColor,
                  fontWeight: FontWeight.bold,
                ),
                side: BorderSide.none,
              ),
              Chip(
                avatar: Icon(
                  categoryIcon(category),
                  color: categoryColor(category),
                  size: 18,
                ),
                label: Text(category),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: categoryColor(category),
                  fontWeight: FontWeight.bold,
                ),
                side: BorderSide.none,
              ),
              Chip(
                avatar: Icon(
                  Icons.workspace_premium,
                  color: ticketQualityColor,
                  size: 18,
                ),
                label: Text(ticketQualityLabel),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: ticketQualityColor,
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
                  title: 'Priority',
                  value: priority,
                  icon: priorityIcon(priority),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Status',
                  value: canSubmit ? 'READY' : 'DRAFT',
                  icon: canSubmit ? Icons.check_circle : Icons.edit_note,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Setup',
                  value: setupProgressLabel,
                  icon: Icons.auto_graph,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Quality',
                  value: '$ticketQualityScore%',
                  icon: Icons.workspace_premium,
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
                  categoryDescription(category),
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
                    onPressed: openPreviewSheet,
                    icon: const Icon(Icons.visibility),
                    label: const Text('Preview'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: submitting || !hasData
                        ? null
                        : confirmClearDraft,
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Clear'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
                    : const Icon(Icons.add_task),
                label: Text(
                  submitting
                      ? 'Submitting...'
                      : isTenant
                      ? 'Submit Request'
                      : 'Create Ticket',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionSwitch() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            sectionChip('DETAILS', 'Details', Icons.description),
            const SizedBox(width: 8),
            sectionChip('LOCATION', 'Location', Icons.home_work),
            const SizedBox(width: 8),
            sectionChip('REVIEW', 'Review', Icons.checklist),
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

  Widget previewCard() {
    final pColor = priorityColor(priority);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 31,
                  backgroundColor: pColor.withOpacity(0.12),
                  child: Icon(priorityIcon(priority), color: pColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titlePreview(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: darkText,
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        selectedPropertyName(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedUnitName(),
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
                  avatar: Icon(
                    canSubmit ? Icons.check_circle : Icons.edit_note,
                    color: canSubmit ? Colors.green : Colors.grey,
                    size: 16,
                  ),
                  label: Text(canSubmit ? 'READY' : 'DRAFT'),
                  backgroundColor: canSubmit
                      ? Colors.green.withOpacity(0.12)
                      : Colors.grey.withOpacity(0.12),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.description, color: pColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      descriptionPreview(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 12,
                        height: 1.35,
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
                color: ticketQualityColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: ticketQualityColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ticket quality: $ticketQualityLabel • $ticketQualityScore%',
                      style: TextStyle(
                        color: ticketQualityColor,
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

  Widget templatesCard() {
    final templates = [
      {
        'title': 'Water leak in bathroom',
        'description':
            'There is a water leak in the bathroom. Please inspect it as soon as possible.',
        'category': 'Plumbing',
        'priority': 'high',
        'icon': Icons.water_damage,
        'color': Colors.blue,
      },
      {
        'title': 'Power outlet not working',
        'description':
            'One of the power outlets is not working. Please check the electrical issue.',
        'category': 'Electrical',
        'priority': 'medium',
        'icon': Icons.electrical_services,
        'color': Colors.orange,
      },
      {
        'title': 'Air conditioning issue',
        'description':
            'The air conditioning is not working properly and needs inspection.',
        'category': 'HVAC',
        'priority': 'medium',
        'icon': Icons.ac_unit,
        'color': Colors.cyan,
      },
      {
        'title': 'Door lock problem',
        'description':
            'There is a problem with the door lock. Please review the security issue.',
        'category': 'Security',
        'priority': 'urgent',
        'icon': Icons.security,
        'color': Colors.red,
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Templates',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              'Use a template to fill the form faster.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            ...templates.map((template) {
              final color = template['color'] as Color;

              return Card(
                color: color.withOpacity(0.07),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.12),
                    child: Icon(template['icon'] as IconData, color: color),
                  ),
                  title: Text(
                    template['title'].toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(template['category'].toString()),
                  trailing: const Icon(Icons.add_circle_outline),
                  onTap: submitting
                      ? null
                      : () {
                          applyTemplate(
                            title: template['title'].toString(),
                            description: template['description'].toString(),
                            templateCategory: template['category'].toString(),
                            templatePriority: template['priority'].toString(),
                          );
                        },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget categorySelectorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Issue Category',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              'Choose the closest category to help routing and triage.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((item) {
                final selected = category == item;
                final color = categoryColor(item);

                return ChoiceChip(
                  selected: selected,
                  label: Text(item),
                  avatar: Icon(
                    categoryIcon(item),
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
                  onSelected: submitting
                      ? null
                      : (_) => setState(() => category = item),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: categoryColor(category).withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(categoryIcon(category), color: categoryColor(category)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      categoryDescription(category),
                      style: TextStyle(color: Colors.grey.shade800),
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

  Widget mainFormCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: titleCtrl,
                focusNode: titleFocus,
                enabled: !submitting,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Issue Title',
                  hintText: 'Example: Water leak in bathroom',
                  prefixIcon: Icon(Icons.report_problem),
                ),
                validator: requiredValidator,
                onEditingComplete: () {
                  FocusScope.of(context).requestFocus(descriptionFocus);
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: descriptionCtrl,
                focusNode: descriptionFocus,
                enabled: !submitting,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description Optional',
                  hintText:
                      'Describe what happened, where it is, and how urgent it feels...',
                  prefixIcon: Icon(Icons.description),
                ),
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  prefixIcon: Icon(Icons.priority_high),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                ],
                onChanged: submitting
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => priority = value);
                      },
              ),

              const SizedBox(height: 14),

              priorityInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget priorityInfoCard() {
    final color = priorityColor(priority);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(priorityIcon(priority), color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              priorityDescription(priority),
              style: TextStyle(color: Colors.grey.shade800, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget tenantInfoCard() {
    return Card(
      color: primary.withOpacity(0.07),
      child: const ListTile(
        leading: Icon(Icons.info_outline, color: primary),
        title: Text(
          'Tenant request',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Your request will be sent to the property management team. They can assign it, reply, and update the status.',
        ),
      ),
    );
  }

  Widget propertyUnitFields() {
    if (isTenant) return tenantInfoCard();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (properties.isEmpty)
              Card(
                color: Colors.orange.withOpacity(0.10),
                child: const ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.orange),
                  title: Text(
                    'No properties found',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Create a property before creating staff tickets linked to a unit.',
                  ),
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: selectedPropertyId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Related Property',
                  prefixIcon: Icon(Icons.apartment),
                ),
                items: properties.map((property) {
                  return DropdownMenuItem<String>(
                    value: property['id']?.toString(),
                    child: Text(
                      propertyLabel(property),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: submitting || loadingUnits
                    ? null
                    : (value) async {
                        setState(() {
                          selectedPropertyId = value;
                          selectedUnitId = null;
                          units = [];
                        });

                        if (value != null) {
                          await loadUnits(value);
                        }
                      },
              ),

            const SizedBox(height: 14),

            if (loadingUnits)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (selectedPropertyId != null && units.isEmpty)
              Card(
                color: Colors.orange.withOpacity(0.10),
                child: const ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.orange),
                  title: Text(
                    'No units found',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'This property has no units. Add a unit first before creating a ticket.',
                  ),
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: selectedUnitId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Related Unit',
                  prefixIcon: Icon(Icons.home_work),
                ),
                items: units.map((unit) {
                  return DropdownMenuItem<String>(
                    value: unit['id']?.toString(),
                    child: Text(
                      unitLabel(unit),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: submitting
                    ? null
                    : (value) {
                        setState(() => selectedUnitId = value);
                      },
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
              title: 'Issue title',
              subtitle: 'Required so the team can understand the request.',
              done: hasTitle,
            ),
            const Divider(height: 18),
            checklistItem(
              title: 'Description',
              subtitle: 'Optional, but useful for faster diagnosis.',
              done: hasDescription,
              optional: true,
            ),
            const Divider(height: 18),
            checklistItem(
              title: 'Category',
              subtitle: categoryDescription(category),
              done: category.trim().isNotEmpty,
            ),
            const Divider(height: 18),
            checklistItem(
              title: 'Priority',
              subtitle: priorityDescription(priority),
              done: priority.trim().isNotEmpty,
            ),
            const Divider(height: 18),
            checklistItem(
              title: isTenant ? 'Tenant route' : 'Property / Unit',
              subtitle: isTenant
                  ? 'Request goes to the management team.'
                  : selectedPropertyId == null
                  ? 'Select a property.'
                  : selectedUnitId == null
                  ? 'Select a unit.'
                  : '${selectedPropertyName()} • ${selectedUnitName()}',
              done: hasLocation,
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
                isTenant
                    ? 'Describe the issue clearly. The team will review it, reply, and update the status.'
                    : 'Property and unit are required for staff-created tickets so requests are routed to the correct location.',
                style: TextStyle(color: Colors.grey.shade700, height: 1.35),
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

  Widget detailsSection() {
    return Column(
      children: [
        templatesCard(),
        const SizedBox(height: 14),
        categorySelectorCard(),
        const SizedBox(height: 14),
        mainFormCard(),
      ],
    );
  }

  Widget locationSection() {
    return Column(
      children: [
        propertyUnitFields(),
        const SizedBox(height: 14),
        helperCard(),
      ],
    );
  }

  Widget reviewSection() {
    return Column(
      children: [
        previewCard(),
        const SizedBox(height: 14),
        checklistCard(),
        const SizedBox(height: 14),
        helperCard(),
      ],
    );
  }

  Widget selectedSectionBody() {
    if (selectedSection == 'LOCATION') return locationSection();
    if (selectedSection == 'REVIEW') return reviewSection();

    return detailsSection();
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
                    'Could not load ticket form',
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

  Widget restrictedBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
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
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 31,
                backgroundColor: Colors.white,
                child: Icon(Icons.engineering, color: primary, size: 31),
              ),
              SizedBox(height: 18),
              Text(
                'Ticket creation restricted',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Agents work on tickets assigned by assistants, owners or admins.',
                style: TextStyle(color: Colors.white70, height: 1.35),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 31,
                  backgroundColor: primary.withOpacity(0.12),
                  child: const Icon(Icons.assignment_ind, color: primary),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Use My Work instead',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'As a maintenance agent, your workspace is focused on assigned tickets. New support requests are created by tenants, assistants, owners or admins.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to My Work'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget bodyContent() {
    return RefreshIndicator(
      onRefresh: () => loadInitialData(silent: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          heroHeader(),

          const SizedBox(height: 18),

          quickActions(),

          const SizedBox(height: 14),

          previewCard(),

          const SizedBox(height: 14),

          sectionSwitch(),

          const SizedBox(height: 14),

          selectedSectionBody(),

          const SizedBox(height: 14),

          errorCard(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = isAgent
        ? 'Restricted'
        : isTenant
        ? 'Report an Issue'
        : 'Create Ticket';
    return PopScope(
      canPop: !submitting && !hasData,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final canLeave = await confirmBack();

        if (!mounted) return;

        if (canLeave) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: softBg,
        appBar: AppBar(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              tooltip: 'Preview',
              icon: const Icon(Icons.visibility),
              onPressed: loading || submitting ? null : openPreviewSheet,
            ),
            IconButton(
              tooltip: 'Clear draft',
              icon: const Icon(Icons.cleaning_services),
              onPressed: submitting || !hasData ? null : confirmClearDraft,
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
              onPressed: submitting || refreshing
                  ? null
                  : () => loadInitialData(silent: true),
            ),
          ],
        ),
        body: loading
            ? loadingBody()
            : error.isNotEmpty && role == null
            ? errorBody()
            : isAgent
            ? restrictedBody()
            : bodyContent(),
      ),
    );
  }
}

class _TicketPreviewSheet extends StatelessWidget {
  final String title;
  final String description;
  final String priority;
  final String category;
  final String property;
  final String unit;
  final int qualityScore;
  final String qualityLabel;
  final Color qualityColor;
  final bool isTenant;
  final bool canSubmit;
  final Color Function(String value) priorityColor;
  final IconData Function(String value) priorityIcon;
  final Color Function(String value) categoryColor;
  final IconData Function(String value) categoryIcon;
  final Future<void> Function() onSubmit;

  const _TicketPreviewSheet({
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    required this.property,
    required this.unit,
    required this.qualityScore,
    required this.qualityLabel,
    required this.qualityColor,
    required this.isTenant,
    required this.canSubmit,
    required this.priorityColor,
    required this.priorityIcon,
    required this.categoryColor,
    required this.categoryIcon,
    required this.onSubmit,
  });

  static const softBg = Color(0xFFF8F5FF);

  Widget infoRow(String label, dynamic value) {
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
              value?.toString().isNotEmpty == true ? value.toString() : '—',
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget scoreCard() {
    return Card(
      color: qualityColor.withOpacity(0.07),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: qualityColor.withOpacity(0.12),
                  child: Icon(Icons.workspace_premium, color: qualityColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ticket quality • $qualityLabel',
                    style: TextStyle(
                      color: qualityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '$qualityScore%',
                  style: TextStyle(
                    color: qualityColor,
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
                value: qualityScore / 100,
                minHeight: 8,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(qualityColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pColor = priorityColor(priority);
    final cColor = categoryColor(category);

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
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
                  backgroundColor: pColor.withOpacity(0.12),
                  child: Icon(priorityIcon(priority), color: pColor, size: 36),
                ),

                const SizedBox(height: 14),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  isTenant ? 'Tenant request preview' : '$property • $unit',
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
                      avatar: Icon(
                        priorityIcon(priority),
                        color: pColor,
                        size: 18,
                      ),
                      label: Text(priority),
                      backgroundColor: pColor.withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: pColor,
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide.none,
                    ),
                    Chip(
                      avatar: Icon(
                        categoryIcon(category),
                        color: cColor,
                        size: 18,
                      ),
                      label: Text(category),
                      backgroundColor: cColor.withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: cColor,
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide.none,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                scoreCard(),

                const SizedBox(height: 14),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        infoRow('Title', title),
                        infoRow('Description', description),
                        infoRow('Priority', priority),
                        infoRow('Category', category),
                        infoRow('Property', property),
                        infoRow('Unit', unit),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  color: canSubmit
                      ? Colors.green.withOpacity(0.07)
                      : Colors.orange.withOpacity(0.08),
                  child: ListTile(
                    leading: Icon(
                      canSubmit ? Icons.check_circle : Icons.info_outline,
                      color: canSubmit ? Colors.green : Colors.orange,
                    ),
                    title: Text(
                      canSubmit ? 'Ready to submit' : 'Still incomplete',
                      style: TextStyle(
                        color: canSubmit ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      canSubmit
                          ? 'This ticket has the required information.'
                          : 'Complete the required fields before submitting.',
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: canSubmit ? onSubmit : null,
                    icon: const Icon(Icons.add_task),
                    label: Text(isTenant ? 'Submit Request' : 'Create Ticket'),
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
