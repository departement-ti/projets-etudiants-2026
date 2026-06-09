import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../widgets/cards/event_card.dart';
import '../../widgets/common/common_widgets.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  int _regionIdx = 0;

  List<PlaceModel> get _places {
    if (_regionIdx == 0) return MockData.places;
    final r = MockData.regions[_regionIdx - 1]['name'];
    return MockData.places.where((p) => p.region == r).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(32))),
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: AppConstants.pagePadding, right: AppConstants.pagePadding, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Découvrir', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text('Les merveilles de la Tunisie 🇹🇳', style: TextStyle(fontSize: 13, color: Colors.white70)),
                    ]),
                    GestureDetector(onTap: () => context.push('/chatbot'), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: const Icon(Iconsax.message_text_1, color: Colors.white, size: 20))),
                  ]),
                  const SizedBox(height: 18),
                  // Featured place hero
                  _HeroPlace(place: MockData.places.firstWhere((p) => p.isFeatured)),
                ],
              ),
            ),
          ),

          // ── AI Itineraries ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppConstants.pagePadding, 22, AppConstants.pagePadding, 12),
              child: SectionHeader(title: 'Parcours IA recommandés', actionLabel: 'Voir tout'),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.pagePadding),
                itemCount: MockData.itineraries.length,
                itemBuilder: (context, i) => _ItineraryCard(itin: MockData.itineraries[i]),
              ),
            ),
          ),

          // ── Sites by region ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppConstants.pagePadding, 22, AppConstants.pagePadding, 10),
              child: SectionHeader(title: 'Sites tunisiens'),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.pagePadding),
                itemCount: MockData.regions.length + 1,
                itemBuilder: (context, i) {
                  final label = i == 0 ? 'Tout' : '${MockData.regions[i-1]['emoji']} ${MockData.regions[i-1]['name']}';
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _regionIdx = i),
                      child: TagChip(label: label, isSelected: _regionIdx == i),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppConstants.pagePadding, 12, AppConstants.pagePadding, 0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.78),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _PlaceCard(place: _places[i]),
                childCount: _places.length,
              ),
            ),
          ),

          // ── Trending events ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppConstants.pagePadding, 22, AppConstants.pagePadding, 12),
              child: SectionHeader(title: 'Événements en vedette', actionLabel: 'Voir tout', onAction: () => context.go('/home')),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 270,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.pagePadding),
                itemCount: MockData.events.where((e) => e.rating >= 4.8).length,
                itemBuilder: (context, i) {
                  final ev = MockData.events.where((e) => e.rating >= 4.8).toList()[i];
                  return EventCardCompact(event: ev, onTap: () => context.push('/event/${ev.id}'));
                },
              ),
            ),
          ),

          // ── Tips ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppConstants.pagePadding, 20, AppConstants.pagePadding, 12),
              child: const Text('Conseils de voyage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppConstants.pagePadding, 0, AppConstants.pagePadding, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _TipCard(tip: _tips[i]),
                childCount: _tips.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _tips = [
    _Tip(icon: Iconsax.sun_1, title: 'Meilleure saison', body: 'Avril–Juin et Sept–Oct offrent les meilleures conditions climatiques pour explorer la Tunisie.', color: AppColors.amber),
    _Tip(icon: Iconsax.translate, title: 'Langues utiles', body: 'L\'arabe et le français sont parlés partout. Dans les zones touristiques, l\'anglais est souvent compris.', color: AppColors.info),
    _Tip(icon: Iconsax.money, title: 'Budget & Monnaie', body: 'Le dinar tunisien (TND) est la monnaie locale. Les ATM sont disponibles dans toutes les villes.', color: AppColors.success),
  ];
}

class _HeroPlace extends StatelessWidget {
  final PlaceModel place;
  const _HeroPlace({required this.place});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/place/${place.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(children: [
          Image.network(place.imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover),
          Container(height: 150, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.65)]))),
          Positioned(top: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppConstants.radiusRound)), child: const Text('⭐ Incontournable', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)))),
          Positioned(bottom: 14, left: 14, right: 14, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(place.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
              Text(place.region, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('Entrée', style: TextStyle(fontSize: 10, color: Colors.white70)),
              Text(place.entryFee, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
            ]),
          ])),
        ]),
      ),
    );
  }
}

class _ItineraryCard extends StatelessWidget {
  final ItineraryModel itin;
  const _ItineraryCard({required this.itin});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/itinerary/${itin.id}'),
      child: Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(fit: StackFit.expand, children: [
          Image.network(itin.imageUrl, fit: BoxFit.cover),
          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.65)]))),
          Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(6)), child: Text('🤖 IA • ${itin.duration}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
            const SizedBox(height: 5),
            Text(itin.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
            Text('${itin.regions.join(' · ')} • ${itin.difficulty}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ])),
        ]),
      ),
    ),
    );
  }
}

class _PlaceCard extends StatefulWidget {
  final PlaceModel place;
  const _PlaceCard({required this.place});

  @override
  State<_PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<_PlaceCard> {
  bool _isFav = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/place/${widget.place.id}'),
      child: ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      child: Stack(fit: StackFit.expand, children: [
        Image.network(widget.place.imageUrl, fit: BoxFit.cover),
        Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.72)]))),
        Positioned(top: 10, right: 10, child: GestureDetector(
          onTap: () => setState(() => _isFav = !_isFav),
          child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: _isFav ? AppColors.accent : Colors.white.withOpacity(0.8), shape: BoxShape.circle), child: Icon(_isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 14, color: _isFav ? Colors.white : AppColors.accent)),
        )),
        Positioned(bottom: 12, left: 12, right: 12, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.place.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
          Text(widget.place.region, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          const SizedBox(height: 5),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            RatingChip(rating: widget.place.rating),
            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(6)), child: Text(widget.place.entryFee, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700))),
          ]),
        ])),
      ]),
    ),
    );
  }
}

class _Tip { final IconData icon; final String title; final String body; final Color color; const _Tip({required this.icon, required this.title, required this.body, required this.color}); }

class _TipCard extends StatelessWidget {
  final _Tip tip;
  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppConstants.radiusLg), border: Border.all(color: AppColors.border)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: tip.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(tip.icon, color: tip.color, size: 22)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tip.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(tip.body, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
      ])),
    ]));
  }
}