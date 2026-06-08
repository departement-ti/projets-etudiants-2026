import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class RoleGuard {
  static const Map<String, List<String>> routeRoles = {
    '/dashboard': ['ROLE_PDG'],
    '/articles': ['ROLE_PDG'],
    '/ventes': ['ROLE_PDG', 'ROLE_RESPONSABLE_VENTE'],
    '/clients': ['ROLE_PDG', 'ROLE_RESPONSABLE_VENTE'],
    '/achats': ['ROLE_PDG', 'ROLE_RESPONSABLE_ACHAT'],
    '/fournisseurs': ['ROLE_PDG', 'ROLE_RESPONSABLE_ACHAT'],
    '/production': ['ROLE_PDG', 'ROLE_RESPONSABLE_PRODUCTION'],
    '/stock': ['ROLE_PDG', 'ROLE_RESPONSABLE_VENTE', 'ROLE_RESPONSABLE_ACHAT', 'ROLE_RESPONSABLE_PRODUCTION', 'ROLE_MAGASINIER'],
    '/rapports': ['ROLE_PDG'],
    '/utilisateurs': ['ROLE_PDG'],
  };

  static bool hasAccess(String? role, String route) {
    if (role == 'ROLE_PDG') return true;
    final baseRoute = '/' + route.split('/').where((s) => s.isNotEmpty).first;
    final allowed = routeRoles[route] ?? routeRoles[baseRoute];
    if (allowed == null) return true;
    if (role == null) return false;
    return allowed.contains(role);
  }

  static String getDefaultRoute(String? role) {
    if (role == 'ROLE_PDG') return '/dashboard';
    if (role == 'ROLE_RESPONSABLE_VENTE') return '/ventes';
    if (role == 'ROLE_RESPONSABLE_ACHAT' || role == 'ROLE_MAGASINIER') return '/stock';
    if (role == 'ROLE_RESPONSABLE_PRODUCTION') return '/production';
    if (role == 'ROLE_FOURNISSEUR') return '/';
    if (role == 'ROLE_CLIENT') return '/catalogue';
    return '/dashboard';
  }
}

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.kCtaOrangeLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    color: AppTheme.kCtaOrange, size: 48),
              ),
              const SizedBox(height: 24),
              Text('Accès non autorisé',
                  style: AppTheme.headlineSmall.copyWith(fontSize: 20)),
              const SizedBox(height: 8),
              Text(
                'Vous n\'avez pas les permissions nécessaires pour accéder à cette page.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.kTextSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
                style: AppTheme.primaryButton,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
