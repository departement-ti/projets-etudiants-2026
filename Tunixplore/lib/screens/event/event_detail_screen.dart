import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:tunixplore/screens/reviews/reviews_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/models.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/cards/review_card.dart';

// ─────────────────────────────────────────────────────────────
// TOP-LEVEL HELPERS
// ─────────────────────────────────────────────────────────────

/// Converts a Firestore field (Timestamp | "YYYY-MM-DD" | null) → "DD/MM/YYYY".
String _dateToDisplay(dynamic raw) {
  if (raw == null) return '—';
  if (raw is Timestamp) {
    final d = raw.toDate();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }
  if (raw is String && raw.contains('-')) {
    final p = raw.split('-');
    if (p.length == 3) return '${p[2]}/${p[1]}/${p[0]}';
  }
  return raw.toString();
}

/// Compact form: "DD/MM".
String _dateShort(dynamic raw) {
  final full = _dateToDisplay(raw);
  final p = full.split('/');
  return p.length >= 2 ? '${p[0]}/${p[1]}' : full;
}

/// Converts Firestore (Timestamp | String) to "YYYY-MM-DD" for the model field.
String _dateToModelString(dynamic raw) {
  if (raw == null) return '';
  if (raw is Timestamp) {
    final d = raw.toDate();
    return '${d.year}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
  return raw.toString();
}

/// Parses Firestore price (num | String) → double.
double _parsePrice(dynamic raw) {
  if (raw == null) return 0;
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ??
      0;
}

/// Builds [EventModel] from a Firestore [DocumentSnapshot].
EventModel _eventFromDoc(DocumentSnapshot doc) {
  final j = doc.data() as Map<String, dynamic>;
  return EventModel(
    id: doc.id,
    title: j['title'] ?? '',
    description: j['description'] ?? '',
    imageUrl: j['imageUrl'] ?? '',
    gallery: List<String>.from(j['gallery'] ?? []),
    organiserId: j['organiserId'] ?? '',
    organiserName: j['organiserName'] ?? '',
    organiserAvatar: j['organiserAvatar'] ?? '',
    type: EventModel.eventTypeFromString(j['type'] ?? 'visit'),
    location: j['location'] ?? '',
    region: j['region'] ?? '',
    latitude: (j['lat'] ?? 0).toDouble(),
    longitude: (j['lng'] ?? 0).toDouble(),
    date: _dateToModelString(j['date']),
    startTime: j['startTime'] ?? '',
    duration: j['duration'] ?? '',
    // Firestore stores price as a number; model field is String
    price: _parsePrice(j['price']).toStringAsFixed(3),
    maxParticipants: j['maxParticipants'] ?? 0,
    currentParticipants: j['currentParticipants'] ?? 0,
    rating: (j['rating'] ?? 0).toDouble(),
    reviewCount: j['reviewCount'] ?? 0,
    tags: List<String>.from(j['tags'] ?? []),
    includes: List<String>.from(j['includes'] ?? []),
    isOnline: j['isOnline'] ?? false,
    language: j['language'] ?? 'fr',
  );
}

/// Builds [ReviewModel] from a Firestore [DocumentSnapshot].
ReviewModel _reviewFromDoc(DocumentSnapshot doc) {
  final j = doc.data() as Map<String, dynamic>;
  return ReviewModel(
    id: doc.id,
    userName: j['userName'] ?? '',
    userAvatar: j['userAvatar'] ?? '',
    rating: (j['rating'] ?? 0).toDouble(),
    comment: j['comment'] ?? '',
    date: _dateToDisplay(j['createdAt']),
    targetName: j['targetName'] ?? '',
    authorName: j['userName'] ?? '',
  );
}

// ─────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  // ── UI ────────────────────────────────────────────────────
  int _participants = 1;
  bool _isFav = false;
  bool _descExpanded = false;
  int _galleryPage = 0;
  final PageController _galleryCtrl = PageController();

  // ── Data ──────────────────────────────────────────────────
  EventModel? _event;
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  String? _registrationDocId;
  String? _loadError;
  String? _registrationStatus; // null | upcoming | cancelled | completed
  bool _isRegistering = false;

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _galleryCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  // LOAD
  // ─────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      await Future.wait([
        _loadEvent(),
        _loadReviews(),
        _checkRegistration(),
        _checkIfFavorite(),
      ]);
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEvent() async {
    final doc = await _db.collection('events').doc(widget.eventId).get();
    if (!doc.exists) throw Exception('Événement introuvable');
    if (mounted) setState(() => _event = _eventFromDoc(doc));
  }

  Future<void> _loadReviews() async {
    final snap = await _db
        .collection('reviews')
        .where('targetId', isEqualTo: widget.eventId)
        // .orderBy('createdAt', descending: true)
        .limit(5)
        .get();
    if (mounted) {
      setState(() => _reviews = snap.docs.map(_reviewFromDoc).toList());
    }
  }

  Future<void> _checkRegistration() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final snap = await _db
        .collection('registrations')
        .where('userId', isEqualTo: uid)
        .where('eventId', isEqualTo: widget.eventId)
        .limit(1)
        .get();

    if (!mounted) return;

    if (snap.docs.isEmpty) {
      setState(() => _registrationStatus = null);
      return;
    }

    final data = snap.docs.first.data();

    setState(() {
      _registrationStatus = data['status'] as String?;
      _registrationDocId = snap.docs.first.id; // 👈 IMPORTANT FIX
    });
  }

  Future<void> _checkIfFavorite() async {
    final user = _auth.currentUser;

    if (user == null) return;

    final doc = await _db
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.eventId)
        .get();

    if (mounted) {
      setState(() {
        _isFav = doc.exists;
      });
    }
  }

  Future<void> _registerUserDebug() async {
    if (!mounted || _event == null) return;

    final totalPrice = _isFree
        ? '0'
        : (_unitPrice * _participants).toStringAsFixed(3);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Debug Registration'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Event ID: ${widget.eventId}'),
                const SizedBox(height: 8),

                Text('Title: ${_event!.title}'),
                const SizedBox(height: 8),

                Text('Participants: $_participants'),
                const SizedBox(height: 8),

                Text(
                  'Location: ${_event!.isOnline ? 'En ligne' : _event!.location}',
                ),
                const SizedBox(height: 8),

                Text('Date: ${_event!.date}'),
                const SizedBox(height: 8),

                Text('Price: $totalPrice TND'),
                const SizedBox(height: 8),

                Text('Status: upcoming'),
                const SizedBox(height: 8),

                Text('Current Participants: ${_event!.currentParticipants}'),
                const SizedBox(height: 8),

                Text(
                  'New Participants Count: '
                  '${_event!.currentParticipants + _participants}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _registerUser() async {
    final uid = _auth.currentUser?.uid;
    final currentUser = _auth.currentUser;

    if (uid == null || _event == null || currentUser == null) return;

    setState(() => _isRegistering = true);

    try {
      final batch = _db.batch();

      // ─────────────────────────────
      // References
      // ─────────────────────────────
      final regRef = _db.collection('registrations').doc();
      final notifUserRef = _db.collection('notifications').doc();
      final notifOrgRef = _db.collection('notifications').doc();
      final ticketRef = _db.collection('tickets').doc();

      // ─────────────────────────────
      // Registration
      // ─────────────────────────────
      batch.set(regRef, {
        'id': regRef.id,
        'userId': uid,
        'eventId': widget.eventId,

        'userName': currentUser.displayName ?? 'Utilisateur',
        'userEmail': currentUser.email ?? '',

        'eventTitle': _event!.title,
        'eventImage': _event!.imageUrl,
        'eventDate': _event!.date,
        'eventLocation': _event!.isOnline ? 'En ligne' : _event!.location,

        'participants': _participants,

        'price': _isFree
            ? '0'
            : (_unitPrice * _participants).toStringAsFixed(3),

        'status': 'upcoming',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ─────────────────────────────
      // Update event participants
      // ─────────────────────────────
      batch.update(_db.collection('events').doc(widget.eventId), {
        'currentParticipants': FieldValue.increment(_participants),
      });

      // ─────────────────────────────
      // NOTIFICATION 1 → PARTICIPANT (SUCCESS)
      // ─────────────────────────────
      batch.set(notifUserRef, {
        'id': notifUserRef.id,

        // owner of notification
        'userId': uid,

        // type
        'type': 'event_registration_success',

        // generic display
        'title': 'Inscription confirmée 🎉',
        'message':
            'Votre participation à "${_event!.title}" a été enregistrée avec succès.',

        // structured data
        'eventId': widget.eventId,
        'eventTitle': _event!.title,
        'eventImage': _event!.imageUrl,
        'eventDate': _event!.date,
        'eventLocation': _event!.isOnline ? 'En ligne' : _event!.location,

        'participants': _participants,

        // actor
        'actorUserId': uid,
        'actorUserName': currentUser.displayName ?? 'Utilisateur',
        'actorUserEmail': currentUser.email ?? '',

        // status
        'isRead': false,

        // timestamps
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ─────────────────────────────
      // NOTIFICATION 2 → ORGANISER
      // ─────────────────────────────
      batch.set(notifOrgRef, {
        'id': notifOrgRef.id,

        // owner of notification
        'userId': _event!.organiserId,

        // type used by admin panel
        'type': 'registration',

        // generic display
        'title': 'Nouvelle participation 🎉',
        'message':
            '${currentUser.displayName ?? 'Un utilisateur'} '
            'a rejoint votre événement "${_event!.title}".',

        // event data
        'eventId': widget.eventId,
        'eventTitle': _event!.title,
        'eventImage': _event!.imageUrl,
        'eventDate': _event!.date,
        'eventLocation': _event!.isOnline ? 'En ligne' : _event!.location,

        // participant data
        'participants': _participants,
        'userName': currentUser.displayName ?? 'Utilisateur',
        'userEmail': currentUser.email ?? '',
        'participantUserId': uid,

        // organiser data
        'organiserId': _event!.organiserId,

        // read state
        'isRead': false,

        // timestamp
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ─────────────────────────────
      // TICKET
      // ─────────────────────────────
      batch.set(ticketRef, {
        'id': ticketRef.id,

        'registrationId': regRef.id,
        'eventId': widget.eventId,
        'organiserId': _event!.organiserId,
        'userId': uid,

        // standardized user fields
        'userName': currentUser.displayName ?? 'Utilisateur',
        'userEmail': currentUser.email ?? '',

        // legacy compatibility (optional for now)
        'participantName': currentUser.displayName ?? 'Utilisateur',
        'participantEmail': currentUser.email ?? '',

        'eventTitle': _event!.title,
        'eventImage': _event!.imageUrl,
        'eventDate': _event!.date,
        'eventLocation': _event!.isOnline ? 'En ligne' : _event!.location,

        'participants': _participants,

        'price': _isFree
            ? '0'
            : (_unitPrice * _participants).toStringAsFixed(3),

        'ticketCode': 'TICKET-${ticketRef.id.substring(0, 8).toUpperCase()}',

        'status': 'active',

        'qrData': {
          'ticketId': ticketRef.id,
          'eventId': widget.eventId,
          'userId': uid,
        },

        'createdAt': FieldValue.serverTimestamp(),
      });

      // ─────────────────────────────
      // Commit all
      // ─────────────────────────────
      await batch.commit();

      await Future.wait([_loadEvent(), _checkRegistration()]);

      // ─────────────────────────────
      // UI SUCCESS
      // ─────────────────────────────
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Inscription confirmée! 🎉'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }

      // ─────────────────────────────
      // DEBUG
      // ─────────────────────────────
      debugPrint('================ REGISTRATION SUCCESS ================');
      debugPrint('User: $uid');
      debugPrint('Event: ${_event!.title}');
      debugPrint('Organiser: ${_event!.organiserId}');
      debugPrint(
        'Ticket Code: TICKET-${ticketRef.id.substring(0, 8).toUpperCase()}',
      );
      debugPrint('======================================================');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }

      debugPrint('================ REGISTER ERROR =================');
      debugPrint(e.toString());
      debugPrint('=================================================');
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  // PRICE HELPERS
  // ─────────────────────────────────────────────────────────

  bool get _isFree {
    if (_event == null) return true;
    final p = _event!.price;
    return p == '0' ||
        p == '0.000' ||
        p.toLowerCase() == 'gratuit' ||
        p.isEmpty ||
        _parsePrice(p) == 0;
  }

  double get _unitPrice => _parsePrice(_event?.price);

  String get _formattedUnit =>
      _isFree ? 'Gratuit' : '${_unitPrice.toStringAsFixed(3)} TND';

  String _totalPrice() => _isFree
      ? 'Gratuit'
      : '${(_unitPrice * _participants).toStringAsFixed(3)} TND';

  // ─────────────────────────────────────────────────────────
  // TYPE HELPERS
  // ─────────────────────────────────────────────────────────

  Color _typeColor(EventType t) {
    switch (t) {
      case EventType.visit:
        return AppColors.info;
      case EventType.tour:
        return AppColors.teal;
      case EventType.festival:
        return AppColors.accent;
      case EventType.workshop:
        return AppColors.warning;
      case EventType.adventure:
        return AppColors.success;
      case EventType.cultural:
        return const Color(0xFF9C27B0);
    }
  }

  String _typeLabel(EventType t) {
    switch (t) {
      case EventType.visit:
        return 'Visite';
      case EventType.tour:
        return 'Tour';
      case EventType.festival:
        return 'Festival';
      case EventType.workshop:
        return 'Atelier';
      case EventType.adventure:
        return 'Aventure';
      case EventType.cultural:
        return 'Culture';
    }
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // ── Loading skeleton ──
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ── Error state ──
    if (_loadError != null || _event == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.warning_2, size: 52, color: AppColors.error),
              const SizedBox(height: 14),
              Text(
                _loadError ?? 'Événement introuvable',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadAll,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final event = _event!;
    final allImages = [
      if (event.imageUrl.isNotEmpty) event.imageUrl,
      ...event.gallery,
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero gallery ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            leading: _CircleAction(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => context.pop(),
            ),
            actions: [
              _CircleAction(
                icon: _isFav
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,

                iconColor: _isFav ? Colors.white : AppColors.accent,

                bgColor: _isFav
                    ? AppColors.accent
                    : Colors.white.withOpacity(0.9),

                onTap: () async {
                  final user = FirebaseAuth.instance.currentUser;

                  if (user == null || _event == null) return;

                  final favRef = FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('favorites')
                      .doc(_event!.id);

                  try {
                    if (_isFav) {
                      // REMOVE FAVORITE
                      await favRef.delete();

                      if (mounted) {
                        setState(() => _isFav = false);
                      }
                    } else {
                      // ADD FAVORITE
                      await favRef.set({
                        'eventId': _event!.id,
                        'title': _event!.title,
                        'imageUrl': _event!.imageUrl,
                        'location': _event!.location,
                        'date': _event!.date,
                        'price': _event!.price,
                        'rating': _event!.rating,
                        'type': _event!.type.name,

                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      if (mounted) {
                        setState(() => _isFav = true);
                      }
                    }
                  } catch (e) {
                    debugPrint('Favorite error: $e');

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur favoris: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
              ),
              _CircleAction(icon: Icons.share_rounded, onTap: () {}),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (allImages.isNotEmpty)
                    PageView.builder(
                      controller: _galleryCtrl,
                      itemCount: allImages.length,
                      onPageChanged: (i) => setState(() => _galleryPage = i),
                      itemBuilder: (_, i) => CachedNetworkImage(
                        imageUrl: allImages[i],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(
                            Iconsax.gallery,
                            size: 48,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: AppColors.surfaceVariant,
                      child: const Icon(
                        Iconsax.gallery,
                        size: 64,
                        color: AppColors.textHint,
                      ),
                    ),

                  // Gradient
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.45, 1.0],
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),

                  // Badges + dots
                  Positioned(
                    bottom: 14,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        _TypeBadge(
                          label: _typeLabel(event.type),
                          color: _typeColor(event.type),
                        ),
                        if (event.isOnline) ...[
                          const SizedBox(width: 6),
                          _TypeBadge(
                            label: '🌐 En ligne',
                            color: AppColors.info,
                          ),
                        ],
                        const Spacer(),
                        if (allImages.length > 1)
                          _GalleryDots(
                            count: allImages.length,
                            current: _galleryPage,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.pagePadding,
                    20,
                    AppConstants.pagePadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Rating + language badge
                      Row(
                        children: [
                          RatingBar.builder(
                            initialRating: event.rating,
                            minRating: 1,
                            itemCount: 5,
                            itemSize: 15,
                            ignoreGestures: true,
                            itemBuilder: (_, __) => const Icon(
                              Icons.star_rounded,
                              color: AppColors.amber,
                            ),
                            onRatingUpdate: (_) {},
                          ),
                          const SizedBox(width: 6),
                          Text(
                            event.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            ' (${event.reviewCount} avis)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          _LanguageBadge(language: event.language),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Key info grid
                      _InfoGrid(event: event),
                      const SizedBox(height: 18),

                      // Location card (offline only)
                      if (!event.isOnline && event.location.isNotEmpty) ...[
                        _LocationCard(event: event),
                        const SizedBox(height: 18),
                      ],

                      // Organiser
                      _OrgCard(event: event),
                      const SizedBox(height: 22),

                      // Description
                      const _SectionTitle(label: 'Description'),
                      const SizedBox(height: 8),
                      _ExpandableText(
                        text: event.description,
                        expanded: _descExpanded,
                        onToggle: () =>
                            setState(() => _descExpanded = !_descExpanded),
                      ),
                      const SizedBox(height: 22),
                    ],
                  ),
                ),

                // Gallery thumbnails strip
                if (event.gallery.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.pagePadding,
                    ),
                    child: _SectionTitle(label: 'Galerie'),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.pagePadding,
                      ),
                      itemCount: event.gallery.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => _galleryCtrl.animateToPage(
                          i + 1,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: event.gallery[i],
                            width: 140,
                            height: 110,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.pagePadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Includes
                      if (event.includes.isNotEmpty) ...[
                        const _SectionTitle(label: 'Ce qui est inclus'),
                        const SizedBox(height: 10),
                        _IncludesList(items: event.includes),
                        const SizedBox(height: 22),
                      ],

                      // Tags
                      if (event.tags.isNotEmpty) ...[
                        const _SectionTitle(label: 'Tags'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: event.tags
                              .map((t) => TagChip(label: t))
                              .toList(),
                        ),
                        const SizedBox(height: 22),
                      ],

                      // Participants selector
                      _ParticipantsSelector(
                        value: _participants,
                        spotsLeft: event.spotsLeft,
                        isFull: event.isFull,
                        isRegistered: _registrationStatus == 'upcoming',
                        onDecrement: () {
                          if (_participants > 1 &&
                              _registrationStatus != 'upcoming') {
                            setState(() => _participants--);
                          }
                        },
                        onIncrement: () {
                          if (_participants < event.spotsLeft &&
                              _registrationStatus != 'upcoming') {
                            setState(() => _participants++);
                          }
                        },
                      ),
                      const SizedBox(height: 22),

                      // Reviews section
                      SectionHeader(
                        title: 'Avis (${event.reviewCount})',
                        actionLabel: 'Voir tout',
                        onAction: () =>
                            context.push('/reviews/${widget.eventId}'),
                      ),
                      const SizedBox(height: 12),
                      if (_reviews.isNotEmpty)
                        ..._reviews.take(2).map((r) => ReviewCard(review: r))
                      else
                        _EmptyReviews(),

                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        event: event,
        participants: _participants,
        isFree: _isFree,
        totalPrice: _totalPrice(),
        isRegistered: _registrationStatus == 'upcoming',
        isLoading: _isRegistering,
        onRegister: (event.isFull || _registrationStatus == 'upcoming')
            ? null
            : () => _showRegistrationSheet(context, event),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // REGISTRATION SHEET
  // ─────────────────────────────────────────────────────────

  void _showRegistrationSheet(BuildContext context, EventModel event) {
    // Tracks which payment option is highlighted inside the sheet.
    // 0 = cash on day (default, working), 1 = card (goes to checkout UI).
    int sheetPayment = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXl),
        ),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle bar ────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Icon + title ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.success,
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Confirmer l\'inscription',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                event.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_dateToDisplay(event.date)}  •  ${event.startTime}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textHint, fontSize: 12),
              ),
              const SizedBox(height: 20),

              // ── Price breakdown ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _PriceLine(
                      label: '$_formattedUnit × $_participants personne(s)',
                      value: _isFree
                          ? 'Gratuit'
                          : '${(_unitPrice * _participants).toStringAsFixed(3)} TND',
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    _PriceLine(
                      label: 'Total',
                      value: _totalPrice(),
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Payment method choice (only for paid events) ───────────
              if (!_isFree) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Mode de paiement',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Cash on day option
                _SheetPaymentOption(
                  icon: Iconsax.money,
                  label: 'Payer sur place',
                  subtitle: 'Espèces le jour de l\'événement',
                  isSelected: sheetPayment == 0,
                  onTap: () => setSheetState(() => sheetPayment = 0),
                ),
                const SizedBox(height: 8),

                // Card option
                _SheetPaymentOption(
                  icon: Iconsax.card,
                  label: 'Payer par carte',
                  subtitle: 'Visa / Mastercard — paiement sécurisé',
                  isSelected: sheetPayment == 1,
                  onTap: () => setSheetState(() => sheetPayment = 1),
                ),
                const SizedBox(height: 20),
              ],

              // ── Action button — behaviour depends on payment choice ────
              if (_isFree || sheetPayment == 0)
                // FREE or cash: existing working Firestore logic
                AppButton(
                  label: _isRegistering
                      ? 'Inscription en cours…'
                      : 'Confirmer l\'inscription',
                  onTap: _isRegistering ? null : _registerUser,
                )
              else
                // Card: navigate to checkout screen (UI only, pay button disabled there)
                AppButton(
                  label: 'Continuer vers le paiement',
                  icon: Iconsax.card,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push(
                      '/checkout/${widget.eventId}?participants=$_participants',
                    );
                  },
                ),

              const SizedBox(height: 10),
              AppButton(
                label: 'Annuler',
                isOutline: true,
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PRIVATE WIDGETS  ── same design as before
// ═══════════════════════════════════════════════════════════════

// ── Back / Fav / Share floating button ───────────────────────
class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? bgColor;

  const _CircleAction({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor ?? Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor ?? AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ── Coloured label pill ───────────────────────────────────────
class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _TypeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppConstants.radiusRound),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Animated pagination dots ──────────────────────────────────
class _GalleryDots extends StatelessWidget {
  final int count;
  final int current;
  const _GalleryDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(left: 4),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white54,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ── Language pill ─────────────────────────────────────────────
class _LanguageBadge extends StatelessWidget {
  final String language;
  const _LanguageBadge({required this.language});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.radiusRound),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Iconsax.global, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            language,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bold section header ───────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ── 4-cell info grid (date / time / duration / spots) ─────────
class _InfoGrid extends StatelessWidget {
  final EventModel event;
  const _InfoGrid({required this.event});

  @override
  Widget build(BuildContext context) {
    final spotsLabel = event.isFull
        ? 'Complet'
        : '${event.spotsLeft}/${event.maxParticipants}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          _InfoCell(
            icon: Iconsax.calendar,
            label: 'Date',
            value: _dateShort(event.date),
          ),
          _VertDivider(),
          _InfoCell(
            icon: Iconsax.clock,
            label: 'Heure',
            value: event.startTime.isNotEmpty ? event.startTime : '—',
          ),
          _VertDivider(),
          _InfoCell(
            icon: Iconsax.timer_1,
            label: 'Durée',
            value: event.duration.isNotEmpty ? event.duration : '—',
          ),
          _VertDivider(),
          _InfoCell(
            icon: Iconsax.people,
            label: 'Places',
            value: spotsLabel,
            valueColor: event.isFull ? AppColors.error : null,
          ),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppColors.accent),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 44, color: AppColors.border);
}

// ── Location card ─────────────────────────────────────────────
class _LocationCard extends StatelessWidget {
  final EventModel event;
  const _LocationCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Iconsax.location,
              size: 20,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.location,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (event.region.isNotEmpty)
                  Text(
                    event.region,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.textHint,
          ),
        ],
      ),
    );
  }
}

// ── Organiser card ────────────────────────────────────────────
class _OrgCard extends StatelessWidget {
  final EventModel event;
  const _OrgCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: event.organiserAvatar.isNotEmpty
                ? NetworkImage(event.organiserAvatar)
                : null,
            backgroundColor: AppColors.surfaceVariant,
            child: event.organiserAvatar.isEmpty
                ? Text(
                    event.organiserName.isNotEmpty
                        ? event.organiserName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.organiserName.isNotEmpty
                      ? event.organiserName
                      : 'Organisateur',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: const [
                    Icon(Iconsax.verify5, size: 13, color: AppColors.info),
                    SizedBox(width: 4),
                    Text(
                      'Organisateur vérifié',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/chatbot'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: const Text(
                'Contacter',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Collapsible description ───────────────────────────────────
class _ExpandableText extends StatelessWidget {
  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  const _ExpandableText({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 14,
      color: AppColors.textSecondary,
      height: 1.65,
    );
    final isLong = text.length > 200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: style,
          maxLines: expanded ? null : 4,
          overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (isLong) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onToggle,
            child: Text(
              expanded ? 'Voir moins' : 'Voir plus',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Includes checklist ────────────────────────────────────────
class _IncludesList extends StatelessWidget {
  final List<String> items;
  const _IncludesList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 11,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Empty reviews placeholder ─────────────────────────────────
class _EmptyReviews extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Iconsax.star, size: 20, color: AppColors.textHint),
          SizedBox(width: 10),
          Text(
            'Aucun avis pour l\'instant',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Participants counter ──────────────────────────────────────
class _ParticipantsSelector extends StatelessWidget {
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final int spotsLeft;
  final bool isFull;
  final bool isRegistered;

  const _ParticipantsSelector({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    required this.spotsLeft,
    required this.isFull,
    required this.isRegistered,
  });

  @override
  Widget build(BuildContext context) {
    final String subtitle;
    final Color subtitleColor;

    if (isRegistered) {
      subtitle = 'Vous êtes déjà inscrit(e)';
      subtitleColor = AppColors.info;
    } else if (isFull) {
      subtitle = 'Événement complet';
      subtitleColor = AppColors.error;
    } else {
      subtitle = '$spotsLeft place(s) disponible(s)';
      subtitleColor = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.people, size: 20, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Participants',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _CountBtn(
            icon: Icons.remove_rounded,
            enabled: !isFull && !isRegistered && value > 1,
            filled: false,
            onTap: onDecrement,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$value',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
          _CountBtn(
            icon: Icons.add_rounded,
            enabled: !isFull && !isRegistered,
            filled: true,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _CountBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final bool filled;
  final VoidCallback onTap;

  const _CountBtn({
    required this.icon,
    required this.enabled,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: filled
              ? (enabled ? AppColors.accent : AppColors.border)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: filled ? null : Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          size: 18,
          color: filled
              ? Colors.white
              : (enabled ? AppColors.textPrimary : AppColors.textHint),
        ),
      ),
    );
  }
}

// ── Sticky bottom bar ─────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final EventModel event;
  final int participants;
  final bool isFree;
  final String totalPrice;
  final bool isRegistered;
  final bool isLoading;
  final VoidCallback? onRegister;

  const _BottomBar({
    required this.event,
    required this.participants,
    required this.isFree,
    required this.totalPrice,
    required this.isRegistered,
    required this.isLoading,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color btnColor;

    if (isRegistered) {
      label = 'Déjà inscrit(e) ✓';
      btnColor = AppColors.success;
    } else if (event.isFull) {
      label = 'Complet';
      btnColor = AppColors.textHint;
    } else if (isLoading) {
      label = 'Inscription…';
      btnColor = AppColors.accent;
    } else {
      label = 'S\'inscrire maintenant';
      btnColor = AppColors.accent;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFree ? 'Prix' : 'Total (×$participants)',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                totalPrice,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isFree ? AppColors.success : AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AppButton(label: label, onTap: onRegister, color: btnColor),
          ),
        ],
      ),
    );
  }
}

// ── Payment option row in confirmation sheet ───────────────────
class _SheetPaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _SheetPaymentOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withOpacity(0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withOpacity(0.15)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, size: 20, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

// ── Price row in confirmation sheet ───────────────────────────
class _PriceLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _PriceLine({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? AppColors.accent : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
