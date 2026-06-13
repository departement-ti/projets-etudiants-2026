import 'package:flutter/material.dart';

import '../../core/ui/app_error.dart';
import 'properties_service.dart';

class CreatePropertyPage extends StatefulWidget {
  const CreatePropertyPage({super.key});

  @override
  State<CreatePropertyPage> createState() => _CreatePropertyPageState();
}

class _CreatePropertyPageState extends State<CreatePropertyPage> {
  final formKey = GlobalKey<FormState>();

  final titleCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final countryCtrl = TextEditingController();

  final titleFocus = FocusNode();
  final addressFocus = FocusNode();
  final cityFocus = FocusNode();
  final countryFocus = FocusNode();

  bool loading = false;
  String error = '';

  String propertyType = 'Residence';

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);
  static const darkText = Color(0xFF1D1B20);

  final propertyTypes = const [
    'Residence',
    'Building',
    'Villa',
    'Apartment Complex',
    'Commercial',
  ];

  final cityPresets = const [
    'Tunis',
    'Sousse',
    'Sfax',
    'Nabeul',
    'Ariana',
    'Djerba',
  ];

  @override
  void initState() {
    super.initState();

    titleCtrl.addListener(refresh);
    addressCtrl.addListener(refresh);
    cityCtrl.addListener(refresh);
    countryCtrl.addListener(refresh);
  }

  @override
  void dispose() {
    titleCtrl.removeListener(refresh);
    addressCtrl.removeListener(refresh);
    cityCtrl.removeListener(refresh);
    countryCtrl.removeListener(refresh);

    titleCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    countryCtrl.dispose();

    titleFocus.dispose();
    addressFocus.dispose();
    cityFocus.dispose();
    countryFocus.dispose();

    super.dispose();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  String cleanText(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool get hasRequiredFields {
    return cleanText(titleCtrl.text).isNotEmpty &&
        cleanText(addressCtrl.text).isNotEmpty;
  }

  bool get hasOptionalLocation {
    return cleanText(cityCtrl.text).isNotEmpty ||
        cleanText(countryCtrl.text).isNotEmpty;
  }

  bool get hasData {
    return cleanText(titleCtrl.text).isNotEmpty ||
        cleanText(addressCtrl.text).isNotEmpty ||
        cleanText(cityCtrl.text).isNotEmpty ||
        cleanText(countryCtrl.text).isNotEmpty;
  }

  bool get canSubmit {
    return !loading && hasRequiredFields;
  }

  int get completedSteps {
    int completed = 0;

    if (cleanText(titleCtrl.text).isNotEmpty) completed++;
    if (cleanText(addressCtrl.text).isNotEmpty) completed++;
    if (cleanText(cityCtrl.text).isNotEmpty) completed++;
    if (cleanText(countryCtrl.text).isNotEmpty) completed++;

    return completed;
  }

  double get setupProgress {
    return completedSteps / 4;
  }

  String get setupProgressLabel {
    return '${(setupProgress * 100).round()}% complete';
  }

  int get qualityScore {
    int score = 0;

    if (cleanText(titleCtrl.text).length >= 3) score += 30;
    if (cleanText(addressCtrl.text).length >= 6) score += 35;
    if (cleanText(cityCtrl.text).length >= 2) score += 20;
    if (cleanText(countryCtrl.text).length >= 2) score += 15;

    return score.clamp(0, 100);
  }

  String get qualityLabel {
    if (qualityScore >= 85) return 'Excellent';
    if (qualityScore >= 65) return 'Good';
    if (qualityScore >= 35) return 'Basic';
    return 'Draft';
  }

  Color get qualityColor {
    if (qualityScore >= 85) return Colors.green;
    if (qualityScore >= 65) return primary;
    if (qualityScore >= 35) return Colors.orange;
    return Colors.grey;
  }

  String get titlePreview {
    final value = cleanText(titleCtrl.text);
    return value.isEmpty ? 'New Property' : value;
  }

  String get addressPreview {
    final value = cleanText(addressCtrl.text);
    return value.isEmpty ? 'Address not added yet' : value;
  }

  String get locationPreview {
    final city = cleanText(cityCtrl.text);
    final country = cleanText(countryCtrl.text);

    final location = [
      city,
      country,
    ].where((value) => value.isNotEmpty).join(', ');

    return location.isEmpty ? 'Location optional' : location;
  }

  String get initials {
    final clean = titlePreview.trim();

    if (clean.isEmpty) return 'P';

    final parts = clean.split(' ').where((part) => part.trim().isNotEmpty);
    final list = parts.toList();

    if (list.length >= 2) {
      return '${list[0][0]}${list[1][0]}'.toUpperCase();
    }

    return clean[0].toUpperCase();
  }

  String? requiredValidator(String? value) {
    final text = cleanText(value ?? '');

    if (text.isEmpty) return 'This field is required';
    if (text.length < 3) return 'Must be at least 3 characters';

    return null;
  }

  String? addressValidator(String? value) {
    final text = cleanText(value ?? '');

    if (text.isEmpty) return 'Address is required';
    if (text.length < 6) return 'Address is too short';

    return null;
  }

  String? optionalValidator(String? value) {
    final text = cleanText(value ?? '');

    if (text.isEmpty) return null;
    if (text.length < 2) return 'Too short';

    return null;
  }

  void applyCityPreset(String city) {
    cityCtrl.text = city;

    if (countryCtrl.text.trim().isEmpty) {
      countryCtrl.text = 'Tunisia';
    }

    FocusScope.of(context).unfocus();
  }

  void applyPropertyType(String type) {
    setState(() => propertyType = type);

    final title = cleanText(titleCtrl.text);

    if (title.isEmpty || title == 'New Property') {
      titleCtrl.text = type;
      titleCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: titleCtrl.text.length),
      );
      return;
    }
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();

    setState(() => error = '');

    if (!formKey.currentState!.validate()) {
      setState(() {
        error = 'Please complete the required property information.';
      });
      return;
    }

    setState(() {
      loading = true;
      error = '';
    });

    try {
      await PropertiesService.create(
        title: cleanText(titleCtrl.text),
        address: cleanText(addressCtrl.text),
        city: cleanText(cityCtrl.text),
        country: cleanText(countryCtrl.text),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property created successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = AppError.clean(e);
      });

      await AppError.show(context, e, title: 'Could not create property');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void clearForm() {
    titleCtrl.clear();
    addressCtrl.clear();
    cityCtrl.clear();
    countryCtrl.clear();

    setState(() {
      propertyType = 'Residence';
      error = '';
    });
  }

  Future<void> confirmClear() async {
    if (!hasData) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmSheet(
        icon: Icons.cleaning_services,
        color: Colors.orange,
        title: 'Clear property form?',
        message: 'All entered property information will be removed.',
        confirmText: 'Clear Form',
      ),
    );

    if (confirmed == true) {
      clearForm();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Form cleared')));
    }
  }

  Future<bool> confirmBack() async {
    if (!hasData || loading) return true;

    final leave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ConfirmSheet(
        icon: Icons.warning_amber,
        color: Colors.red,
        title: 'Discard property draft?',
        message:
            'You have unsaved property information. Leaving now will discard your changes.',
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
              fontSize: 18,
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Property',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Build the foundation before units and leases.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Status',
                  value: hasRequiredFields ? 'Ready' : 'Draft',
                  icon: hasRequiredFields
                      ? Icons.check_circle
                      : Icons.edit_note,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Quality',
                  value: qualityLabel,
                  icon: Icons.workspace_premium,
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
                  title: 'Type',
                  value: propertyType,
                  icon: Icons.category,
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
                  'Property setup score: $qualityScore%',
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
              value: qualityScore / 100,
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
    final ready = hasRequiredFields;
    final color = ready ? Colors.green : Colors.grey;

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
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titlePreview,
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
                        addressPreview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        locationPreview,
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
                const SizedBox(width: 8),
                Chip(
                  avatar: Icon(
                    ready ? Icons.check_circle : Icons.edit_note,
                    color: color,
                    size: 16,
                  ),
                  label: Text(ready ? 'READY' : 'DRAFT'),
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
                  Icon(
                    hasOptionalLocation
                        ? Icons.location_on
                        : Icons.info_outline,
                    color: hasOptionalLocation ? primary : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasOptionalLocation
                          ? 'Location details added. This property will be easier to find and filter.'
                          : 'City and country are optional but useful for filtering and reports.',
                      style: TextStyle(
                        color: Colors.grey.shade800,
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

  Widget typeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Property Type',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose a type to guide your setup.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: propertyTypes.map((type) {
                final selected = propertyType == type;

                return ChoiceChip(
                  selected: selected,
                  label: Text(type),
                  avatar: Icon(
                    selected ? Icons.check_circle : Icons.category,
                    size: 18,
                    color: selected ? Colors.white : primary,
                  ),
                  selectedColor: primary,
                  backgroundColor: primary.withOpacity(0.08),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : primary,
                    fontWeight: FontWeight.bold,
                  ),
                  side: BorderSide.none,
                  onSelected: loading ? null : (_) => applyPropertyType(type),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget locationPresetsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Location',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a city to quickly fill city and country.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cityPresets.map((city) {
                final selected =
                    cleanText(cityCtrl.text).toLowerCase() ==
                    city.toLowerCase();

                return ActionChip(
                  avatar: Icon(
                    selected ? Icons.check_circle : Icons.location_city,
                    size: 18,
                    color: selected ? Colors.green : primary,
                  ),
                  label: Text(city),
                  backgroundColor: selected
                      ? Colors.green.withOpacity(0.10)
                      : primary.withOpacity(0.08),
                  labelStyle: TextStyle(
                    color: selected ? Colors.green : primary,
                    fontWeight: FontWeight.bold,
                  ),
                  side: BorderSide.none,
                  onPressed: loading ? null : () => applyCityPreset(city),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
      ],
    );
  }

  Widget inputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    String? hint,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputAction textInputAction = TextInputAction.next,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    VoidCallback? onEditingComplete,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: !loading,
      validator: validator,
      maxLines: maxLines,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      onEditingComplete: onEditingComplete,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
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
                focusNode: titleFocus,
                label: 'Property Title',
                hint: 'Example: Résidence El Amen',
                icon: Icons.apartment,
                validator: requiredValidator,
                textCapitalization: TextCapitalization.words,
                onEditingComplete: () {
                  FocusScope.of(context).requestFocus(addressFocus);
                },
              ),

              const SizedBox(height: 14),

              inputField(
                controller: addressCtrl,
                focusNode: addressFocus,
                label: 'Address',
                hint: 'Street, building number, area...',
                icon: Icons.location_on,
                validator: addressValidator,
                maxLines: 2,
                onEditingComplete: () {
                  FocusScope.of(context).requestFocus(cityFocus);
                },
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: inputField(
                      controller: cityCtrl,
                      focusNode: cityFocus,
                      label: 'City',
                      hint: 'Tunis',
                      icon: Icons.location_city,
                      validator: optionalValidator,
                      textCapitalization: TextCapitalization.words,
                      onEditingComplete: () {
                        FocusScope.of(context).requestFocus(countryFocus);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: inputField(
                      controller: countryCtrl,
                      focusNode: countryFocus,
                      label: 'Country',
                      hint: 'Tunisia',
                      icon: Icons.public,
                      validator: optionalValidator,
                      textInputAction: TextInputAction.done,
                      textCapitalization: TextCapitalization.words,
                      onEditingComplete: () {
                        FocusScope.of(context).unfocus();
                      },
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

  Widget qualityCard() {
    return Card(
      color: qualityColor.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: qualityColor.withOpacity(0.12),
              child: Icon(Icons.workspace_premium, color: qualityColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Setup Quality: $qualityLabel',
                    style: TextStyle(
                      color: qualityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: qualityScore / 100,
                      minHeight: 8,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(qualityColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$qualityScore% complete based on title, address and location details.',
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

  Widget checklistCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            checklistItem(
              title: 'Property title',
              subtitle: 'Used in dashboards, units and lease pages.',
              done: cleanText(titleCtrl.text).isNotEmpty,
            ),
            const Divider(height: 18),
            checklistItem(
              title: 'Address',
              subtitle: 'Helps identify the physical rental location.',
              done: cleanText(addressCtrl.text).isNotEmpty,
            ),
            const Divider(height: 18),
            checklistItem(
              title: 'City / Country',
              subtitle: 'Optional, but useful for filtering and reports.',
              done: hasOptionalLocation,
              optional: true,
            ),
            const Divider(height: 18),
            checklistItem(
              title: 'Ready for units',
              subtitle: 'After creation, open this property and add units.',
              done: hasRequiredFields,
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

  Widget nextStepCard() {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What happens next?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'After creating the property, add units with rent amounts, availability status, bedrooms and floor details. Then you can create leases.',
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
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_business),
            label: Text(loading ? 'Creating Property...' : 'Create Property'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: loading || !hasData ? null : confirmClear,
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

        const SizedBox(height: 20),

        previewCard(),

        const SizedBox(height: 14),

        typeSelector(),

        const SizedBox(height: 14),

        qualityCard(),

        const SizedBox(height: 20),

        sectionTitle(
          'Property Information',
          'Enter the main identity and location of the rental property.',
        ),

        const SizedBox(height: 8),

        formCard(),

        const SizedBox(height: 14),

        locationPresetsCard(),

        const SizedBox(height: 14),

        checklistCard(),

        const SizedBox(height: 14),

        nextStepCard(),

        const SizedBox(height: 14),

        errorCard(),

        const SizedBox(height: 22),

        actionButtons(),

        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !loading && !hasData,
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
          title: const Text(
            'Create Property',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              tooltip: 'Clear form',
              icon: const Icon(Icons.cleaning_services),
              onPressed: loading || !hasData ? null : confirmClear,
            ),
          ],
        ),
        body: bodyContent(),
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String confirmText;

  const _ConfirmSheet({
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
                child: Icon(icon, color: color, size: 32),
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
