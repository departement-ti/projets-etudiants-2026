import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/models.dart';
import '../../widgets/cards/event_card.dart';
import '../../widgets/common/common_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  const _HeaderIconBtn({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          if (badge)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Model builders  (same helpers as home screen pattern)
// ─────────────────────────────────────────────────────────────

EventModel _eventFromDoc(QueryDocumentSnapshot doc) {
  final j = doc.data() as Map<String, dynamic>;

  String dateStr = '';
  final rawDate = j['date'];
  if (rawDate is Timestamp) {
    final d = rawDate.toDate();
    dateStr =
        '${d.year}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  } else if (rawDate is String) {
    dateStr = rawDate;
  }

  double parsePrice(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ??
        0;
  }

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
    date: dateStr,
    startTime: j['startTime'] ?? '',
    duration: j['duration'] ?? '',
    price: parsePrice(j['price']).toStringAsFixed(3),
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

class _PlaceChip extends StatelessWidget {
  final PlaceModel place;
  final VoidCallback onTap;

  const _PlaceChip({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(place.imageUrl, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      place.region,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedType = 'Tout';

  final List<String> _typeFilters = [
    'Tout',
    'visit',
    'tour',
    'festival',
    'workshop',
    'adventure',
  ];

  // ─────────────────────────────────────────────────────────────
  // FIRESTORE STREAMS
  // ─────────────────────────────────────────────────────────────

  final _eventsStream = FirebaseFirestore.instance
      .collection('events')
      .where('isActive', isEqualTo: true)
      .snapshots();

  final _placesStream = FirebaseFirestore.instance
      .collection('places')
      .where('isFeatured', isEqualTo: true)
      .snapshots();

  // ─────────────────────────────────────────────────────────────
  // FILTER EVENTS
  // ─────────────────────────────────────────────────────────────

  List<QueryDocumentSnapshot> _filterEvents(List<QueryDocumentSnapshot> docs) {
    if (_selectedType == 'Tout') return docs;

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['type'] == _selectedType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/chatbot'),
        backgroundColor: AppColors.accent,
        icon: const Icon(Iconsax.message_text_1, color: Colors.white),
        label: const Text(
          'Assistant IA',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),

      body: CustomScrollView(
        slivers: [
          // ─────────────────────────────────────────────
          // HERO HEADER (unchanged UI)
          // ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: AppConstants.pagePadding,
                right: AppConstants.pagePadding,
                bottom: 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Marhba bik! 🇹🇳',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Découvrez la Tunisie',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          _HeaderIconBtn(
                            icon: Iconsax.heart,
                            badge: true,
                            onTap: () => context.go('/wishlist'),
                          ),
                          const SizedBox(width: 8),
                          _HeaderIconBtn(
                            icon: Iconsax.setting_2,
                            onTap: () => context.push('/settings'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─────────────────────────────────────────────
          // PLACES (FIRESTORE)
          // ─────────────────────────────────────────────

          // SliverToBoxAdapter(
          //   child: Padding(
          //     padding: const EdgeInsets.fromLTRB(
          //       AppConstants.pagePadding,
          //       22,
          //       AppConstants.pagePadding,
          //       10,
          //     ),
          //     child: const SectionHeader(
          //       title: 'Sites incontournables',
          //       actionLabel: 'Voir tout',
          //     ),
          //   ),
          // ),

          // SliverToBoxAdapter(
          //   child: StreamBuilder<QuerySnapshot>(
          //     stream: _placesStream,
          //     builder: (context, snapshot) {
          //       if (snapshot.connectionState == ConnectionState.waiting) {
          //         return const SizedBox(
          //           height: 130,
          //           child: Center(child: CircularProgressIndicator()),
          //         );
          //       }

          //       if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          //         return Padding(
          //           padding: const EdgeInsets.fromLTRB(
          //             AppConstants.pagePadding,
          //             22,
          //             AppConstants.pagePadding,
          //             10,
          //           ),
          //           child: Container(
          //             height: 120,
          //             width: double.infinity,
          //             decoration: BoxDecoration(
          //               color: Colors.grey.shade200,
          //               borderRadius: BorderRadius.circular(16),
          //             ),
          //             child: const Center(
          //               child: Text(
          //                 'Aucune donnée disponible',
          //                 style: TextStyle(
          //                   color: Colors.grey,
          //                   fontWeight: FontWeight.w600,
          //                 ),
          //               ),
          //             ),
          //           ),
          //         );
          //       }

          //       final places = snapshot.data!.docs;

          //       return SizedBox(
          //         height: 130,
          //         child: ListView.builder(
          //           scrollDirection: Axis.horizontal,
          //           padding: const EdgeInsets.symmetric(
          //             horizontal: AppConstants.pagePadding,
          //           ),
          //           itemCount: places.length,
          //           itemBuilder: (context, i) {
          //             final data = places[i].data() as Map<String, dynamic>;

          //             final place = PlaceModel.fromJson(places[i].id, data);

          //             return _PlaceChip(
          //               place: place,
          //               onTap: () => context.push('/place/${places[i].id}'),
          //             );
          //           },
          //         ),
          //       );
          //     },
          //   ),
          // ),

          // ─────────────────────────────────────────────
          // EVENTS HEADER
          // ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.pagePadding,
                22,
                AppConstants.pagePadding,
                12,
              ),
              child: const SectionHeader(
                title: 'Événements & Circuits',
                actionLabel: 'Explorer',
              ),
            ),
          ),

          // ─────────────────────────────────────────────
          // FILTERS
          // ─────────────────────────────────────────────
          // SliverToBoxAdapter(
          //   child: SizedBox(
          //     height: 44,
          //     child: ListView.builder(
          //       scrollDirection: Axis.horizontal,
          //       padding: const EdgeInsets.symmetric(
          //         horizontal: AppConstants.pagePadding,
          //       ),
          //       itemCount: _typeFilters.length,
          //       itemBuilder: (context, i) {
          //         final type = _typeFilters[i];

          //         return Padding(
          //           padding: const EdgeInsets.only(right: 8),
          //           child: GestureDetector(
          //             onTap: () {
          //               setState(() {
          //                 _selectedType = type;
          //               });
          //             },
          //             child: TagChip(
          //               label: type,
          //               isSelected: _selectedType == type,
          //             ),
          //           ),
          //         );
          //       },
          //     ),
          //   ),
          // ),

          // ─────────────────────────────────────────────
          // EVENTS LIST (FIRESTORE)
          // ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: _eventsStream,
              builder: (context, snapshot) {
                // ─────────────────────────────
                // ERROR STATE
                // ─────────────────────────────
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(AppConstants.pagePadding),
                    child: Container(
                      height: 120,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Erreur de chargement des événements',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }

                // ─────────────────────────────
                // LOADING STATE
                // ─────────────────────────────
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                // ─────────────────────────────
                // EMPTY STATE
                // ─────────────────────────────
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppConstants.pagePadding,
                      14,
                      AppConstants.pagePadding,
                      100,
                    ),
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'Aucun événement trouvé',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // ─────────────────────────────
                // DATA STATE (EventCard style)
                // ─────────────────────────────
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.pagePadding,
                    8,
                    AppConstants.pagePadding,
                    100,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final event = _eventFromDoc(docs[i]);

                    return EventCard(
                      event: event,
                      onTap: () => context.push('/event/${event.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
