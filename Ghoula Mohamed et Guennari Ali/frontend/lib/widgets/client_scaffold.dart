import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';

class ClientScaffold extends StatefulWidget {
  final Widget body;
  final String currentRoute;

  const ClientScaffold({
    super.key,
    required this.body,
    this.currentRoute = '/catalogue',
  });

  @override
  State<ClientScaffold> createState() => _ClientScaffoldState();
}

class _ClientScaffoldState extends State<ClientScaffold> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().startPolling();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final notif = Provider.of<NotificationProvider>(context);
    final role = auth.role;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.kTextPrimary,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.kSurfaceWhite,
                AppTheme.kPrimaryOrange.withValues(alpha: 0.04),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.kBlack.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/rayhan_icon.png',
              width: 22,
              height: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'RayhanERP',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.kTextPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        actions: [
          if (role == 'ROLE_CLIENT') ...[
            TextButton(
              onPressed: () => context.go('/catalogue'),
              child: Text(
                'Catalogue',
                style: TextStyle(
                  color: widget.currentRoute.startsWith('/catalogue')
                      ? Colors.amber
                      : AppTheme.kTextPrimary,
                  fontWeight: widget.currentRoute.startsWith('/catalogue')
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/mes-commandes'),
              child: Text(
                'Mes commandes',
                style: TextStyle(
                  color: widget.currentRoute.startsWith('/mes-commandes')
                      ? Colors.amber
                      : AppTheme.kTextPrimary,
                  fontWeight: widget.currentRoute.startsWith('/mes-commandes')
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    notif.markAllAsRead();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Notifications marquées comme lues')),
                    );
                  },
                ),
                if (notif.unreadCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${notif.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.go('/mon-profil'),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ],
      ),
      body: widget.body,
    );
  }
}
