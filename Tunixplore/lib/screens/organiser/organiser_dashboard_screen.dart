import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';

class OrganiserDashboardScreen extends StatefulWidget {
  const OrganiserDashboardScreen({super.key});

  @override
  State<OrganiserDashboardScreen> createState() =>
      _OrganiserDashboardScreenState();
}

class _OrganiserDashboardScreenState extends State<OrganiserDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late UserModel user;
  late Stream<QuerySnapshot> _organiserEvents;
  int eventsCount = 0;
  int participantsCount = 0;
  double? rating;

  // Mock organiser events (filter by org1)
  Stream<List<EventModel>> get _myEvents {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('events')
        .where('organiserId', isEqualTo: uid)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromJson(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  void initState() {
    super.initState();
    _load();
    _tab = TabController(length: 2, vsync: this);
  }

  Future<UserModel> getCurrentUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      throw Exception('No authenticated user');
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (!doc.exists || doc.data() == null) {
      throw Exception('User not found');
    }

    return UserModel.fromJson(doc.id, doc.data()!);
  }

  Future<List<EventModel>> getMyEvents(String organiserId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('organiserId', isEqualTo: organiserId)
        .get();

    return snapshot.docs
        .map((doc) => EventModel.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<void> _load() async {
    final u = await getCurrentUser();

    setState(() {
      user = u;

      _organiserEvents = FirebaseFirestore.instance
          .collection('events')
          .where('organiserId', isEqualTo: user.id)
          .where('isActive', isEqualTo: true)
          .snapshots();
    });
  }

  Future<void> _loadEvents() async {
    final events = await getMyEvents(user.id);

    setState(() {
      eventsCount = events.length;
      participantsCount = events.fold(0, (s, e) => s + e.currentParticipants);

      rating = events.isEmpty
          ? null
          : events.fold(0.0, (s, e) => s + e.rating) / events.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: AppConstants.pagePadding,
                right: AppConstants.pagePadding,
                bottom: 24,
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
                            user.role == UserRole.organiserAgency
                                ? 'Agence'
                                : 'Espace Organisateur',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            user.role == UserRole.organiserAgency
                                ? (user.agencyName ?? user.name)
                                : user.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.push('/settings'),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundImage: user.avatarUrl.isNotEmpty
                              ? NetworkImage(user.avatarUrl)
                              : null,
                          child: user.avatarUrl.isEmpty
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  StreamBuilder<List<EventModel>>(
                    stream: _myEvents,
                    builder: (context, snapshot) {
                      final events = snapshot.data ?? [];

                      final eventsCount = events.length;

                      final participantsCount = events.fold(
                        0,
                        (s, e) => s + e.currentParticipants,
                      );

                      final rating = events.isEmpty
                          ? null
                          : events.fold<double>(
                                  0.0,
                                  (s, e) => s + (e.rating ?? 0.0),
                                ) /
                                events.length;

                      return Row(
                        children: [
                          _DashStat(
                            label: 'Événements',
                            value: '$eventsCount',
                            icon: Iconsax.calendar_tick,
                            color: AppColors.teal,
                          ),
                          const SizedBox(width: 10),

                          _DashStat(
                            label: 'Participants',
                            value: '$participantsCount',
                            icon: Iconsax.people,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 10),

                          _DashStat(
                            label: 'Avis',
                            value: rating != null
                                ? '${rating!.toStringAsFixed(1)}' /*★*/
                                : '—',
                            icon: Iconsax.star,
                            color: AppColors.amber,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: TabBar(
              controller: _tab,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.accent,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(text: 'Mes événements'),
                Tab(text: 'Statistiques'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            // ── My Events Tab ────────────────────────────────────────────
            StreamBuilder<List<EventModel>>(
              stream: _myEvents,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final events = snapshot.data ?? [];
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.pagePadding,
                    16,
                    AppConstants.pagePadding,
                    100,
                  ),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _OrgEventTile(event: events[i]),
                );
              },
            ),

            // ── Statistics Tab ────────────────────────────────────────────
            StreamBuilder<List<EventModel>>(
              stream: _myEvents,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final events = snapshot.data ?? [];
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Performance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...events.map((e) => _StatRow(event: e)),
                      const SizedBox(height: 20),
                      const Text(
                        'Répartition par type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _TypeBreakdown(events: events),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/organiser/create'),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Créer un événement',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _DashStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _DashStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrgEventTile extends StatelessWidget {
  final EventModel event;
  const _OrgEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final fillPct = event.maxParticipants == 0
        ? 0.0
        : event.currentParticipants / event.maxParticipants;

    final isFull = event.currentParticipants >= event.maxParticipants;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _StatusBadge(isFull: isFull),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(
                Iconsax.calendar,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                event.date,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(
                Iconsax.location,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                event.region,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${event.currentParticipants}/${event.maxParticipants} participants',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${(fillPct * 100).round()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: fillPct >= 0.9
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fillPct.clamp(0.0, 1.0),
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          fillPct >= 0.9 ? AppColors.error : AppColors.success,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/organiser/event-edit/${event.id}'),
                  icon: const Icon(Iconsax.edit, size: 14),
                  label: const Text('Modifier'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Annuler l’événement'),
                        content: const Text(
                          'Êtes-vous sûr de vouloir annuler cet événement ?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Non'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Oui, continuer'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      try {
                        final firestore = FirebaseFirestore.instance;

                        // Récupérer tous les utilisateurs
                        final usersSnapshot = await firestore
                            .collection('users')
                            .get();

                        // Batch pour envoyer les notifications
                        final batch = firestore.batch();

                        for (final userDoc in usersSnapshot.docs) {
                          final notificationRef = firestore
                              .collection('notifications')
                              .doc();

                          batch.set(notificationRef, {
                            'createdAt': FieldValue.serverTimestamp(),
                            'isRead': false,
                            'message':
                                'L’événement "${event.title}" a été annulé.',
                            'title': 'Événement annulé',
                            'type': 'event_cancelled',
                            'userId': userDoc.id,
                          });
                        }

                        // Envoyer les notifications
                        await batch.commit();

                        // DEBUG:
                        // Suppression de l’événement désactivée temporairement

                        await firestore
                            .collection('events')
                            .doc(event.id)
                            .delete();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Notifications envoyées avec succès',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur : $e')),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Iconsax.close_circle, size: 14),
                  label: const Text('Annuler'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isFull;
  const _StatusBadge({required this.isFull});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isFull ? AppColors.error : AppColors.success).withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusRound),
      ),
      child: Text(
        isFull ? 'Complet' : 'Ouvert',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isFull ? AppColors.error : AppColors.success,
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final EventModel event;
  const _StatRow({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              event.title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: event.maxParticipants == 0
                    ? 0
                    : event.currentParticipants / event.maxParticipants,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.accent,
                ),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${event.currentParticipants}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TypeBreakdown extends StatelessWidget {
  final List<EventModel> events;
  const _TypeBreakdown({required this.events});

  @override
  Widget build(BuildContext context) {
    final counts = <EventType, int>{};
    for (final e in events) {
      counts[e.type] = (counts[e.type] ?? 0) + 1;
    }

    return Column(
      children: counts.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                MockData.eventTypeLabel(entry.key),
                style: const TextStyle(fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${entry.value} événement(s)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
