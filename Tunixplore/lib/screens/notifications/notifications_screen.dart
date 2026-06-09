import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/models.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ─────────────────────────────
  // STREAM (user + global notifications)
  // ─────────────────────────────
  Stream<QuerySnapshot> get _stream {
    final uid = _uid;

    if (uid == null) return const Stream.empty();

    return _db
        .collection('notifications')
        .where('userId', whereIn: [uid, 'all'])
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ─────────────────────────────
  // MARK AS READ (safe for "all")
  // ─────────────────────────────
  Future<void> _markAsRead(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) return;

    // Do NOT modify global notifications
    if (data['userId'] == 'all') return;

    await doc.reference.update({'isRead': true});
  }

  Future<void> _markAllAsRead(List<QueryDocumentSnapshot> docs) async {
    final batch = _db.batch();

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      if (data['userId'] == 'all') continue;

      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  Future<void> _deleteNotification(String id) async {
    await _db.collection('notifications').doc(id).delete();
  }

  // ─────────────────────────────
  NotificationType _parseType(String type) {
    switch (type) {
      case 'registration':
        return NotificationType.registration;
      case 'promotion':
        return NotificationType.promotion;
      case 'reminder':
        return NotificationType.reminder;
      case 'alert':
        return NotificationType.alert;
      case 'newEvent':
        return NotificationType.newEvent;
      default:
        return NotificationType.alert;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    if (timestamp is Timestamp) {
      final d = timestamp.toDate();
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
    }

    return timestamp.toString();
  }

  bool _isUnread(Map<String, dynamic> data) {
    return data['isRead'] == false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ─────────────────────────────
      appBar: AppBar(
        title: StreamBuilder<QuerySnapshot>(
          stream: _stream,
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            final unread = docs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              return _isUnread(data);
            }).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Notifications'),
                if (unread > 0)
                  Text(
                    '$unread non lue(s)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            );
          },
        ),

        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _stream,
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) return const SizedBox.shrink();

              return TextButton(
                onPressed: () => _markAllAsRead(docs),
                child: const Text(
                  'Tout lire',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      // ─────────────────────────────
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.notification_bing,
                    size: 60,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Aucune notification',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Vous êtes à jour! 🎉',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: AppConstants.pagePadding,
            ),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),

            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;

              final notif = NotificationModel(
                id: doc.id,
                title: data['title'] ?? '',
                message: data['message'] ?? '',
                time: _formatTimestamp(data['createdAt']),
                type: _parseType(data['type'] ?? ''),
                isRead: data['isRead'] ?? false,
              );

              return Dismissible(
                key: Key(notif.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _deleteNotification(notif.id),

                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                  ),
                  child: const Icon(
                    Iconsax.trash,
                    color: AppColors.error,
                    size: 22,
                  ),
                ),

                child: _NotifTile(notif: notif, onTap: () => _markAsRead(doc)),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────
// TILE
// ─────────────────────────────
class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onTap;

  const _NotifTile({required this.notif, required this.onTap});

  IconData get _icon {
    switch (notif.type) {
      case NotificationType.registration:
        return Iconsax.ticket;
      case NotificationType.promotion:
        return Iconsax.discount_shape;
      case NotificationType.reminder:
        return Iconsax.clock;
      case NotificationType.alert:
        return Iconsax.warning_2;
      case NotificationType.newEvent:
        return Iconsax.calendar_add;
    }
  }

  Color get _color {
    switch (notif.type) {
      case NotificationType.registration:
        return AppColors.success;
      case NotificationType.promotion:
        return AppColors.accent;
      case NotificationType.reminder:
        return AppColors.teal;
      case NotificationType.alert:
        return AppColors.warning;
      case NotificationType.newEvent:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animFast,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead
              ? AppColors.surface
              : AppColors.accent.withOpacity(0.04),
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(
            color: notif.isRead
                ? AppColors.border
                : AppColors.accent.withOpacity(0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: _color, size: 20),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notif.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        const Icon(
                          Icons.circle,
                          size: 8,
                          color: AppColors.accent,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notif.time,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
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
}
