import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/cards/event_card.dart';

class ItineraryDetailScreen extends StatelessWidget {
  final String itineraryId;
  const ItineraryDetailScreen({super.key, required this.itineraryId});

  ItineraryModel get _itin => MockData.itineraries.firstWhere(
        (i) => i.id == itineraryId,
        orElse: () => MockData.itineraries.first,
      );

  @override
  Widget build(BuildContext context) {
    final itin = _itin;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Image AppBar ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: AppColors.textPrimary),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.share_rounded,
                      size: 18, color: AppColors.textPrimary),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(fit: StackFit.expand, children: [
                CachedNetworkImage(
                    imageUrl: itin.imageUrl, fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.65)
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 16,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: AppColors.teal,
                          borderRadius: BorderRadius.circular(
                              AppConstants.radiusRound)),
                      child: Text(
                          '🤖 Parcours IA • ${itin.duration}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),
              ]),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(itin.title,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),

                  // Meta chips
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _MetaChip(
                        icon: Iconsax.clock,
                        label: itin.duration,
                        color: AppColors.teal),
                    _MetaChip(
                        icon: Iconsax.location,
                        label: itin.regions.join(' · '),
                        color: AppColors.accent),
                    _MetaChip(
                        icon: Iconsax.chart_2,
                        label: itin.difficulty,
                        color: AppColors.warning),
                    _MetaChip(
                        icon: Iconsax.routing,
                        label: '${itin.steps.length} étapes',
                        color: AppColors.info),
                  ]),
                  const SizedBox(height: 20),

                  // AI info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: AppColors.tealGradient,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusLg),
                    ),
                    child: const Row(children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                            Text('Parcours généré par IA',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                            Text(
                                'Optimisé selon vos préférences et la durée disponible.',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12)),
                          ])),
                    ]),
                  ),
                  const SizedBox(height: 22),

                  // Steps timeline
                  const Text('Itinéraire détaillé',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  ...List.generate(itin.steps.length, (i) {
                    final step = itin.steps[i];
                    final isLast = i == itin.steps.length - 1;
                    return _TimelineStep(
                      step: step,
                      index: i,
                      isLast: isLast,
                      onPlaceTap: () {
                        final place = MockData.places.firstWhere(
                            (p) => p.id == step.placeId,
                            orElse: () => MockData.places.first);
                        context.push('/place/${place.id}');
                      },
                    );
                  }),
                  const SizedBox(height: 22),

                  // Related events
                  SectionHeader(
                    title: 'Événements sur ce parcours',
                    actionLabel: 'Voir tout',
                    onAction: () => context.go('/search'),
                  ),
                  const SizedBox(height: 12),
                  ...MockData.events
                      .where((e) =>
                          itin.regions.contains(e.region))
                      .take(2)
                      .map((e) => EventCard(
                            event: e,
                            onTap: () => context.push('/event/${e.id}'),
                          )),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -8))
          ],
        ),
        child: Row(children: [
          Expanded(
            child: AppButton(
              label: 'Démarrer ce parcours',
              icon: Iconsax.routing,
              onTap: () => context.go('/search'),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.push('/chatbot'),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Iconsax.message_text_1,
                  size: 22, color: AppColors.accent),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusRound),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color)),
      ]),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final ItineraryStep step;
  final int index;
  final bool isLast;
  final VoidCallback onPlaceTap;

  const _TimelineStep({
    required this.step,
    required this.index,
    required this.isLast,
    required this.onPlaceTap,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${index + 1}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.accent.withOpacity(0.2),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Step content
          Expanded(
            child: GestureDetector(
              onTap: onPlaceTap,
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(step.time,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teal)),
                  ),
                  const SizedBox(height: 8),
                  Text(step.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(step.description,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Iconsax.arrow_right_3,
                        size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    const Text('Voir ce site',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent)),
                  ]),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}