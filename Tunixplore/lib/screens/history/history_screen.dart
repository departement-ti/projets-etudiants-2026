import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/models.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.calendar, size: 60, color: AppColors.textHint),
          SizedBox(height: 16),
          Text(
            'Aucune inscription',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Participez à un événement pour le voir ici!',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RegCard extends StatelessWidget {
  final RegistrationModel reg;

  const _RegCard({required this.reg});

  Color get _statusColor {
    switch (reg.status) {
      case RegistrationStatus.upcoming:
        return AppColors.info;
      case RegistrationStatus.completed:
        return AppColors.success;
      case RegistrationStatus.cancelled:
        return AppColors.error;
    }
  }

  String get _statusLabel {
    switch (reg.status) {
      case RegistrationStatus.upcoming:
        return 'À venir';
      case RegistrationStatus.completed:
        return 'Terminé';
      case RegistrationStatus.cancelled:
        return 'Annulé';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.radiusLg),
            ),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: reg.eventImage,
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          reg.eventTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // INFO
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Iconsax.calendar, size: 14),
                    const SizedBox(width: 6),
                    Text(reg.eventDate, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Iconsax.location, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reg.eventLocation,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${reg.participants} participant(s)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      reg.price == '0' ? 'Gratuit' : '${reg.price} TND',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            context.push('/registration/${reg.id}'),
                        child: const Text('Détails'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (reg.status == RegistrationStatus.upcoming)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showCancelDialog(context, reg),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          child: const Text('Annuler'),
                        ),
                      ),
                    if (reg.status == RegistrationStatus.completed)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              context.push('/reviews/${reg.eventId}'),
                          child: const Text('Avis'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _filterIdx = 0;

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> get _stream {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('registrations')
        .where('userId', isEqualTo: uid)
        // .orderBy('createdAt', descending: true)
        .snapshots();
  }

  List<QueryDocumentSnapshot> _filter(List<QueryDocumentSnapshot> docs) {
    if (_filterIdx == 1) {
      return docs.where((d) => d['status'] == 'upcoming').toList();
    }
    if (_filterIdx == 2) {
      return docs.where((d) => d['status'] == 'completed').toList();
    }
    if (_filterIdx == 3) {
      return docs.where((d) => d['status'] == 'cancelled').toList();
    }
    return docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mes Inscriptions')),

      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const _EmptyState();
          }

          final docs = _filter(snapshot.data!.docs);

          return Column(
            children: [
              // ── FILTERS ─────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.pagePadding,
                  14,
                  AppConstants.pagePadding,
                  0,
                ),
                child: Row(
                  children: [
                    _chip('Tous', 0, docs.length),
                    const SizedBox(width: 8),
                    _chip(
                      'À venir',
                      1,
                      snapshot.data!.docs
                          .where((d) => d['status'] == 'upcoming')
                          .length,
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      'Terminés',
                      2,
                      snapshot.data!.docs
                          .where((d) => d['status'] == 'completed')
                          .length,
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      'Annulés',
                      3,
                      snapshot.data!.docs
                          .where((d) => d['status'] == 'cancelled')
                          .length,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.pagePadding,
                    14,
                    AppConstants.pagePadding,
                    100,
                  ),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),

                  // ✅ CLEAN MODEL USAGE
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;

                    final reg = RegistrationModel.fromMap(doc.id, data);

                    return _RegCard(reg: reg);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String label, int idx, int count) {
    final selected = _filterIdx == idx;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterIdx = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withOpacity(0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.accent : AppColors.textPrimary,
                ),
              ),
              Text(label, style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

void _showCancelDialog(BuildContext context, RegistrationModel reg) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Annuler ?"),
      content: const Text("Cette action est irréversible."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("Retour"),
        ),

        ElevatedButton(
          onPressed: () async {
            try {
              final db = FirebaseFirestore.instance;
              final currentUser = FirebaseAuth.instance.currentUser;

              if (currentUser == null) return;

              // ─────────────────────────────
              // Get event document
              // ─────────────────────────────
              final eventDoc = await db
                  .collection('events')
                  .doc(reg.eventId)
                  .get();

              final eventData = eventDoc.data();

              if (eventData == null) {
                throw Exception("Événement introuvable");
              }

              // ─────────────────────────────
              // Batch
              // ─────────────────────────────
              final batch = db.batch();

              // Registration reference
              final regRef = db.collection('registrations').doc(reg.id);

              // Event reference
              final eventRef = db.collection('events').doc(reg.eventId);

              // ─────────────────────────────
              // Delete registration
              // ─────────────────────────────
              batch.delete(regRef);

              // ─────────────────────────────
              // Decrement participants
              // ─────────────────────────────
              batch.update(eventRef, {
                'currentParticipants': FieldValue.increment(-reg.participants),
              });

              // ─────────────────────────────
              // Notify organiser
              // ─────────────────────────────
              final notifRef = db.collection('notifications').doc();

              batch.set(notifRef, {
                'id': notifRef.id,

                // receiver
                'userId': eventData['organiserId'],

                // sender
                'senderId': currentUser.uid,
                'senderName': currentUser.displayName ?? 'Utilisateur',

                // notification
                'type': 'event_cancellation',
                'title': 'Participation annulée',
                'message':
                    '${currentUser.displayName ?? 'Un utilisateur'} '
                    'a annulé sa participation à votre événement '
                    '"${eventData['title']}".',

                // event data
                'eventId': reg.eventId,
                'eventTitle': eventData['title'],
                'eventImage': eventData['imageUrl'],

                // status
                'isRead': false,
                'createdAt': FieldValue.serverTimestamp(),
              });

              // ─────────────────────────────
              // Commit
              // ─────────────────────────────
              await batch.commit();

              // ─────────────────────────────
              // Close dialog
              // ─────────────────────────────
              Navigator.pop(ctx);

              // ─────────────────────────────
              // Success snackbar
              // ─────────────────────────────
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Inscription annulée avec succès"),
                ),
              );
            } catch (e) {
              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Erreur: ${e.toString()}")),
              );
            }
          },
          child: const Text("Confirmer"),
        ),
      ],
    ),
  );
}
