import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/models.dart';
import '../../widgets/common/common_widgets.dart';

// ─────────────────────────────────────────────────────────────
// Tunisian regions list
// ─────────────────────────────────────────────────────────────
const _tunisianRegions = [
  'Ariana',
  'Béja',
  'Ben Arous',
  'Bizerte',
  'Gabès',
  'Gafsa',
  'Jendouba',
  'Kairouan',
  'Kasserine',
  'Kébili',
  'Kef',
  'Mahdia',
  'Manouba',
  'Médenine',
  'Monastir',
  'Nabeul',
  'Sfax',
  'Sidi Bouzid',
  'Siliana',
  'Sousse',
  'Tataouine',
  'Tozeur',
  'Tunis',
  'Zaghouan',
];

const _languageOptions = ['Français', 'Arabe', 'Anglais'];

// ─────────────────────────────────────────────────────────────
// CreateEventScreen
// ─────────────────────────────────────────────────────────────
class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen>
    with SingleTickerProviderStateMixin {
  // ── Multi-step ──
  int _step = 0;
  final _steps = ['Type & Infos', 'Lieu & Date', 'Détails & Prix', 'Aperçu'];

  // ── Loading ──
  bool _isPublishing = false;

  // ── Step 0 ──
  EventType _selectedType = EventType.visit;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedLanguage = 'Français';
  final List<String> _tags = [];
  final List<String> _includes = [];
  final _tagInputCtrl = TextEditingController();
  final _includeInputCtrl = TextEditingController();

  // ── Step 1 ──
  final _locationCtrl = TextEditingController();
  String _selectedRegion = 'Tunis';
  DateTime? _selectedDate;
  DateTime _focusedDay = DateTime.now();
  final _startTimeCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  bool _isOnline = false;

  // ── Step 2 ──
  bool _isFree = false;
  final _priceCtrl = TextEditingController();
  int _maxParticipants = 10;
  File? _coverImage;
  final List<File> _galleryImages = [];
  bool _isUploadingCover = false;
  bool _isUploadingGallery = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _startTimeCtrl.dispose();
    _tagInputCtrl.dispose();
    _includeInputCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // IMAGE HELPERS
  // ─────────────────────────────────────────────

  Future<void> _pickCoverImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null) setState(() => _coverImage = File(picked.path));
  }

  Future<void> _pickGalleryImages() async {
    final picked = await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked.isNotEmpty) {
      setState(() {
        for (final img in picked) {
          if (_galleryImages.length < 6) {
            _galleryImages.add(File(img.path));
          }
        }
      });
    }
  }

  Future<String> _uploadImage(File file, String path) async {
    final ref = FirebaseStorage.instance.ref(path);
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  // ─────────────────────────────────────────────
  // FIRESTORE
  // ─────────────────────────────────────────────

  Future<void> _createEvent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final docRef = FirebaseFirestore.instance.collection('events').doc();
    final eventId = docRef.id;

    // Upload cover
    String imageUrl = '';
    if (_coverImage != null) {
      setState(() => _isUploadingCover = true);
      imageUrl = await _uploadImage(_coverImage!, 'events/$eventId/cover.jpg');
      setState(() => _isUploadingCover = false);
    }

    // Upload gallery
    final List<String> galleryUrls = [];
    if (_galleryImages.isNotEmpty) {
      setState(() => _isUploadingGallery = true);
      for (int i = 0; i < _galleryImages.length; i++) {
        final url = await _uploadImage(
          _galleryImages[i],
          'events/$eventId/gallery_$i.jpg',
        );
        galleryUrls.add(url);
      }
      setState(() => _isUploadingGallery = false);
    }

    // Format date as string (e.g. "2025-08-20")
    final dateStr = _selectedDate != null
        ? '${_selectedDate!.year.toString().padLeft(4, '0')}-'
              '${_selectedDate!.month.toString().padLeft(2, '0')}-'
              '${_selectedDate!.day.toString().padLeft(2, '0')}'
        : '';

    await docRef.set({
      'id': eventId,
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'imageUrl': imageUrl,
      'gallery': galleryUrls,

      'organiserId': user.uid,
      'organiserName': user.displayName ?? '',
      'organiserAvatar': user.photoURL ?? '',

      'type': _selectedType.name,
      'location': _locationCtrl.text.trim(),
      'region': _selectedRegion,
      'latitude': 0.0,
      'longitude': 0.0,

      'date': dateStr,
      'startTime': _startTimeCtrl.text.trim(),
      'duration': _durationCtrl.text.trim(),

      'price': _isFree ? '0' : _priceCtrl.text.trim(),

      'maxParticipants': _maxParticipants,
      'currentParticipants': 0,

      'rating': 0.0,
      'reviewCount': 0,

      'tags': _tags,
      'includes': _includes,

      'language': _selectedLanguage,
      'isOnline': _isOnline,
      'isActive': true,
    });
  }

  // ─────────────────────────────────────────────
  // VALIDATION PER STEP
  // ─────────────────────────────────────────────

  String? _validateCurrentStep() {
    switch (_step) {
      case 0:
        if (_titleCtrl.text.trim().isEmpty) return 'Le titre est requis';
        if (_descCtrl.text.trim().isEmpty) return 'La description est requise';
        return null;
      case 1:
        if (!_isOnline && _locationCtrl.text.trim().isEmpty) {
          return 'Le lieu est requis';
        }
        if (_selectedDate == null) return 'Veuillez choisir une date';
        if (_startTimeCtrl.text.trim().isEmpty) {
          return 'L\'heure de début est requise';
        }
        if (_durationCtrl.text.trim().isEmpty) return 'La durée est requise';
        return null;
      case 2:
        if (!_isFree && _priceCtrl.text.trim().isEmpty) {
          return 'Veuillez indiquer le prix';
        }
        if (_coverImage == null) {
          return 'Veuillez ajouter une image de couverture';
        }
        return null;
      default:
        return null;
    }
  }

  bool _canPublish() =>
      _titleCtrl.text.isNotEmpty &&
      _descCtrl.text.isNotEmpty &&
      _selectedDate != null &&
      _coverImage != null;

  // ─────────────────────────────────────────────
  // TIME PICKER
  // ─────────────────────────────────────────────

  Future<void> _selectTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: now);
    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      setState(() => _startTimeCtrl.text = '$hh:$mm');
    }
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Créer un événement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(5),
          child: LinearProgressIndicator(
            value: (_step + 1) / _steps.length,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            minHeight: 4,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.pagePadding,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(key: ValueKey(_step), child: _buildStep()),
              ),
            ),
          ),
          _buildNavButtons(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STEP INDICATOR
  // ─────────────────────────────────────────────

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.pagePadding,
        14,
        AppConstants.pagePadding,
        0,
      ),
      child: Row(
        children: List.generate(_steps.length, (i) {
          final active = i == _step;
          final done = i < _step;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done
                              ? Colors.green
                              : active
                              ? AppColors.accent
                              : Colors.grey.shade300,
                        ),
                        child: Center(
                          child: done
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _steps[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: active
                              ? FontWeight.bold
                              : FontWeight.w400,
                          color: active
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < _steps.length - 1)
                  Expanded(
                    child: Divider(
                      thickness: 2,
                      color: i < _step ? Colors.green : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // NAV BUTTONS
  // ─────────────────────────────────────────────

  Widget _buildNavButtons() {
    final isLast = _step == _steps.length - 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.pagePadding,
          8,
          AppConstants.pagePadding,
          12,
        ),
        child: Row(
          children: [
            if (_step > 0) ...[
              OutlinedButton.icon(
                onPressed: () => setState(() => _step--),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                label: const Text('Retour'),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: FilledButton.icon(
                onPressed: _isPublishing
                    ? null
                    : () async {
                        if (!isLast) {
                          final err = _validateCurrentStep();
                          if (err != null) {
                            _showError(err);
                            return;
                          }
                          setState(() => _step++);
                          return;
                        }

                        if (!_canPublish()) {
                          _showError(
                            'Veuillez remplir tous les champs obligatoires',
                          );
                          return;
                        }

                        setState(() => _isPublishing = true);
                        try {
                          await _createEvent();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Événement publié 🎉'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            context.pop();
                          }
                        } catch (e) {
                          if (mounted) _showError('Erreur: $e');
                        } finally {
                          if (mounted) setState(() => _isPublishing = false);
                        }
                      },
                icon: _isPublishing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isLast
                            ? Iconsax.send_1
                            : Icons.arrow_forward_ios_rounded,
                        size: 16,
                      ),
                label: Text(isLast ? 'Publier' : 'Suivant'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade600),
    );
  }

  // ─────────────────────────────────────────────
  // STEP DISPATCHER
  // ─────────────────────────────────────────────

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3Preview();
      default:
        return const SizedBox();
    }
  }

  // ═══════════════════════════════════════════════
  // STEP 0 — Type & Infos
  // ═══════════════════════════════════════════════

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _sectionLabel('Type d\'événement'),
        const SizedBox(height: 10),

        // Event type chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EventType.values.map((type) {
            final selected = _selectedType == type;
            return ChoiceChip(
              label: Text(_eventTypeLabel(type)),
              avatar: Icon(_eventTypeIcon(type), size: 16),
              selected: selected,
              onSelected: (_) => setState(() => _selectedType = type),
              selectedColor: AppColors.accent.withOpacity(0.15),
              labelStyle: TextStyle(
                color: selected ? AppColors.accent : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: selected ? AppColors.accent : AppColors.border,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),
        _sectionLabel('Titre *'),
        const SizedBox(height: 6),
        _styledField(
          controller: _titleCtrl,
          hint: 'Ex: Visite guidée de la Médina de Tunis',
          icon: Iconsax.text,
          maxLength: 80,
        ),

        const SizedBox(height: 16),
        _sectionLabel('Description *'),
        const SizedBox(height: 6),
        _styledField(
          controller: _descCtrl,
          hint: 'Décrivez votre événement en détail…',
          icon: Iconsax.document_text,
          maxLines: 5,
          maxLength: 600,
        ),

        const SizedBox(height: 16),
        _sectionLabel('Langue'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _languageOptions.map((lang) {
            final sel = _selectedLanguage == lang;
            return ChoiceChip(
              label: Text(lang),
              selected: sel,
              onSelected: (_) => setState(() => _selectedLanguage = lang),
              selectedColor: AppColors.accent.withOpacity(0.15),
              side: BorderSide(
                color: sel ? AppColors.accent : AppColors.border,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),
        _sectionLabel('Tags'),
        const SizedBox(height: 8),
        _chipInputRow(
          controller: _tagInputCtrl,
          hint: 'Ajouter un tag',
          items: _tags,
          onAdd: () {
            final val = _tagInputCtrl.text.trim();
            if (val.isNotEmpty && !_tags.contains(val)) {
              setState(() {
                _tags.add(val);
                _tagInputCtrl.clear();
              });
            }
          },
          onRemove: (t) => setState(() => _tags.remove(t)),
        ),

        const SizedBox(height: 20),
        _sectionLabel('Ce qui est inclus'),
        const SizedBox(height: 8),
        _chipInputRow(
          controller: _includeInputCtrl,
          hint: 'Ex: Transport, Repas…',
          items: _includes,
          onAdd: () {
            final val = _includeInputCtrl.text.trim();
            if (val.isNotEmpty && !_includes.contains(val)) {
              setState(() {
                _includes.add(val);
                _includeInputCtrl.clear();
              });
            }
          },
          onRemove: (t) => setState(() => _includes.remove(t)),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // STEP 1 — Lieu & Date
  // ═══════════════════════════════════════════════

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // Online toggle
        _toggleRow(
          label: 'Événement en ligne',
          value: _isOnline,
          icon: Iconsax.monitor,
          onChanged: (v) => setState(() => _isOnline = v),
        ),

        if (!_isOnline) ...[
          const SizedBox(height: 16),
          _sectionLabel('Lieu *'),
          const SizedBox(height: 6),
          _styledField(
            controller: _locationCtrl,
            hint: 'Ex: Amphithéâtre El Jem',
            icon: Iconsax.location,
          ),

          const SizedBox(height: 16),
          _sectionLabel('Région'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedRegion,
            isExpanded: true,
            decoration: _inputDecoration(
              hint: 'Sélectionner une région',
              icon: Iconsax.map,
            ),
            items: _tunisianRegions.map((r) {
              return DropdownMenuItem(value: r, child: Text(r));
            }).toList(),
            onChanged: (v) => setState(() => _selectedRegion = v!),
          ),
        ],

        const SizedBox(height: 20),
        _sectionLabel('Date *'),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.border),
          ),
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 730)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => isSameDay(d, _selectedDate),
            onDaySelected: (d, f) => setState(() {
              _selectedDate = d;
              _focusedDay = f;
            }),
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
        ),

        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Heure de début *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _startTimeCtrl,
                    readOnly: true,
                    onTap: _selectTime,
                    decoration: _inputDecoration(
                      hint: '09:00',
                      icon: Iconsax.clock,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Durée *'),
                  const SizedBox(height: 6),
                  _styledField(
                    controller: _durationCtrl,
                    hint: 'Ex: 2h30',
                    icon: Iconsax.timer_1,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // STEP 2 — Détails & Prix
  // ═══════════════════════════════════════════════

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // ── Cover image ──
        _sectionLabel('Image de couverture *'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickCoverImage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _coverImage != null
                    ? AppColors.accent
                    : AppColors.border,
                width: 2,
              ),
              image: _coverImage != null
                  ? DecorationImage(
                      image: FileImage(_coverImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: AppColors.surface,
            ),
            child: _coverImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.gallery_add,
                        size: 40,
                        color: AppColors.accent,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajouter une couverture',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  )
                : Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                          onPressed: () => setState(() => _coverImage = null),
                        ),
                      ),
                    ),
                  ),
          ),
        ),

        // ── Gallery ──
        const SizedBox(height: 20),
        Row(
          children: [
            _sectionLabel('Galerie'),
            const Spacer(),
            Text(
              '${_galleryImages.length}/6',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._galleryImages.map((img) => _galleryThumb(img)),
              if (_galleryImages.length < 6)
                GestureDetector(
                  onTap: _pickGalleryImages,
                  child: Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.border,
                        style: BorderStyle.solid,
                        width: 1.5,
                      ),
                      color: AppColors.surface,
                    ),
                    child: Icon(Iconsax.add, color: AppColors.accent),
                  ),
                ),
            ],
          ),
        ),

        // ── Price ──
        const SizedBox(height: 20),
        _toggleRow(
          label: 'Événement gratuit',
          value: _isFree,
          icon: Iconsax.ticket,
          onChanged: (v) => setState(() => _isFree = v),
        ),
        if (!_isFree) ...[
          const SizedBox(height: 12),
          _styledField(
            controller: _priceCtrl,
            hint: 'Ex: 30.000',
            icon: Iconsax.money,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            suffix: 'TND',
          ),
        ],

        // ── Max Participants ──
        const SizedBox(height: 20),
        _sectionLabel('Participants maximum'),
        const SizedBox(height: 8),
        Row(
          children: [
            _counterButton(
              icon: Icons.remove_rounded,
              onTap: () {
                if (_maxParticipants > 1) {
                  setState(() => _maxParticipants--);
                }
              },
            ),
            Expanded(
              child: Center(
                child: Text(
                  '$_maxParticipants',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _counterButton(
              icon: Icons.add_rounded,
              onTap: () {
                if (_maxParticipants < 500) {
                  setState(() => _maxParticipants++);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // STEP 3 — Aperçu
  // ═══════════════════════════════════════════════

  Widget _buildStep3Preview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // Cover
        if (_coverImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              _coverImage!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

        const SizedBox(height: 16),

        _previewRow(Iconsax.category, 'Type', _eventTypeLabel(_selectedType)),
        _previewRow(Iconsax.text, 'Titre', _titleCtrl.text),
        _previewRow(
          Iconsax.document_text,
          'Description',
          _descCtrl.text,
          multiline: true,
        ),
        _previewRow(Iconsax.global, 'Langue', _selectedLanguage),

        const Divider(height: 28),

        _previewRow(
          _isOnline ? Iconsax.monitor : Iconsax.location,
          'Lieu',
          _isOnline ? 'En ligne' : _locationCtrl.text,
        ),
        if (!_isOnline) _previewRow(Iconsax.map, 'Région', _selectedRegion),
        _previewRow(
          Iconsax.calendar,
          'Date',
          _selectedDate != null
              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
              : '—',
        ),
        _previewRow(Iconsax.clock, 'Heure', _startTimeCtrl.text),
        _previewRow(Iconsax.timer_1, 'Durée', _durationCtrl.text),

        const Divider(height: 28),

        _previewRow(
          Iconsax.money,
          'Prix',
          _isFree ? 'Gratuit' : '${_priceCtrl.text} TND',
        ),
        _previewRow(Iconsax.people, 'Max participants', '$_maxParticipants'),
        _previewRow(
          Iconsax.ticket,
          'Places galerie',
          '${_galleryImages.length} photo(s)',
        ),

        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          _sectionLabel('Tags'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _tags
                .map(
                  (t) => Chip(
                    label: Text(t, style: const TextStyle(fontSize: 12)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
                .toList(),
          ),
        ],

        if (_includes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _sectionLabel('Inclus'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _includes
                .map(
                  (t) => Chip(
                    label: Text(t, style: const TextStyle(fontSize: 12)),
                    avatar: const Icon(Icons.check, size: 14),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
                .toList(),
          ),
        ],

        const SizedBox(height: 24),

        // Publishing status
        if (_isUploadingCover || _isUploadingGallery)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  _isUploadingCover
                      ? 'Envoi de la couverture…'
                      : 'Envoi de la galerie…',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // REUSABLE WIDGETS
  // ─────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      letterSpacing: 0.2,
    ),
  );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    String? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18),
      suffixText: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.8),
      ),
      filled: true,
      fillColor: AppColors.surface,
    );
  }

  Widget _styledField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? suffix,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      decoration: _inputDecoration(hint: hint, icon: icon, suffix: suffix),
    );
  }

  Widget _toggleRow({
    required String label,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, size: 20, color: AppColors.textSecondary),
        title: Text(label, style: const TextStyle(fontSize: 14)),
        activeColor: AppColors.accent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  Widget _counterButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }

  Widget _chipInputRow({
    required TextEditingController controller,
    required String hint,
    required List<String> items,
    required VoidCallback onAdd,
    required void Function(String) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _styledField(
                controller: controller,
                hint: hint,
                icon: Iconsax.tag,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              child: const Icon(Icons.add_rounded, size: 18),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items.map((t) {
              return Chip(
                label: Text(t, style: const TextStyle(fontSize: 12)),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () => onRemove(t),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _galleryThumb(File img) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(image: FileImage(img), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 2,
          right: 10,
          child: GestureDetector(
            onTap: () => setState(() => _galleryImages.remove(img)),
            child: const CircleAvatar(
              radius: 10,
              backgroundColor: Colors.black54,
              child: Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _previewRow(
    IconData icon,
    String label,
    String value, {
    bool multiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: multiline ? 4 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  String _eventTypeLabel(EventType t) {
    switch (t) {
      case EventType.visit:
        return 'Visite';
      case EventType.tour:
        return 'Tour';
      case EventType.workshop:
        return 'Atelier';
      case EventType.cultural:
        return 'Culture';
      case EventType.adventure:
        return 'Aventure';
      default:
        return t.name;
    }
  }

  IconData _eventTypeIcon(EventType t) {
    switch (t) {
      case EventType.visit:
        return Iconsax.eye;
      case EventType.tour:
        return Iconsax.map_1;
      case EventType.workshop:
        return Iconsax.brush_2;
      case EventType.cultural:
        return Iconsax.music;
      case EventType.adventure:
        return Iconsax.wind_2;
      default:
        return Iconsax.category;
    }
  }
}
