import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../constants/app_theme.dart';
import '../widgets/role_guard.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final role = auth.role;

    if (role == 'ROLE_CLIENT') return const SizedBox.shrink();

    return Drawer(
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppTheme.kPrimaryGradient),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.kWhite.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person, color: AppTheme.kWhite, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  auth.isAuthenticated ? auth.user ?? 'VISITEUR' : 'VISITEUR',
                  style: const TextStyle(
                      color: AppTheme.kWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _roleLabel(auth.role),
                  style: TextStyle(
                      color: AppTheme.kWhite.withValues(alpha: 0.8), fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (role == 'ROLE_PDG')
                  _item(context, Icons.dashboard_rounded, 'Tableau de bord',
                      '/dashboard', role),
                if (role == 'ROLE_PDG')
                  _item(context, Icons.inventory_2_rounded, 'Articles',
                      '/articles', role),
                if (role == 'ROLE_PDG' || role == 'ROLE_RESPONSABLE_VENTE')
                  _item(context, Icons.shopping_cart_rounded, 'Ventes',
                      '/ventes', role),
                if (role == 'ROLE_PDG' || role == 'ROLE_RESPONSABLE_VENTE')
                  _item(context, Icons.people_rounded, 'Clients',
                      '/clients', role),
                if (role == 'ROLE_PDG' || role == 'ROLE_RESPONSABLE_ACHAT')
                  _item(context, Icons.factory_rounded, 'Fournisseurs',
                      '/fournisseurs', role),
                if (role == 'ROLE_PDG' || role == 'ROLE_RESPONSABLE_ACHAT')
                  _item(context, Icons.local_shipping_rounded, 'Achats',
                      '/achats', role),
                if (role == 'ROLE_PDG' || role == 'ROLE_RESPONSABLE_PRODUCTION')
                  _item(context, Icons.precision_manufacturing_rounded,
                      'Production', '/production', role),
                _item(context, Icons.warehouse_rounded, 'Stock', '/stock', role),
                if (role == 'ROLE_PDG') ...[
                  _item(context, Icons.people_alt_rounded, 'Utilisateurs', '/utilisateurs', role),
                  _item(context, Icons.assessment_rounded, 'Rapports', '/rapports', role),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.kErrorRed),
            title: const Text('Déconnexion',
                style: TextStyle(color: AppTheme.kErrorRed)),
            onTap: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, String route,
      String? role) {
    final selected = currentRoute == route;
    final hasAccess = RoleGuard.hasAccess(role, route);
    final color = selected ? AppTheme.kPrimaryTeal : AppTheme.kTextPrimary;
    final opacity = hasAccess ? 1.0 : 0.4;

    return Opacity(
      opacity: opacity,
      child: ListTile(
        selected: selected,
        selectedTileColor: AppTheme.kPrimaryTealLight,
        leading: Icon(icon, color: color, size: 22),
        title: Text(label,
            style: TextStyle(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: hasAccess
            ? () {
                Navigator.pop(context);
                if (currentRoute != route) context.go(route);
              }
            : null,
      ),
    );
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'ROLE_PDG':
        return 'Gérant';
      case 'ROLE_RESPONSABLE_VENTE':
        return 'Responsable Ventes';
      case 'ROLE_RESPONSABLE_ACHAT':
        return 'Responsable Achats';
      case 'ROLE_RESPONSABLE_PRODUCTION':
        return 'Responsable Production';
      case 'ROLE_MAGASINIER':
        return 'Magasinier';
      case 'ROLE_CLIENT':
        return 'Client';
      default:
        return role?.replaceAll('ROLE_', '') ?? 'VISITEUR';
    }
  }
}
