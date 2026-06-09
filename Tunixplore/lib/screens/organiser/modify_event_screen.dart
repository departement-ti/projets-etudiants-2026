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

class ModifyEventScreen extends StatefulWidget {
  final EventModel event;

  const ModifyEventScreen({super.key, required this.event});

  @override
  State<ModifyEventScreen> createState() => _ModifyEventScreenState();
}

class ModifyEventScreenLoader extends StatelessWidget {
  final String eventId;

  const ModifyEventScreenLoader({super.key, required this.eventId});

  Future<EventModel> _loadEvent() async {
    final doc = await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .get();

    if (!doc.exists || doc.data() == null) {
      throw Exception("Event not found");
    }

    return EventModel.fromJson(doc.id, doc.data()!);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EventModel>(
      future: _loadEvent(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Erreur: ${snapshot.error}")),
          );
        }

        return ModifyEventScreen(event: snapshot.data!);
      },
    );
  }
}

class _ModifyEventScreenState extends State<ModifyEventScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  final _steps = ['Type & Infos', 'Lieu & Date', 'Détails & Prix', 'Aperçu'];

  bool _isSaving = false;

  // Step 0
  late EventType _selectedType;
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late String _selectedLanguage;
  late List<String> _tags;
  late List<String> _includes;
  final _tagInputCtrl = TextEditingController();
  final _includeInputCtrl = TextEditingController();

  // Step 1
  late TextEditingController _locationCtrl;
  late String _selectedRegion;
  DateTime? _selectedDate;
  DateTime _focusedDay = DateTime.now();
  late TextEditingController _startTimeCtrl;
  late TextEditingController _durationCtrl;
  late bool _isOnline;

  // Step 2
  late bool _isFree;
  late TextEditingController _priceCtrl;
  late int _maxParticipants;

  String _existingImageUrl = '';
  List<String> _existingGallery = [];

  File? _coverImage;
  final List<File> _galleryImages = [];

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    final e = widget.event;

    // ── preload all fields ──
    _selectedType = e.type;
    _titleCtrl = TextEditingController(text: e.title);
    _descCtrl = TextEditingController(text: e.description);
    _selectedLanguage = e.language;
    _tags = List.from(e.tags);
    _includes = List.from(e.includes);

    _locationCtrl = TextEditingController(text: e.location);
    _selectedRegion = e.region;

    _startTimeCtrl = TextEditingController(text: e.startTime);
    _durationCtrl = TextEditingController(text: e.duration);
    _isOnline = e.isOnline;

    _isFree = (e.price == "0" || e.price.isEmpty);
    _priceCtrl = TextEditingController(text: e.price);
    _maxParticipants = e.maxParticipants;

    _existingImageUrl = e.imageUrl;
    _existingGallery = List.from(e.gallery);

    // parse date safely
    try {
      final parts = e.date.split('-');
      if (parts.length == 3) {
        _selectedDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {}
  }

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

  // ─────────────────────────────
  // IMAGE PICKERS
  // ─────────────────────────────

  Future<void> _pickCover() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _coverImage = File(picked.path));
    }
  }

  Future<void> _pickGallery() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        for (final p in picked) {
          if (_galleryImages.length < 6) {
            _galleryImages.add(File(p.path));
          }
        }
      });
    }
  }

  Future<String> _upload(File file, String path) async {
    final ref = FirebaseStorage.instance.ref(path);
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  // ─────────────────────────────
  // UPDATE EVENT
  // ─────────────────────────────

  Future<void> _updateEvent() async {
    final docRef = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event.id);

    String imageUrl = _existingImageUrl;

    if (_coverImage != null) {
      imageUrl = await _upload(
        _coverImage!,
        'events/${widget.event.id}/cover.jpg',
      );
    }

    List<String> galleryUrls = List.from(_existingGallery);

    if (_galleryImages.isNotEmpty) {
      for (int i = 0; i < _galleryImages.length; i++) {
        final url = await _upload(
          _galleryImages[i],
          'events/${widget.event.id}/gallery_$i.jpg',
        );
        galleryUrls.add(url);
      }
    }

    final dateStr = _selectedDate != null
        ? '${_selectedDate!.year.toString().padLeft(4, '0')}-'
              '${_selectedDate!.month.toString().padLeft(2, '0')}-'
              '${_selectedDate!.day.toString().padLeft(2, '0')}'
        : widget.event.date;

    await docRef.update({
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),

      'imageUrl': imageUrl,
      'gallery': galleryUrls,

      'type': _selectedType.name,
      'location': _locationCtrl.text.trim(),
      'region': _selectedRegion,

      'date': dateStr,
      'startTime': _startTimeCtrl.text.trim(),
      'duration': _durationCtrl.text.trim(),

      'price': _isFree ? '0' : _priceCtrl.text.trim(),
      'maxParticipants': _maxParticipants,

      'tags': _tags,
      'includes': _includes,

      'language': _selectedLanguage,
      'isOnline': _isOnline,
    });
  }

  // ─────────────────────────────
  // VALIDATION
  // ─────────────────────────────

  String? _validate() {
    if (_titleCtrl.text.isEmpty) return "Titre requis";
    if (_descCtrl.text.isEmpty) return "Description requise";
    if (!_isOnline && _locationCtrl.text.isEmpty) return "Lieu requis";
    if (_selectedDate == null) return "Date requise";
    return null;
  }

  // ─────────────────────────────
  // UI
  // ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier l'événement"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_step + 1) / _steps.length,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              child: ListView(
                children: [
                  const SizedBox(height: 10),

                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: "Titre"),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: _locationCtrl,
                    decoration: const InputDecoration(labelText: "Lieu"),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(labelText: "Prix"),
                  ),

                  const SizedBox(height: 20),

                  if (_existingImageUrl.isNotEmpty)
                    Image.network(_existingImageUrl, height: 160),

                  if (_coverImage != null)
                    Image.file(_coverImage!, height: 160),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: _pickCover,
                    child: const Text("Changer image"),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                        final err = _validate();
                        if (err != null) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(err)));
                          return;
                        }

                        setState(() => _isSaving = true);

                        try {
                          await _updateEvent();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Événement modifié ✔"),
                                backgroundColor: Colors.green,
                              ),
                            );
                            context.pop();
                          }
                        } finally {
                          if (mounted) setState(() => _isSaving = false);
                        }
                      },
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Enregistrer"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
