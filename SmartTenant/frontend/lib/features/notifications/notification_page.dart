import 'package:flutter/material.dart';

import '../tickets/ticket_details_page.dart';
import 'notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<dynamic> notifications = [];

  bool loading = true;
  bool loadingMore = false;
  bool markingAll = false;

  String error = '';

  int page = 1;
  int totalPages = 1;
  int unread = 0;
  int total = 0;

  String filter = 'ALL';

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);
  static const darkText = Color(0xFF1D1B20);

  @override
  void initState() {
    super.initState();
    load(reset: true);
  }

  Future<void> load({bool reset = false}) async {
    if (reset) {
      setState(() {
        loading = true;
        error = '';
        page = 1;
      });
    } else {
      setState(() {
        loadingMore = true;
      });
    }

    try {
      final data = await NotificationService.getMine(
        page: reset ? 1 : page,
        limit: 30,
      );

      final items = data['items'];
      final meta = data['meta'];

      if (!mounted) return;

      setState(() {
        if (reset) {
          notifications = items is List ? items : [];
        } else {
          notifications.addAll(items is List ? items : []);
        }

        page = meta?['page'] is int ? meta['page'] : page;
        totalPages = meta?['totalPages'] is int ? meta['totalPages'] : 1;
        unread = meta?['unread'] is int ? meta['unread'] : 0;
        total = meta?['total'] is int ? meta['total'] : notifications.length;

        loading = false;
        loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
        loadingMore = false;
      });
    }
  }

  Future<void> loadMore() async {
    if (loadingMore || page >= totalPages) return;

    setState(() {
      page += 1;
    });

    await load(reset: false);
  }

  Future<void> markAllAsRead() async {
    if (unread == 0) return;

    setState(() => markingAll = true);

    try {
      await NotificationService.markAllAsRead();

      if (!mounted) return;

      await load(reset: true);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => markingAll = false);
      }
    }
  }

  Future<void> markAsRead(dynamic notification) async {
    final id = notification['id']?.toString();
    if (id == null) return;

    if (notification['isRead'] == true) return;

    try {
      await NotificationService.markAsRead(id);

      if (!mounted) return;

      setState(() {
        notification['isRead'] = true;
        notification['readAt'] = DateTime.now().toIso8601String();
        if (unread > 0) unread -= 1;
      });
    } catch (_) {}
  }

  Future<void> deleteNotification(dynamic notification) async {
    final id = notification['id']?.toString();
    if (id == null) return;

    try {
      await NotificationService.delete(id);

      if (!mounted) return;

      setState(() {
        notifications.removeWhere((item) => item['id'] == id);
        total = total > 0 ? total - 1 : 0;

        if (notification['isRead'] != true && unread > 0) {
          unread -= 1;
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> openNotification(dynamic notification) async {
    await markAsRead(notification);

    final resource = notification['resource']?.toString();
    final resourceId = notification['resourceId']?.toString();

    if (resource == 'Ticket' && resourceId != null && resourceId.isNotEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TicketDetailsPage(ticketId: resourceId),
        ),
      );

      await load(reset: true);
      return;
    }

    showDetails(notification);
  }

  List<dynamic> get filteredNotifications {
    if (filter == 'UNREAD') {
      return notifications.where((n) => n['isRead'] != true).toList();
    }

    if (filter == 'READ') {
      return notifications.where((n) => n['isRead'] == true).toList();
    }

    return notifications;
  }

  String formatDate(dynamic value) {
    if (value == null) return '—';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    return parsed.toLocal().toString().split('.')[0];
  }

  Color typeColor(String? type) {
    switch (type) {
      case 'TICKET':
        return primary;
      case 'MESSAGE':
        return Colors.blue;
      case 'ASSIGNMENT':
        return Colors.orange;
      case 'STATUS':
        return Colors.green;
      case 'WARNING':
        return Colors.red;
      case 'PAYMENT':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData typeIcon(String? type) {
    switch (type) {
      case 'TICKET':
        return Icons.construction;
      case 'MESSAGE':
        return Icons.chat;
      case 'ASSIGNMENT':
        return Icons.assignment_ind;
      case 'STATUS':
        return Icons.sync;
      case 'WARNING':
        return Icons.warning_amber;
      case 'PAYMENT':
        return Icons.payments;
      default:
        return Icons.notifications;
    }
  }

  int get unreadVisible {
    return notifications.where((n) => n['isRead'] != true).length;
  }

  int get readVisible {
    return notifications.where((n) => n['isRead'] == true).length;
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
              fontSize: 19,
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
          colors: [Color(0xFF6750A4), Color(0xFF8B7DD8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_active, color: Colors.white, size: 44),

          const SizedBox(height: 18),

          const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Stay updated on tickets, assignments, replies and important activity.',
            style: TextStyle(color: Colors.white70),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Unread',
                  value: unread.toString(),
                  icon: Icons.mark_email_unread,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Total',
                  value: total.toString(),
                  icon: Icons.notifications,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget filterBar() {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: Text('All (${notifications.length})'),
            selected: filter == 'ALL',
            onSelected: (_) => setState(() => filter = 'ALL'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceChip(
            label: Text('Unread ($unreadVisible)'),
            selected: filter == 'UNREAD',
            onSelected: (_) => setState(() => filter = 'UNREAD'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceChip(
            label: Text('Read ($readVisible)'),
            selected: filter == 'READ',
            onSelected: (_) => setState(() => filter = 'READ'),
          ),
        ),
      ],
    );
  }

  Widget notificationCard(dynamic notification) {
    final type = notification['type']?.toString() ?? 'INFO';
    final isRead = notification['isRead'] == true;
    final color = typeColor(type);

    return Dismissible(
      key: ValueKey(notification['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await deleteNotification(notification);
        return false;
      },
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => openNotification(notification),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: color.withOpacity(0.12),
                      child: Icon(typeIcon(type), color: color),
                    ),
                    if (!isRead)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title']?.toString() ?? 'Notification',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: darkText,
                          fontWeight: isRead
                              ? FontWeight.w600
                              : FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        notification['body']?.toString() ?? '',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.35,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Chip(
                            label: Text(type),
                            backgroundColor: color.withOpacity(0.12),
                            labelStyle: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                            side: BorderSide.none,
                          ),
                          Chip(
                            label: Text(formatDate(notification['createdAt'])),
                            backgroundColor: softBg,
                            labelStyle: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                            side: BorderSide.none,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => showActions(notification),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showActions(dynamic notification) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isRead = notification['isRead'] == true;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: softBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
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

                const SizedBox(height: 18),

                ListTile(
                  leading: const Icon(Icons.open_in_new),
                  title: const Text('Open'),
                  onTap: () {
                    Navigator.pop(context);
                    openNotification(notification);
                  },
                ),

                if (!isRead)
                  ListTile(
                    leading: const Icon(Icons.done),
                    title: const Text('Mark as read'),
                    onTap: () {
                      Navigator.pop(context);
                      markAsRead(notification);
                    },
                  ),

                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Details'),
                  onTap: () {
                    Navigator.pop(context);
                    showDetails(notification);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    deleteNotification(notification);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showDetails(dynamic notification) {
    final type = notification['type']?.toString() ?? 'INFO';
    final color = typeColor(type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.68,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: softBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: ListView(
                  controller: controller,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: color.withOpacity(0.12),
                          child: Icon(typeIcon(type), color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            notification['title']?.toString() ?? 'Notification',
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          notification['body']?.toString() ?? '',
                          style: const TextStyle(fontSize: 15, height: 1.45),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    detailCard('Details', {
                      'Type': type,
                      'Resource': notification['resource'],
                      'Resource ID': notification['resourceId'],
                      'Read': notification['isRead'],
                      'Created': formatDate(notification['createdAt']),
                      'Read At': formatDate(notification['readAt']),
                    }),

                    const SizedBox(height: 12),

                    jsonCard('Metadata', notification['metadata']),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget detailCard(String title, Map<String, dynamic> values) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ...values.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        '${entry.key}:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: SelectableText(entry.value?.toString() ?? '—'),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget jsonCard(String title, dynamic value) {
    final text = value == null ? 'No data' : value.toString();

    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.data_object),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(text),
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.notifications_off,
              size: 62,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            const Text(
              'No notifications found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              filter == 'ALL'
                  ? 'Important ticket updates, assignments and replies will appear here.'
                  : 'No notifications match this filter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => load(reset: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget loadingBody() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget errorBody() {
    return RefreshIndicator(
      onRefresh: () => load(reset: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 120),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 42),
                  const SizedBox(height: 12),
                  const Text(
                    'Could not load notifications',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () => load(reset: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget bodyContent() {
    final data = filteredNotifications;

    return RefreshIndicator(
      onRefresh: () => load(reset: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          heroHeader(),

          const SizedBox(height: 18),

          filterBar(),

          const SizedBox(height: 14),

          if (data.isEmpty) emptyState() else ...data.map(notificationCard),

          if (page < totalPages) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: loadingMore ? null : loadMore,
                icon: loadingMore
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more),
                label: Text(loadingMore ? 'Loading...' : 'Load More'),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: markingAll ? null : markAllAsRead,
              child: markingAll
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Read all'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => load(reset: true),
          ),
        ],
      ),
      body: loading
          ? loadingBody()
          : error.isNotEmpty
          ? errorBody()
          : bodyContent(),
    );
  }
}
